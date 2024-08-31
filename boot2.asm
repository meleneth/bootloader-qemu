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

    ; Load the kernel (assuming it's on the third sector)
    mov bx, 0x1000         ; Load address: 0x0000:0x1000 (offset 0x1000)
    mov dh, 0              ; Head 0
    mov dl, 0x80           ; Drive 0 (floppy)
    mov ch, 0              ; Track 0
    mov cl, 3              ; Sector 3 (kernel sector)
    mov ah, 0x02           ; BIOS: Read sectors
    mov al, 1              ; Number of sectors to read (adjust based on kernel size)
    int 0x13               ; Call BIOS interrupt 13h

    jc disk_error          ; If carry flag is set, there was an error

    ; Now switch to protected mode
    cli                    ; Clear interrupts
    cld                    ; Clear direction flag

    ; set A20 gate
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Set up the GDT (Global Descriptor Table)
    lgdt [gdt_descriptor]  ; Load the GDT descriptor

    ; Enter protected mode
    mov eax, cr0
    or eax, 0x1            ; Set the PE bit (protected mode enable)
    mov cr0, eax
    jmp 0x08:protected_mode ; Far jump to clear the pipeline and switch to PM

[bits 32]
protected_mode:
    ; Set up segment registers with data segment selector
    mov ax, 0x10           ; Data segment selector (index 2 in GDT)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9000        ; Set stack pointer

  pusha
    ; Display "Starting kernel" message on the screen
    mov esi, message       ; Load the address of the message into ESI
    mov edi, 0xB8000       ; Point EDI to the VGA text buffer
    call print_string      ; Call the string printing routine
popa
    ; Jump to the kernel entry point (0x1000:0x0000)
    jmp 0x1000:0x0000

disk_error:
    mov ah, 0x0E           ; BIOS teletype function
    mov al, 'd'            ; Character to print
    mov bh, 0x00           ; Page number (0)
    mov bl, 0x07           ; Text attribute (light grey on black background)
    int 0x10               ; Call BIOS interrupt 0x10
    hlt                    ; Halt the CPU if there is an error

print_string:
    ; Print a null-terminated string at ESI to the VGA text buffer
.print_char:
    lodsb                  ; Load byte at [ESI] into AL and increment ESI
    cmp al, 0              ; Compare AL with null (end of string)
    je .done               ; If null, we are done
    mov [edi], al          ; Store the character in the VGA text buffer
    mov byte [edi+1], 0x07 ; Set the attribute byte (light grey on black)
    add edi, 2             ; Move to the next character cell
    jmp .print_char        ; Repeat for the next character

.done:
    ret                    ; Return from the subroutine

gdt_start:
gdt_null:                  ; Null descriptor
    dd 0                   ; 4 bytes
    dd 0                   ; 4 bytes

gdt_code:                  ; Code segment descriptor
    dw 0xFFFF              ; Limit low (0xFFFF = 4 GiB limit)
    dw 0x0000              ; Base low
    db 0x00                ; Base middle
    db 10011010b           ; Access byte (present, ring 0, executable, readable)
    db 11001111b           ; Granularity byte (4 KiB blocks, 32-bit protected mode)
    db 0x00                ; Base high

gdt_data:                  ; Data segment descriptor
    dw 0xFFFF              ; Limit low (0xFFFF = 4 GiB limit)
    dw 0x0000              ; Base low
    db 0x00                ; Base middle
    db 10010010b           ; Access byte (present, ring 0, writable)
    db 11001111b           ; Granularity byte (4 KiB blocks, 32-bit protected mode)
    db 0x00                ; Base high

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Limit
    dd gdt_start                ; Base address

message db 'Starting kernel', 0  ; The message to print, null-terminated

times 512-($-$$) db 0            ; Pad to 512 bytes

