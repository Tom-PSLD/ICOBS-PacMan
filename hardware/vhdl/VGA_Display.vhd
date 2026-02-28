library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VGA_Display is
    Port ( vidon : in  STD_LOGIC;
           hc : in  STD_LOGIC_VECTOR (9 downto 0);
           vc : in  STD_LOGIC_VECTOR (9 downto 0);
           sw: in  STD_LOGIC_VECTOR (11 downto 0);
           red : out  STD_LOGIC_VECTOR (3 downto 0);
           green : out  STD_LOGIC_VECTOR (3 downto 0);
           blue : out  STD_LOGIC_VECTOR (3 downto 0));
end VGA_Display;

architecture Behavioral of VGA_Display is

begin

process(vidon, sw)
begin
	
	if vidon = '1' then
		red   <= sw(11 downto 8) ;
		green <= sw(7 downto 4);
		blue  <= sw(3 downto 0); 
	else
	   red <="0000"; green <="0000";blue <="0000";


	end if;
end process;

end Behavioral;

