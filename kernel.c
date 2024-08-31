void clear_screen() {
    char *vidmem = (char *)0xB8000;
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        vidmem[i] = ' ';
        vidmem[i + 1] = 0x07;
    }
}

void kernel_main() {
    char *vidmem = (char *)0xB8000;

    // Write '>' to the sixth column of the second row
    vidmem[160 + 10] = '>';
    vidmem[160 + 11] = 0x07;

    // Decorate the 4th through 7th rows with xXxXxXx
    for (int row = 3; row <= 6; row++) {
        for (int col = 0; col < 80; col++) {
            vidmem[2 * col + 160 * row] = (col % 2 == 0) ? 'x' : 'X';
            vidmem[2 * col + 160 * row + 1] = 0x07;
        }
    }

    // Halt the CPU (infinite loop)
    while (1) {
        asm("hlt");
    }
}

