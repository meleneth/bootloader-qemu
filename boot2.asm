; Second stage bootloader (boot2.asm)

[bits 16]
[org 0x0200]

start:
    ; Print '1' using BIOS interrupt 0x10
    mov ah, 0x0E           ; BIOS teletype function
    mov al, '2'            ; Character to print
    mov bh, 0x00           ; Page number (0)
    mov bl, 0x07           ; Text attribute (light grey on black background)
    int 0x10               ; Call BIOS interrupt 0x10
    cli                    ; Clear interrupts
    lgdt [gdt_descriptor]  ; Load the GDT
    mov eax, cr0
    or eax, 0x1            ; Set the PE bit (protected mode enable)
    mov cr0, eax
    jmp 0x08:protected_mode ; Far jump to clear the pipeline and switch to PM

[bits 32]
protected_mode:
    mov ax, 0x10           ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9000        ; Set stack pointer

    ; Load kernel (assuming it's on the third sector)
    mov bx, 0x1000         ; Load address: 0x0000:0x1000 (offset 0x1000)
    mov dh, 0              ; Head 0
    mov dl, 0x00           ; Drive 0 (floppy)
    mov ch, 0              ; Track 0
    mov cl, 3              ; Sector 3
    mov ah, 0x02           ; BIOS: Read sectors
    mov al, 1              ; Number of sectors to read
    int 0x13               ; Call BIOS interrupt 13h

    jmp 0x1000:0x0000      ; Jump to kernel entry point

gdt_start:
gdt_null:                  ; Null descriptor
    dd 0                   ; 4 bytes
    dd 0                   ; 4 bytes

gdt_code:                  ; Code segment descriptor
    dw 0xFFFF              ; Limit low
    dw 0x0000              ; Base low
    db 0x00                ; Base middle
    db 10011010b           ; Access byte (present, ring 0, executable, readable)
    db 11001111b           ; Granularity byte
    db 0x00                ; Base high

gdt_data:                  ; Data segment descriptor
    dw 0xFFFF              ; Limit low
    dw 0x0000              ; Base low
    db 0x00                ; Base middle
    db 10010010b           ; Access byte (present, ring 0, writable)
    db 11001111b           ; Granularity byte
    db 0x00                ; Base high

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Limit
    dd gdt_start                 ; Base address

times 512-($-$$) db 0      ; Pad to 512 bytes

