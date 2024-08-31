; kernel_entry.asm
[bits 32]
[extern kernel_main]      ; Declare the external C function

section .text
global _start

_start:
    ; Write 'X' to the second row, second column of the screen
    mov edi, 0xB8000          ; VGA text buffer start address
    add edi, 160              ; Move to the second row (160 bytes per row in text mode)
    add edi, 2                ; Move to the second column (each character cell is 2 bytes)
    mov al, 'X'               ; Character 'X'
    mov ah, 0x07              ; Attribute byte: light grey on black background
    mov [edi], ax             ; Write the character and attribute to the VGA buffer

    call kernel_main      ; Call the kernel's main function

    hlt                   ; Halt the CPU

