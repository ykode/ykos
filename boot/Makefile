# Set perintah untuk assembler, linker, dan object copier
AS := as
LD := ld
OBJCOPY := objcopy

# Target tanpa file,
# Target selain all hanya digunakan untuk alasan kepraktisan

.PHONY: all clean disk

all: disk

disk: disk.qcow disk.vdi

mbr: boot.mbr

# Membuat disk yang siap digunakan QEMU
disk.raw: boot.mbr
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$< of=$@ bs=512 count=1
	
disk.qcow: disk.raw
	qemu-img convert -c -O qcow2 $< $@
	
disk.vdi: disk.raw
	qemu-img convert -O vdi $< $@

# Membuat citra MBR 
boot.mbr: boot.bin
	dd of=$@ if=$< bs=512 count=1

# Membuat berkas biner flat
boot.bin: boot.out
	$(OBJCOPY) -O binary -j .text boot.out boot.bin

# Membuat berkas executable dari berkas objek
boot.out: boot.o
	$(LD) -o $@ $^ -Ttext 0x7c00 -e BootEntry

# Merakit berkas objek dari bahasa assembly
boot.o: boot.S
	$(AS) -g -gstabs+ -o $@ $^

# Membersihkan berkas
clean: 
	rm -f boot.mbr boot.bin boot.out boot.o disk.raw disk.qcow disk.vdi 
