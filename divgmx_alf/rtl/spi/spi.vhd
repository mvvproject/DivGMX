-------------------------------------------------------------------[14.01.2017]
-- SPI Master
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity spi is
port (
	I_RESET		: in std_logic;
	I_CLK		: in std_logic;
	I_SCK		: in std_logic;
	I_DI		: in std_logic_vector(7 downto 0);
	O_DO		: out std_logic_vector(7 downto 0);
	I_WR		: in std_logic;
	O_BUSY		: out std_logic;
	O_SCLK		: out std_logic;
	O_MOSI		: out std_logic;
	I_MISO		: in std_logic);
end;

architecture rtl of spi is
	signal cnt		: std_logic_vector(2 downto 0) := "000";
	signal shift_reg	: std_logic_vector(7 downto 0) := "11111111";
	signal buffer_reg	: std_logic_vector(7 downto 0) := "11111111";
	signal state		: std_logic := '0';
	signal start		: std_logic := '0';
begin
	-- buffer_reg
	process (I_RESET, I_CLK, I_WR, I_DI)
	begin
		if (I_RESET = '1') then
			buffer_reg <= (others => '1');
		elsif (I_CLK'event and I_CLK = '1' and I_WR = '1') then
			buffer_reg <= I_DI;
		end if;
	end process;

	-- start
	process (I_RESET, I_CLK, I_WR, state)
	begin
		if (I_RESET = '1' or state = '1') then
			start <= '0';
		elsif (I_CLK'event and I_CLK = '1' and I_WR = '1') then
			start <= '1';
		end if;
	end process;

	process (I_RESET, I_SCK, start, buffer_reg)
	begin
		if (I_RESET = '1') then
			state <= '0';
			cnt <= "000";
			shift_reg <= "11111111";
		elsif (I_SCK'event and I_SCK = '0') then
			case state is
				when '0' =>
					if (start = '1') then
						shift_reg <= buffer_reg;
						cnt <= "000";
						state <= '1';
					end if;
				when '1' =>
					if (cnt	= "111") then state <= '0'; end if;
					shift_reg <= shift_reg(6 downto 0) & I_MISO;
					cnt <= cnt + 1;
				when others => null;
			end case;
		end if;
	end process;
	
O_BUSY	<= state;
O_DO	<= shift_reg;
O_MOSI	<= shift_reg(7);
O_SCLK	<= I_SCK when state = '1' else '0';

end rtl;