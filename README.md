# Berzerk_FPGA_by_Dar
Porting to Xilinx Artix 7 Basys 3 board -- original Berzerk FPGA by Dar - (darfpga@aol.fr) -- http://darfpga.blogspot.fr

https://sourceforge.net/projects/darfpga/files/Software%20VHDL/berzerk/

## Basys 3 Port

PS/2 keyboard on the JB PMOD header (JB1=ps2_data, JB3=ps2_clk).
JA joystick OR-merged with keyboard. btnC = reset.
Audio output on the PmodAMP2 header (JC).

Open the project in `berzerk_xc7/berzerk_xc7.xpr` with Vivado 2020.2.

Switches:
- sw(15) — PmodAMP2 gain: 0 = 12 dB, 1 = 6 dB
- sw(14) — PmodAMP2 shutdown: 0 = off, 1 = on
