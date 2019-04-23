-------------------------------------------------------------------[24.12.2016]
-- SDRAM Controller
-------------------------------------------------------------------------------
-- Engineer: MVV

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sdram is
port (
	I_CLK		: in std_logic;
	-- Memory port
	I_ADDR		: in std_logic_vector(24 downto 0);
	I_DATA		: in std_logic_vector(7 downto 0);
	O_DATA		: out std_logic_vector(7 downto 0);
	I_WR		: in std_logic;
	I_RD		: in std_logic;
	I_RFSH		: in std_logic;
	O_IDLE		: out std_logic;
	-- SDRAM Pin
	O_CLK		: out std_logic;
	O_RAS		: out std_logic;
	O_CAS		: out std_logic;
	O_WE		: out std_logic;
	O_DQM		: out std_logic;
	O_BA		: out std_logic_vector(1 downto 0);
	O_MA		: out std_logic_vector(12 downto 0);
	IO_DQ		: inout std_logic_vector(7 downto 0) );
end sdram;

architecture rtl of sdram is
	signal state 		: unsigned(4 downto 0) := "00000";
	signal address 		: std_logic_vector(9 downto 0);
	signal data_reg		: std_logic_vector(7 downto 0);
	signal data		: std_logic_vector(7 downto 0);	
	signal idle1		: std_logic;
	
	-- SD-RAM control signals
	signal sdr_cmd		: std_logic_vector(2 downto 0);
	signal sdr_ba		: std_logic_vector(1 downto 0);
	signal sdr_dqm		: std_logic;
	signal sdr_a		: std_logic_vector(12 downto 0);
	signal sdr_dq		: std_logic_vector(7 downto 0);

	constant SdrCmd_xx 	: std_logic_vector(2 downto 0) := "111"; -- no operation
	constant SdrCmd_ac 	: std_logic_vector(2 downto 0) := "011"; -- activate
	constant SdrCmd_rd 	: std_logic_vector(2 downto 0) := "101"; -- read
	constant SdrCmd_wr 	: std_logic_vector(2 downto 0) := "100"; -- write		
	constant SdrCmd_pr 	: std_logic_vector(2 downto 0) := "010"; -- precharge all
	constant SdrCmd_re 	: std_logic_vector(2 downto 0) := "001"; -- refresh
	constant SdrCmd_ms 	: std_logic_vector(2 downto 0) := "000"; -- mode regiser set

-- Init----------------------------------------------------------  Idle      Read----------  Write---------  Refresh-------
-- 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14  15        16 17 12 13 14  18 19 12 13 14  10 11 12 13 14
-- pr xx xx re xx xx xx xx xx re xx xx xx xx xx ms xx xx xx xx xx  xx/ac/re  xx rd xx xx xx  xx wr xx xx xx  xx xx xx xx xx

begin
	process (I_CLK)
	begin
		if (I_CLK'event and I_CLK = '0') then
			case state is
				-- Init
				when "00000" =>					-- s00
					sdr_cmd <= SdrCmd_pr;			-- PRECHARGE
					sdr_a <= "1111111111111";
					sdr_ba <= "00";
					sdr_dqm <= '1';
					state <= state + 1;
				when "00011" | "01001" =>			-- s03 s09
					sdr_cmd <= SdrCmd_re;			-- REFRESH
					state <= state + 1;
				when "01111" =>					-- s0F
					sdr_cmd <= SdrCmd_ms;			-- LOAD MODE REGISTER
					sdr_a <= "000" & "1" & "00" & "010" & "0" & "000";				
					state <= state + 1;
				
				-- Idle
				when "10101" =>					-- s15
					sdr_cmd <= SdrCmd_xx;			-- NOP
					sdr_dq <= (others => 'Z');
					idle1 <= '1';
					if (I_WR = '1') then
						idle1 <= '0';
						address <= I_ADDR(9 downto 0);
						data <= I_DATA;
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba <= I_ADDR(11 downto 10);
						sdr_a <= I_ADDR(24 downto 12);
						state <= "11000";		-- s18 Write
					elsif (I_RD = '1') then
						idle1 <= '0';
						address <= I_ADDR(9 downto 0);
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba <= I_ADDR(11 downto 10);
						sdr_a <= I_ADDR(24 downto 12);					 
						state <= "10110";		-- s16 Read
					elsif (I_RFSH = '1') then
						idle1 <= '0';
						sdr_cmd <= SdrCmd_re;		-- REFRESH
						state <= "10000";		-- s10
					end if;

				-- A24 A23 A22 A21 A20 A19 A18 A17 A16 A15 A14 A13 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0
				-- -----------------------ROW------------------------- BA1 BA0 ----------COLUMN-------------		

				-- Single read - with auto precharge
				when "10111" =>					-- s17
					sdr_cmd <= SdrCmd_rd;			-- READ (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "001" & address;
					sdr_dqm <= '0';
					state <= "10010";			-- s12
				-- Single write - with auto precharge
				when "11001" =>					-- s19
					sdr_cmd <= SdrCmd_wr;			-- WRITE (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "001" & address;
					sdr_dq <= data;
					sdr_dqm <= '0';
					state <= "10010";			-- s12
				when others =>
					sdr_dq <= (others => 'Z');
					sdr_cmd <= SdrCmd_xx;			-- NOP
					state <= state + 1;
			end case;
		end if;
	end process;
	
	process (I_CLK, state, IO_DQ, data_reg, idle1)
	begin
		if (I_CLK'event and I_CLK = '1' and idle1 = '0') then
			if (state = "10100") then				-- s14
				data_reg <= IO_DQ;
			end if;
		end if;
	end process;
	
	O_IDLE	<= idle1;
	O_DATA 	<= data_reg;
	O_CLK 	<= I_CLK;
	O_RAS 	<= sdr_cmd(2);
	O_CAS 	<= sdr_cmd(1);
	O_WE 	<= sdr_cmd(0);
	O_DQM 	<= sdr_dqm;
	O_BA	<= sdr_ba;
	O_MA 	<= sdr_a;
	IO_DQ 	<= sdr_dq;

end rtl;