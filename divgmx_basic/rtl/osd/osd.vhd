-------------------------------------------------------------------[11.01.2017]
-- OSD
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity osd is
port (
	I_RESET		: in std_logic;
	I_CLK_VGA	: in std_logic;
	I_CLK_CPU	: in std_logic;
	
	I_P0		: in std_logic_vector(7 downto 0);
	I_P1		: in std_logic_vector(7 downto 0);
	I_P2		: in std_logic_vector(7 downto 0);
	I_P3		: in std_logic_vector(7 downto 0);
	I_P4		: in std_logic_vector(7 downto 0);
	I_P5		: in std_logic_vector(7 downto 0);
	I_P6		: in std_logic_vector(7 downto 0);
	I_P7		: in std_logic_vector(7 downto 0);
	I_P8		: in std_logic_vector(7 downto 0);
	I_P9		: in std_logic_vector(7 downto 0);
	I_P10		: in std_logic_vector(7 downto 0);
	I_P11		: in std_logic_vector(7 downto 0);
	I_P12		: in std_logic_vector(7 downto 0);
	I_P13		: in std_logic_vector(7 downto 0);
	I_P14		: in std_logic_vector(7 downto 0);
	I_P15		: in std_logic_vector(7 downto 0);
	
	I_KEY		: in std_logic;
	I_RED		: in std_logic_vector(7 downto 0);
	I_GREEN		: in std_logic_vector(7 downto 0);
	I_BLUE		: in std_logic_vector(7 downto 0);
	I_HCNT		: in std_logic_vector(9 downto 0);
	I_VCNT		: in std_logic_vector(9 downto 0);
	I_H		: in std_logic_vector(9 downto 0);
	O_RED		: out std_logic_vector(7 downto 0);
	O_GREEN		: out std_logic_vector(7 downto 0);
	O_BLUE		: out std_logic_vector(7 downto 0));
end osd;

architecture rtl of osd is

signal cpu_di		: std_logic_vector(7 downto 0);
signal cpu_do		: std_logic_vector(7 downto 0);
signal cpu_addr		: std_logic_vector(15 downto 0);
signal cpu_mreq		: std_logic;
signal cpu_iorq		: std_logic;
signal cpu_wr		: std_logic;
signal cpu_m1		: std_logic;

signal ram_wr		: std_logic;
signal ram_do		: std_logic_vector(7 downto 0);
signal reg_0		: std_logic_vector(7 downto 0) := "11111111";
signal osd_addr		: std_logic_vector(9 downto 0);
signal osd_data		: std_logic_vector(7 downto 0);
signal osd_pixel	: std_logic;
signal osd_de		: std_logic;
signal osd_wr		: std_logic;
signal osd_vcnt		: std_logic_vector(9 downto 0);
signal osd_hcnt		: std_logic_vector(9 downto 0);
signal osd_h_active	: std_logic;
signal osd_v_active	: std_logic;
signal int		: std_logic;

signal font_addr	: std_logic_vector(10 downto 0);
signal font_data	: std_logic_vector(3 downto 0);
signal font_buff	: std_logic_vector(3 downto 0);

constant OSD_INK	: std_logic_vector(2 downto 0) := "001";	-- RGB
constant OSD_H_ON	: std_logic_vector(9 downto 0) := "0000000000";	-- OSD hstart = 0
constant OSD_H_OFF	: std_logic_vector(9 downto 0) := "1000000000";	-- OSD hend   = 512
constant OSD_V_ON	: std_logic_vector(9 downto 0) := "0000000000";	-- OSD vstart = 0
constant OSD_V_OFF	: std_logic_vector(9 downto 0) := "0001000000";	-- OSD vend   = 64

begin

u0: entity work.nz80cpu
port map(
	I_WAIT		=> '0',
	I_RESET		=> I_RESET,
	I_CLK		=> not I_CLK_CPU,
	I_NMI		=> '0',
	I_INT		=> int,
	I_DATA		=> cpu_di,
	O_DATA		=> cpu_do,
	O_ADDR		=> cpu_addr,
	O_M1		=> cpu_m1,
	O_MREQ		=> cpu_mreq,
	O_IORQ		=> cpu_iorq,	
	O_WR		=> cpu_wr,
	O_HALT		=> open);
	
u1: entity work.ram	-- 4K
port map(
	address_a 	=> cpu_addr(11 downto 0),
	address_b	=> "11" & osd_addr,
	clock_a	 	=> I_CLK_CPU,
	clock_b		=> I_CLK_VGA,
	data_a	 	=> cpu_do,
	data_b		=> (others => '0'),
	wren_a	 	=> ram_wr,
	wren_b		=> '0',
	q_a	 	=> ram_do,
	q_b		=> osd_data);
	
u2: entity work.font	-- 1K
port map(
	address 	=> font_addr,
	clock		=> I_CLK_VGA,
	q		=> font_data);

-- Memory MAP:
-- 0000 - 03FF	ROM 1K
-- 0400 - 0BFF	RAM Buffer 2K
-- 0C00 - 0FFF	Test Buffer 1K

-------------------------------------------------------------------------------
-- CPU
process (I_CLK_CPU, I_RESET, cpu_addr, cpu_iorq, cpu_wr)
begin
	if (I_RESET = '1') then
		reg_0 <= (others => '1');
	elsif (I_CLK_CPU'event and I_CLK_CPU = '1') then
		if cpu_addr(7 downto 0) = X"00" and cpu_iorq = '1' and cpu_wr = '1' then reg_0 <= cpu_do; end if;
	end if;
end process;

cpu_di <=	ram_do when cpu_addr(15 downto 12) = "0000" and cpu_mreq = '1' and cpu_wr = '0' else
		reg_0 when cpu_addr = X"0000" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P0 when cpu_addr = X"0001" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P1 when cpu_addr = X"0101" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P2 when cpu_addr = X"0201" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P3 when cpu_addr = X"0301" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P4 when cpu_addr = X"0401" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P5 when cpu_addr = X"0501" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P6 when cpu_addr = X"0601" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P7 when cpu_addr = X"0701" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P8 when cpu_addr = X"0801" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P9 when cpu_addr = X"0901" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P10 when cpu_addr = X"0A01" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P11 when cpu_addr = X"0B01" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P12 when cpu_addr = X"0C01" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P13 when cpu_addr = X"0D01" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P14 when cpu_addr = X"0E01" and cpu_iorq = '1' and cpu_wr = '0' else
		I_P15 when cpu_addr = X"0F01" and cpu_iorq = '1' and cpu_wr = '0' else
		X"FF";

ram_wr <= '1' when cpu_mreq = '1' and cpu_wr = '1' else '0';

-- INT
process (I_CLK_CPU, cpu_iorq, cpu_m1, I_VCNT)
begin
	if (cpu_iorq = '1' and cpu_m1 = '1') then
		int <= '0';
	elsif (I_CLK_CPU'event and I_CLK_CPU = '1') then
		if (I_VCNT = "0000000000") then
			int <= '1';
		end if;
	end if;
end process;



-------------------------------------------------------------------------------
-- OSD
process (I_CLK_VGA, osd_hcnt, font_data, font_buff)
begin
	if (I_CLK_VGA'event and I_CLK_VGA = '1') then
		if osd_hcnt(1 downto 0) = "01" then osd_addr <= osd_vcnt(5 downto 3) & osd_hcnt(8 downto 2); end if;	-- osd 128x8 symbols 1K
		if osd_hcnt(1 downto 0) = "10" then font_addr <= osd_data & osd_vcnt(2 downto 0); end if;
		if osd_hcnt(1 downto 0) = "11" then font_buff <= font_data; end if;		
	end if;
	case osd_hcnt(1 downto 0) is
		when "00" => osd_pixel <= font_buff(3);
		when "01" => osd_pixel <= font_buff(2);
		when "10" => osd_pixel <= font_buff(1);
		when "11" => osd_pixel <= font_buff(0);
		when others => null;
	end case;
end process;

osd_h_active <= '1' when (I_HCNT >= OSD_H_ON) and (I_HCNT < OSD_H_OFF) else '0';
osd_v_active <= '1' when (I_VCNT >= OSD_V_ON) and (I_VCNT < OSD_V_OFF) else '0';
osd_de <= I_KEY and osd_h_active and osd_v_active;
osd_hcnt <= I_H - OSD_H_ON;
osd_vcnt <= I_VCNT - OSD_V_ON;

O_RED <= (others => OSD_INK(2)) when osd_pixel = '1' and osd_de = '1' else I_RED when osd_de = '1' else I_RED;
O_GREEN <= (others => OSD_INK(1)) when osd_pixel = '1' and osd_de = '1' else I_GREEN when osd_de = '1' else I_GREEN;
O_BLUE <= (others => OSD_INK(0)) when osd_pixel = '1' and osd_de = '1' else I_BLUE when osd_de = '1' else I_BLUE;

end rtl;