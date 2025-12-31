.globl _start
.text

_start:
    li t0, 0x20000000     # graphic base
    li t4, 38400     # graphic length
    add t4, t4, t0

main_loop:
    li t3, 0xffffffff  
    sw t3, 0(t0)       
    addi t0, t0, 4

#    addi t2, zero, 0
#    addi t2, t2, 1024
#delay_countdown:
#    addi t2, t2, -1
#
#    bne  t2, zero, delay_countdown
    blt t0, t4, main_loop
endloop:
    j endloop
