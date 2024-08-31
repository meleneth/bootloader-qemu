; kernel_entry.asm
[bits 32]
[extern kernel_main]      ; Declare the external C function

section .text
global _start

_start:
    call kernel_main      ; Call the kernel's main function

    hlt                   ; Halt the CPU

