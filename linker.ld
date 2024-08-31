ENTRY(_start)

SECTIONS
{
    /* Start the code at address 0x1000 */
    . = 0x1000;

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }

    /DISCARD/ : { *(.eh_frame) }
}

