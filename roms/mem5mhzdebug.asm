# Simple RV32I assembly code to test memory load and store instructions
# This program tests lb, lh, lw, lbu, lhu, sb, sh, sw
# It stores values to memory, loads them back, and checks if they match expected values
# Run in a RISC-V simulator (e.g., Ripes, Spike) to verify
# Base address 0x80000000 (common DRAM start)
# Added: After every load instruction, the loaded 32-bit value is output to 8-bit GPIO at 0x10000001
#        Bytes are sent MSB-first, one byte at a time via sb
#        ~4 nops (~160ns at 25MHz) between each byte write → effective ~5MHz update rate on GPIO
#        Suitable for capture on a logic analyzer

.global _start

_start:
    li t0, 0x80000000     # Memory base address
    li t1, 0x10000000     # LED address (original 32-bit port)
    li t4, 0x10000001     # 8-bit GPIO address for debug output

    li t6, 0x00000004              # Set t6 to 4 for init light 1 led
    sw t6, 0(t1)

    # Test 2: sw (store word)
    li t2, 0xcafebabe   
    sw t2, 4(t0)       

    # Test 4: sh (store halfword)
    li t2, 0xfedc         # Value to store (lower 16 bits)
    sh t2, 12(t0)         # Store halfword to +12

    # Test 6: sb (store byte)
    li t2, 0xef           # Value to store (lower 8 bits)
    sb t2, 20(t0)         # Store byte to +20

    # 2-result: lw check
    li t2, 0xcafebabe     # Expected value
    lw t3, 4(t0)          # Load back
    mv a1, t3             # Prepare for GPIO output
    jal output_32         # Output loaded value to GPIO
    bne t2, t3, fail      # Fail if not equal

    # 4-result: lh check (sign-extended)
    lh t2, 12(t0)         # Load back sign-extended
    mv a1, t2             # Prepare for GPIO output
    jal output_32         # Output loaded value to GPIO
    li t3, 0xfffffedc     # Expected sign-extended value from 0xfedc
    bne t2, t3, fail

    # 6-result: lb check (sign-extended)
    lb t2, 20(t0)         # Load back sign-extended
    mv a1, t2             # Prepare for GPIO output
    jal output_32         # Output loaded value to GPIO
    li t3, 0xffffffef     # Expected sign-extended value from 0xef
    bne t2, t3, fail

    # Test 7: lhu (load halfword unsigned, zero-extended)
    lhu t2, 12(t0)        # Load halfword unsigned (0xfedc → 0x0000fedc)
    mv a1, t2             # Prepare for GPIO output
    jal output_32         # Output loaded value to GPIO
    li t3, 0x0000fedc     # Expected zero-extended value
    bne t2, t3, fail

    # Test 8: lbu (load byte unsigned, zero-extended)
    lbu t2, 20(t0)        # Load byte unsigned (0xef → 0x000000ef)
    mv a1, t2             # Prepare for GPIO output
    jal output_32         # Output loaded value to GPIO
    li t3, 0x000000ef     # Expected zero-extended value
    bne t2, t3, fail

success:
    # All tests passed
    li t6, 0x00000007              # Set t6 to 7 for pass light 3 led
    sw t6, 0(t1)
    li t5, 0x0000000f
    sb t5, 0(t4)
    addi zero, zero, 0
    j success

fail:
    li t6, 0x00000003              # Set t6 to 3 for nopass light 2 led
    sw t6, 0(t1)
    li t5, 0x000000f1
    sb t5, 0(t4)
    j fail

# Subroutine: Output 32-bit value in a1 to 8-bit GPIO at address in t4
#             MSB first, 4 bytes sequentially
#             ~4 nops delay between bytes for ~5MHz effective rate at 25MHz core clock
output_32:
# shows this is start of a data
    li t5, 0x000000ff
    sb t5, 0(t4)
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0


    srli t5, a1, 24
    sb t5, 0(t4)
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

    srli t5, a1, 16
    sb t5, 0(t4)
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

    srli t5, a1, 8
    sb t5, 0(t4)
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

    sb a1, 0(t4)                   # LSB (low 8 bits of a1)
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

    ret

    # End of program
