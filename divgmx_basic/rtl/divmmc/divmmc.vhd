-------------------------------------------------------------------[29.04.2017]
-- DivMMC
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divmmc is
port (
	I_CLK			: in std_logic;
	I_SCLK			: in std_logic;
	I_CS			: in std_logic;
	I_RESET			: in std_logic;
	I_ADDR			: in std_logic_vector(15 downto 0);
	I_DATA			: in std_logic_vector(7 downto 0);
	O_DATA			: out std_logic_vector(7 downto 0);
	I_WR_N			: in std_logic;
	I_RD_N			: in std_logic;
	I_IORQ_N		: in std_logic;
	I_MREQ_N		: in std_logic;
	I_M1_N			: in std_logic;
	I_RFSH_N		: in std_logic;
	O_E3REG			: out std_logic_vector(7 downto 0);
	O_AMAP			: out std_logic;
	O_CS_N			: out std_logic;
	O_SCLK			: out std_logic;
	O_MOSI			: out std_logic;
	I_MISO			: in std_logic);
end divmmc;

architecture rtl of divmmc is
	signal cnt		: std_logic_vector(3 downto 0);
	signal cnt_en		: std_logic;
	signal cs		: std_logic := '1';
	signal reg_e3		: std_logic_vector(7 downto 0) := "00000000";
	signal reg_e7		: std_logic := '0';
	signal automap		: std_logic := '0';
	signal detect		: std_logic := '0';
	signal shift_in		: std_logic_vector(7 downto 0);
	signal shift_out	: std_logic_vector(7 downto 0);

	
begin

process (I_RESET, I_CLK, I_WR_N, I_ADDR, I_IORQ_N, I_CS, I_DATA)
begin
	if (I_RESET = '1') then
		cs <= '1';
		reg_e3 <= (others => '0');
	elsif (I_CLK'event and I_CLK = '1') then
		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E3") then	reg_e3 <= I_DATA; end if;	-- #E3
		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E7") then cs <= I_DATA(0); end if;	-- #E7
	end if;
end process;

process (I_CLK, I_M1_N, I_MREQ_N, I_ADDR, I_CS, detect, automap)
begin
	if (I_CLK'event and I_CLK = '1') then
		if (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and (I_ADDR = X"0000" or I_ADDR = X"0008" or I_ADDR = X"0038" or I_ADDR = X"0066" or I_ADDR = X"04C6" or I_ADDR = X"0562")) then
			detect <= '1';	-- активируется при извлечении кода команды в М1 цикле при совпадении заданных адресов
		elsif (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and I_ADDR(15 downto 8) = X"3D") then
			automap <= '1';
			detect <= '1';
		elsif (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and I_ADDR(15 downto 3) = "0001111111111") then
			detect <= '0';	-- деактивируется при извлечении кода команды в М1 при совпадении адресов 0x1FF8-0x1FFF
		end if;
		
		if (I_M1_N = '1' and I_CS = '1') then
			automap <= detect;	-- переключение после чтения опкода
		end if;
	end if;
end process;

O_E3REG <= reg_e3;
O_AMAP  <= automap;
O_CS_N  <= cs;

-------------------------------------------------------------------------------
-- SPI Interface
cnt_en <= not cnt(3) or cnt(2) or cnt(1) or cnt(0);

process (I_SCLK, cnt_en, I_ADDR, I_IORQ_N, I_RD_N, I_WR_N, I_CS)
begin
	if (I_ADDR(7 downto 0) = X"EB" and I_IORQ_N = '0' and I_CS = '1' and (I_WR_N = '0' or I_RD_N = '0')) then
		cnt <= "1110";
	else 
		if (I_SCLK'event and I_SCLK = '0') then			
			if cnt_en = '1' then 
				cnt <= cnt + 1;
			end if;
		end if;
	end if;
end process;

process (I_SCLK)
begin
	if (I_SCLK'event and I_SCLK = '0') then			
		if (I_ADDR(7 downto 0) = X"EB" and I_WR_N = '0' and I_IORQ_N = '0' and I_CS = '1') then
			shift_out <= I_DATA;
		else
			if cnt(3) = '0' then
				shift_out(7 downto 0) <= shift_out(6 downto 0) & '1';
			end if;
		end if;
	end if;
end process;

process (I_SCLK)
begin
	if (I_SCLK'event and I_SCLK = '0') then			
		if cnt(3) = '0' then
			shift_in <= shift_in(6 downto 0) & I_MISO;
		end if;
	end if;
end process;

O_SCLK  <= I_SCLK and not cnt(3);
O_MOSI  <= shift_out(7);
O_DATA  <= shift_in;


end rtl;

---------------------------------------------------------------------[03.12.2016]
---- DivMMC
---------------------------------------------------------------------------------
---- Engineer: MVV <mvvproject@gmail.com>
--
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
--entity divmmc is
--port (
--	I_CLK			: in std_logic;
--	I_CS			: in std_logic;
--	I_RESET			: in std_logic;
--	I_ADDR			: in std_logic_vector(15 downto 0);
--	I_DATA			: in std_logic_vector(7 downto 0);
--	O_DATA			: out std_logic_vector(7 downto 0);
--	I_WR_N			: in std_logic;
--	I_RD_N			: in std_logic;
--	I_IORQ_N		: in std_logic;
--	I_MREQ_N		: in std_logic;
--	I_M1_N			: in std_logic;
--	I_RFSH_N		: in std_logic;
--	O_E3REG			: out std_logic_vector(7 downto 0);
--	O_AMAP			: out std_logic;
--	O_CS_N			: out std_logic;
--	O_SCLK			: out std_logic;
--	O_MOSI			: out std_logic;
--	I_MISO			: in std_logic);
--end divmmc;
--
--architecture rtl of divmmc is
--	signal cnt		: std_logic_vector(3 downto 0);
--	signal cnt_en		: std_logic;
--	signal cs		: std_logic := '1';
--	signal reg_e3		: std_logic_vector(7 downto 0) := "00000000";
--	signal reg_e7		: std_logic := '0';
--	signal automap		: std_logic := '0';
--	signal detect		: std_logic := '0';
--	signal shift_in		: std_logic_vector(7 downto 0);
--	signal shift_out	: std_logic_vector(7 downto 0);
--
--	
--begin
--
--process (I_RESET, I_CLK, I_WR_N, I_ADDR, I_IORQ_N, I_CS, I_DATA)
--begin
--	if (I_RESET = '1') then
--		cs <= '1';
--		reg_e3 <= (others => '0');
--	elsif (I_CLK'event and I_CLK = '1') then
--		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E3") then	reg_e3 <= I_DATA; end if;	-- #E3
--		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E7") then cs <= I_DATA(0); end if;	-- #E7
--	end if;
--end process;
--
--process (I_CLK, I_M1_N, I_MREQ_N, I_ADDR, I_CS, detect, automap)
--begin
--	if (I_CLK'event and I_CLK = '1') then
--		if (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and (I_ADDR = X"0000" or I_ADDR = X"0008" or I_ADDR = X"0038" or I_ADDR = X"0066" or I_ADDR = X"04C6" or I_ADDR = X"0562" or I_ADDR(15 downto 8) = X"3D")) then
--			detect <= '1';	-- активируется при извлечении кода команды в М1 цикле при совпадении заданных адресов
--		elsif (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and I_ADDR(15 downto 3) = "0001111111111") then
--			detect <= '0';	-- деактивируется при извлечении кода команды в М1 при совпадении адресов 0x1FF8-0x1FFF
--		end if;
--		if (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and I_CS = '1' and I_ADDR(15 downto 8) = X"3D") then
--			automap <= '1';	-- моментальное переключение без ожидания чтения опкода
--		elsif (I_MREQ_N = '0' and I_RD_N = '1' and I_WR_N = '1' and I_CS = '1') then
--			automap <= detect;	-- переключение после чтения опкода
--		end if;
--	end if;
--end process;
--
--O_E3REG <= reg_e3;
--O_AMAP  <= automap;
--O_CS_N  <= cs;
--
---------------------------------------------------------------------------------
---- SPI Interface
--cnt_en <= not cnt(3) or cnt(2) or cnt(1) or cnt(0);
--
--process (I_CLK, cnt_en, I_ADDR, I_IORQ_N, I_RD_N, I_WR_N, I_CS)
--begin
--	if (I_ADDR(7 downto 0) = X"EB" and I_IORQ_N = '0' and I_CS = '1' and (I_WR_N = '0' or I_RD_N = '0')) then
--		cnt <= "1110";
--	else 
--		if (I_CLK'event and I_CLK = '0') then			
--			if cnt_en = '1' then 
--				cnt <= cnt + 1;
--			end if;
--		end if;
--	end if;
--end process;
--
--process (I_CLK)
--begin
--	if (I_CLK'event and I_CLK = '0') then			
--		if (I_ADDR(7 downto 0) = X"EB" and I_WR_N = '0' and I_IORQ_N = '0' and I_CS = '1') then
--			shift_out <= I_DATA;
--		else
--			if cnt(3) = '0' then
--				shift_out(7 downto 0) <= shift_out(6 downto 0) & '1';
--			end if;
--		end if;
--	end if;
--end process;
--
--process (I_CLK)
--begin
--	if (I_CLK'event and I_CLK = '0') then			
--		if cnt(3) = '0' then
--			shift_in <= shift_in(6 downto 0) & I_MISO;
--		end if;
--	end if;
--end process;
--
--O_SCLK  <= I_CLK and not cnt(3);
--O_MOSI  <= shift_out(7);
--O_DATA  <= shift_in;
--
--
--end rtl;