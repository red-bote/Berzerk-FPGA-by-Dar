---------------------------------------------------------------------------------
-- Company: Red~Bote
-- Engineer: Glenn Neidermeier
-- 
-- Create Date: 10/06/2024 07:46:55 AM
-- Design Name: 
-- Module Name: rtl_top - RTL
-- Project Name: berzerk by Dar (darfpga@aol.fr)
-- Target Devices: Artix 7
-- Tool Versions: Vivado v2020.2
-- Description: Top-level for Basys 3 board
-- Dependencies: vhdl_berzerk_rev_0_1_2018_08_08
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   based on DE10_lite Top level berzerk by Dar (darfpga@aol.fr)
--   http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input on JB PMOD header
--  Audio pwm output on PmodAMP2
--
-- Uses Xilinx clock IP to generate 10 MHz from the 100 MHz Basys3 oscillator
--
-- Board key :
--   btnC : reset game
--
-- Keyboard players inputs :
--
--   F3 : Add coin
--   F2 : Start 2 players
--   F1 : Start 1 player
--   SPACE       : fire
--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : move up
--   DOWN  arrow : move down
--
-- Sound effects : OK
-- Speech synthesis : todo
--
-- Other details : see berzerk.vhd
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rtl_top is
  port (
    clk              : in  std_logic;

    btnC             : in  std_logic;
    btnU             : in  std_logic;
    btnL             : in  std_logic;
    btnR             : in  std_logic;
    btnD             : in  std_logic;

    sw               : in  std_logic_vector(15 downto 0);

    JA               : in  std_logic_vector(4 downto 0);
    JB               : in  std_logic_vector(7 downto 0);

    O_PMODAMP2_AIN   : out std_logic;
    O_PMODAMP2_GAIN  : out std_logic;
    O_PMODAMP2_SHUTD : out std_logic;

    vgaRed           : out std_logic_vector(3 downto 0);
    vgaGreen         : out std_logic_vector(3 downto 0);
    vgaBlue          : out std_logic_vector(3 downto 0);
    vgaHsync         : out std_logic;
    vgaVsync         : out std_logic;

    led              : out std_logic_vector(15 downto 0)
  );
end rtl_top;

architecture RTL of rtl_top is

  signal ledr                 : std_logic_vector(9 downto 0);

  signal clock_10             : std_logic;
  signal reset                : std_logic;

  signal r                    : std_logic;
  signal g                    : std_logic;
  signal b                    : std_logic;
  signal hi                   : std_logic;
  signal csync                : std_logic;
  signal hsync                : std_logic;
  signal vsync                : std_logic;
  signal blankn               : std_logic;
  signal tv15Khz_mode         : std_logic;

  signal video_r              : std_logic_vector(3 downto 0);
  signal video_g              : std_logic_vector(3 downto 0);
  signal video_b              : std_logic_vector(3 downto 0);

  signal audio                : std_logic_vector(15 downto 0);
  signal pwm_accumulator      : std_logic_vector(12 downto 0);

  alias  ps2_dat              : std_logic is JB(0);
  alias  ps2_clk              : std_logic is JB(2);

  signal kbd_intr             : std_logic;
  signal kbd_scancode         : std_logic_vector(7 downto 0);
  signal joyHBCPPFRLDU    : std_logic_vector(9 downto 0);

  signal dbg_cpu_di           : std_logic_vector(7 downto 0);
  signal dbg_cpu_addr         : std_logic_vector(15 downto 0);
  signal dbg_cpu_addr_latch   : std_logic_vector(15 downto 0);
  alias  vga_r                : std_logic_vector is vgaRed;
  alias  vga_g                : std_logic_vector is vgaGreen;
  alias  vga_b                : std_logic_vector is vgaBlue;
  alias  vga_hs               : std_logic is vgaHsync;
  alias  vga_vs               : std_logic is vgaVsync;

  component clk_wiz_0
    port (
      clk_out1                : out std_logic;
      reset                   : in  std_logic;
      locked                  : out std_logic;
      clk_in1                 : in  std_logic
    );
  end component;

  signal ja_right             : std_logic;
  signal ja_left              : std_logic;
  signal ja_up                : std_logic;
  signal ja_down              : std_logic;
  signal ja_fire              : std_logic;

  signal berzerk_coin1        : std_logic;
  signal berzerk_start1       : std_logic;
  signal berzerk_right1       : std_logic;
  signal berzerk_left1        : std_logic;
  signal berzerk_up1          : std_logic;
  signal berzerk_down1        : std_logic;
  signal berzerk_fire1        : std_logic;

begin

  led(9 downto 0) <= ledr;

  -- JA joystick
  ja_right <= not JA(0);
  ja_left  <= not JA(1);
  ja_down  <= not JA(2);
  ja_up    <= not JA(3);
  ja_fire  <= not JA(4);

  -- merge keyboard and joystick
  berzerk_coin1  <= joyHBCPPFRLDU(7) or (ja_fire and ja_up);
  berzerk_start1 <= joyHBCPPFRLDU(5) or (ja_fire and ja_left);
  berzerk_right1 <= joyHBCPPFRLDU(3) or ja_right;
  berzerk_left1  <= joyHBCPPFRLDU(2) or ja_left;
  berzerk_down1  <= joyHBCPPFRLDU(1) or ja_down;
  berzerk_up1    <= joyHBCPPFRLDU(0) or ja_up;
  berzerk_fire1  <= joyHBCPPFRLDU(4) or ja_fire;

  reset        <= btnC;
  tv15Khz_mode <= '0';

  -- Clock 10MHz for Berzerk core
  clocks : clk_wiz_0
    port map(
      clk_out1                => clock_10,
      reset                   => reset,
      locked                  => open,
      clk_in1                 => clk
    );

  -- berzerk
  berzerk : entity work.berzerk
    port map(
      clock_10                => clock_10,
      reset                   => reset,

      tv15Khz_mode            => tv15Khz_mode,
      video_r                 => r,
      video_g                 => g,
      video_b                 => b,
      video_hi                => hi,
      video_csync             => csync,
      video_hs                => hsync,
      video_vs                => vsync,
      audio_out               => audio,

      start2                  => joyHBCPPFRLDU(6),
      start1                  => berzerk_start1,
      coin1                   => berzerk_coin1,
      cocktail                => '1',

      right1                  => berzerk_right1,
      left1                   => berzerk_left1,
      down1                   => berzerk_down1,
      up1                     => berzerk_up1,
      fire1                   => berzerk_fire1,

      right2                  => berzerk_right1,
      left2                   => berzerk_left1,
      down2                   => berzerk_down1,
      up2                     => berzerk_up1,
      fire2                   => berzerk_fire1,

      sw                      => (others => '0'),
      ledr                    => ledr,
      dbg_cpu_di              => dbg_cpu_di,
      dbg_cpu_addr            => dbg_cpu_addr,
      dbg_cpu_addr_latch      => dbg_cpu_addr_latch
    );

  blankn <= '1';

  -- adapt video to 4bits/color only
  video_r <= "1100" when r = '1' and hi = '1' else
             "0100" when r = '1' and hi = '0' else
             "0000";

  video_g <= "1100" when g = '1' and hi = '1' else
             "0100" when g = '1' and hi = '0' else
             "0000";

  video_b <= "1100" when b = '1' and hi = '1' else
             "0100" when b = '1' and hi = '0' else
             "0000";

  vga_r <= video_r when blankn = '1' else "0000";
  vga_g <= video_g when blankn = '1' else "0000";
  vga_b <= video_b when blankn = '1' else "0000";

-- synchro composite/ synchro horizontale
  vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
  vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

-- get scancode from keyboard
  keyboard : entity work.io_ps2_keyboard
    port map(
      clk                     => clock_10, -- use same clock as main core
      kbd_clk                 => ps2_clk,
      kbd_dat                 => ps2_dat,
      interrupt               => kbd_intr,
      scancode                => kbd_scancode
    );

-- translate scancode to joystick
  joystick : entity work.kbd_joystick
    port map(
      clk                     => clock_10, -- use same clock as main core
      kbdint                  => kbd_intr,
      kbdscancode             => std_logic_vector(kbd_scancode),
      joyHBCPPFRLDU           => joyHBCPPFRLDU,
      keys_HUA                => open
    );

  -- pwm sound output
  process (clock_10)  -- use same clock as sound_board
  begin
    if rising_edge(clock_10) then
      pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned('0' & audio(15 downto 4)));
    end if;
  end process;

    -- active-low shutdown pin
  O_PMODAMP2_SHUTD <= sw(14);
    -- gain pin is driven high there is a 6 dB gain, low is a 12 dB gain 
  O_PMODAMP2_GAIN  <= sw(15);
  O_PMODAMP2_AIN   <= pwm_accumulator(12);

end RTL;
