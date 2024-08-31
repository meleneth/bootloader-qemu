[BITS 16]
[ORG 0x7C00]

start:
    ; Clear the screen
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov di, 0xb800
    mov cx, 2000
    mov al, ' '
    mov ah, 0x07
    rep stosw

    ; Write 'd' to the first column of the second row (row 2, col 1)
    mov ax, 0x0B800
    mov es, ax
    mov [es:160], byte 'd'   ; 160 is the offset for the 2nd row, 1st column
    mov [es:161], byte 0x07   ; Attribute byte

    xor ax, ax
    mov es, ax

    ; Load the second stage bootloader from disk (floppy disk assumed)
    mov ah, 0x02         ; BIOS read sector function
    mov al, 1            ; Number of sectors to read
    mov ch, 0            ; Track (cylinder) number
    mov cl, 2            ; Sector number
    mov dh, 0            ; Head number
    mov dl, 0x80            ; Drive number (0 = A:)
    mov bx, 0x0200       ; Address to load to (0x8000)
    int 0x13             ; Call BIOS

    ; Write '1' to the second column of the second row (row 2, col 2)
    mov ax, 0x0B800
    mov es, ax
    mov [es:162], byte '1'
    mov [es:163], byte 0x07
    xor ax, ax
    mov es, ax

    ; Jump to second stage
    jmp 0x0000:0x0200

    times 510-($-$$) db 0   ; Fill remaining bytes with 0
    dw 0xAA55               ; Boot signature

