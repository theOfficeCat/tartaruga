.section .init

.option norvc

.type start, @function
.global start
start:
	.cfi_startproc

.option push
.option norelax
	la gp, global_pointer
.option pop

	/* Setup stack */
	la sp, stack_top

	/* Clear the BSS section */
	la t5, bss_start
	la t6, bss_end
bss_clear:
	sw zero, (t5)
	addi t5, t5, 8
	bltu t5, t6, bss_clear

	call main

	la x1, 0x40000000
	li x2, 0x1
	sw x10, 4(x1)
	sw x2, 0(x1)

	.cfi_endproc

.end
