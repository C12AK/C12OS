AS = nasm
CC = i386-elf-gcc
LD = i386-elf-ld
OBJCOPY = i386-elf-objcopy

CFLAGS = -ffreestanding -O2 -nostdlib -Wall -Wextra

all: c12os.bin

mbr.bin: mbr.s
	$(AS) -f bin mbr.s -o mbr.bin

stage2.bin: stage2.s
	$(AS) -f bin stage2.s -o stage2.bin

kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

kernel.elf: kernel.o kernel_link.ld
	$(LD) -T kernel_link.ld kernel.o -o kernel.elf

kernel.bin: kernel.elf
	$(OBJCOPY) -O binary kernel.elf kernel.bin

# 让内核完整地占据几个扇区
kernel_padded.bin: kernel.bin
	dd if=kernel.bin of=kernel_padded.bin bs=512 conv=sync

c12os.bin: mbr.bin stage2.bin kernel_padded.bin
	rm -f c12os.bin
	dd if=mbr.bin of=c12os.bin bs=512 count=1 conv=notrunc
	dd if=stage2.bin of=c12os.bin bs=512 seek=1 conv=notrunc
	dd if=kernel_padded.bin of=c12os.bin bs=512 seek=3 conv=notrunc

run: c12os.bin
	qemu-system-i386 -drive format=raw,file=c12os.bin

clean:
	rm -f *.o *.bin *.elf c12os.bin
