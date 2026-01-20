CC=riscv64-unknown-elf-gcc
AS=riscv64-unknown-elf-as
LD=riscv64-unknown-elf-ld

all: matrix_mul.elf

matrix_mul.o: matrix_mul.c
	$(CC) -c -march=rv64im -mabi=lp64 matrix_mul.c -ffreestanding -g -O2

entry.o: ../common/entry.S
	$(AS) -march=rv64im -mabi=lp64 -g -c ../common/entry.S -o entry.o

matrix_mul.elf: entry.o matrix_mul.o
	$(LD) -nostdlib -m elf64lriscv -T ../common/linker.ld entry.o matrix_mul.o -o matrix_mul.elf

clean:
	rm -f *.o *.elf
