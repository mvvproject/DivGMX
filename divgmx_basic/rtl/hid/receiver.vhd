-------------------------------------------------------------------[11.09.2015]
-- Receiver
-------------------------------------------------------------------------------
-- Engineer: 	MVV
--
-- 15.07.2014	Initial release
-- 10.09.2015	
-------------------------------------------------------------------------------

-- The keyboard firmware expects to receive 8 bytes formatted as a Keyboard HID report. The format is as follows:
-- Byte 0	Modifier keys:
-- 		Bit 0 - Left CTRL
-- 		Bit 1 - Left SHIFT
-- 		Bit 2 - Left ALT
-- 		Bit 3 - Left GUI
-- 		Bit 4 - Right CTRL
-- 		Bit 5 - Right SHIFT
-- 		Bit 6 - Right ALT
-- 		Bit 7 - Right GUI
-- Byte 1	Not used
-- Byte 2-7	HID active key usage codes. This represents up to 6 keys currently being pressed.

library ieee;
use ieee.std_logic_1164.all;

entity receiver is
	generic (
		divisor		: integer := 434 );	-- divisor = 50MHz / 115200 Baud = 434
	port (
		I_CLK		: in  std_logic;
		I_RESET		: in  std_logic;
		I_RX		: in  std_logic;
		O_DATA		: out std_logic_vector(7 downto 0);
		O_READY		: out std_logic);
end receiver;

architecture rtl of receiver is
	constant halfbit 	: integer := divisor / 2; 
	signal rx_buffer	: std_logic_vector(7 downto 0);
	signal rx_bit_count	: integer range 0 to 10;
	signal rx_count		: integer range 0 to divisor;
	signal rx_avail		: std_logic;
	signal rx_shift_reg	: std_logic_vector(7 downto 0);
	signal rx_bit		: std_logic;

	signal buffer0, buffer1, buffer2, buffer3, buffer4, buffer5, buffer6, buffer7	: std_logic_vector(7 downto 0);
	signal buffer_count 	: integer range 0 to 7;
	signal count		: integer range 0 to 15;
	
begin

process(I_CLK, I_RESET) is
begin
	if I_RESET = '1' then
		rx_buffer <= (others => '0');
		rx_bit_count <= 0;
		rx_count <= 0;
		rx_avail <= '0';
	elsif I_CLK'event and I_CLK = '1' then
	-- Receiver
		rx_avail <= '0';
		if rx_count /= 0 then 
			rx_count <= rx_count - 1;
		else
			if rx_bit_count = 0 then		-- wait for startbit
				if rx_bit = '0' then		-- FOUND
					rx_count <= halfbit;
					rx_bit_count <= rx_bit_count + 1;                                               
				end if;
			elsif rx_bit_count = 1 then		-- sample mid of startbit
				if rx_bit = '0' then		-- OK
					rx_count <= divisor;
					rx_bit_count <= rx_bit_count + 1;
					rx_shift_reg <= "00000000";
				else				-- ERROR
					rx_bit_count <= 0;
				end if;
			elsif rx_bit_count = 10 then		-- stopbit
				if rx_bit = '1' then		-- OK
					rx_buffer <= rx_shift_reg;
					rx_avail <= '1';
					rx_count <= 0;
					rx_bit_count <= 0;
				else				-- ERROR
					rx_count <= divisor;
					rx_bit_count <= 0;
				end if;
			else
				rx_shift_reg(6 downto 0) <= rx_shift_reg(7 downto 1);
				rx_shift_reg(7)	<= rx_bit;
				rx_count <= divisor;
				rx_bit_count <= rx_bit_count + 1;
			end if;
		end if;
	end if;
end process;

-- Sync incoming RXD (anti metastable)
syncproc: process (I_RESET, I_CLK) is
begin
	if I_RESET = '1' then
		rx_bit <= '1';
	elsif I_CLK'event and I_CLK = '0' then
		rx_bit <= I_RX;
	end if;
end process;

O_DATA  <= rx_buffer;
O_READY	<= rx_avail;

end rtl;