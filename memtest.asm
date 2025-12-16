# Simple RV32I assembly code to test memory load and store instructions
# This program tests lb, lh, lw, lbu, lhu, sb, sh, sw
# It stores values to memory, loads them back, and checks if they match expected values
# If all tests pass, a0 = 1 at the end; otherwise, branches to fail and sets a0 = 0
# Run in a RISC-V simulator (e.g., Ripes, Spike) to verify
# Base address changed to 0x80000000 (common DRAM start in many RISC-V setups)
# Fixed obvious bug in lbu expected value and comments (original had mismatched 0xab vs stored 0xef)

.global _start

_start:
    li t0, 0x80000000     # Changed base address to 0x80000000
    li t1, 0x10000000     # Changed led address to 0x10000000

    li a0, 0x00000004              # Set a0 to 4 for init light 1 led
    sw a0, 0(t1)
    # Test 2: sw (store word)
    li t2, 0xcafebabe   
    sw t2, 4(t0)       

    # Test 4: sh (store halfword)
    li t2, 0xfedc         # Value to store (lower 16 bits)
    sh t2, 12(t0)         # Store halfword to a0+12

    # Test 6: sb (store byte)
    li t2, 0xef           # Value to store (lower 8 bits)
    sb t2, 20(t0)         # Store byte to a0+20


    # 2-result: lw check
    li t2, 0xcafebabe     # Expected value
    lw t3, 4(t0)          # Load back
    bne t2, t3, fail      # Fail if not equal

    # 4-result: lh check (sign-extended)
    lh t2, 12(t0)         # Load back sign-extended
    li t3, 0xfffffedc     # Expected sign-extended value from 0xfedc
    bne t2, t3, fail

    # 6-result: lb check (sign-extended)
    lb t2, 20(t0)         # Load back sign-extended
    li t3, 0xffffffef     # Expected sign-extended value from 0xef
    bne t2, t3, fail

    # Test 7: lhu (load halfword unsigned, zero-extended)
    lhu t2, 12(t0)        # Load halfword unsigned from a0+12 (0xfedc -> 0x0000fedc)
    li t3, 0x0000fedc     # Expected zero-extended value
    bne t2, t3, fail

    # Test 8: lbu (load byte unsigned, zero-extended)
    lbu t2, 20(t0)        # Load byte unsigned from a0+20 (0xef -> 0x000000ef)
    li t3, 0x000000ef     # Expected zero-extended value (fixed from original 0xab bug)
    bne t2, t3, fail

success:
    # All tests passed
    li a0, 0x00000007              # Set a0 to 7 for pass light 3 led
    sw a0, 0(t1)
    j success

fail:
    li a0, 0x00000003              # Set a0 to 3 for nopass light 2 led
    sw a0, 0(t1)
    j fail

    # End of program
