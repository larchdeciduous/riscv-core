# beq_bne_detailed_test.s
# Detailed BEQ / BNE Instructions Test for RV32I
# Uses 3 LEDs at 0x10000000 to show precise failure mode
#
# LED codes:
#   000 (0) → Very early failure / program didn't run
#   001 (1) → BEQ taken when should NOT (false positive on equal)
#   010 (2) → BEQ not taken when should (false negative on equal)
#   011 (3) → BNE taken when should NOT (false positive on not-equal)
#   100 (4) → BNE not taken when should (false negative on not-equal)
#   101 (5) → Both BEQ and BNE fully correct on all tested cases
#
# Tests:
# - Equal values (10 == 10)
# - Unequal values (10 != 25)
# - Zero == zero
# - Zero != positive

.section .text
.globl _start

# ====================== Initialization ======================
_start:
    li t5, 0x10000000           # LED address
    sw zero, 0(t5)              # Clear LEDs (000)

# ====================== Prepare Test Values ======================
    li t1, 10
    li t2, 10                   # t1 == t2 (equal case)
    li t3, 25                   # t1 != t3 (unequal case)
    li t4, 0                    # zero for edge test

# ====================== Test 1: BEQ when equal (should TAKE branch) ======================
    beq t1, t2, beq_equal_taken_ok
    # If we reach here: BEQ failed to take branch when values equal
    li t0, 2                    # Code 2
    j show_result
beq_equal_taken_ok:

# ====================== Test 2: BEQ when unequal (should NOT take) ======================
    beq t1, t3, beq_unequal_bad_taken
    # Correct: branch not taken → continue
    j beq_unequal_ok
beq_unequal_bad_taken:
    # Wrong: branch taken when values different
    li t0, 1                    # Code 1
    j show_result
beq_unequal_ok:

# ====================== Test 3: BNE when equal (should NOT take) ======================
    bne t1, t2, bne_equal_bad_taken
    # Correct: branch not taken
    j bne_equal_ok
bne_equal_bad_taken:
    # Wrong: branch taken when values equal
    li t0, 3                    # Code 3
    j show_result
bne_equal_ok:

# ====================== Test 4: BNE when unequal (should TAKE branch) ======================
    bne t1, t3, bne_unequal_taken_ok
    # If we reach here: BNE failed to take branch when values different
    li t0, 4                    # Code 4
    j show_result
bne_unequal_taken_ok:

# ====================== Extra Edge Tests: Zero comparisons ======================
    beq t4, zero, zero_beq_ok
    li t0, 2
    j show_result
zero_beq_ok:

    bne t4, zero, zero_bne_bad
    j zero_bne_ok
zero_bne_bad:
    li t0, 3
    j show_result
zero_bne_ok:

    beq t1, zero, pos_beq_bad
    j pos_beq_ok
pos_beq_bad:
    li t0, 1
    j show_result
pos_beq_ok:

# ====================== All Tests Passed ======================
    li t0, 5                    # Code 5 = 101 on LEDs → BEQ/BNE perfect

# ====================== Show Result on LEDs ======================
show_result:
    sw t0, 0(t5)

# ====================== Infinite Loop ======================
end:
    j end
