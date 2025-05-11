/*
 *  Copyright 2025 Sergey Khabarov, sergeykhbr@gmail.com
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <linux/module.h>
#include <linux/pci.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/uaccess.h>

#define DRV_NAME "khbr_accel"
#define BAR_INDEX 0
#define FRAMEBUFFER_SIZE (1024*1024 * 2)//(1920 * 1080 * 4) // Assume 1080p RGBA


/**
 @todo: change it later:
    10ee Xilinx Corporation Vendor ID
    7021 Xilinx Corporation Device ID
    0007 Subsystem
 */
static const struct pci_device_id khbr_accel_ids[] = {
    { PCI_DEVICE(0x10ee, 0x7021), },
    { 0, }
};

MODULE_DEVICE_TABLE(pci, khbr_accel_ids);

struct private_driver_data {
    struct pci_dev *pdev;
    void __iomem *bar0;
    resource_size_t bar0_len;
    struct miscdevice miscdev;
};

// Single device assumption for now
static struct private_driver_data *g_accel;

static ssize_t khbr_read(struct file *f,
                         char *buf,
                         size_t len,
                         loff_t *off)
{
    if (!g_accel || !g_accel->bar0) {
        return -ENODEV;
    }

    if (*off  > FRAMEBUFFER_SIZE) {
        // No more data to read
        return 0;
    }

    if (*off + len > FRAMEBUFFER_SIZE) {
        len = FRAMEBUFFER_SIZE - *off;
    }

    if (copy_to_user(buf, g_accel->bar0 + *off, len)) {
        return -EFAULT;
    }
    *off += len;
    return len;
}

static ssize_t khbr_write(struct file *f,
                          const char __user *buf,
                          size_t len,
                          loff_t *off)
{
    if (!g_accel || !g_accel->bar0) {
        return -ENODEV;
    }

    if (*off > FRAMEBUFFER_SIZE) {
        // nothing to write
        return 0;
    }

    if (*off + len > FRAMEBUFFER_SIZE) {
        len = FRAMEBUFFER_SIZE - *off;
    }

    // Copy user framebuffer to device memory (BAR0)
    if (copy_from_user(g_accel->bar0 + *off, buf, len)) {
        return -EFAULT;
    }

    *off += len;
    // Optionally: trigger render start by writing to control register

    return len;
}

/**
    to support user application:
        lseek(fd, 1024, SEEK_SET);
        write(fd, data, 256);
 */
loff_t khbr_llseek(struct file *f,
                   loff_t off,
                   int whence)
{
    switch (whence) {
    case SEEK_SET:
        f->f_pos = off;
        break;
    case SEEK_CUR:
        f->f_pos += off;
        break;
    case SEEK_END:
        f->f_pos = FRAMEBUFFER_SIZE - off;
        break;
    default:
        return -EINVAL;
    }

    if (f->f_pos < 0 || f->f_pos > FRAMEBUFFER_SIZE) {
        return -EINVAL;
    }

    return f->f_pos;
}

/**
   To support mmap() DMA access in User Application:
       uint8_t *fb = mmap(NULL,
                          buf_size,
                          PROT_WRITE,
                          MAP_SHARED,
                          fd,
                          0);
 */
static int khbr_mmap(struct file *filp, struct vm_area_struct *vma)
{
    unsigned long phys_addr;
    size_t size = vma->vm_end - vma->vm_start;

    printk("khbr_mmap: requested=%d KB\n", (int)(size / 1024));

    if (!g_accel || !g_accel->bar0) {
        return -ENODEV;
    }

    if (size > FRAMEBUFFER_SIZE) {
        return -EINVAL;
    }

    // BAR0 physical address
    phys_addr = pci_resource_start(g_accel->pdev, BAR_INDEX);
    printk("khbr_mmap: phys_addr=%lx KB\n", phys_addr);

    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
    vma->vm_flags |= VM_IO | VM_DONTEXPAND | VM_DONTDUMP;

    // Remap BAR0 into userspace
    return remap_pfn_range(vma,
                           vma->vm_start,
                           phys_addr >> PAGE_SHIFT,
                           size,
                           vma->vm_page_prot);
}


static const struct file_operations khbr_fops = {
    .owner = THIS_MODULE,
    .read = khbr_read,
    .write = khbr_write,
    .llseek = khbr_llseek,
    .mmap = khbr_mmap,
};



static int khbr_accel_probe(struct pci_dev *pdev,
                            const struct pci_device_id *id)
{
    struct private_driver_data *accel;
    int err;

    pr_info(DRV_NAME ": Probing PCI device %04x:%04x (subsystem %04x:%04x)\n",
        pdev->vendor, pdev->device,
        pdev->subsystem_vendor, pdev->subsystem_device);

    accel = devm_kzalloc(&pdev->dev, sizeof(*accel), GFP_KERNEL);
    if (!accel) {
        return -ENOMEM;
    }

    pci_set_drvdata(pdev, accel);
    g_accel = accel;
    accel->pdev = pdev;

    err = pci_enable_device(pdev);
    if (err) {
        return err;
    }

    err = pci_request_regions(pdev, DRV_NAME);
    if (err) {
        goto disable_dev;
    }

    accel->bar0_len = pci_resource_len(pdev, BAR_INDEX);
    accel->bar0 = pci_iomap(pdev, BAR_INDEX, 0);
    if (!accel->bar0) {
        err = -EIO;
        goto release_regions;
    }

    accel->miscdev.minor = MISC_DYNAMIC_MINOR;
    accel->miscdev.name = DRV_NAME;
    accel->miscdev.fops = &khbr_fops;
    accel->miscdev.parent = &pdev->dev;

    err = misc_register(&accel->miscdev);
    if (err) {
        dev_err(&pdev->dev, "Failed to register misc device\n");
        goto unmap_bar0;
    }

    dev_info(&pdev->dev, "khbr_accel device initialized\n");
    return 0;

unmap_bar0:
    pci_iounmap(pdev, accel->bar0);
release_regions:
    pci_release_regions(pdev);
disable_dev:
    pci_disable_device(pdev);
    return err;
}

static void khbr_accel_remove(struct pci_dev *pdev)
{
    struct private_driver_data *accel = pci_get_drvdata(pdev);
    misc_deregister(&accel->miscdev);
    pci_iounmap(pdev, accel->bar0);
    pci_release_regions(pdev);
    pci_disable_device(pdev);
    dev_info(&pdev->dev, "khbr_accel removed\n");
}


static struct pci_driver khbr_accel_driver = {
    .name = DRV_NAME,
    .id_table = khbr_accel_ids,
    .probe = khbr_accel_probe,
    .remove = khbr_accel_remove,
};

// module_init/module_exit
module_pci_driver(khbr_accel_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Sergey Khabarov");
MODULE_DESCRIPTION("PCIe Math Accelerator");
