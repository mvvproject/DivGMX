-------------------------------------------------------------------[22.11.2016]
-- Basic build 20161122
-- DEVBOARD DivGMX Rev.A
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>
--
-- https://github.com/mvvproject/DivGMX
--
-- Copyright (c) 2016 Vladislav Matlash
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

entity basic is
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
--	BUF_NNMI	: in std_logic;
	BUF_NRESET	: in std_logic;
	BUF_DIR		: out std_logic_vector(1 downto 0);
--	BUS_CLK		: inout std_logic;
	BUS_D		: inout std_logic_vector(7 downto 0);
	BUS_A		: inout std_logic_vector(15 downto 0);
	BUS_NMREQ	: inout std_logic;
	BUS_NIORQ	: inout std_logic;
--	BUS_NBUSACK	: inout std_logic;
	BUS_NRD		: inout std_logic;
	BUS_NWR		: inout std_logic;
--	BUS_NM1		: inout std_logic;
--	BUS_NRFSH	: inout std_logic;
	BUS_NINT	: out std_logic;
	BUS_NWAIT	: out std_logic;
	BUS_NBUSRQ	: out std_logic;
	BUS_NROMOE	: out std_logic;
	BUS_NIORQGE	: out std_logic);
end basic;

architecture rtl of basic is

--signal areset		: std_logic;
signal clk_vga		: std_logic;
signal clk_tmds		: std_logic;
signal clk_bus		: std_logic;

signal sync_hsync	: std_logic;
signal sync_vsync	: std_logic;
signal sync_blank	: std_logic;
signal sync_hcnt	: std_logic_vector(9 downto 0);
signal sync_vcnt	: std_logic_vector(9 downto 0);
signal sync_flash	: std_logic;

signal vga_r		: std_logic_vector(1 downto 0);
signal vga_g		: std_logic_vector(1 downto 0);
signal vga_b		: std_logic_vector(1 downto 0);
signal vga_di		: std_logic_vector(7 downto 0);

signal audio_l		: std_logic_vector(15 downto 0);
signal audio_r		: std_logic_vector(15 downto 0);

signal vram_wr		: std_logic;
signal reg_mreq_n_i	: std_logic;
signal mreq_n_i		: std_logic;
--signal reg_iorq_n_i	: std_logic;
--signal iorq_n_i		: std_logic;
signal reg_rd_n_i	: std_logic;
signal rd_n_i		: std_logic;
signal vram_scr		: std_logic;
signal ram_addr		: std_logic_vector(3 downto 0);
signal port_7ffd_reg	: std_logic_vector(7 downto 0) := "00010000";
signal mux		: std_logic_vector(2 downto 0);
signal port_xxfe_reg	: std_logic_vector(7 downto 0);
signal vga_addr		: std_logic_vector(12 downto 0);

signal rom_do		: std_logic_vector(7 downto 0);


--Вывод изображения на HDMI со звуком +
--DivMMC/Z-Controller
--CMOS (стандарт Mr. Gluk)
--Kempston joystick/Gamepad
--Kempston mouse
--SounDrive
--Turbo Sound

begin

-- PLL
U1: entity work.altpll0
port map (
	areset		=> '0',
	locked		=> open,
	inclk0		=> CLK_50MHZ,		--  50.00 MHz
	c0		=> clk_vga,		--  25.20 MHz
	c1		=> clk_tmds,		-- 126.00 MHz
	c2		=> clk_bus);		--  28.00 MHz

-- HDMI
U2: entity work.hdmi
generic map (
	FREQ		=> 25200000,		-- pixel clock frequency = 25.2MHz
	FS		=> 48000,		-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
	CTS		=> 25200,		-- CTS = Freq(pixclk) * N / (128 * Fs)
	N		=> 6144)		-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
port map (
	I_CLK_VGA	=> clk_vga,
	I_CLK_TMDS	=> clk_tmds,
	I_HSYNC		=> sync_hsync,
	I_VSYNC		=> sync_vsync,
	I_BLANK		=> sync_blank,
	I_RED		=> vga_r & vga_r & vga_r & vga_r,
	I_GREEN		=> vga_g & vga_g & vga_g & vga_g,
	I_BLUE		=> vga_b & vga_b & vga_b & vga_b,
	I_AUDIO_PCM_L 	=> audio_l,
	I_AUDIO_PCM_R	=> audio_r,
	O_TMDS		=> TMDS);

-- Sync
U3: entity work.sync
port map (
	I_CLK		=> clk_vga,
	I_EN		=> '1',
	O_HCNT		=> sync_hcnt,
	O_VCNT		=> sync_vcnt,
	O_INT		=> open,
	O_FLASH		=> sync_flash,
	O_BLANK		=> sync_blank,
	O_HSYNC		=> sync_hsync,
	O_VSYNC		=> sync_vsync);	

-- Video
U4: entity work.vga_zx
port map (
	I_CLK		=> clk_vga,
	I_CLKEN		=> '1',
	I_DATA		=> vga_di,
	I_BORDER	=> port_xxfe_reg(2 downto 0),	-- Биты D0..D2 порта xxFE определяют цвет бордюра
	I_HCNT		=> sync_hcnt,
	I_VCNT		=> sync_vcnt,
	I_BLANK		=> sync_blank,
	I_FLASH		=> sync_flash,
	O_ADDR		=> vga_addr,
	O_PAPER		=> open,
	O_RED		=> vga_r,
	O_GREEN		=> vga_g,
	O_BLUE		=> vga_b);	
	
-- Video RAM 16K
U5: entity work.vram
port map (
	address_a	=> vram_scr & BUS_A(12 downto 0),
	address_b	=> port_7ffd_reg(3) & vga_addr,
	clock_a		=> clk_bus,
	clock_b		=> clk_vga,
	data_a	 	=> BUS_D,
	data_b	 	=> (others => '0'),
	wren_a	 	=> vram_wr,
	wren_b	 	=> '0',
	q_a	 	=> open,
	q_b	 	=> vga_di);

U6: entity work.rom
port map (
	address		=> BUS_A(13 downto 0),
	clock		=> clk_bus,
	q		=> rom_do);


--areset <= not BUF_NRESET;	-- глобальный сброс
	
	
process (clk_bus)
begin
	if clk_bus'event and clk_bus = '1' then
		reg_mreq_n_i	<= BUS_NMREQ;
--		reg_iorq_n_i	<= BUS_NIORQ;
		reg_rd_n_i	<= BUS_NRD;
--		reg_wr_n_i	<= BUS_NWR;
		
		mreq_n_i	<= reg_mreq_n_i;
--		iorq_n_i	<= reg_iorq_n_i;
		rd_n_i		<= reg_rd_n_i;
--		wr_n_i		<= reg_wr_n_i;
		
	end if;
end process;

-------------------------------------------------------------------------------
-- Video
vram_scr <= '1' when (ram_addr = "1110") else '0';
vram_wr  <= '1' when (BUS_NMREQ = '0' and BUS_NWR = '0' and ((ram_addr = "1010") or (ram_addr = "1110"))) else '0';

------------------------------------------------------------------------------
-- Селектор
mux <= BUS_A(15 downto 13);

process (mux, port_7ffd_reg, ram_addr)
begin
	case mux is
		when "010" => ram_addr <= "1010";				-- Seg1 RAM 4000-5FFF
		when "011" => ram_addr <= "1011";				-- Seg1 RAM 6000-7FFF
		when "100" => ram_addr <= "0100";				-- Seg2 RAM 8000-9FFF
		when "101" => ram_addr <= "0101";				-- Seg2 RAM A000-BFFF
		when "110" => ram_addr <= port_7ffd_reg(2 downto 0) & '0';	-- Seg3 RAM C000-DFFF
		when "111" => ram_addr <= port_7ffd_reg(2 downto 0) & '1';	-- Seg3 RAM E000-FFFF
		when others => ram_addr <= "0000";
	end case;
end process;

-------------------------------------------------------------------------------
-- Регистры
process (BUF_NRESET, clk_bus, BUS_A, port_7ffd_reg, BUS_NWR, BUS_D, BUS_NIORQ)
begin
	if (BUF_NRESET = '0') then
		port_7ffd_reg <= "00010000";
	elsif (clk_bus'event and clk_bus = '1') then
		if (BUS_NIORQ = '0' and BUS_NWR = '0' and BUS_A = X"7FFD" and port_7ffd_reg(5) = '0') then port_7ffd_reg <= BUS_D; end if;	-- D7-D6:не используются; D5:1=запрещение расширенной памяти (48K защёлка); D4=номер страницы ПЗУ(0-BASIC128, 1-BASIC48); D3=выбор отображаемой видеостраницы(0-страница в банке 5, 1 - в банке 7); D2-D0=номер страницы ОЗУ подключенной в верхние 16 КБ памяти (с адреса #C000)
	end if;
end process;

process (clk_bus, BUS_A, port_xxfe_reg, BUS_NWR, BUS_D, BUS_NIORQ)
begin
	if (clk_bus'event and clk_bus = '1') then
		if (BUS_NIORQ = '0' and BUS_NWR = '0' and BUS_A(7 downto 0) = X"FE") then port_xxfe_reg <= BUS_D; end if;	-- D7-D5=не используются; D4=бипер; D3=MIC; D2-D0=цвет бордюра
	end if;
end process;

audio_l <= "0000" & port_xxfe_reg(4) & "00000000000";
audio_r <= "0000" & port_xxfe_reg(4) & "00000000000";

-- ZX-BUS
BUS_NINT	<= '1';
BUS_NWAIT	<= '1';
BUS_NBUSRQ	<= '1';
BUS_NROMOE	<= '1';
BUS_NIORQGE	<= '0';

BUS_D	<= rom_do when (mreq_n_i = '0' and rd_n_i = '0' and BUS_A(15 downto 14) = "00") else (others => 'Z');
BUF_DIR	<= "10" when (mreq_n_i = '0' and rd_n_i = '0' and BUS_A(15 downto 14) = "00") else "00";


end rtl;
