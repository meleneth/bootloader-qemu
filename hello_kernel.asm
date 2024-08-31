; hello_kernel.asm - A simple kernel that prints a message in 32-bit protected mode

[bits 32]
[org 0x1000]

section .text
start:
    ; Set up segment registers
    mov ax, 0x10           ; Data segment selector (index 2 in GDT)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9000        ; Set up stack pointer

    ; Load the message into the VGA text buffer
    mov esi, message       ; Load address of the message into ESI
    mov edi, 0xB8000       ; Point EDI to the VGA text buffer

print_loop:
    lodsb                  ; Load byte at [ESI] into AL and increment ESI
    cmp al, 0              ; Compare AL with null (end of string)
    je done                ; If null, jump to done
    mov [edi], al          ; Store the character in the VGA text buffer
    mov byte [edi+1], 0x07 ; Set the attribute byte (light grey on black)
    add edi, 2             ; Move to the next character cell
    jmp print_loop         ; Repeat for the next character

done:
    hlt                    ; Halt the CPU

section .data
message db 'Kernel loaded in 32 bit protected mode', 0  ; Null-terminated message

