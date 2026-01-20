CC=riscv64-unknown-elf-gcc
AS=riscv64-unknown-elf-as
LD=riscv64-unknown-elf-ld

all: memcpy.elf

memcpy.o: memcpy.c
	$(CC) -c -march=rv32im -mabi=ilp32 memcpy.c -ffreestanding -g -O0

entry.o: ../common/entry.S
	$(AS) -march=rv32im -mabi=ilp32 -g -c ../common/entry.S -o entry.o

memcpy.elf: entry.o memcpy.o
	$(LD) -nostdlib -m elf32lriscv -T ../common/linker.ld entry.o memcpy.o -o memcpy.elf

clean:
	rm -f *.o *.elf
