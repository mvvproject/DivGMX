-------------------------------------------------------------------[07.04.2018]
-- FPGA SoftCore - ALF TV GAME
-- DEVBOARD DivGMX-Ultimate Rev.A
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>
--
-- https://github.com/mvvproject/DivGMX
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

-- 20180404	Первая сборка

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity alf is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;
	-- HDMI
	TMDS		: out std_logic_vector(7 downto 0);
	-- USB Host (VNC2-32)
	USB_IO3		: in std_logic;
	USB_TXD		: in std_logic;
--	USB_RXD		: out std_logic;
	-- SPI (W25Q64/SD)
	DATA0		: in std_logic;
	ASDO		: out std_logic;
	DCLK		: out std_logic;
	NCSO		: out std_logic;
	-- I2C (HDMI/RTC)
	I2C_SCL		: inout std_logic;
	I2C_SDA		: inout std_logic;
	-- SD
	SD_NDET		: in std_logic;
	SD_NCS		: out std_logic;
	-- SDRAM (32M8)
	DRAM_DQ		: inout std_logic_vector(7 downto 0);
	DRAM_A		: out std_logic_vector(12 downto 0);
	DRAM_BA		: out std_logic_vector(1 downto 0);
	DRAM_DQM	: out std_logic;
	DRAM_CLK	: out std_logic;
	DRAM_NWE	: out std_logic;
	DRAM_NCAS	: out std_logic;
	DRAM_NRAS	: out std_logic;
	-- Audio
	OUT_L		: out std_logic;
	OUT_R		: out std_logic;
	-- ZXBUS
	BUF_NINT	: in std_logic;
	BUF_NNMI	: in std_logic;
	BUF_NRESET	: in std_logic;
	BUF_DIR		: inout std_logic_vector(1 downto 0);
	BUS_CLK		: inout std_logic;
	BUS_D		: inout std_logic_vector(7 downto 0);
	BUS_A		: inout std_logic_vector(15 downto 0);
	BUS_NMREQ	: inout std_logic;
	BUS_NIORQ	: inout std_logic;
	BUS_NBUSACK	: inout std_logic;
	BUS_NRD		: inout std_logic;
	BUS_NWR		: inout std_logic;
	BUS_NM1		: inout std_logic;
	BUS_NRFSH	: inout std_logic;
	BUS_NINT	: out std_logic;
	BUS_NWAIT	: out std_logic;
	BUS_NBUSRQ	: out std_logic;
	BUS_NROMOE	: out std_logic;
	BUS_NIORQGE	: out std_logic);
end alf;

architecture rtl of alf is

signal reset		: std_logic;
signal areset		: std_logic;
signal loader		: std_logic := '1';
signal clk_vga		: std_logic;
signal clk_tmds		: std_logic;
signal clk_bus		: std_logic;
signal clk_sdr		: std_logic;
signal c8		: std_logic;

signal sync_hsync	: std_logic;
signal sync_vsync	: std_logic;
signal sync_blank	: std_logic;
signal sync_h		: std_logic_vector(9 downto 0);
signal sync_hcnt	: std_logic_vector(9 downto 0);
signal sync_vcnt	: std_logic_vector(9 downto 0);
signal sync_flash	: std_logic;
signal sync_int		: std_logic;

signal vga_r		: std_logic_vector(1 downto 0);
signal vga_g		: std_logic_vector(1 downto 0);
signal vga_b		: std_logic_vector(1 downto 0);
signal vga_di		: std_logic_vector(7 downto 0);

-- Audio
signal beeper		: std_logic_vector(7 downto 0);
signal audio_l		: std_logic_vector(15 downto 0);
signal audio_r		: std_logic_vector(15 downto 0);

signal reg_mreq_n_i	: std_logic;
signal reg_iorq_n_i	: std_logic;
signal reg_rd_n_i	: std_logic;
signal reg_wr_n_i	: std_logic;
signal reg_a_i		: std_logic_vector(15 downto 0);
signal reg_d_i		: std_logic_vector(7 downto 0);
signal reg_reset_n_i	: std_logic;
signal reg_m1_n_i	: std_logic;
signal reg_rfsh_n_i	: std_logic;
signal reg_nmi_n_i	: std_logic;
signal reg_int_n_i	: std_logic;
signal mreq_n_i		: std_logic;
signal iorq_n_i		: std_logic;
signal rd_n_i		: std_logic;
signal wr_n_i		: std_logic;
signal a_i		: std_logic_vector(15 downto 0);
signal d_i		: std_logic_vector(7 downto 0);
signal reset_n_i	: std_logic;
signal m1_n_i		: std_logic;
signal rfsh_n_i		: std_logic;
signal nmi_n_i		: std_logic;
signal int_n_i		: std_logic;

signal selector		: std_logic_vector(3 downto 0);
signal inta_n		: std_logic;
signal mux		: std_logic_vector(1 downto 0);
signal vga_addr		: std_logic_vector(12 downto 0);
signal rom_do		: std_logic_vector(7 downto 0);
signal vram_wr		: std_logic;
--signal vram_scr		: std_logic;
signal ram_a		: std_logic_vector(10 downto 0);
signal turbo		: std_logic_vector(1 downto 0) := "00";
-- Ports registers
signal port_0000_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_0001_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_xxfe_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_xx5f_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_xx7f_reg	: std_logic_vector(10 downto 0) := "00000000000";
-- SDRAM
signal sdr_do		: std_logic_vector(7 downto 0);
signal sdr_wr		: std_logic;
signal sdr_rd		: std_logic;
signal sdr_rfsh		: std_logic;
-- Keyboard
signal kb_fkeys		: std_logic_vector(12 downto 1);
signal kb_fn		: std_logic_vector(12 downto 1);
signal key		: std_logic_vector(12 downto 1) := "000000000000";
signal kb_soft		: std_logic_vector(3 downto 0);
signal kb_joy1		: std_logic_vector(4 downto 0);
signal kb_joy2		: std_logic_vector(4 downto 0);
signal gamepad1		: std_logic_vector(13 downto 0);
signal gamepad2		: std_logic_vector(13 downto 0);

signal ena_14m0hz	: std_logic;
signal ena_7m0hz	: std_logic;
signal ena_3m5hz	: std_logic;
signal ena_1m75hz	: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt		: std_logic_vector(5 downto 0);
-- CPU
signal cpu_a		: std_logic_vector(15 downto 0);
signal cpu_do		: std_logic_vector(7 downto 0);
signal cpu_di		: std_logic_vector(7 downto 0);
signal cpu_mreq_n	: std_logic;
signal cpu_iorq_n	: std_logic;
signal cpu_wr_n		: std_logic;
signal cpu_rd_n		: std_logic;
signal cpu_int_n	: std_logic;
signal cpu_m1_n		: std_logic;
signal cpu_nmi_n	: std_logic;
signal cpu_rfsh_n	: std_logic;
signal cpu_ena		: std_logic;
-- PLL
signal locked0		: std_logic;
-- SPI
signal spi_do		: std_logic_vector(7 downto 0);
signal spi_wr		: std_logic;
signal spi_busy		: std_logic;
signal spi_sclk		: std_logic;
signal spi_mosi		: std_logic;


begin

-- PLL
U1: entity work.altpll0
port map (
	areset		=> '0',
	locked		=> locked0,
	inclk0		=> CLK_50MHZ,	--  50.00 MHz
	c0		=> clk_vga,	--  25.20 MHz
	c1		=> clk_tmds,	-- 126.00 MHz
	c2		=> clk_bus,	--  28.00 MHz
	c3		=> clk_sdr,	--  84.00 MHz
	c4		=> c8);

-- HDMI
U2: entity work.hdmi
generic map (
	FREQ		=> 25200000,	-- pixel clock frequency = 25.2MHz
	FS		=> 48000,	-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
	CTS		=> 25200,	-- CTS = Freq(pixclk) * N / (128 * Fs)
	N		=> 6144)	-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
port map (
--	I_CLK_PIXEL	=> clk_vga,
--	I_CLK_TMDS	=> clk_tmds,
--	I_HSYNC		=> sync_hsync,
--	I_VSYNC		=> sync_vsync,
--	I_BLANK		=> sync_blank,
--	I_RED		=> vga_r & vga_r & vga_r & vga_r,
--	I_GREEN		=> vga_g & vga_g & vga_g & vga_g,
--	I_BLUE		=> vga_b & vga_b & vga_b & vga_b,
--	O_TMDS		=> TMDS);

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
	O_H		=> sync_h,
	O_HCNT		=> sync_hcnt,
	O_VCNT		=> sync_vcnt,
	O_INT		=> sync_int,
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
	
-- Video RAM 8K
U5: entity work.vram
port map (
	address_a	=> cpu_a(12 downto 0),
	address_b	=> vga_addr,
	clock_a		=> clk_bus,
	clock_b		=> clk_vga,
	data_a	 	=> cpu_do,
	data_b	 	=> (others => '0'),
	wren_a	 	=> vram_wr,
	wren_b	 	=> '0',
	q_a	 	=> open,
	q_b	 	=> vga_di);

-- Loader 4KB
U6: entity work.rom
port map (
	address		=> cpu_a(11 downto 0),
	clock		=> clk_bus,
	q		=> rom_do);

-- SDRAM Controller
U7: entity work.sdram
port map (
	I_CLK		=> clk_sdr,
	-- Memory port
	I_ADDR		=> ram_a & cpu_a(13 downto 0),
	I_DATA		=> cpu_do,
	O_DATA		=> sdr_do,
	I_WR		=> sdr_wr,
	I_RD		=> sdr_rd,
	I_RFSH		=> sdr_rfsh,
	O_IDLE		=> open,
	-- SDRAM Pin
	O_CLK		=> DRAM_CLK,
	O_RAS		=> DRAM_NRAS,
	O_CAS		=> DRAM_NCAS,
	O_WE		=> DRAM_NWE,
	O_DQM		=> DRAM_DQM,
	O_BA		=> DRAM_BA,
	O_MA		=> DRAM_A,
	IO_DQ		=> DRAM_DQ);

-- Delta-Sigma
U12: entity work.dac
generic map (
	msbi_g		=> 15)
port map (
	I_CLK		=> clk_sdr,
	I_RESET		=> reset,
	I_DATA		=> audio_l,
	O_DAC		=> OUT_L);

U13: entity work.dac
generic map (
	msbi_g		=> 15)
port map (
	I_CLK		=> clk_sdr,
	I_RESET		=> reset,
	I_DATA		=> audio_r,
	O_DAC		=> OUT_R);	

-- USB HID
U14: entity work.deserializer
generic map (
	divisor		=> 434)		-- divisor = 50MHz / 115200 Baud = 434
port map(
	I_CLK		=> CLK_50MHZ,
	I_RESET		=> areset,
	I_RX		=> USB_TXD,
	I_NEWFRAME	=> USB_IO3,
	O_FKEYS		=> kb_fkeys,
	O_JOY1		=> kb_joy1,
	O_JOY2		=> kb_joy2,
	O_GAMEPAD1	=> gamepad1,
	O_GAMEPAD2	=> gamepad2,
	O_CTLKEYS	=> kb_soft);

U17: entity work.spi
port map(
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_SCK		=> c8,
	I_DI		=> cpu_do,
	O_DO		=> spi_do,
	I_WR		=> spi_wr,
	O_BUSY		=> spi_busy,
	O_SCLK		=> spi_sclk,
	O_MOSI		=> spi_mosi,
	I_MISO		=> DATA0);
	
-- CPU
U18: entity work.t80se
generic map (
	Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	T2Write		=> 1,	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
	IOWait		=> 1 )	-- 0 => Single cycle I/O, 1 => Std I/O cycle
port map (
	RESET_n		=> not reset,
	CLK_n		=> clk_bus,
	ENA		=> cpu_ena,
	WAIT_n		=> '1',
	INT_n		=> cpu_int_n,
	NMI_n		=> nmi_n_i and not kb_fkeys(5),
	BUSRQ_n		=> '1',
	M1_n		=> cpu_m1_n,
	MREQ_n		=> cpu_mreq_n,
	IORQ_n		=> cpu_iorq_n,
	RD_n		=> cpu_rd_n,
	WR_n		=> cpu_wr_n,
	RFSH_n		=> cpu_rfsh_n,
	HALT_n		=> open,
	BUSAK_n		=> open,
	A		=> cpu_a,
	DI		=> cpu_di,
	DO		=> cpu_do);

	
-------------------------------------------------------------------------------
-- Формирование глобальных сигналов
areset	<= not locked0;			-- сброс
reset	<= kb_soft(0) or areset or gamepad1(12);	-- горячий сброс
inta_n	<= cpu_iorq_n or cpu_m1_n;	-- inta

process (clk_bus, inta_n)
begin
	if (inta_n = '0') then
		cpu_int_n <= '1';
	elsif (clk_bus'event and clk_bus = '1') then
		if (sync_int = '1') then cpu_int_n <= '0'; end if;
	end if;
end process;

process (turbo, ena_3m5hz, ena_7m0hz, ena_14m0hz)
begin
	case turbo is
		when "00" => cpu_ena <= ena_3m5hz;
		when "01" => cpu_ena <= ena_7m0hz;
		when "10" => cpu_ena <= ena_14m0hz;
		when others => null;
	end case;
end process;

-------------------------------------------------------------------------------	
-- FF FKeys
process (clk_bus, key, kb_fkeys, kb_fn, turbo)
begin
	if (clk_bus'event and clk_bus = '1') then
		key <= kb_fkeys;
		if (kb_fkeys /= key) then kb_fn <= kb_fn xor key; end if;
		if kb_fkeys(1) = '1' then turbo <= "00"; end if;
		if kb_fkeys(2) = '1' then turbo <= "01"; end if;
		if kb_fkeys(3) = '1' then turbo <= "10"; end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- SDRAM
sdr_wr <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and mux /= "00" else '0';
sdr_rd <= not (cpu_mreq_n or cpu_rd_n);
sdr_rfsh <= not cpu_rfsh_n;

-------------------------------------------------------------------------------
-- Clock
process (clk_bus)
begin
	if clk_bus' event and clk_bus = '0' then
		ena_cnt <= ena_cnt + 1;
	end if;
end process;

ena_14m0hz	<= ena_cnt(0);
ena_7m0hz	<= ena_cnt(1) and ena_cnt(0);
ena_3m5hz	<= ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_1m75hz	<= ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_0_4375mhz	<= ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);

-------------------------------------------------------------------------------
-- Video
vram_wr  <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_a(15 downto 13) = "010" else '0'; 

-------------------------------------------------------------------------------
-- SD DIVMMC/Z-Controller/SPIFLASH
process (port_0001_reg, kb_fn, spi_sclk, spi_mosi) 
begin
	if port_0001_reg(6) = '0' then	-- bit7=LOADER; bit6=0:SD,1:W25Q64; bit0=SPICS
		NCSO	<= '1';
		SD_NCS	<= '1';
		DCLK	<= '1';
		ASDO	<= '1';
	else
		NCSO	<= port_0001_reg(0);	-- bit0=SPICS
		SD_NCS	<= '1';
		DCLK	<= spi_sclk;
		ASDO	<= spi_mosi;
	end if;
end process;
	
spi_wr <= '1' when cpu_iorq_n & cpu_wr_n & cpu_a(7 downto 0) = "0000000010" else '0';	-- Port #xx02 SPI Data W/R

-------------------------------------------------------------------------------
-- Регистры
process (areset, clk_bus, cpu_a, port_0000_reg, cpu_mreq_n, cpu_wr_n, cpu_do, port_0001_reg, loader)
begin
	if areset = '1' then
		port_0000_reg <= (others => '0');	-- маска по AND порта #DFFD
		port_0001_reg <= (others => '0');	-- bit7=LOADER; bit6=0:SD,1:W25Q64; bit0=SPICS
		loader <= '1';
	elsif clk_bus'event and clk_bus = '1' then
		if cpu_iorq_n & cpu_wr_n & cpu_a = "000000000000000000" then port_0000_reg <= cpu_do; end if;
		if cpu_iorq_n & cpu_wr_n & cpu_a = "000000000000000001" then port_0001_reg <= cpu_do; end if;
		if cpu_m1_n & cpu_mreq_n & cpu_a & port_0001_reg(7) = "0000000000000000001" then loader <= '0'; end if;
	end if;
end process;

process (reset, clk_bus, cpu_a, port_xx5f_reg, port_xx7f_reg, cpu_wr_n, cpu_do, cpu_iorq_n)
begin
	if reset = '1' then
		port_xx5f_reg <= (others => '0');	-- W:Порт управления банками ПЗУ #0000-#3FFF
		port_xx7f_reg <= "00100000010";		-- W:Порт управления банками ОЗУ #C000-#FFFF
		
	elsif clk_bus'event and clk_bus = '1' then
		if cpu_iorq_n & cpu_wr_n & cpu_a(7 downto 0) = "0011111110" then port_xxfe_reg <= cpu_do; end if;			-- D7-D5=не используются; D4=бипер; D3=не используется; D2-D0=цвет бордюра
		if cpu_iorq_n & cpu_wr_n & cpu_a(7 downto 0) = "0001011111" then port_xx5f_reg <= cpu_do; end if;			-- D7=0:ПЗУ приставки, 1:ПЗУ картриджа; D6-D0=выбирают номер банка ПЗУ
		if cpu_iorq_n & cpu_wr_n & cpu_a(7 downto 0) = "0001111111" then port_xx7f_reg <= cpu_a(10 downto 8) & cpu_do; end if;	-- номер банка ОЗУ
	end if;
end process;

------------------------------------------------------------------------------
-- Селектор
selector <=	-- Memory
		X"0" when cpu_mreq_n & cpu_rd_n & cpu_a(15 downto 14) & loader = "00001" else				-- Read Data ROM Loader
		X"1" when cpu_mreq_n = '0' and cpu_rd_n = '0' else							-- Read Data SDRAM
		-- Ports
		X"2" when cpu_iorq_n & cpu_rd_n & cpu_a(7 downto 0) = "0000000010" else					-- Port SPI Data
		X"3" when cpu_iorq_n & cpu_rd_n & cpu_a(7 downto 0) = "0000000011" else					-- Port SPI Control
		X"5" when cpu_iorq_n & cpu_rd_n & cpu_a(7 downto 0) = "0011111110" else					-- Read port #xxFE
		X"6" when cpu_iorq_n & cpu_rd_n & cpu_a(7 downto 0) = "0000011111" else					-- Read port #xx1F
		(others => '1');

process (selector, rom_do, sdr_do, spi_do, spi_busy, kb_joy1, kb_joy2, gamepad1)
begin
	case selector is
		-- Memory
		when X"0" => cpu_di <= rom_do;			-- ROM Loader
		when X"1" => cpu_di <= sdr_do;			-- SDRAM
		-- Ports
		when X"2" => cpu_di <= spi_do;			-- SPI Data
		when X"3" => cpu_di <= spi_busy & "1111111";	-- SPI Control
		when X"5" => cpu_di <= "000" & kb_joy2;		-- Read port #xxFE Джойстик 2
		when X"6" => cpu_di <= "101" & kb_joy1 or (gamepad1(9) & gamepad1(3) & gamepad1(2) & gamepad1(1) & gamepad1(0));		-- Read port #xx1F Джойстик 1
		when others => cpu_di <= (others => '1');
	end case;
end process;

-- SDRAM 32MB:
-- 0000000-1FFFFFF

-- 4 3210 9876 5432 1098 7654 3210
-- 0 0000_0000 00xx_xxxx xxxx_xxxx	0000000-03FFFFF		MENU       16K
-- 0 0000_0000 01xx_xxxx xxxx_xxxx	0000000-03FFFFF		ROM'82     16K
-- 0 000x_xxxx xxxx_xxxx xxxx_xxxx	0000000-03FFFFF		ROM ELF  2016K
-- 0 001x_xxxx xxxx_xxxx xxxx_xxxx	0000000-03FFFFF		ROM ELF1 2048K
-- 0 0100_0000 xxxx_xxxx xxxx_xxxx	0000000-03FFFFF		RAM        48K


-- FLASH 8MB:
-- 000000-05FFFF	Конфигурация Cyclone EP3C10/EP4CE10
-- 060000-07FFFF	MENU   128K
-- 080000-0BFFFF	ELF1   256K


mux <= cpu_a(15 downto 14);

process (mux, ram_a, port_xx5f_reg, port_xx7f_reg)
begin
	case mux is
		when "00" => ram_a <= "000" & port_xx5f_reg;	-- ROM 0000-1FFF
		when "01" => ram_a <= "00100000000";		-- RAM 4000-7FFF
		when "10" => ram_a <= "00100000001";		-- RAM 8000-BFFF
		when "11" => ram_a <= port_xx7f_reg;		-- RAM C000-FFFF
		when others => null;
	end case;
end process;


-------------------------------------------------------------------------------
-- Audio
beeper	<= (others => port_xxfe_reg(4));
audio_l	<= ("000" & beeper & "00000");
audio_r	<= ("000" & beeper & "00000");

-------------------------------------------------------------------------------
-- ZX-BUS
BUS_NINT	<= '1';
BUS_NWAIT	<= '1';
BUS_NBUSRQ	<= '1';
BUS_CLK		<= 'Z';
BUS_A		<= (others => 'Z');
BUS_D		<= (others => 'Z');
BUS_NMREQ	<= 'Z';
BUS_NIORQ	<= 'Z';
BUS_NBUSACK	<= 'Z';
BUS_NRD		<= 'Z';
BUS_NWR		<= 'Z';
BUS_NM1		<= 'Z';
BUS_NRFSH	<= 'Z';

BUS_NIORQGE	<= '0';		-- 1=блокируем порта в/в на шине Спектрума
BUS_NROMOE	<= '0';		-- 1=блокируем ПЗУ Спектрума
BUF_DIR		<= "01";	-- 1=данные от FPGA, 0=данные к FPGA

process (clk_bus)
begin
	if clk_bus'event and clk_bus = '1' then
		reg_nmi_n_i	<= BUF_NNMI;
		reg_int_n_i	<= BUF_NINT;
		nmi_n_i		<= reg_nmi_n_i;
		int_n_i		<= reg_int_n_i;
	end if;
end process;
		

end rtl;
