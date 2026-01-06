# jal_detailed_test_fixed.s
# Detailed JAL Instruction Test for RV32I - FIXED VERSION
# Precisely distinguishes:
#   LED 001 (1) → JAL jump not taken
#   LED 010 (2) → JAL jump taken but ra (link register) wrong
#   LED 011 (3) → JAL fully correct (jump taken AND ra = PC+4)
#   LED 000 (0) → Very early failure

.section .text
.globl _start

# ====================== Initialization ======================
_start:
    li t5, 0x10000000           # LED memory-mapped address
    sw zero, 0(t5)              # Clear LEDs at start (000)

# ====================== Test JAL - Check if jump is taken ======================
    jal ra, jal_target          # Perform JAL

# ----- Normal return point: this is exactly PC+4 from the JAL above -----
correct_return:                 # ← ra MUST point exactly here if JAL is correct
    li t0, 1                    # If we reach here → jump was NOT taken
    j show_result

# ====================== Jump Target (reached only if jump works) ======================
jal_target:
    # Jump succeeded → now verify the link register (ra)

    la t1, correct_return       # Load the address that ra should hold (PC+4)
    beq ra, t1, ra_correct      # Compare: if equal → ra is correct

# ----- ra is incorrect -----
    li t0, 2                    # Code 2 = jump worked, but ra wrong
    j show_result

# ----- ra is correct -----
ra_correct:
    li t0, 3                    # Code 3 = everything perfect (011 on LEDs)

# ====================== Show Result on LEDs ======================
show_result:
    sw t0, 0(t5)

# ====================== Infinite Loop ======================
end:
    j end
