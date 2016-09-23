.code16                     # 16-bit Assembly (real mode)
.text                       # Mulai section text
.set MAGIC, 0xAA55          # Macro untuk MAGIC number boot record 
.set PRT_OFF, 0x1BE         # Ofset tempat tabel partisi berada
.set LOAD, 0x7c00           # Alamat kode ini dimuat oleh BIOS
.set ORIGIN, 0x0600         # Alamat relokasi kode

# Informasi disk
.set B0_BASE, 0x1ae           # Volume Serial Number
.set B0_OFF, (B0_BASE-0x200)  # Offset 
.set _FLAGS, B0_OFF + 9       # Flags
.set USEPACKET, 0x8           # Pakai modus paket

.globl BootEntry            # Simbol Entry Point

BootEntry: 

  cli                       # Matikan interrupt
  cld
  xorw %ax, %ax              # AX = 0
  movw %ax, %ds              # DS = AX = 0
  movw %ax, %es              # ES = AX = 0
  movw %ax, %ss              # SS = AX = 0
  movw $LOAD, %sp            # Set stack dari 0x7c00 ke bawah
  sti                       # Hidupkan interrupt

# Relakasi ke ORIGIN (0x600)
  movw %sp, %si             # Source = SP = $LOAD
  movw $BootEntry, %di      # Destination = ORIGIN = BootEntry
  movw $0x100, %cx          # Ukuran = 512 -> 1 sektor (2x256)
  rep movsw                 # Salin dari [DS:SI] -> [ES:DI]

# Bikin tabel partisi setelah code (DI, 0x800)
# Diinisialisasi dengan LBA 0 / CHS 0: 0: 1
# Arahkan BP ke partisi dengan ofset negatif dari akhir code

  movw %di, %bp             # Alamat Variable
  movb $0x8, %cl            # Clear LSB 
  rep stosw                 # Kosongkan semua
  incb -0xe(%di)            # Set S dari CHS ke 1
  jmp StartBoot-LOAD+ORIGIN # Lompat ke kode yang sudah direlokasi

StartBoot:

.ifdef SIO

  movw 9600, %ax            # 9600 baud
  callw BIOSCom             # Panggil fungsi BIOS 

.endif /* SIO */

  lea startbootmsg, %si         # Cetak `Cetak di disk'
  callw WriteString

# Tampilkan nomor disk boot

  movb %dl, %al                 # Simpan nomor disk u/ dicetak 
  andb $0x7F, %al               # Hilangkan MSB ( DL - 0x80)
  addb $0x30, %al               # AL = '0' + AL
  call WriteChar                # Tulis karakter ke layar
  lea  elipsis, %si             # Tulis elipsis
  call WriteString              #  ke layar
  call WriteN                   # Tulis baris baru

# Baca 1 sector ke 0000:7c00
ReadSector:

# Coba dengan mode CHS
  movw $(LOAD+PRT_OFF), %si
  movw $LOAD, %bx
  movb $0x2, %ah
  movb 0x1(%si), %dh
  movw 0x2(%si), %cx
  movb $0x1, %al
  
# Modifikasi nilai untuk LBA
# BP < register tempat awal tabel partisi
# Cek http://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)#LBA_in_Extended_Mode
  pushw %si
  movw  %sp, %di
  testb $USEPACKET, _FLAGS(%bp)
  jz ReadSector.1

  pushl $0x0       # { uint32_t LBA48 Upper Bit = 0
  pushl 0x8(%si)   #   uint32_t Start
  pushw %es        #   uint32_t segment
  pushw %bx        #   -------- offset = Tujuan
  push  $0x1       #   uint8_t jumlah sector | uint8_t reserved (zero)
  push  $0x10      #   ukuran paket (16 byte) }
  movw  %sp, %si   # DS:SI arahkan ke permukaan stack

  decw  %ax        # Dari CHS tadinya jumlah sektor, kita 0 kan saja 
  orb   $0x40, %ah # AH = 2 (sudah diset sebelumnya), AH = AH | 0x40 
                   # artinya AH=42H -> pakai modus paket
ReadSector.1:
  int  $0x13       # Layanan disk 

  movw %di, %sp    # Kembalikan stack pointer ke semula 
  popw %si         # Kembalikan 'source index' ke semula

  xor  %ah, %ah    # Reset disk
  int  $0x13       # --- JALANKAN!

  jmp  *%bx        # Lompat ke bx=0x7c00
  
.ifndef SIO
  callw Reboot
.endif

  cli                       # Matikan interrupt
  hlt                       # Halt (berhenti)

/* 
 * Fungsi-fungsi tampilan
 * WriteN         tulis baris baru
 * WriteString    tulis string yang ada di register SI
 * WriteChar      tulis karakter yang ada di AL
 *
 * Note: Urutan fungsi jangan diputar, karena berbeda
 * Akhir string bukan dengan byte baru tetapi dengan meng-OR kan
 * karakter dengan 0x80 sehingga MSB menjadi 1 sehingge menghemat 1 byte
 * tiap string daripada dengan .asciiz
 */

.func WriteN
WriteN:
  movw  $crlf, %si
  jmp   WriteString
.endfunc /* Write N */

.func WriteString           # Fungsi WriteString direktif .func untuk menandai simbol debug
WriteString.1: 
  callw WriteChar

WriteString:
  lodsb                     # Muat SI ke AL dan naikkan nilai SI 1 byte
  testb $0x80, %al          # Cek apakah AL = 0x80 (EOS)
  jz    WriteString.1
  andb  $~0x80, %al          # Buang MSB dan tulis karakter terakhir
.endfunc /* WriteString */  

.func WriteChar
WriteChar:

.ifndef SIO

  pushw %bx                 # Simpan BX
  movw  $0x7, %bx           # Page: Atribut
  movb  $0xe, %ah           # BIOS: Display
  int   $0x10               # Cetak ke layar
  popw  %bx                 # Kembalikan BX

.else

  movb  $0x01, %ah          # BIOS: Send Character

BIOSCom:
  pushw %dx
  xorw  %dx, %dx
  int   $0x14
  popw  %dx

.endif

  retw
.endfunc /* WriteChar */

Reboot:
  lea   rebootmsg, %si
  callw WriteString
  xorw  %ax, %ax
  int   $0x16
  ljmp  $0xFFFF, $0x0000  

# ----- SEGMEN DATA DI SINI ----
crlf:
  .ascii "\r" ; .byte  '\n' | 0x80 
hellostr: 
  .ascii "Halo" ; .byte '!' | 0x80
rebootmsg:
  .ascii "Tekan tombol apapun untuk mulai ulang" ; .byte '.' | 0x80
startbootmsg:
  .ascii "But dari disk"; .byte ' ' | 0x80
elipsis:
  .ascii ".."; .byte '.' | 0x80
# ----- Mulai tabel partisi ---
.fill (PRT_OFF-(.-BootEntry)), 0x1, 0xFF # Isi sisanya sebelum magic dengan 0xBA (atau nilai apapun)
.org PRT_OFF
.fill 0x40, 0x1, 0x0        # Tabel partisi palsu isi dengon 0
bootmagic: .int MAGIC       # Akhiri dengan boot magic 0xAA55

