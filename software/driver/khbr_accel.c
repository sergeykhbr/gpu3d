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
#define FRAMEBUFFER_SIZE (1920 * 1080 * 4) // Assume 1080p RGBA


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

static ssize_t khbr_write(struct file *f,
                          const char __user *buf,
                          size_t len, loff_t *off)
{
    if (!g_accel || !g_accel->bar0)
        return -ENODEV;

    if (len > FRAMEBUFFER_SIZE)
        return -EINVAL;

    // Copy user framebuffer to device memory (BAR0)
    if (copy_from_user(g_accel->bar0, buf, len))
        return -EFAULT;

    // Optionally: trigger render start by writing to control register

    return len;
}

static const struct file_operations khbr_fops = {
    .owner = THIS_MODULE,
    .write = khbr_write,
};



static int khbr_accel_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    struct private_driver_data *accel;
    int err;

    pr_info(DRV_NAME ": Probing PCI device %04x:%04x (subsystem %04x:%04x)\n",
        pdev->vendor, pdev->device, pdev->subsystem_vendor, pdev->subsystem_device);

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

module_pci_driver(khbr_accel_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Sergey Khabarov");
MODULE_DESCRIPTION("PCIe Math Accelerator");
