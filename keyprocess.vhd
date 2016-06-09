LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.numeric_std.all;

entity keyprocess is

	port(scan_code : in std_logic_vector(7 downto 0);
			scan_ready : in std_logic;
			resetn : in std_logic;
			lpad_up : out std_logic;
			lpad_dn : out std_logic;
			rpad_up : out std_logic;
			rpad_dn : out std_logic;
			read_out : out std_logic
		);
end keyprocess;

architecture a of keyprocess is

signal break_int : std_logic := '1';

--signal lpad_up_int : std_logic := '0';
--signal lpad_dn_int : std_logic := '0';
--signal rpad_up_int : std_logic := '0';
--signal rpad_dn_int : std_logic := '0';

begin

--lpad_up <= lpad_up_int;
--lpad_dn <= lpad_dn_int;
--rpad_up <= rpad_up_int;
--rpad_dn <= rpad_dn_int;

process(scan_ready, resetn)
begin
	if resetn = '0' then
		read_out <= '0';
		break_int <= '0';
		lpad_up <= '0';
		lpad_dn <= '0';
		rpad_up <= '0';
		rpad_dn <= '0';
	else
		if scan_ready = '1' then
			read_out <= '1';
		
			if break_int = '0' then
				case scan_code is
					when x"1D" => lpad_up <= '1';
					when x"1B" => lpad_dn <= '1';
					when x"44" => rpad_up <= '1';
					when x"4B" => rpad_dn <= '1';
					when others => null;
				end case;
			else
				case scan_code is
					when x"1D" => lpad_up <= '0';
					when x"1B" => lpad_dn <= '0';
					when x"44" => rpad_up <= '0';
					when x"4B" => rpad_dn <= '0';
					when others => null;
				end case;
				break_int <= '0';
			end if;
			
			if scan_code = x"F0" then
				break_int <= '1';
			end if;
		else
			read_out <= '0';
		end if;
	end if;
end process;

end a;