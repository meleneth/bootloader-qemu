;; Boot sector
;; Loads kernel from the disk into memory
;; Switches processor to 32-bit Protected Mode
;; Executes loaded kernel

[org 0x7C00]
[bits 16]

;; memory offset where our kernel is located
KERNEL_OFFSET equ 0x1000

; Print '1' using BIOS interrupt 0x10
pusha
mov ah, 0x0E           ; BIOS teletype function
mov al, '2'            ; Character to print
mov bh, 0x00           ; Page number (0)
mov bl, 0x07           ; Text attribute (light grey on black background)
int 0x10               ; Call BIOS interrupt 0x10
popa
;; save the boot drive number
mov [BOOT_DRIVE], dl

;; update base and stack pointers
mov bp, 0x9000
mov sp, bp

;; call routine that loads kernel into memory
call load_kernel_into_memory

;; switch to Protected Mode
call switch_to_pm

;; routine reads kernel from disk into memory
load_kernel_into_memory:
	;; store all register values
	pusha

	;; set up parameters for disk_read routine
	mov bx, KERNEL_OFFSET
	mov dh, 15
	mov dl, [BOOT_DRIVE]
	call disk_read

	;; restore register values and ret
	popa
	ret

[bits 32]

begin_pm:
	;; Check if we can move from Protected Mode to Long Mode
	;; If something went wrong (detect_lm shouldn't return at all)
	;; we call execute_kernel in x32 Protected Mode
	call detect_lm
	call execute_kernel
	jmp $

[bits 64]

begin_lm:
	;; In case, if detect_lm and switch_to_lm works fine, call kernel in x64 mode
	call execute_kernel
	jmp $

execute_kernel:
	call KERNEL_OFFSET
	jmp $

;; Implementation for sector-based hard disk and floppy disk read\write
;; It uses BIOS INT 13h
;; https://en.wikipedia.org/wiki/INT_13H
;; http://stanislavs.org/helppc/int_13-2.html

[bits 16]

disk_read:
	;; store all register values
	pusha

	push dx

	;; prepare data for reading the disk
	;; al = number of sectors to read (1 - 128)
	;; ch = track/cylinder number
	;; dh = head number
	;; cl = sector number
	mov ah, 0x02
	mov al, dh
  mov dl, 0x80           ; Drive 0 (floppy)
	mov ch, 0x00
	mov dh, 0x00
	mov cl, 0x02
	int 0x13

	;; in case of read error
	;; show the message about it

	jc disk_read_error

	;; check if we read expected count of sectors
	;; if not, show the message with error
	pop dx
	cmp dh, al
	jne disk_read_error


	;; restore register values and ret
	popa
	ret

disk_read_error:
pusha
mov ah, 0x0E           ; BIOS teletype function
mov al, '*'            ; Character to print
mov bh, 0x00           ; Page number (0)
mov bl, 0x07           ; Text attribute (light grey on black background)
int 0x10               ; Call BIOS interrupt 0x10
popa
	call print_nl
	mov bx, DISK_READ_ERROR_MSG
	call print_string
	call print_nl
	jmp $

DISK_READ_ERROR_MSG: db "Disk read error!", 0

;; Implemenation for detecting if CPU supports x64 Long Mode
;; In case, if CPU is not support this, leave CPU in x32 Protected Mode
;; http://wiki.osdev.org/Setting_Up_Long_Mode#Detecting_the_Presence_of_Long_Mode

[bits 32]

;; Check if CPUID is supported by attempting to flip the ID bit
;; If we can flip it, CPUID is available
detect_lm:
  ;; Copy FLAGS in to EAX via stack
  pushfd
  pop eax

  ;; Copy to ECX as well for comparing later on
  mov ecx, eax

  ;; Flip the ID bit
  xor eax, 1 << 21

  ;; Copy EAX to FLAGS via the stack
  push eax
  popfd

  ;; Copy FLAGS back to EAX
  pushfd
  pop eax

  ;; Restore FLAGS from the old version stored in ECX
  push ecx
  popfd

  ;; Compare EAX and ECX
  ;; If they are equal then that means the bit wasn't flipped
  ;; so that, CPUID isn't supported
  xor eax, ecx
  jz detect_lm_no_cpuid

  ;; Otherwise, we have to check whether long mode can be used or not
  mov eax, 0x80000000
  cpuid
  cmp eax, 0x80000001
  jb detect_lm_no_long_mode

  ;; We can use extended function for detecting long mode now
  mov eax, 0x80000001
  cpuid
  test edx, 1 << 29
  jz detect_lm_no_long_mode

  ;; In case, if all check are successful, we can actually switch to Long Mode
  call switch_to_lm
  ret

detect_lm_no_cpuid:
  ;; In case, if CPUID isn't supported execute kernel in x32 Protected Mode
  call execute_kernel
  jmp $

detect_lm_no_long_mode:
  ;; In case, if Long Mode is not supported execute kernel in x32 Protected Mode
  call execute_kernel
  jmp $

;; Implemenation for switching to x64 Long Mode
;; http://wiki.osdev.org/Setting_Up_Long_Mode#Entering_Long_Mode

[bits 32]

switch_to_lm:
  ;; Before we actually cover up the new paging used in x86-64
  ;; we should disable the old paging first set up in protected mode
  mov eax, cr0
  and eax, 01111111111111111111111111111111b
  mov cr0, eax

  ;; Clear the tables
  mov edi, 0x1000
  mov cr3, edi
  xor eax, eax
  mov ecx, 4096
  rep stosd
  mov edi, cr3

  ;; Set up the new tables
  mov DWORD [edi], 0x2003
  add edi, 0x1000
  mov DWORD [edi], 0x3003
  add edi, 0x1000
  mov DWORD [edi], 0x4003
  add edi, 0x1000
  mov ebx, 0x00000003
  mov ecx, 512

switch_to_lm_set_entry:
  mov DWORD [edi], ebx
  add ebx, 0x1000
  add edi, 8
  loop switch_to_lm_set_entry

;; Now, we need to enable PAE-paging
switch_to_lm_enable_paging:
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ;; Set the LM-bit
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ;; Enable paging
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ;; Load our GDT with the 64-bit flags
  ;; and make far jump to init_lm
  lgdt [gdt_descriptor]
  jmp CODE_SEG:init_lm

[bits 64]

init_lm:
  ;; update all segment registers
  mov ax, DATA_SEG
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  ;; Update base and stack pointers
  mov ebp, 0x90000
  mov esp, ebp

  call begin_lm

;; Global Descriptor Table
;; It contains entries telling the CPU about memory segments
;; http://wiki.osdev.org/Global_Descriptor_Table

[bits 16]

gdt_start:
gdt_null:
	dd 0x0
	dd 0x0

;; Kernel Code Segment
gdt_kernel_code:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10011010b
	db 11001111b
	db 0x0

;; Kernel Data Segment
gdt_kernel_data:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0

;; Userland Code Segment
gdt_userland_code:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 11111010b
	db 11001111b
	db 0x0

;; Userland Data Segment
gdt_userland_data:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 11110010b
	db 11001111b
	db 0x0

gdt_end:
gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd gdt_start

CODE_SEG equ gdt_kernel_code - gdt_start
DATA_SEG equ gdt_kernel_data - gdt_start

;; Sub-routine to switch on Protected Mode
;; A CPU that is initialized by the BIOS starts in Real Mode
;; Enabling Protected Mode unleashes the real power of your CPU
;; http://wiki.osdev.org/Protected_Mode

[bits 16]

switch_to_pm:
	;; clear all interrupts
	cli

	;; load our Global Descriptor Table
	lgdt [gdt_descriptor]

	;; switch to protected mode
	;; set PE (Protection Enable) bit in CR0
	;; CR0 is a Control Register 0
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax

	;; far jump to 32 bit instructions
	;; so we can be sure processor has done
	;; all other operations before switch
	;; at this moment we can say bye to 16-bit Real Mode
	jmp CODE_SEG:init_pm

[bits 32]

init_pm:
	;; update all segment registers
	mov ax, DATA_SEG
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	;; update base and stack pointers
	mov ebp, 0x90000
	mov esp, ebp

	;; start protected mode
	;; begin_pm is located in boot.asm
	;; that is the last step in our journey
	;; before we are give execution to our kernel
	call begin_pm

;; Sub-routine for printing new line
;; using BIOS interrupts print two ASCII symbols:
;; new line = 0x0A
;; carriage return = 0x0D

[bits 16]

print_nl:
	;; store all register values
	pusha

	;; prepare for BIOS interrupt
	mov ah, 0x0E
	mov al, 0x0A
	int 0x10
	mov al, 0x0D
	int 0x10

	;; restore all registers
	popa
	ret

;; Sub-routine for string printing
;; Accepts pointer where string is stored in bx register

[bits 16]

print_string:
	;; store all register values
	pusha

print_string_loop:
	;; get first char from address at bx
	;; if char is equal to null-terminating symbol
	;; jump to return
	mov al, [bx]
	cmp al, 0
	je print_string_ret

	;; if char is exists
	;; prepare BIOS interrupt
	mov ah, 0x0E
	int 0x10

	;; offset at bx + 1
	;; so we have the next char from string
	inc bx
	jmp print_string_loop

print_string_ret:
	;; restore register values and return
	popa
	ret

BOOT_DRIVE: db 0x80

times 510 - ($-$$) db 0
dw 0xAA55
