	.file	"buffer_sum.c"
	.option nopic
	.attribute arch, "rv32i2p0_m2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
# GNU C17 (SiFive GCC-Metal 10.2.0-2020.12.8) version 10.2.0 (riscv64-unknown-elf)
#	compiled by GNU C version 5.4.0 20160609, GMP version 6.1.0, MPFR version 3.1.4, MPC version 1.0.3, isl version isl-0.18-GMP

# GGC heuristics: --param ggc-min-expand=30 --param ggc-min-heapsize=4096
# options passed: 
# -iprefix /opt/riscv64-unknown-elf-toolchain/bin/../lib/gcc/riscv64-unknown-elf/10.2.0/
# -isysroot /opt/riscv64-unknown-elf-toolchain/bin/../riscv64-unknown-elf
# buffer_sum.c -march=rv32im -mabi=ilp32 -march=rv32im -ffreestanding
# -fverbose-asm
# options enabled:  -faggressive-loop-optimizations -fallocation-dce
# -fauto-inc-dec -fdelete-null-pointer-checks -fdwarf2-cfi-asm
# -fearly-inlining -feliminate-unused-debug-symbols
# -feliminate-unused-debug-types -ffp-int-builtin-inexact -ffunction-cse
# -fgcse-lm -fgnu-unique -fident -finline-atomics -fipa-stack-alignment
# -fira-hoist-pressure -fira-share-save-slots -fira-share-spill-slots
# -fivopts -fkeep-static-consts -fleading-underscore -flifetime-dse
# -fmath-errno -fmerge-debug-strings -fpeephole -fplt
# -fprefetch-loop-arrays -freg-struct-return
# -fsched-critical-path-heuristic -fsched-dep-count-heuristic
# -fsched-group-heuristic -fsched-interblock -fsched-last-insn-heuristic
# -fsched-rank-heuristic -fsched-spec -fsched-spec-insn-heuristic
# -fsched-stalled-insns-dep -fschedule-fusion -fsemantic-interposition
# -fshow-column -fshrink-wrap-separate -fsigned-zeros
# -fsplit-ivs-in-unroller -fssa-backprop -fstdarg-opt
# -fstrict-volatile-bitfields -fsync-libcalls -ftrapping-math -ftree-cselim
# -ftree-forwprop -ftree-loop-if-convert -ftree-loop-im -ftree-loop-ivcanon
# -ftree-loop-optimize -ftree-parallelize-loops= -ftree-phiprop
# -ftree-reassoc -ftree-scev-cprop -funit-at-a-time -fverbose-asm
# -fzero-initialized-in-bss -mdiv -mexplicit-relocs -mplt -mriscv-attribute
# -mstrict-align

	.text
	.globl	a
	.data
	.align	2
	.type	a, @object
	.size	a, 512
a:
	.word	1
	.zero	508
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32	#,,
	sw	s0,28(sp)	#,
	addi	s0,sp,32	#,,
# buffer_sum.c:4: 	int sum = 0;
	sw	zero,-20(s0)	#, sum
# buffer_sum.c:5: 	for (int i=0; i<128; i++)
	sw	zero,-24(s0)	#, i
# buffer_sum.c:5: 	for (int i=0; i<128; i++)
	j	.L2		#
.L3:
# buffer_sum.c:7: 	    sum += a[i];
	lui	a5,%hi(a)	# tmp136,
	addi	a4,a5,%lo(a)	# tmp137, tmp136,
	lw	a5,-24(s0)		# tmp138, i
	slli	a5,a5,2	#, tmp139, tmp138
	add	a5,a4,a5	# tmp139, tmp140, tmp137
	lw	a5,0(a5)		# _1, a[i_3]
# buffer_sum.c:7: 	    sum += a[i];
	lw	a4,-20(s0)		# tmp142, sum
	add	a5,a4,a5	# _1, tmp141, tmp142
	sw	a5,-20(s0)	# tmp141, sum
# buffer_sum.c:5: 	for (int i=0; i<128; i++)
	lw	a5,-24(s0)		# tmp144, i
	addi	a5,a5,1	#, tmp143, tmp144
	sw	a5,-24(s0)	# tmp143, i
.L2:
# buffer_sum.c:5: 	for (int i=0; i<128; i++)
	lw	a4,-24(s0)		# tmp145, i
	li	a5,127		# tmp146,
	ble	a4,a5,.L3	#, tmp145, tmp146,
# buffer_sum.c:9: }
	nop	
	mv	a0,a5	#, <retval>
	lw	s0,28(sp)		#,
	addi	sp,sp,32	#,,
	jr	ra		#
	.size	main, .-main
	.ident	"GCC: (SiFive GCC-Metal 10.2.0-2020.12.8) 10.2.0"
