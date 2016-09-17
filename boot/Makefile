AS := as
LD := ld
OBJCOPY := objcopy

.PHONY: all clean disk

all: disk

disk: disk.qcow

disk.qcow: boot.mbr
	if test -e /tmp/disk.raw; then  rm /tmp/disk.raw; fi
	dd if=/dev/zero of=/tmp/disk.raw bs=512 count=2880
	dd if=$< of=/tmp/disk.raw bs=512 count=1
	qemu-img convert -O qcow2 /tmp/disk.raw disk.qcow

boot.mbr: boot.bin
	dd of=$@ if=$< bs=512 count=1

boot.bin: boot.out
	$(OBJCOPY) -O binary -j .text boot.out boot.bin

boot.out: boot.o
	$(LD) -o $@ $^ -Ttext 0x7c00 -e BootEntry

boot.o: boot.S
	$(AS) -g -gstabs+ -o $@ $^

clean: 
	rm -f boot.mbr boot.bin boot.out boot.o disk.qcow 
