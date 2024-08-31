; First stage bootloader (boot1.asm)
[bits 16]
[org 0x7C00]

start:
    xor ax, ax             ; Clear AX
    mov ds, ax             ; Set DS to 0x0000
    mov es, ax             ; Set ES to 0x0000
    mov ss, ax             ; Set SS to 0x0000
    mov sp, 0x7C00         ; Set stack pointer to 0x7C00

    ; Print '1' using BIOS interrupt 0x10
    mov ah, 0x0E           ; BIOS teletype function
    mov al, '1'            ; Character to print
    mov bh, 0x00           ; Page number (0)
    mov bl, 0x07           ; Text attribute (light grey on black background)
    int 0x10               ; Call BIOS interrupt 0x10

    ; Load second stage bootloader (assuming it is on the second sector)
    mov bx, 0x0200         ; Load address: 0x0000:0x0200 (offset 0x0200)
    mov dh, 0              ; Head 0
    mov dl, 0x02           ; Drive 0 (floppy)
    mov ch, 0              ; Track 0
    mov cl, 2              ; Sector 2
    mov ah, 0x02           ; BIOS: Read sectors
    mov al, 1              ; Number of sectors to read
    int 0x13               ; Call BIOS interrupt 13h

    jc disk_error          ; If carry flag is set, there was an error

    jmp 0x0000:0x0200      ; Jump to the second stage bootloader

disk_error:
    ; Print '1' using BIOS interrupt 0x10
    mov ah, 0x0E           ; BIOS teletype function
    mov al, 'x'            ; Character to print
    mov bh, 0x00           ; Page number (0)
    mov bl, 0x07           ; Text attribute (light grey on black background)
    int 0x10               ; Call BIOS interrupt 0x10
    hlt                    ; Halt the CPU if there is an error

times 510-($-$$) db 0      ; Pad with zeros to make the boot sector 512 bytes
dw 0xAA55                  ; Boot signature (must be 0xAA55)

