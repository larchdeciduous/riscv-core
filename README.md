# RISC-V Core (RV32I, CSR M-MODE, Timer interrupt)

This repository contains a simple RISC-V RV32I CPU core implemented in Verilog. It is designed and tested on the iCESugar Pro FPGA board (based on Lattice ECP5). The core supports basic RISC-V instructions, CSR operations, timer interrupts, and peripherals like SDRAM, HDMI output (via frame buffer), UART (TX only), GPIO, and LEDs. It uses a single-cycle-like architecture with stalls for memory operations.

The core is loaded with a program via `inst.rom` (a hex file for instruction memory). It includes support for machine mode.

## Features

- **Instruction Set**: RV32I_zicsr
- **Privileges**: Machine mode (M-mode) with CSR support; partial delegation for Supervisor mode (S-mode).
- **Interrupts**: Timer interrupt (via `mtime` and `mtimecmp` CSRs).
- **Memory**: 
  - Instruction ROM (4KB).
  - SDRAM (up to 32MB).
  - Frame buffer for graphics.
- **Peripherals**:
  - UART TX (baud rate configurable).
  - 3 LEDs.
  - 8 GPIO pins.
  - HDMI output (simple black/white frame buffer).
- **Clocking**: Uses PLL to generate 25MHz and 250MHz clocks from 25MHz input.
- **Tools**: Synthesizable with open-source FPGA tools (Yosys, nextpnr-ecp5, Trellis).

## CPU Structure

The CPU is modular, with the following key components:

- **riscvcore.v**: Top-level module integrating all components.
- **instf.v**: Instruction fetch and decode stage. Handles PC management, register addressing, ALU control, memory control, CSR operations, jumps/branches, and traps.
- **registers.v**: 32-register file (x0-x31), for single-cycle operation.
- **alu.v**: Arithmetic Logic Unit supporting add, sub, shifts, comparisons, logical ops.
- **instmem.v**: Instruction memory (ROM, 2048 halfwords / 4KB, loaded from `inst.rom`).
- **datamem.v**: Data memory interface. Routes accesses to SDRAM, IO, frame buffer, or instruction ROM (for data reads). Handles stalls for slow operations.
- **csr.v**: Control and Status Registers. Supports `mstatus`, `mie`, `mtvec`, `mepc`, `mcause`, `mip`, `mtime`/`mtimecmp` (for timers).
- **uart.v**: Simple UART transmitter (TX only, FIFO-buffered).
- **frame_buffer.v**: 640x480 black/white frame buffer (38KB RAM, 1-bit per pixel).
- **sdram.v** : SDRAM controller for external memory.
- **hdmi_ctler.v** : HDMI controller using GP-DI for TMDS output.
- **pll.v** : PLL for clock generation.

### Architecture Overview

- **Pipeline**: Simple, non-pipelined (single-stage with stalls for memory/IO).
- **Execution Flow**:
  1. Fetch instruction from `instmem` based on PC.
  2. Decode in `instf` (extract opcodes, registers, immediates).
  3. Read registers from `registers`.
  4. Execute in `alu` or handle branches/jumps.
  5. Access memory/IO via `datamem` if needed (stall if busy).
  6. Write back to registers or CSRs.
  7. Handle traps/interrupts via `csr` (e.g., timer interrupt when `mtime >= mtimecmp`).
- **Stalls**: Occur during SDRAM, frame buffer, or UART accesses if fifo full.
- **Interrupts/Traps**: Timer interrupt enabled via `mie` and `mstatus`. Traps vector to `mtvec`.

## Memory Map

The data memory (`datamem.v`) maps addresses as follows:

- **0x00000000 - 0x00000FFF**: Instruction ROM (readable as data; 4KB, halfword-aligned).
- **0x20000000 - 0x2000FFFF**: IO Region
  - 0x20000000: LEDs (write: bits 0-2 control 3 LEDs; read: current state).
  - 0x20001000: GPIO (write: bits 0-7 control 8 GPIO pins; read: current state).
  - 0x20002000: UART TX Data (write: send byte; stalls if FIFO full).
  - 0x20004000: `mtimecmp` Low 32 bits (write: set timer compare value).
  - 0x20004004: `mtimecmp` High 32 bits (write: set timer compare value).
  - 0x2000BFF8: `mtime` Low 32 bits (read-only: current timer value).
  - 0x2000BFFC: `mtime` High 32 bits (read-only: current timer value).
- **0x21000000 - 0x210095FF**: Frame Buffer (38KB; 640x480 pixels, 1-bit per pixel, 32-bit words).
  - Write: Update pixels (mask controls byte/halfword/word).
  - Read: Fetch pixel data.
- **0x80000000 - 0x81FFFFFF**: SDRAM (32MB; byte/halfword/word access, odd-byte support).
- **Other Addresses**: Illegal access (traps with cause 0x02).

Note: Instruction fetch uses a separate path to `instmem`, but data accesses to 0x0000xxxx route to the same ROM.

## Tested Board: iCESugar Pro

This core is tested on the [iCESugar Pro](https://github.com/wuxx/icesugar-pro) board (Lattice ECP5-25F FPGA, 25MHz oscillator, 32MB SDRAM, HDMI, UART via USB).

### Build

 **Build**:
   ```
   make
   ```
 **Change rom of instruction by .asm**:
   ```
   cd src_roms/<any demo>
   make
   ```
 **Change rom of instruction by c lang**:
   ```
   cd src_clang_roms/<any demo>
   make
   ```


## Limitations

- No floating-point or atomic extensions.
- UART is TX-only (no RX).
- HDMI is basic (monochrome 640x480).
- No S-mode
- No cache; SDRAM accesses are slow (stalls).
