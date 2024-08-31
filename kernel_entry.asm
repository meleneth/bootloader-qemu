; kernel_entry.asm
[bits 32]
[extern kernel_main]      ; Declare the external C function

section .text
        ;multiboot spec
        align 4
        dd 0x1BADB002 ;magic
        dd 0x00 ;flags
        dd - (0x1BADB002 + 0x00) ;checksum

global _start

_start:
    ; Write 'X' to the second row, second column of the screen
    mov edi, 0xB8000          ; VGA text buffer start address
    add edi, 170              ; Move to the second row (160 bytes per row in text mode)
    add edi, 2                ; Move to the second column (each character cell is 2 bytes)
    mov al, 'X'               ; Character 'X'
    mov ah, 0x07              ; Attribute byte: light grey on black background
    mov [edi], ax             ; Write the character and attribute to the VGA buffer

        extern kernel_main ;kernalMain is the function in C file
         
         cli ;clear interrupts-- to diable interrupts
         mov esp, stack_space ;set stack pointer
         call kernel_main ;calls the main kernel function from c file
         hlt ;halts the CPU
         
        section .bss
        resb 8192 ;8KB memory reserved for the stack
        stack_space:
