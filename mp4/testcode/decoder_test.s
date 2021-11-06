.align 4
.section .text
.globl _start
_start:

    add x3, x1, x2
    slt x1, x2, x4

    addi x1, x1, 5
    slti x1, x2, 6

halt:
    beq x0, x0, halt

.section .rodata
