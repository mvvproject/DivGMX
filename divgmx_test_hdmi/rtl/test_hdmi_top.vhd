-------------------------------------------------------------------[06.11.2016]
-- Test HDMI
-- DevBoard DivGMX Ultimate rev.A By MVV
-------------------------------------------------------------------------------
-- Engineer: MVV
-- https://github.com/mvvproject/divgmx
--
-- Author VGA test pattern By Mike Field <hamster@snap.net.nz>
-- http://hamsterworks.co.nz/mediawiki/index.php/Minimal_HDMI
--
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity test_hdmi_top is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;
	-- HDMI
	TMDS		: out std_logic_vector(7 downto 0);
	-- USB Host (VNC2-32)
--	USB_IO3		: in std_logic;
--	USB_TXD		: in std_logic;
--	USB_RXD		: out std_logic;
	-- SPI (W25Q64/SD)
--	DATA0		: in std_logic;
--	ASDO		: out std_logic;
--	DCLK		: out std_logic;
	NCSO		: out std_logic;
	-- I2C (HDMI/RTC)
--	I2C_SCL		: inout std_logic;
--	I2C_SDA		: inout std_logic;
	-- SD
--	SD_NDET		: in std_logic;
--	SD_NCS		: out std_logic;
	-- SDRAM (32M8)
--	DRAM_DQ		: inout std_logic_vector(7 downto 0);
--	DRAM_A		: out std_logic_vector(12 downto 0);
--	DRAM_BA		: out std_logic_vector(1 downto 0);
--	DRAM_DQM	: out std_logic;
--	DRAM_CLK	: out std_logic;
--	DRAM_NWE	: out std_logic;
--	DRAM_NCAS	: out std_logic;
--	DRAM_NRAS	: out std_logic;
	-- Audio
--	OUT_L		: out std_logic;
--	OUT_R		: out std_logic;
	-- ZXBUS
--	BUF_NINT	: in std_logic;
	BUF_NNMI	: in std_logic;
--	BUF_NRESET	: in std_logic;
--	BUF_DIR		: out std_logic_vector(1 downto 0)
--	BUS_CLK		: inout std_logic;
--	BUS_D		: inout std_logic_vector(7 downto 0);
--	BUS_A		: inout std_logic_vector(15 downto 0);
--	BUS_NMREQ	: inout std_logic;
--	BUS_NIORQ	: inout std_logic;
--	BUS_NBUSACK	: inout std_logic;
--	BUS_NRD		: inout std_logic;
--	BUS_NWR		: inout std_logic;
--	BUS_NM1		: inout std_logic;
--	BUS_NRFSH	: inout std_logic;
	BUS_NINT	: out std_logic;
	BUS_NWAIT	: out std_logic;
	BUS_NBUSRQ	: out std_logic;
	BUS_NROMOE	: out std_logic;
	BUS_NIORQGE	: out std_logic);
end test_hdmi_top;


architecture rtl of test_hdmi_top is

-- ModeLine " 640x 480@60Hz"  25.20  640  656  752  800  480  490  492  525 -HSync -VSync
-- ModeLine " 720x 480@60Hz"  27.00  720  736  798  858  480  489  495  525 -HSync -VSync
-- Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync
-- ModeLine "1024x 768@60Hz"  65.00 1024 1048 1184 1344  768  771  777  806 -HSync -VSync
-- ModeLine "1280x 720@60Hz"  74.25 1280 1390 1430 1650  720  725  730  750 +HSync +VSync
-- ModeLine "1280x 768@60Hz"  80.14 1280 1344 1480 1680  768  769  772  795 +HSync +VSync
-- ModeLine "1280x 800@60Hz"  83.46 1280 1344 1480 1680  800  801  804  828 +HSync +VSync
-- ModeLine "1280x 960@60Hz" 108.00 1280 1376 1488 1800  960  961  964 1000 +HSync +VSync
-- ModeLine "1280x1024@60Hz" 108.00 1280 1328 1440 1688 1024 1025 1028 1066 +HSync +VSync
-- ModeLine "1360x 768@60Hz"  85.50 1360 1424 1536 1792  768  771  778  795 -HSync -VSync
-- ModeLine "1920x1080@25Hz"  74.25 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync
-- ModeLine "1920x1080@30Hz"  89.01 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync

-- Horizontal Timing constants  
constant h_pixels_across	: integer := 640 - 1;
constant h_sync_on		: integer := 656 - 1;
constant h_sync_off		: integer := 752 - 1;
constant h_end_count		: integer := 800 - 1;
-- Vertical Timing constants
constant v_pixels_down		: integer := 480 - 1;
constant v_sync_on		: integer := 490 - 1;
constant v_sync_off		: integer := 492 - 1;
constant v_end_count		: integer := 525 - 1;

signal hcnt		: std_logic_vector(11 downto 0) := "000000000000"; 	-- horizontal pixel counter
signal vcnt		: std_logic_vector(11 downto 0) := "000000000000"; 	-- vertical line counter
signal hsync		: std_logic;
signal vsync		: std_logic;
signal blank		: std_logic;
signal shift		: std_logic_vector(7 downto 0);
signal red		: std_logic_vector(7 downto 0);
signal green		: std_logic_vector(7 downto 0);
signal blue		: std_logic_vector(7 downto 0);
signal clk_hdmi		: std_logic;
signal clk_vga		: std_logic;


begin

-- PLL
pll0_inst: entity work.pll0
port map (
	areset		=> not BUF_NNMI,
	inclk0		=> CLK_50MHZ,	-- 50.0 MHz
	-- out
	locked		=> open,
	c0		=> clk_hdmi,	-- clk_vga * 5
	c1		=> clk_vga);

-- HDMI
hdmi_inst: entity work.hdmi
port map (
	I_CLK_PIXEL	=> clk_vga,
	I_CLK_TMDS	=> clk_hdmi,	-- 472.6 MHz max

	I_HSYNC		=> hsync,
	I_VSYNC		=> vsync,
	I_BLANK		=> blank,
	I_RED		=> red,
	I_GREEN		=> green,
	I_BLUE		=> blue,
	O_TMDS		=> TMDS);

	process (clk_vga, hcnt)
	begin
		if clk_vga'event and clk_vga = '1' then
			if hcnt = h_end_count then
				hcnt <= (others => '0');
			else
				hcnt <= hcnt + 1;
			end if;
			if hcnt = h_sync_on then
				if vcnt = v_end_count then
					vcnt <= (others => '0');
					shift <= shift + 1;
				else
					vcnt <= vcnt + 1;
				end if;
			end if;
		end if;
	end process;

	hsync	<= '1' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '0';	-- -HSync
	vsync	<= '1' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '0';	-- -VSync
	blank	<= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';

	red	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (hcnt(7 downto 0) + shift) and "11111111";
	green	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (vcnt(7 downto 0) + shift) and "11111111";
	blue	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (hcnt(7 downto 0) + vcnt(7 downto 0) - shift) and "11111111";
	
	NCSO		<= '1';
	BUS_NINT	<= '1';
	BUS_NWAIT	<= '1';
	BUS_NBUSRQ	<= '1';
	BUS_NROMOE	<= '0';
	BUS_NIORQGE	<= '0';

end rtl;