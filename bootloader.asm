; bootloader.asm
BITS 16
ORG 0x7C00

; Print 'hello world from the bootloader'
mov ah, 0x0E            ; BIOS teletype function
mov al, 'H'
int 0x10
mov al, 'e'
int 0x10
mov al, 'l'
int 0x10
mov al, 'l'
int 0x10
mov al, 'o'
int 0x10
mov al, ' '
int 0x10
mov al, 'w'
int 0x10
mov al, 'o'
int 0x10
mov al, 'r'
int 0x10
mov al, 'l'
int 0x10
mov al, 'd'
int 0x10
mov al, ' '
int 0x10
mov al, 'f'
int 0x10
mov al, 'r'
int 0x10
mov al, 'o'
int 0x10
mov al, 'm'
int 0x10
mov al, ' '
int 0x10
mov al, 't'
int 0x10
mov al, 'h'
int 0x10
mov al, 'e'
int 0x10
mov al, ' '
int 0x10
mov al, 'b'
int 0x10
mov al, 'o'
int 0x10
mov al, 'o'
int 0x10
mov al, 't'
int 0x10
mov al, 'l'
int 0x10
mov al, 'o'
int 0x10
mov al, 'a'
int 0x10
mov al, 'd'
int 0x10
mov al, 'e'
int 0x10
mov al, 'r'
int 0x10

jmp $

TIMES 510 - ($ - $$) DB 0  ; Pad the rest of the sector with zeroes
DW 0xAA55                ; Boot sector signature

