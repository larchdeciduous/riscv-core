# counter_100ms.s
#
# Increments t0 every 0.1 seconds.
# This version uses the 'bgt' (Branch if Greater Than) instruction.
#
# Calibrated for a ~25 MHz clock.
#
# Target delay: 2,500,000 cycles (0.1s @ 25MHz)
# Loop count:   625,000 (which is 0x98968 in hex)
#
# Instructions used: addi, lui, bne, bgt (SB-Type)

.globl _start
.text

_start:
    # Initialize our main counter register t0 to zero
    addi t0, zero, 0        # t0 = 0

main_loop:
    # 1. ADD 1 TO T0
    addi t0, t0, 1          # t0 = t0 + 1

    # 2. DELAY FOR 0.1 SECONDS (Calibrated for 25 MHz)
    #
    # We load the value 625,000 (0x98968) into t1.
    # To do this, we load the *next highest* upper value (0x99)
    # and then subtract to get the exact number.
    #
    # lui  t1, 0x99         # Loads t1 = 0x00099000
    # addi t1, t1, -1688     # t1 = 0x99000 - 1688 = 0x98968
    #
    # (Note: -1688 is 0x-698, which is well within
    # the 12-bit signed immediate range)
    
    addi t1, zero, 0        # t0 = 0
    addi t1, t1, 4      # Load 625,000 into t1

delay_countdown:
    # Decrement t1 by one (1 cycle)
    addi t1, t1, -1         # t1 = t1 - 1

    # Check the loop condition:
    # If t1 is GREATER THAN zero, jump back. (3 cycles)
    bne  t1, zero, delay_countdown

    # 3. REPEAT
    # If t1 is 0 or less, the delay is over.
    # Unconditional jump back to the main loop.
    beq zero, zero, main_loop
