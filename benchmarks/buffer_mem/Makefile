CC=riscv64-unknown-elf-gcc
AS=riscv64-unknown-elf-as
LD=riscv64-unknown-elf-ld

all: buffer_sum.elf

buffer_sum.o: buffer_sum.c
	$(CC) -c -march=rv32im -mabi=ilp32 buffer_sum.c -ffreestanding -g -O0

entry.o: ../common/entry.S
	$(AS) -march=rv32im -mabi=ilp32 -g -c ../common/entry.S -o entry.o

buffer_sum.elf: entry.o buffer_sum.o
	$(LD) -nostdlib -m elf32lriscv -T ../common/linker.ld entry.o buffer_sum.o -o buffer_sum.elf

clean:
	rm -f *.o *.elf
