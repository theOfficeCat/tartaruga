li x1, 0x12345678
li x2, 0x87654321

add x3, x1, x2
sub x3, x2, x1
slt x3, x2, x1
sltu x3, x2, x1
sll x3, x2, x1
srl x3, x2, x1
sra x3, x2, x1
xor x3, x2, x1
or x3, x2, x1
and x3, x2, x1
li x4, 0x100
sw x3, 0x20(x4)
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
lw x5, 0x20(x4)
