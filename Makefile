boot : boot.img
	qemu-system-x86_64 -fda boot.img -blockdev driver=raw,node-name=disk,file.driver=file,file.filename=boot.img

bootloader.bin : bootloader.asm
	nasm -f bin -o bootloader.bin bootloader.asm

boot.img : bootloader.bin
	dd if=bootloader.bin of=boot.img bs=512 count=1


