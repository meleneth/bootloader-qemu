[BITS 16]
[ORG 0x0200]

start:
    ; Write '3' to the third column of the second row
    mov ax, 0x0B800
    mov es, ax
    mov [es:164], byte '3'   ; Offset for row 2, col 3
    mov [es:165], byte 0x07   ; Attribute byte

    ; Load the kernel from disk (floppy disk assumed)
    mov ah, 0x02         ; BIOS read sector function
    mov al, 5            ; Number of sectors to read (adjust as necessary)
    mov ch, 0            ; Track (cylinder) number
    mov cl, 3            ; Sector number
    mov dh, 0            ; Head number
    mov dl, 0x80            ; Drive number (0 = A:)
    mov bx, 0x1000       ; Address to load to (0x1000)
    int 0x13             ; Call BIOS

    ; Write '.' to the fourth column of the second row
    mov [es:166], byte '.'
    mov [es:167], byte 0x07

    ; Enable A20 line
    in al, 0x64
    test al, 2
    jnz $

    mov al, 0xD1
    out 0x64, al

    mov al, 0xDF
    out 0x60, al

    ; Switch to 32-bit protected mode
    cli                    ; Disable interrupts
    lgdt [gdt_descriptor]  ; Load Global Descriptor Table
    mov eax, cr0
    or eax, 0x1            ; Set PE bit (protected mode enable)
    mov cr0, eax
    jmp 0x08:protected_mode_start  ; Far jump to flush prefetch queue

[BITS 32]
protected_mode_start:
    ; Update segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Write '+' to the fifth column of the second row
    mov esi, 0xB8000 + 160 + 8
    mov byte [esi], '+'
    mov byte [esi+1], 0x07

    ; Jump to the kernel
    call 0x1000

gdt_start:
    dw 0                  ; Null segment
    dw 0
    dw 0
    dw 0

    dw 0xFFFF             ; Code segment
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

    dw 0xFFFF             ; Data segment
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

gdt_end:

times 510-($-$$) db 0
dw 0xAA55

