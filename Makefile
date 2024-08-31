boot : floppy.img
	qemu-system-i386 -drive format=raw,file=floppy.img

boot1.bin : boot1.asm
	nasm -f bin -o boot1.bin boot1.asm

boot2.bin : boot2.asm
	nasm -f bin -o boot2.bin boot2.asm

floppy.img : boot1.bin boot2.bin kernel.bin
	dd if=/dev/zero of=floppy.img bs=512 count=2880
	dd if=boot1.bin of=floppy.img bs=512 count=1 seek=0
	dd if=boot2.bin of=floppy.img bs=512 count=1 seek=1
	dd if=kernel.bin of=floppy.img bs=512 count=1 seek=2

kernel_entry.o : kernel_entry.asm
	nasm -f elf32 -o kernel_entry.o kernel_entry.asm

kernel.o : kernel.c
	gcc -m32 -ffreestanding -fno-pic -c kernel.c -o kernel.o

kernel.bin : kernel.o kernel_entry.o
	ld -m elf_i386 -T linker.ld -Ttext 0x1000 --oformat binary -o kernel.bin kernel_entry.o kernel.o

clean :
	rm *.o
