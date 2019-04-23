-------------------------------------------------------------------[21.11.2016]
-- VGA ZX-Spectum screen
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity vga_zx is port (
	I_CLK		: in std_logic;
	I_CLKEN		: in std_logic;
	I_DATA		: in std_logic_vector(7 downto 0);
	I_BORDER	: in std_logic_vector(2 downto 0);	-- Биты D0..D2 порта xxFE определяют цвет бордюра
	I_HCNT		: in std_logic_vector(9 downto 0);
	I_VCNT		: in std_logic_vector(9 downto 0);
	I_BLANK		: in std_logic;
	I_FLASH		: in std_logic;				-- скорость мерцания курсора 1.875Гц
	O_ADDR		: out std_logic_vector(12 downto 0);
	O_PAPER		: out std_logic;
	O_RED		: out std_logic_vector(1 downto 0);	-- Red
	O_GREEN		: out std_logic_vector(1 downto 0);	-- Green
	O_BLUE		: out std_logic_vector(1 downto 0));	-- Blue
end entity;

architecture rtl of vga_zx is

-- ZX-Spectum screen
	constant spec_border_left	: natural :=  30;
	constant spec_screen_h		: natural := 256;
	constant spec_border_right	: natural :=  32;

	constant spec_border_top	: natural :=  24;
	constant spec_screen_v		: natural := 192;
	constant spec_border_bot	: natural :=  24;
	constant h_sync_on		: integer := 655;	-- h_visible_area + h_front_porch - 1 = 655

---------------------------------------------------------------------------------------	
	signal spec_h_count_reg		: std_logic_vector(9 downto 0);
	signal spec_v_count_reg		: std_logic_vector(9 downto 0);

	signal paper			: std_logic;
	signal pixel			: std_logic;
	signal paper1			: std_logic;
	signal vid_reg			: std_logic_vector(7 downto 0);
	signal pixel_reg		: std_logic_vector(7 downto 0);
	signal attr_reg			: std_logic_vector(7 downto 0);
	signal vga_rgb			: std_logic_vector(5 downto 0);
	signal addr_reg			: std_logic_vector(12 downto 0);
	
begin

process (I_CLK, I_CLKEN, I_HCNT, I_VCNT)
begin
	if (I_CLK'event and I_CLK = '1' and I_CLKEN = '1') then
		if (I_HCNT = spec_border_left * 2) then
			spec_h_count_reg <= (others => '0');
		else
			spec_h_count_reg <= spec_h_count_reg + 1;
		end if;

		if (I_HCNT = h_sync_on) then
			if (I_VCNT = spec_border_top * 2) then
				spec_v_count_reg <= (others => '0');
			else
				spec_v_count_reg <= spec_v_count_reg + 1;
			end if;
			
		end if;

		case spec_h_count_reg(3 downto 1) is
			when "000" =>
				pixel <= pixel_reg(6);
			when "001" =>
				pixel <= pixel_reg(5);
			when "010" =>
				pixel <= pixel_reg(4);
			when "011" =>
				pixel <= pixel_reg(3);
			when "100" => 
				pixel <= pixel_reg(2);
				addr_reg <= spec_v_count_reg(8 downto 7) & spec_v_count_reg(3 downto 1) & spec_v_count_reg(6 downto 4) & spec_h_count_reg(8 downto 4);
			when "101" =>
				pixel <= pixel_reg(1);
				vid_reg <= I_DATA;
			when "110" =>
				pixel <= pixel_reg(0);
				addr_reg <= "110" & spec_v_count_reg(8 downto 4) & spec_h_count_reg(8 downto 4);
			when "111" =>
				pixel <= vid_reg(7);
				pixel_reg <= vid_reg;
				attr_reg <= I_DATA;
				paper1 <= paper;
			when others => null;
		end case;
		
	end if;
end process;

paper <= '1' when (spec_h_count_reg(9 downto 1) < spec_screen_h and spec_v_count_reg(9 downto 1) < spec_screen_v) else '0';

vga_rgb <= 	(others => '0') when (I_BLANK = '1') else
		attr_reg(4) & (attr_reg(4) and attr_reg(6)) & attr_reg(5) & (attr_reg(5) and attr_reg(6)) & attr_reg(3) & (attr_reg(3) and attr_reg(6)) when paper1 = '1' and (pixel xor (I_FLASH and attr_reg(7))) = '0' else
		attr_reg(1) & (attr_reg(1) and attr_reg(6)) & attr_reg(2) & (attr_reg(2) and attr_reg(6)) & attr_reg(0) & (attr_reg(0) and attr_reg(6)) when paper1 = '1' and (pixel xor (I_FLASH and attr_reg(7))) = '1' else
		I_BORDER(1) & '0' & I_BORDER(2) & '0' & I_BORDER(0) & '0';

O_ADDR	<= addr_reg;
O_PAPER	<= paper1;
O_RED	<= vga_rgb(5 downto 4);
O_GREEN	<= vga_rgb(3 downto 2);
O_BLUE	<= vga_rgb(1 downto 0);

end architecture;