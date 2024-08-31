ENTRY(_start)


SECTIONS
{
    /* Set the starting address of the kernel */
    . = 0x1000;

    /* The text section for code */
    .text : {
        *(.text)
    }

    /* The data section for initialized data */
    .data : {
        *(.data)
    }

    /* The bss section for uninitialized data */
    .bss : {
        *(.bss)
        *(COMMON)
    }

    /* Align the end of the kernel to a 4-byte boundary */
    . = ALIGN(4);
}
