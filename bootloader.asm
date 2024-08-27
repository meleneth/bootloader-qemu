[BITS 16]            ; We're in real mode
[ORG 0x7C00]         ; Bootloader loaded at 0x7C00


start:
    cli              ; Disable interrupts
    xor ax, ax       ; Clear AX register
    mov ds, ax       ; Set DS segment to 0
    mov es, ax       ; Set ES segment to 0
    mov ss, ax       ; Set SS segment to 0
    mov sp, 0x7C00   ; Set stack pointer to 0x7C00


    ; Print message: "Entering 16-bit Real Mode"
    call print_string
    db 'Entering 16-bit Real Mode', 0

    ; Set up GDT

    lgdt [gdt_descriptor]

    ; Enter Protected Mode

    call print_string
    db 'Switching to Protected Mode', 0

    mov eax, cr0
    or eax, 1         ; Set PE bit (Protection Enable)
    mov cr0, eax

    jmp 0x08:protected_mode    ; Far jump to flush the pipeline

[BITS 32]             ; We are now in Protected Mode


protected_mode:
    ; Set up segment registers
    mov ax, 0x10     ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Print message: "Entering 32-bit Protected Mode"
    call print_string
    db 'Entering 32-bit Protected Mode', 0

    ; Set up page tables for 64-bit mode

    call setup_paging

    ; Switch to Long Mode
    call print_string
    db 'Switching to Long Mode', 0

    ; Enable PAE
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax

    ; Enable Long Mode
    rdmsr
    or eax, 0x100     ; Set LME bit in EFER

    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 0x80000000 ; Set PG bit
    mov cr0, eax


    jmp 0x08:long_mode    ; Far jump to enter Long Mode

[BITS 64]             ; We are now in Long Mode

long_mode:
    ; Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Print message: "Entering 64-bit Long Mode"
    call print_string
    db 'Entering 64-bit Long Mode', 0

    hlt               ; Halt the CPU

; Simple function to print a string on the screen
print_string:

    pusha
    mov ah, 0x0E     ; Teletype output (BIOS interrupt)
.next_char:
    lodsb            ; Load next character from string

    cmp al, 0
    je .done         ; If null terminator, end
    int 0x10         ; BIOS interrupt to print character
    jmp .next_char
.done:
    popa
    ret

; GDT setup
gdt_start:
    dq 0x0000000000000000   ; Null descriptor
    dq 0x00CF9A000000FFFF   ; Code segment descriptor
    dq 0x00CF92000000FFFF   ; Data segment descriptor
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Page Table setup for 64-bit mode (Identity mapping)
setup_paging:
    ; Identity map first 4 MB
    mov eax, cr3         ; Get current page directory base register

    mov eax, page_directory
    mov cr3, eax         ; Load it into CR3
    ret

align 4096
page_directory:
    dd page_table - 0xC0000000 + 3
    times 1023 dd 0
page_table:
    times 1024 dd 0x00000000 + 3


times 510-($-$$) db 0 ; Pad to make 512 bytes
dw 0xAA55             ; Boot signature

