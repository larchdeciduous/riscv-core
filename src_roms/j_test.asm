.section .text
.globl _start
# ====================== Initialization ======================
_start:
    li t5, 0x10000000           # LED memory-mapped address
    sw zero, 0(t5)              # Clear LEDs at start (000)

    li t0, 2                    # load to led (010)
    sw t0, 0(t5)

    j end                       # if jump, led (001) otherwise led(101)

    li t0, 5
    sw t0, 0(t5)

end:
    j end 
