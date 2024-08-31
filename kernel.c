// kernel.c
void kernel_main() {
    char *video_memory = (char *)0xB8000; // VGA text buffer starts at 0xB8000
    const char *message = "Hello, World!";
    int i = 0;

    // VGA text mode: each character cell is 2 bytes (char + attribute)
    while (message[i] != '\0') {
        video_memory[i * 2] = message[i];     // Character
        video_memory[i * 2 + 1] = 0x07;       // Attribute byte: light grey on black background
        i++;
    }

    // Halt the CPU
    while (1) {
        //asm volatile ("hlt");
    }
}

