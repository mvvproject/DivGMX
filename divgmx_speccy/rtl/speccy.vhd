-------------------------------------------------------------------[15.01.2017]
-- FPGA SoftCore - Speccy build 20170115
-- DEVBOARD DivGMX Rev.A
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

--build 20170115	Первая сборка


library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity speccy is
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
--	BUF_NINT	: in std_logic;
	BUF_NNMI	: in std_logic;
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
	BUS_NM1		: inout std_logic;
	BUS_NRFSH	: inout std_logic;
	BUS_NINT	: out std_logic;
	BUS_NWAIT	: out std_logic;
	BUS_NBUSRQ	: out std_logic;
	BUS_NROMOE	: out std_logic;
	BUS_NIORQGE	: out std_logic);
end speccy;

architecture rtl of speccy is

signal reset		: std_logic;
signal areset		: std_logic;
signal loader		: std_logic := '1';
signal clk_vga		: std_logic;
signal clk_tmds		: std_logic;
signal clk_bus		: std_logic;
signal clk_sdr		: std_logic;
signal clk_saa		: std_logic;

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

signal selector		: std_logic_vector(7 downto 0);
signal inta_n		: std_logic;
signal mux		: std_logic_vector(3 downto 0);
signal vga_addr		: std_logic_vector(12 downto 0);
signal rom_do		: std_logic_vector(7 downto 0);
signal trdos		: std_logic := '1';
signal vram_wr		: std_logic;
signal vram_scr		: std_logic;
signal ram_a		: std_logic_vector(11 downto 0);
signal turbo		: std_logic_vector(1 downto 0) := "00";
-- Ports registers
signal port_0000_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_0001_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_xxfe_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_1ffd_reg	: std_logic_vector(7 downto 0);
signal port_7ffd_reg	: std_logic_vector(7 downto 0);
signal port_dffd_reg	: std_logic_vector(7 downto 0);
-- DIVMMC
signal divmmc_do	: std_logic_vector(7 downto 0);
signal divmmc_amap	: std_logic;
signal divmmc_e3reg	: std_logic_vector(7 downto 0);	
signal divmmc_ncs	: std_logic;
signal divmmc_sclk	: std_logic;
signal divmmc_mosi	: std_logic;
-- SDRAM
signal sdr_do		: std_logic_vector(7 downto 0);
signal sdr_wr		: std_logic;
signal sdr_rd		: std_logic;
signal sdr_rfsh		: std_logic;
-- Soundrive
signal covox_a		: std_logic_vector(7 downto 0);
signal covox_b		: std_logic_vector(7 downto 0);
signal covox_c		: std_logic_vector(7 downto 0);
signal covox_d		: std_logic_vector(7 downto 0);
-- TurboSound
signal ssg_sel		: std_logic;
signal ssg0_do		: std_logic_vector(7 downto 0);
signal ssg0_a		: std_logic_vector(7 downto 0);
signal ssg0_b		: std_logic_vector(7 downto 0);
signal ssg0_c		: std_logic_vector(7 downto 0);
signal ssg1_do		: std_logic_vector(7 downto 0);
signal ssg1_a		: std_logic_vector(7 downto 0);
signal ssg1_b		: std_logic_vector(7 downto 0);
signal ssg1_c		: std_logic_vector(7 downto 0);
-- Z-Controller
signal zc_do		: std_logic_vector(7 downto 0);
signal zc_ncs		: std_logic;
signal zc_sclk		: std_logic;
signal zc_mosi		: std_logic;
signal zc_rd		: std_logic;
signal zc_wr		: std_logic;
-- Mouse
signal ms0_x		: std_logic_vector(7 downto 0);
signal ms0_y		: std_logic_vector(7 downto 0);
signal ms0_z		: std_logic_vector(7 downto 0);
signal ms0_b		: std_logic_vector(7 downto 0);
signal ms1_x		: std_logic_vector(7 downto 0);
signal ms1_y		: std_logic_vector(7 downto 0);
signal ms1_z		: std_logic_vector(7 downto 0);
signal ms1_b		: std_logic_vector(7 downto 0);
-- Keyboard
signal kb_do		: std_logic_vector(4 downto 0);
signal kb_fkeys		: std_logic_vector(12 downto 1);
signal kb_fn		: std_logic_vector(12 downto 1);
signal key		: std_logic_vector(12 downto 1) := "000000000000";
signal kb_soft		: std_logic_vector(3 downto 0);
signal kb_joy		: std_logic_vector(4 downto 0);

signal ena_14m0hz	: std_logic;
signal ena_7m0hz	: std_logic;
signal ena_3m5hz	: std_logic;
signal ena_1m75hz	: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt		: std_logic_vector(5 downto 0);
-- I2C
signal i2c_do		: std_logic_vector(7 downto 0);
signal i2c_wr		: std_logic;
-- SAA1099
signal saa_wr_n		: std_logic;
signal saa_out_l	: std_logic_vector(7 downto 0);
signal saa_out_r	: std_logic_vector(7 downto 0);
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



component saa1099
port (
	clk_sys		: in std_logic;
	ce		: in std_logic;		--8 MHz
	rst_n		: in std_logic;
	cs_n		: in std_logic;
	a0		: in std_logic;		--0=data, 1=address
	wr_n		: in std_logic;
	din		: in std_logic_vector(7 downto 0);
	out_l		: out std_logic_vector(7 downto 0);
	out_r		: out std_logic_vector(7 downto 0));
end component;


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
	c4		=> clk_saa);	--   8.00 MHz

-- HDMI
U2: entity work.hdmi
generic map (
	FREQ		=> 25200000,	-- pixel clock frequency = 25.2MHz
	FS		=> 48000,	-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
	CTS		=> 25200,	-- CTS = Freq(pixclk) * N / (128 * Fs)
	N		=> 6144)	-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
port map (
	I_CLK_VGA	=> clk_vga,
	I_CLK_TMDS	=> clk_tmds,
	I_HSYNC		=> sync_hsync,
	I_VSYNC		=> sync_vsync,
	I_BLANK		=> sync_blank,
	I_RED		=> vga_r & vga_r & vga_r & vga_r,--osd_red,
	I_GREEN		=> vga_g & vga_g & vga_g & vga_g,--osd_green,
	I_BLUE		=> vga_b & vga_b & vga_b & vga_b,--osd_blue,
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
	
-- Video RAM 16K
U5: entity work.vram
port map (
	address_a	=> vram_scr & cpu_a(12 downto 0),
	address_b	=> port_7ffd_reg(3) & vga_addr,
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
	I_ADDR		=> ram_a & cpu_a(12 downto 0),
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

-- DIVMMC Interface
U8: entity work.divmmc
port map (
	I_CLK		=> clk_bus,
	I_CS		=> kb_fn(6),
	I_RESET		=> reset,
	I_ADDR		=> cpu_a,
	I_DATA		=> cpu_do,
	O_DATA		=> divmmc_do,
	I_WR_N		=> cpu_wr_n,
	I_RD_N		=> cpu_rd_n,
	I_IORQ_N	=> cpu_iorq_n,
	I_MREQ_N	=> cpu_mreq_n,
	I_M1_N		=> cpu_m1_n,
	I_RFSH_N	=> cpu_rfsh_n,
	O_E3REG		=> divmmc_e3reg,
	O_AMAP		=> divmmc_amap,
	O_CS_N		=> divmmc_ncs,
	O_SCLK		=> divmmc_sclk,
	O_MOSI		=> divmmc_mosi,
	I_MISO		=> DATA0);	

-- Soundrive
U9: entity work.soundrive
port map (
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_CS		=> '1',
	I_WR_N		=> cpu_wr_n,
	I_ADDR		=> cpu_a(7 downto 0),
	I_DATA		=> cpu_do,
	I_IORQ_N	=> cpu_iorq_n,
	I_DOS		=> trdos,
	O_COVOX_A	=> covox_a,
	O_COVOX_B	=> covox_b,
	O_COVOX_C	=> covox_c,
	O_COVOX_D	=> covox_d);
	
-- TurboSound
U10: entity work.turbosound
port map (
	I_CLK		=> clk_bus,
	I_ENA		=> ena_1m75hz,
	I_ADDR		=> cpu_a,
	I_DATA		=> cpu_do,
	I_WR_N		=> cpu_wr_n,
	I_IORQ_N	=> cpu_iorq_n,
	I_M1_N		=> cpu_m1_n,
	I_RESET_N	=> not reset,
	O_SEL		=> ssg_sel,
	-- ssg0
	O_SSG0_DA	=> ssg0_do,
	O_SSG0_AUDIO_A	=> ssg0_a,
	O_SSG0_AUDIO_B	=> ssg0_b,
	O_SSG0_AUDIO_C	=> ssg0_c,
	-- ssg1
	O_SSG1_DA	=> ssg1_do,
	O_SSG1_AUDIO_A	=> ssg1_a,
	O_SSG1_AUDIO_B	=> ssg1_b,
	O_SSG1_AUDIO_C	=> ssg1_c);
	
-- Z-Controller
U11: entity work.zcontroller
port map (
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_ADDR		=> cpu_a(5),
	I_DATA		=> cpu_do,
	O_DATA		=> zc_do,
	I_RD		=> zc_rd,
	I_WR		=> zc_wr,
	I_SDDET		=> SD_NDET,
	I_SDPROT	=> '0',
	O_CS_N		=> zc_ncs,
	O_SCLK		=> zc_sclk,
	O_MOSI		=> zc_mosi,
	I_MISO		=> DATA0);

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
	divisor			=> 434)		-- divisor = 50MHz / 115200 Baud = 434
port map(
	I_CLK			=> CLK_50MHZ,
	I_RESET			=> areset,
	I_RX			=> USB_TXD,
	I_NEWFRAME		=> USB_IO3,
	I_ADDR			=> cpu_a(15 downto 8),
	O_MOUSE0_X		=> ms0_x,
	O_MOUSE0_Y		=> ms0_y,
	O_MOUSE0_Z		=> ms0_z,
	O_MOUSE0_BUTTONS	=> ms0_b,
	O_MOUSE1_X		=> ms1_x,
	O_MOUSE1_Y		=> ms1_y,
	O_MOUSE1_Z		=> ms1_z,
	O_MOUSE1_BUTTONS	=> ms1_b,
	O_KEY0			=> open,--kb_key0,
	O_KEY1			=> open,--kb_key1,
	O_KEY2			=> open,--kb_key2,
	O_KEY3			=> open,--kb_key3,
	O_KEY4			=> open,--kb_key4,
	O_KEY5			=> open,--kb_key5,
	O_KEY6			=> open,--kb_key6,
	O_KEYBOARD_SCAN		=> kb_do,
	O_KEYBOARD_FKEYS	=> kb_fkeys,
	O_KEYBOARD_JOYKEYS	=> kb_joy,
	O_KEYBOARD_CTLKEYS	=> kb_soft);

-- I2C Controller
U15: entity work.i2c
port map (
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_ENA		=> ena_0_4375mhz,
	I_ADDR		=> cpu_a(4),
	I_DATA		=> cpu_do,
	O_DATA		=> i2c_do,
	I_WR		=> i2c_wr,
	IO_I2C_SCL	=> I2C_SCL,
	IO_I2C_SDA	=> I2C_SDA);

U16: saa1099
port map(
	clk_sys		=> clk_saa,
	ce		=> '1',			-- 8 MHz
	rst_n		=> not reset,
	cs_n		=> '0',
	a0		=> cpu_a(8),		-- 0=data, 1=address
	wr_n		=> saa_wr_n,
	din		=> cpu_do,
	out_l		=> saa_out_l,
	out_r		=> saa_out_r);

U17: entity work.spi
port map(
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_SCK		=> clk_saa,
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
	WAIT_n		=> '1',--cpu_wait_n,
	INT_n		=> cpu_int_n,
	NMI_n		=> nmi_n_i and not kb_fkeys(5),
	BUSRQ_n		=> '1',
	M1_n		=> cpu_m1_n,
	MREQ_n		=> cpu_mreq_n,
	IORQ_n		=> cpu_iorq_n,
	RD_n		=> cpu_rd_n,
	WR_n		=> cpu_wr_n,
	RFSH_n		=> cpu_rfsh_n,
	HALT_n		=> open,--cpu_halt_n,
	BUSAK_n		=> open,--cpu_basak_n,
	A		=> cpu_a,
	DI		=> cpu_di,
	DO		=> cpu_do);
	
-------------------------------------------------------------------------------
-- Формирование глобальных сигналов
areset	<= not locked0;	-- сброс
reset	<= kb_soft(2) or areset;	-- горячий сброс
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
-- I2C
i2c_wr <= '1' when (cpu_a(7 downto 5) = "100" and cpu_a(3 downto 0) = "1100" and cpu_wr_n = '0' and cpu_iorq_n = '0') else '0';		-- I2C Port xx8C/xx9C[xxxxxxxx_100n1100]

-------------------------------------------------------------------------------	
-- Z-Controller	
zc_wr 	<= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(7 downto 6) = "01" and cpu_a(4 downto 0) = "10111") else '0';
zc_rd 	<= '1' when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 6) = "01" and cpu_a(4 downto 0) = "10111") else '0';
	
-------------------------------------------------------------------------------
-- SDRAM
sdr_wr <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (mux = "1001" or mux(3 downto 2) = "11" or mux(3 downto 2) = "01" or mux(3 downto 1) = "101" or mux(3 downto 1) = "001") else '0';
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
vram_scr <= '1' when ram_a = "000000001110" else '0';
vram_wr  <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and ((ram_a = "000000001010") or (ram_a = "000000001110")) else '0'; 

-------------------------------------------------------------------------------
-- SD DIVMMC/Z-Controller/SPIFLASH
process (port_0001_reg, kb_fn, divmmc_ncs, divmmc_sclk, divmmc_mosi, zc_ncs, zc_sclk, zc_mosi, spi_sclk, spi_mosi) 
begin
	if port_0001_reg(6) = '0' then	-- bit7=LOADER; bit6=0:SD,1:W25Q64; bit0=SPICS
		NCSO	<= '1';
		case kb_fn(6) is
			when '1' =>
				SD_NCS	<= divmmc_ncs;
				DCLK	<= divmmc_sclk;
				ASDO	<= divmmc_mosi;
			when '0' =>
				SD_NCS	<= zc_ncs;
				DCLK	<= zc_sclk;
				ASDO	<= zc_mosi;
			when others => null;
		end case;
	else
		NCSO	<= port_0001_reg(0);	-- bit0=SPICS
		SD_NCS	<= '1';
		DCLK	<= spi_sclk;
		ASDO	<= spi_mosi;
	end if;
end process;
	
spi_wr <= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(7 downto 0) = X"02") else '0';	-- Port #xx02 SPI Data W/R

-------------------------------------------------------------------------------
-- SAA1099
saa_wr_n <= '0' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(7 downto 0) = "11111111" and trdos = '0') else '1';

-------------------------------------------------------------------------------
-- Регистры
process (areset, clk_bus, cpu_a, port_0000_reg, cpu_mreq_n, cpu_wr_n, cpu_do, port_0001_reg, loader)
begin
	if areset = '1' then
		port_0000_reg <= (others => '0');	-- маска по AND порта #DFFD
		port_0001_reg <= (others => '0');	-- bit7=LOADER; bit6=0:SD,1:W25Q64; bit0=SPICS
		loader <= '1';
	elsif clk_bus'event and clk_bus = '1' then
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(15 downto 0) = X"0000" then port_0000_reg <= cpu_do; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(15 downto 0) = X"0001" then port_0001_reg <= cpu_do; end if;
		if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a = X"0000" and port_0001_reg(7) = '1' then loader <= '0'; end if;
	end if;
end process;

process (reset, clk_bus, cpu_a, port_7ffd_reg, cpu_wr_n, cpu_do, cpu_iorq_n, trdos)
begin
	if reset = '1' then
--		port_eff7_reg <= (others => '0');
		port_1ffd_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_dffd_reg <= (others => '0');
		trdos <= '1';
	elsif clk_bus'event and clk_bus = '1' then
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a(7 downto 0) = X"FE" then port_xxfe_reg <= cpu_do; end if;			-- D7-D5=не используются; D4=бипер; D3=MIC; D2-D0=цвет бордюра
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"7FFD" and port_7ffd_reg(5) = '0' then port_7ffd_reg <= cpu_do; end if;	-- D7-D6:не используются; D5:1=запрещение расширенной памяти (48K защёлка); D4=номер страницы ПЗУ(0-BASIC128, 1-BASIC48); D3=выбор отображаемой видеостраницы(0-страница в банке 5, 1 - в банке 7); D2-D0=номер страницы ОЗУ подключенной в верхние 16 КБ памяти (с адреса #C000)
--		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"EFF7" then port_eff7_reg <= cpu_do; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"1FFD" then port_1ffd_reg <= cpu_do; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"7FFD" and port_7ffd_reg(5) = '0' then port_7ffd_reg <= cpu_do; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"DFFD" and port_7ffd_reg(5) = '0' then port_dffd_reg <= cpu_do; end if;
--		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a = X"DFF7" and port_eff7_reg(7) = '1' then mc146818_a <= cpu_do(5 downto 0); end if;
		if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a(15 downto 8) = X"3D" and port_7ffd_reg(4) = '1' then trdos <= '1';
		elsif cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a(15 downto 14) /= "00" then trdos <= '0'; end if;
	end if;
end process;

------------------------------------------------------------------------------
-- Селектор
selector <=	-- Memory
		X"00" when (cpu_mreq_n = '0' and cpu_rd_n = '0' and cpu_a(15 downto 14) = "00" and loader = '1') else							-- Read Data ROM Loader
		X"01" when (cpu_mreq_n = '0' and cpu_rd_n = '0') else													-- Read Data SDRAM
		-- Ports
		X"02" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 0) = X"02") else									-- Port SPI Data
		X"03" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 0) = X"03") else									-- Port SPI Control
		X"04" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 5) = "100" and cpu_a(3 downto 0) = "1100") else 					-- Port I2C
		X"05" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 0) = X"FE") else									-- Read port #xxFE Keyboard
		X"06" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 0) = X"EB" and kb_fn(6) = '1') else							-- DivMMC ESXDOS port
		X"07" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and trdos = '0' and cpu_a(7 downto 0) = X"1F") else							-- Joystick port xx1F
		X"08" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"FFFD" and ssg_sel = '0') else								-- TurboSound SSG0
		X"09" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"FFFD" and ssg_sel = '1') else								-- TurboSound SSG1
		X"0A" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(7 downto 6) = "01" and cpu_a(4 downto 0) = "10111" and kb_fn(6) = '0') else 			-- Z-Controller
		X"0B" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"FADF") else										-- Mouse0 port key, z
		X"0C" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"FBDF") else										-- Mouse0 port x
		X"0D" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"FFDF") else										-- Mouse0 port y
		X"0E" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(15) = '0' and cpu_a(10) = '0' and cpu_a(8) = '0' and cpu_a(7 downto 0) = x"DF") else		-- Mouse1 port key, z
		X"0F" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(15) = '0' and cpu_a(10) = '0' and cpu_a(8) = '1' and cpu_a(7 downto 0) = x"DF") else		-- Mouse1 port x
		X"10" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a(15) = '0' and cpu_a(10) = '1' and cpu_a(8) = '1' and cpu_a(7 downto 0) = x"DF") else		-- Mouse1 port y
		X"11" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"7FFD") else										-- Read port #7FFD
		X"12" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a = X"DFFD") else										-- Read port #DFFD
		(others => '1');

process (selector, rom_do, divmmc_do, sdr_do, ssg0_do, ssg1_do, zc_do, ms0_z, ms0_b, ms0_x, ms0_y, ms1_z, ms1_b, ms1_x, ms1_y, port_7ffd_reg, port_dffd_reg, kb_do, spi_do, spi_busy, i2c_do, kb_joy)
begin
	case selector is
		-- Memory
		when X"00" => cpu_di <= rom_do;			-- ROM Loader
		when X"01" => cpu_di <= sdr_do;			-- SDRAM
		-- Ports
		when X"02" => cpu_di <= spi_do;			-- SPI Data
		when X"03" => cpu_di <= spi_busy & "1111111";	-- SPI Control
		when X"04" => cpu_di <= i2c_do;			-- I2C
		when X"05" => cpu_di <= "111" & kb_do;		-- Read port #xxFE Keyboard
		when X"06" => cpu_di <= divmmc_do;		-- DivMMC ESXDOS port
		when X"07" => cpu_di <= "000" & kb_joy;		-- D7-D5=0; D4=огонь;  D3=вниз; D2=вверх; D1=вправо; D0=влево
		when X"08" => cpu_di <= ssg0_do;		-- TurboSound SSG0
		when X"09" => cpu_di <= ssg1_do;		-- TurboSound SSG1
		when X"0A" => cpu_di <= zc_do;			-- Z-Controller
		when X"0B" => cpu_di <= ms0_z(3 downto 0) & '1' & not ms0_b(2) & not ms0_b(0) & not ms0_b(1);		-- Mouse0 port key, z
		when X"0C" => cpu_di <= ms0_x;			-- Mouse0 port x
		when X"0D" => cpu_di <= not ms0_y;		-- Mouse0 port y
		when X"0E" => cpu_di <= ms1_z(3 downto 0) & '1' & not ms1_b(2) & not ms1_b(0) & not ms1_b(1);		-- Mouse1 port key, z
		when X"0F" => cpu_di <= ms1_x;			-- Mouse1 port x
		when X"10" => cpu_di <= not ms1_y;		-- Mouse1 port y
		when X"11" => cpu_di <= port_7ffd_reg;		-- Read port #7FFD
		when X"12" => cpu_di <= port_dffd_reg;		-- Read port #DFFD
		
		when others => cpu_di <= (others => '1');
	end case;
end process;

-- M9K 46KB:
-- 0000-B7FF

-- SDRAM 32MB:
-- 0000000-1FFFFFF

-- 4 3210 9876 5432 1098 7654 3210
-- 0 00xx_xxxx xxxx_xxxx xxxx_xxxx	0000000-03FFFFF		RAM 	4MB
-- 0 xxxx_xxxx xxxx_xxxx xxxx_xxxx	0400000-0FFFFFF		-----------
-- 1 0000_0xxx xxxx_xxxx xxxx_xxxx	1000000-107FFFF		divMMC 512K
-- 1 0000_1000 00xx_xxxx xxxx_xxxx	1080000-1003FFF		GLUK	16K
-- 1 0000_1000 01xx_xxxx xxxx_xxxx	1084000-1007FFF		TR-DOS	16K
-- 1 0000_1000 10xx_xxxx xxxx_xxxx	1088000-100BFFF		ROM'86	16K
-- 1 0000_1000 11xx_xxxx xxxx_xxxx	108C000-100FFFF		ROM'82	16K
-- 1 0000_1001 000x_xxxx xxxx_xxxx	1090000-1091FFF		divMMC	 8K


-- FLASH 8MB:
-- 000000-05FFFF	Конфигурация Cyclone EP3C10/EP4CE10
-- 060000-063FFF	General Sound ROM	16K  ОТКЛЮЧЕНО
-- 064000-067FFF	General Sound ROM	16K  ОТКЛЮЧЕНО
-- 068000-06BFFF	GLUK 			16K
-- 06C000-06FFFF	TR-DOS 			16K
-- 070000-073FFF	OS'86 			16K
-- 074000-077FFF	OS'82 			16K
-- 078000-07AFFF	DivMMC			 8K

------------------------------------------------------------------------------
-- Селектор
mux <= ((divmmc_amap or divmmc_e3reg(7)) and kb_fn(6)) & cpu_a(15 downto 13);

process (mux, port_7ffd_reg, port_dffd_reg, port_0000_reg, ram_a, cpu_a, trdos, port_1ffd_reg, divmmc_e3reg, kb_fn)
begin
	case mux is
--		when "1000" => ram_a <= "10000" & not(divmmc_e3reg(6)) & "00" & not(divmmc_e3reg(6)) & '0' & divmmc_e3reg(6) & divmmc_e3reg(6);	-- ESXDOS ROM 0000-1FFF
		when "0000" => ram_a <= "100001000" & ((not(trdos) and not(port_1ffd_reg(1))) or kb_fn(6)) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '0';	-- Seg0 ROM 0000-1FFF
		when "0001" => ram_a <= "100001000" & ((not(trdos) and not(port_1ffd_reg(1))) or kb_fn(6)) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '1';	-- Seg0 ROM 2000-3FFF
		when "1000" => ram_a <= "100001001000";	-- ESXDOS ROM 0000-1FFF
		when "1001" => ram_a <= "100000" & divmmc_e3reg(5 downto 0);	-- ESXDOS RAM 2000-3FFF
		when "0010"|"1010" => ram_a <= "000000001010";	-- Seg1 RAM 4000-5FFF
		when "0011"|"1011" => ram_a <= "000000001011";	-- Seg1 RAM 6000-7FFF
		when "0100"|"1100" => ram_a <= "000000000100";	-- Seg2 RAM 8000-9FFF
		when "0101"|"1101" => ram_a <= "000000000101";	-- Seg2 RAM A000-BFFF
		when "0110"|"1110" => ram_a <= (port_dffd_reg and port_0000_reg) & port_7ffd_reg(2 downto 0) & '0';	-- Seg3 RAM C000-DFFF
		when "0111"|"1111" => ram_a <= (port_dffd_reg and port_0000_reg) & port_7ffd_reg(2 downto 0) & '1';	-- Seg3 RAM E000-FFFF
		when others => null;
	end case;
end process;

-------------------------------------------------------------------------------
-- Audio
beeper	<= (others => port_xxfe_reg(4));
audio_l	<= ("000" & beeper & "00000") + ("000" & ssg0_a & "00000") + ("000" & ssg0_b & "00000") + ("000" & ssg1_a & "00000") + ("000" & ssg1_b & "00000") + ("000" & covox_a & "00000") + ("000" & covox_b & "00000") + ("000" & saa_out_l & "00000");
audio_r	<= ("000" & beeper & "00000") + ("000" & ssg0_c & "00000") + ("000" & ssg0_b & "00000") + ("000" & ssg1_c & "00000") + ("000" & ssg1_b & "00000") + ("000" & covox_c & "00000") + ("000" & covox_d & "00000") + ("000" & saa_out_r & "00000");

-------------------------------------------------------------------------------
-- ZX-BUS
BUS_NINT	<= '1';
BUS_NWAIT	<= '1';
BUS_NBUSRQ	<= '1';
BUF_DIR(0)	<= '1';
BUS_A		<= (others => 'Z');
BUS_NMREQ	<= 'Z';
BUS_NIORQ	<= 'Z';
BUS_NRD		<= 'Z';
BUS_NWR		<= 'Z';
BUS_NM1		<= 'Z';
BUS_NRFSH	<= 'Z';

BUS_NIORQGE	<= '0';	-- 1=блокируем порта в/в на шине Спектрума
BUS_NROMOE	<= '0';	-- 1=блокируем ПЗУ Спектрума
BUF_DIR(1)	<= '0';	-- 1=данные от FPGA, 0=данные к FPGA

process (clk_bus)
begin
	if clk_bus'event and clk_bus = '1' then
		reg_mreq_n_i	<= BUS_NMREQ;
		reg_iorq_n_i	<= BUS_NIORQ;
		reg_rd_n_i	<= BUS_NRD;
		reg_wr_n_i	<= BUS_NWR;
		reg_a_i		<= BUS_A;
		reg_d_i		<= BUS_D;
		reg_reset_n_i	<= BUF_NRESET;
		reg_m1_n_i	<= BUS_NM1;
		reg_rfsh_n_i	<= BUS_NRFSH;
		reg_nmi_n_i	<= BUF_NNMI;
		
		mreq_n_i	<= reg_mreq_n_i;
		iorq_n_i	<= reg_iorq_n_i;
		rd_n_i		<= reg_rd_n_i;
		wr_n_i		<= reg_wr_n_i;
		a_i		<= reg_a_i;
		d_i		<= reg_d_i;
		reset_n_i	<= reg_reset_n_i;
		m1_n_i		<= reg_m1_n_i;
		rfsh_n_i	<= reg_rfsh_n_i;
		nmi_n_i		<= reg_nmi_n_i;
	end if;
end process;
		

end rtl;
