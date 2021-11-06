.align 4
.section .text
.globl _start
_start:

    add x3, x1, x2

halt:
    beq x0, x0, halt

.section .rodata
