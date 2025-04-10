# To fix error: make[1]: *** No rule to make target 'modules'.  Stop.
#     sudo ln -s /usr/src/linux-headers-`uname -r` /lib/modules/`uname -r`/build
# To fix Skipping BTF generation for *.ko due to unavailability of vmlinux
#     sudo apt install dwarves
#     sudo cp /sys/kernel/btf/vmlinux /usr/lib/modules/6.1.0-32-amd64/build/
# To fix dmesg: Module verification failed: signature and/or required key missing - tainting kernel
#   

obj-m += khbr_accel.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	sudo mkdir -p /lib/modules/$(shell uname -r)/kernel/drivers/khbr/
	sudo cp khbr_accel.ko /lib/modules/$(shell uname -r)/kernel/drivers/khbr/
	sudo depmod

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

