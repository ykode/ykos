.code16									    # 16-bit Assembly (real mode)
.text												# Mulai section text
.set MAGIC, 0xAA55					# Macro untuk MAGIC number boot record 

.globl BootEntry								# Simbol Entry Point

BootEntry: 
	cli                       # Matikan interrupt
	xor %ax, %ax              # AX = 0
	mov %ax, %ds              # DS = AX = 0
	mov %ax, %es              # ES = AX = 0
	mov %ax, %ss              # SS = AX = 0
	mov $0x7c00, %sp          # Set stack dari 0x7c00 ke bawah
	sti                       # Hidupkan interrupt

	lea hellostr, %si         # Cetak `Halo!'
	call WriteString

	cli                       # Matikan interrupt
	hlt                       # Halt (berhenti)

.func WriteString           # Fungsi WriteString direktif .func untuk menandai simbol debug
WriteString:
	lodsb                     # Muat 1 byte dari alamat [SI] ke AL, naikkan SI satu byte
	or %al, %al               # Cek apakah AL = 0, instruksi OR mengubah flag ZF
	jz .LDoneWrite            # Jika 0 lompat ke label lokal DoneWrite

	mov $0xe, %ah             # AH = 0Eh
	xor %bx, %bx              # BX = 0
	int $0x10                 # Cetak karakter ke layar
	jmp WriteString           # Ulang Lagi
.LDoneWrite:
	retw
.endfunc

# ----- SEGMEN DATA DI SINI ----

hellostr: .asciz "Halo!"    # Simpan string `Halo' di sini 'H', 'a', 'l', 'o', '\0'

# ----- Akhiri boot sector ----
.fill (510-(.-BootEntry)), 1, 0 # Isi sisanya sebelum magic dengan 0
bootmagic: .int MAGIC       # Akhiri dengan boot magic 0xAA55
