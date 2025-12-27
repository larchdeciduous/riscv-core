.section .text
.global _start

_start:
    # Setup stack pointer (safe high address in SDRAM)
    li sp, 0x81000000

    # Constants
    li s0, 0x20000000   # Framebuffer base address
    li s1, 0x80000000   # Variable storage base address (in SDRAM)

    # Clear framebuffer (set all pixels to black/off)
    li t0, 0x20000000
    li t1, 38400        # Total bytes = 640 * 480 / 8
    li t2, 0
clear_loop:
    sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, clear_loop

    # Initialize ball state
    li t0, 100
    sw t0, 0(s1)        # ball_x = 100
    li t0, 100
    sw t0, 4(s1)        # ball_y = 100
    li t0, 4
    sw t0, 8(s1)        # vel_x = +4 (right)
    li t0, 3
    sw t0, 12(s1)       # vel_y = +3 (down)

main_loop:
    # Erase old ball (color = 0)
    lw a1, 0(s1)        # load x
    lw a2, 4(s1)        # load y
    li a3, 0            # clear
    jal plot_ball

    # Update position
    lw t0, 0(s1)
    lw t1, 8(s1)
    add t0, t0, t1
    sw t0, 0(s1)        # ball_x += vel_x

    lw t0, 4(s1)
    lw t1, 12(s1)
    add t0, t0, t1
    sw t0, 4(s1)        # ball_y += vel_y

    # X bounds check (ball fits in 0 <= x <= 638)
    lw t0, 0(s1)
    li t3, 638
    blt t0, zero, hit_left_x
    bgt t0, t3, hit_right_x
    j x_done
hit_left_x:
    li t0, 0
    sw t0, 0(s1)
    lw t1, 8(s1)
    sub t1, zero, t1    # vel_x = -vel_x
    sw t1, 8(s1)
    j x_done
hit_right_x:
    li t0, 638
    sw t0, 0(s1)
    lw t1, 8(s1)
    sub t1, zero, t1
    sw t1, 8(s1)
x_done:

    # Y bounds check (ball fits in 0 <= y <= 478)
    lw t0, 4(s1)
    li t3, 478
    blt t0, zero, hit_top_y
    bgt t0, t3, hit_bottom_y
    j y_done
hit_top_y:
    li t0, 0
    sw t0, 4(s1)
    lw t1, 12(s1)
    sub t1, zero, t1
    sw t1, 12(s1)
    j y_done
hit_bottom_y:
    li t0, 478
    sw t0, 4(s1)
    lw t1, 12(s1)
    sub t1, zero, t1
    sw t1, 12(s1)
y_done:

    # Draw new ball (color = 1)
    lw a1, 0(s1)
    lw a2, 4(s1)
    li a3, 1
    jal plot_ball

    # Simple delay loop (adjust value for speed)
    li t0, 80000        # Larger = slower animation
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop

    j main_loop

# -------------------------------------------------
# plot_ball: draw or erase a 2x2 ball
# a1 = x (top-left), a2 = y (top-left), a3 = color (0=erase, 1=draw)
plot_ball:
    addi sp, sp, -8
    sw ra, 0(sp)

    # (x, y)
    mv a0, a1
    mv a1, a2
    mv a2, a3
    jal plot_pixel

    # (x+1, y)
    addi a0, a0, 1
    jal plot_pixel

    # (x, y+1)
    addi a0, a0, -1
    addi a1, a1, 1
    jal plot_pixel

    # (x+1, y+1)
    addi a0, a0, 1
    jal plot_pixel

    lw ra, 0(sp)
    addi sp, sp, 8
    ret

# -------------------------------------------------
# plot_pixel: set or clear single pixel
# a0 = x, a1 = y, a2 = color (0=clear, 1=set)
plot_pixel:
    addi sp, sp, -16
    sw ra, 0(sp)

    # offset = y*80 = (y<<6) + (y<<4)
    slli t1, a1, 6
    slli t2, a1, 4
    add t1, t1, t2

    # add byte offset = x >> 3
    srli t2, a0, 3
    add t1, t1, t2

    # full address = base + offset
    add t3, s0, t1

    # bit position = x & 7
    andi t4, a0, 7

    # mask = 1 << bit_pos
    li t5, 1
    sll t5, t5, t4

    # load current byte
    lbu t6, 0(t3)

    # branch on color
    beqz a2, pixel_clear
pixel_set:
    or t6, t6, t5
    j pixel_store
pixel_clear:
    li t0, -1
    xor t5, t5, t0      # ~mask
    and t6, t6, t5
pixel_store:
    sb t6, 0(t3)

    lw ra, 0(sp)
    addi sp, sp, 16
    ret
