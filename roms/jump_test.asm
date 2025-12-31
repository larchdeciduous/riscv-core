# jump_branch_test_robust.s
# RV32I Jump and Branch Instructions Test - ROBUST VERSION
# Fixed all 'la' pseudo-instruction issues for backward/forward labels
# Uses only reliable PC-relative address calculation
# Output: 3 LEDs at 0x10000000 (values 0-7)
# LED codes unchanged:
#   000 (0) → early failure
#   001 (1) → JAL failed (jump not taken or ra wrong)
#   010 (2) → JALR failed (jump not taken or ra wrong)
#   011 (3) → BEQ/BNE failed
#   100 (4) → BLT/BGE failed
#   101 (5) → BLTU/BGEU failed
#   110 (6) → Zero/edge cases failed
#   111 (7) → ALL PASS

.section .text
.globl _start

# ====================== Program Entry & Initialization ======================
_start:
    li t0, 0
    li t5, 0x10000000
    sw zero, 0(t5)              # Clear LEDs

# ====================== Test 1: JAL (Jump and Link) ======================
    jal ra, jal_target

jal_normal_return:              # ← Exactly PC+4 from JAL → ra must point here
    li t0, 1                    # Jump not taken
    j fail_exit

jal_target:
    # Manually compute address of jal_normal_return (8 bytes before current PC)
    auipc t1, 0
    addi  t1, t1, -8            # t1 = PC - 8 = jal_normal_return
    bne ra, t1, jal_fail

    j jal_pass

jal_fail:
    li t0, 1
    j fail_exit

jal_pass:

# ====================== Test 2: JALR (Jump and Link Register) ======================
    # Compute absolute address of jalr_target using auipc + addi
    auipc t1, 0
    addi  t1, t1, 20            # jalr_target is ~24-32 bytes ahead (adjust if layout changes)

    jalr ra, t1, 0              # Indirect jump

jalr_normal_return:             # ← Exactly PC+4 from JALR → ra must point here
    li t0, 2                    # Jump not taken
    j fail_exit

jalr_target:
    # Manually compute address of jalr_normal_return (8 bytes before current PC)
    auipc t2, 0
    addi  t2, t2, -8            # t2 = PC - 8 = jalr_normal_return
    bne ra, t2, jalr_fail

    j jalr_pass

jalr_fail:
    li t0, 2
    j fail_exit

jalr_pass:

# ====================== Test 3: BEQ / BNE (Equality Branches) ======================
    li t1, 10
    li t2, 10
    li t4, 25

    beq t1, t2, beq_taken_ok
    li t0, 3
    j fail_exit
beq_taken_ok:

    beq t1, t4, beq_not_ok
    j beq_pass
beq_not_ok:
    li t0, 3
    j fail_exit
beq_pass:

    bne t1, t4, bne_taken_ok
    li t0, 3
    j fail_exit
bne_taken_ok:
    bne t1, t2, bne_not_ok
    j bne_pass
bne_not_ok:
    li t0, 3
    j fail_exit
bne_pass:

# ====================== Test 4: BLT / BGE (Signed Comparisons) ======================
    li t3, -8
    li t6, 0x80000000

    blt t3, t1, blt_taken_ok
    li t0, 4
    j fail_exit
blt_taken_ok:

    blt t1, t3, blt_not_fail
    j blt_not_ok
blt_not_fail:
    li t0, 4
    j fail_exit
blt_not_ok:

    blt t1, t2, blt_eq_fail
    j blt_eq_ok
blt_eq_fail:
    li t0, 4
    j fail_exit
blt_eq_ok:

    blt t6, zero, blt_neg_ok
    li t0, 4
    j fail_exit
blt_neg_ok:

    bge t1, t3, bge_taken_ok
    li t0, 4
    j fail_exit
bge_taken_ok:

    bge t1, t2, bge_eq_ok
    li t0, 4
    j fail_exit
bge_eq_ok:

    bge t3, t1, bge_not_ok
    j bge_pass
bge_not_ok:
    li t0, 4
    j fail_exit
bge_pass:

# ====================== Test 5: BLTU / BGEU (Unsigned Comparisons) ======================
    bltu t1, t4, bltu_taken_ok
    li t0, 5
    j fail_exit
bltu_taken_ok:

    bltu t4, t1, bltu_not_fail
    j bltu_not_ok
bltu_not_fail:
    li t0, 5
    j fail_exit
bltu_not_ok:

    bltu t6, t1, bltu_unsigned_not_fail
    j bltu_unsigned_not_ok
bltu_unsigned_not_fail:
    li t0, 5
    j fail_exit
bltu_unsigned_not_ok:

    bgeu t4, t1, bgeu_taken_ok
    li t0, 5
    j fail_exit
bgeu_taken_ok:

    bgeu t1, t1, bgeu_eq_ok
    li t0, 5
    j fail_exit
bgeu_eq_ok:

    bgeu t1, t6, bgeu_not_fail
    j bgeu_pass
bgeu_not_fail:
    li t0, 5
    j fail_exit
bgeu_pass:

# ====================== Test 6: Zero and Edge Cases ======================
    li t1, 0

    beq t1, zero, beq_take_ok
    li t0, 6
    j fail_exit
beq_take_ok:

    bne t1, zero, bne_not_fail
    j bne_zero_not_ok
bne_not_fail:
    li t0, 6
    j fail_exit
bne_zero_not_ok:

    blt zero, t4, zero_lt_pos_ok
    li t0, 6
    j fail_exit
zero_lt_pos_ok:

    blt t4, zero, zero_gt_pos_fail
    j zero_gt_pos_ok
zero_gt_pos_fail:
    li t0, 6
    j fail_exit
zero_gt_pos_ok:

    bge zero, zero, zero_ge_zero_ok
    li t0, 6
    j fail_exit
zero_ge_zero_ok:

# ====================== All Tests Passed ======================
    li t0, 7

# ====================== Output Result ======================
fail_exit:
    sw t0, 0(t5)

# ====================== Infinite Loop ======================
end:
    j end
