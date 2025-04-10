obj-m += khbr_accel.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	sudo mkdir -p /lib/modules/$(shell uname -r)/kernel/drivers/khbr/
	sudo cp khbr_accel.ko /lib/modules/$(shell uname -r)/kernel/drivers/khbr/
	sudo depmod

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

