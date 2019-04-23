-------------------------------------------------------------------[30.12.2016]
-- VGA Text Mode 128x48, VRAM 12288 bytes, Font 8x16 4096 bytes
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.all;

entity txt is port (
	I_CLK			: in std_logic;
	I_EN			: in std_logic;
	I_CHAR_DATA		: in std_logic_vector(15 downto 0);
	I_FONT_DATA		: in std_logic_vector(7 downto 0);
	I_H			: in std_logic_vector(10 downto 0);
	I_HCNT			: in std_logic_vector(10 downto 0);
	I_VCNT			: in std_logic_vector(9 downto 0);
	I_BLANK			: in std_logic;
	I_INT			: in std_logic;
	I_FLASH			: in std_logic;				-- скорость мерцания курсора 1.875Гц
	I_CURSOR_X		: in std_logic_vector(6 downto 0);	-- 0..127
	I_CURSOR_Y		: in std_logic_vector(5 downto 0);	-- 0..47
	I_CURSOR_COLOR		: in std_logic_vector(7 downto 0);	-- 7:Bright Paper, 6..4:Paper(RGB), 3:Bright Ink, 2..0:Ink(RGB)
	I_CURSOR_SETUP		: in std_logic_vector(2 downto 0);	-- 2:0=off, 1=on; 1:type 0=small, 1=big; 0:Flash 0=off, 1=on
	O_CHAR_ADDR		: out std_logic_vector(12 downto 0);
	O_FONT_ADDR		: out std_logic_vector(11 downto 0);
	O_R			: out std_logic_vector(7 downto 0); 	-- red
	O_G			: out std_logic_vector(7 downto 0); 	-- green
	O_B			: out std_logic_vector(7 downto 0)); 	-- blue
end entity;

architecture rtl of txt is
	signal pixel		: std_logic;
	signal color		: std_logic_vector(3 downto 0);
	signal rgb		: std_logic_vector(23 downto 0);
	signal tmp		: std_logic_vector(1 downto 0);
	signal cursor		: std_logic;
	signal char_tmp		: std_logic_vector(15 downto 0);
	signal char		: std_logic_vector(7 downto 0);
	signal font		: std_logic_vector(7 downto 0);
	signal hcnt		: std_logic_vector(10 downto 0);
begin


	-- Hardware Cursor
	cursor <= '1' when ((I_HCNT(9 downto 3) = I_CURSOR_X) and (I_VCNT(9 downto 4) = I_CURSOR_Y) and (I_CURSOR_SETUP(2) = '1') and (I_FLASH = '1' or I_CURSOR_SETUP(0) = '0')) and ((I_CURSOR_SETUP(1) = '1') or (I_CURSOR_SETUP(1) = '0' and I_VCNT(3 downto 0) > 13)) else '0';
	tmp    <= cursor & pixel;

	process (I_CLK, I_EN, I_H, font, I_BLANK, rgb, tmp, char_tmp, I_CURSOR_COLOR, color)
	begin
		if I_CLK'event and I_CLK = '1' then
			if I_EN = '1' then
				if I_H(2 downto 0) = "100" then
					char_tmp <= I_CHAR_DATA;
				end if;
				if I_H(2 downto 0) = "111" then
					font <= I_FONT_DATA;
					char <= char_tmp(15 downto 8);
				end if;
			end if;
		end if;

		case I_H(2 downto 0) is
			when "000" => pixel <= font(7);
			when "001" => pixel <= font(6);
			when "010" => pixel <= font(5);
			when "011" => pixel <= font(4);
			when "100" => pixel <= font(3);
			when "101" => pixel <= font(2);
			when "110" => pixel <= font(1);
			when "111" => pixel <= font(0);
			when others => null;
		end case;

		-- 7:Bright Paper, 6..4:Paper(RGB), 3:Bright Ink, 2..0:Ink(RGB)
		case tmp is
			when "00" => color <= char(7 downto 4);
			when "01" => color <= char(3 downto 0);
			when "10" => color <= I_CURSOR_COLOR(7 downto 4);
			when "11" => color <= I_CURSOR_COLOR(3 downto 0);
			when  others => null;
		end case;

		-- Make an 24 colors table specifying the color values for each of the basic named set of 16 colors.
		case color is
			when "0000" => rgb <= x"000000"; -- Black
			when "0001" => rgb <= x"000080"; -- Navy
			when "0010" => rgb <= x"009900"; -- Green
			when "0011" => rgb <= x"009999"; -- Teal
			when "0100" => rgb <= x"800000"; -- Maroon
			when "0101" => rgb <= x"800080"; -- Purple
			when "0110" => rgb <= x"999900"; -- Olive
			when "0111" => rgb <= x"CCCCCC"; -- Silver
			when "1000" => rgb <= x"808080"; -- Gray
			when "1001" => rgb <= x"0000FF"; -- Blue
			when "1010" => rgb <= x"00FF00"; -- Lime
			when "1011" => rgb <= x"00FFFF"; -- Aqua
			when "1100" => rgb <= x"FF0000"; -- Red
			when "1101" => rgb <= x"FF00FF"; -- Fuchsia
			when "1110" => rgb <= x"FFFF00"; -- Yellow
			when "1111" => rgb <= x"FFFFFF"; -- White
			when  others => null;
		end case;

		if I_BLANK = '1' then
			O_R <= (others => '0');
			O_G <= (others => '0');
			O_B <= (others => '0');
		else
			O_R <= rgb(23 downto 16);
			O_G <= rgb(15 downto 8);
			O_B <= rgb(7 downto 0);
		end if;

	end process;

	O_CHAR_ADDR <= I_VCNT(9 downto 4) & I_H(9 downto 3);
	O_FONT_ADDR <= char_tmp(7 downto 0) & I_VCNT(3 downto 0);

end architecture;