# Set perintah untuk assembler, linker, dan object copier
BASENAME := boot
DISK_BASENAME := disk
AS := as
LD := ld
OBJCOPY := objcopy
ASFLAGS := 

# Target tanpa file,
# Target selain all hanya digunakan untuk alasan kepraktisan

.PHONY: all clean disk

all: disk

disk: $(DISK_BASENAME).qcow $(DISK_BASENAME).vdi

mbr: $(BASENAME).mbr

# Membuat disk yang siap digunakan QEMU
$(DISK_BASENAME).raw: $(BASENAME).mbr
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$< of=$@ bs=512 count=1
	
$(DISK_BASENAME).qcow: $(DISK_BASENAME).raw
	qemu-img convert -c -O qcow2 $< $@
	
$(DISK_BASENAME).vdi: $(DISK_BASENAME).raw
	qemu-img convert -O vdi $< $@

# Membuat citra MBR 
$(BASENAME).mbr: $(BASENAME).bin
	dd of=$@ if=$< bs=512 count=1

# Membuat berkas biner flat
$(BASENAME).bin: $(BASENAME).out
	$(OBJCOPY) -O binary -j .text $(BASENAME).out $(BASENAME).bin

# Membuat berkas executable dari berkas objek
$(BASENAME).out: $(BASENAME).o
	$(LD) -o $@ $^ -Ttext 0x0600 -e BootEntry

# Merakit berkas objek dari bahasa assembly
$(BASENAME).o: boot.S
	$(AS) $(ASFLAGS) -g -gstabs+ -o $@ $^

# Membersihkan berkas
clean: 
	rm -f $(BASENAME).mbr $(BASENAME).bin $(BASENAME).out $(BASENAME).o \
		$(DISK_BASENAME).raw $(DISK_BASENAME).qcow $(DISK_BASENAME).vdi 
