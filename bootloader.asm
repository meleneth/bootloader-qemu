; bootloader.asm
BITS 16
ORG 0x7C00

; Define the boot messages
msg_real_mode db 'Real mode', 0
msg_protected_mode db 'Protected mode', 0
msg_long_mode db 'Long mode', 0
msg_done db 'Done!', 0

; Print the initial message
mov si, msg_real_mode
call print_message

; Set up the GDT
lgdt [gdt_descriptor]  ; Load the GDT
mov eax, cr0
or eax, 1               ; Set the PE bit (Protection Enable)
mov cr0, eax

; Flush the instruction cache
mov eax, 0x00000000
mov cr3, eax

; Print message indicating the switch to 32-bit protected mode
mov si, msg_protected_mode
call print_message

; Jump to 32-bit code
jmp 0x08:protected_mode_code

; 32-bit protected mode code
BITS 32
protected_mode_code:
mov eax, cr4
or eax, 0x00000020      ; Set PAE bit
mov cr4, eax
mov eax, 0xC0000080
cpuid
shl eax, 1
mov eax, cr4
or eax, 0x00000010      ; Set the LME bit (Long Mode Enable)
mov cr4, eax

; Load the 64-bit GDT
lgdt [gdt_descriptor]

; Print message indicating the switch to 64-bit long mode
mov si, msg_long_mode
call print_message

; Switch to 64-bit mode
mov eax, 0xC0000080
cpuid
shl eax, 1
mov eax, cr4
or eax, 0x00000020      ; Set the LME bit (Long Mode Enable)
mov cr4, eax
mov eax, 0x00000000
mov cr0, eax
jmp 0x10:64bit_mode_entry

; 64-bit mode entry point
BITS 64
64bit_mode_entry:
mov rax, 0xDEADBEEF     ; Test value for 64-bit mode
mov rbx, rax            ; Store value in another register

; Print "Done!" message
mov si, msg_done
call print_message

; Infinite loop
jmp $

; Data section for GDT
gdt_start:
    ; Null descriptor
    dq 0x0000000000000000
    ; Code segment descriptor
    dq 0x00CF9A000000FFFF
    ; Data segment descriptor
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Subroutine to print a message
print_message:
    mov di, si            ; Copy address of the message to DI
print_char:
    lodsb                 ; Load byte at DS:SI into AL and increment SI
    cmp al, 0             ; Check if it's the null terminator
    je print_cr           ; Jump to print carriage return if end of string
    mov ah, 0x0E          ; BIOS teletype function
    int 0x10              ; Print the character in AL
    jmp print_char        ; Loop to print next character
print_cr:
    ; Print carriage return and line feed
    mov al, 0x0D          ; Carriage return
    int 0x10              ; Print carriage return
    mov al, 0x0A          ; Line feed
    int 0x10              ; Print line feed
    ret

TIMES 510 - ($ - $$) DB 0  ; Pad the rest of the sector with zeroes
DW 0xAA55                ; Boot sector signature

