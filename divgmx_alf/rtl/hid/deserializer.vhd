-------------------------------------------------------------------[07.04.2017]
-- CONTROLLER USB HID scancode to Spectrum matrix conversion
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity deserializer is
generic (
	divisor			: integer := 434 );	-- divisor = 50MHz / 115200 Baud = 434
port (
	I_CLK			: in std_logic;
	I_RESET			: in std_logic;
	I_RX			: in std_logic;
	I_NEWFRAME		: in std_logic;
	O_FKEYS			: out std_logic_vector(12 downto 1);
	O_CTLKEYS		: out std_logic_vector(3 downto 0);
	O_JOY1			: out std_logic_vector(4 downto 0);
	O_JOY2			: out std_logic_vector(4 downto 0);
	O_GAMEPAD1		: out std_logic_vector(13 downto 0);
	O_GAMEPAD2		: out std_logic_vector(13 downto 0));
end deserializer;

architecture rtl of deserializer is
	signal ctlkeys		: std_logic_vector(3 downto 0);
	signal fkeys 		: std_logic_vector(12 downto 1);
	
	signal joy1 		: std_logic_vector(4 downto 0);
	signal joy2 		: std_logic_vector(4 downto 0);
	signal count		: integer range 0 to 8;
	signal data		: std_logic_vector(7 downto 0);
	signal ready		: std_logic;
	signal device_id	: std_logic_vector(7 downto 0);
	signal gamepad1		: std_logic_vector(13 downto 0) := "00000000000000";
	signal gamepad2		: std_logic_vector(13 downto 0) := "00000000000000";
	
begin

	inst_rx : entity work.receiver
	generic map (
		divisor		=> 434 )	-- divisor = 50MHz / 115200 Baud = 434
	port map (
		I_CLK		=> I_CLK,
		I_RESET		=> I_RESET,
		I_RX		=> I_RX,
		O_DATA		=> data,
		O_READY		=> ready
	);

	O_CTLKEYS <= ctlkeys;
	O_FKEYS <= fkeys;
	-- Joy
	O_JOY1 <= joy1;
	O_JOY2 <= joy2;
	-- Gamepad
	O_GAMEPAD1 <= gamepad1;
	O_GAMEPAD2 <= gamepad2;
	
	process (I_RESET, I_CLK, data, I_NEWFRAME, ready)
	begin
		if I_RESET = '1' then
			count <= 0;
			ctlkeys <= (others => '0');
			fkeys <= (others => '0');
			joy1 <= (others => '0');
			joy2 <= (others => '1');
			gamepad1 <= (others => '0');
			gamepad2 <= (others => '0');
			
		elsif I_NEWFRAME = '0' then
			count <= 0;
		elsif I_CLK'event and I_CLK = '1' and ready = '1' then
			if count = 0 then
				count <= 1;
				device_id <= data;
				case data(3 downto 0) is
					when x"6" =>	-- Keyboard
						ctlkeys <= (others => '0');
						fkeys <= (others => '0');
						joy1 <= (others => '0');
						joy2 <= (others => '1');
					when others => null;
				end case;
			else
				count <= count + 1;
				case device_id is
					when x"04" => -- Gamepad (Defender Game Master G2)
						case count is
							when 4 => gamepad1(0) <= data(7);		-- [Right]
								  gamepad1(1) <= not data(6);		-- [Left]
							when 5 => gamepad1(2) <= data(7);		-- [Down]
								  gamepad1(3) <= not data(6);		-- [Up]
							when 6 => gamepad1(6) <= data(4);		-- [1]
								  gamepad1(5) <= data(5);		-- [2]
								  gamepad1(4) <= data(6);		-- [3]
								  gamepad1(7) <= data(7);		-- [4]
							when 7 => gamepad1(8) <= data(1);		-- [R1]
								  gamepad1(9) <= data(3);		-- [R2]
								  gamepad1(10) <= data(0);		-- [L1]
								  gamepad1(11) <= data(2);		-- [L2]
								  gamepad1(12) <= data(4);		-- [9]
								  gamepad1(13) <= data(5);		-- [10]
							when others => null;
						end case;
						
					when x"84" => -- Gamepad (Defender Game Master G2)
						case count is
							when 4 => gamepad2(0) <= data(7);		-- [Right]
								  gamepad2(1) <= not data(6);		-- [Left]
							when 5 => gamepad2(2) <= data(7);		-- [Down]
								  gamepad2(3) <= not data(6);		-- [Up]
							when 6 => gamepad2(6) <= data(4);		-- [1]
								  gamepad2(5) <= data(5);		-- [2]
								  gamepad2(4) <= data(6);		-- [3]
								  gamepad2(7) <= data(7);		-- [4]
							when 7 => gamepad2(8) <= data(1);		-- [R1]
								  gamepad2(9) <= data(3);		-- [R2]
								  gamepad2(10) <= data(0);		-- [L1]
								  gamepad2(11) <= data(2);		-- [L2]
								  gamepad2(12) <= data(4);		-- [9]
								  gamepad2(13) <= data(5);		-- [10]
							when others => null;
						end case;					
					
					when x"06" | x"86" =>	-- Keyboard

						if count = 1 then
							if data(0) = '1' then joy1(4) <= '1'; end if;		-- E0 Left Control
--							if data(1) = '1' then <= '0'; end if;	-- E1 Left shift (CAPS SHIFT)
--							if data(2) = '1' then <= '1'; end if;	-- E2 Left Alt
--							if data(3) = '1' then <= '1'; end if;	-- E3 Left Gui
--							if data(4) = '1' then <= '1'; end if;	-- E4 CTRL (Symbol Shift)
--							if data(5) = '1' then <= '1'; end if;	-- E5 Right shift (CAPS SHIFT)
--							if data(6) = '1' then <= '1'; end if;	-- E6 Right Alt
--							if data(7) = '1' then <= '1'; end if;	-- E7 Right Gui
						else
							case data is
								-- Joy1
								when X"4f" =>	joy1(0) <= '1'; -- Right
								when X"50" =>	joy1(1) <= '1'; -- Left
								when X"51" =>	joy1(2) <= '1'; -- Down
								when X"52" =>	joy1(3) <= '1'; -- Up

								-- Joy2
								when X"5e" =>	joy2(2) <= '0'; -- Right
								when X"5c" =>	joy2(4) <= '0'; -- Left
								when X"5d" =>	joy2(1) <= '0'; -- Down
								when X"60" =>	joy2(3) <= '0'; -- Up
								when X"62" =>	joy2(0) <= '0'; -- Fire
		
								-- Fx keys
								when X"3a" =>	fkeys(1) <= '1'; -- F1
								when X"3b" =>	fkeys(2) <= '1'; -- F2
								when X"3c" =>	fkeys(3) <= '1'; -- F3
								when X"3d" =>	fkeys(4) <= '1'; -- F4
								when X"3e" =>	fkeys(5) <= '1'; -- F5
								when X"3f" =>	fkeys(6) <= '1'; -- F6
								when X"40" =>	fkeys(7) <= '1'; -- F7
								when X"41" =>	fkeys(8) <= '1'; -- F8
								when X"42" =>	fkeys(9) <= '1'; -- F9
								when X"43" =>	fkeys(10) <= '1'; -- F10
								when X"44" =>	fkeys(11) <= '1'; -- F11
								when X"45" =>	fkeys(12) <= '1'; -- F12
				 
								-- Soft keys
								when X"46" =>	ctlkeys(0) <= '1'; -- PrtScr
								when X"48" =>	ctlkeys(1) <= '1'; -- Pause
								
								when others => null;
							end case;
						end if;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;

end architecture;
