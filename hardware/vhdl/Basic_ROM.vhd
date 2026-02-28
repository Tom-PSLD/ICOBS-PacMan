
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Use numeric_std instead of std_logic_unsigned
use work.VGA_Generic_Package.ALL;

entity Basic_ROM is
    Port ( addr : in  STD_LOGIC_VECTOR (3 downto 0);
           M : out  STD_LOGIC_VECTOR (11 downto 0));
end Basic_ROM;

architecture Behavioral of Basic_ROM is
type rom_array is array (NATURAL range <>) of std_logic_vector(11 downto 0);

constant rom:rom_array:= (
	"000000000000", "111111111111", "111111111111", "000000000000", --0 --> 3
	"111111111111", "000000000000", "000000000000", "111111111111", --4 --> 7 
	"111111111111", "000000000000", "000000000000", "111111111111", --8 --> 11
	"000000000000", "111111111111", "111111111111", "000000000000"  --12 -->15
	);

begin

process(addr)
variable j: integer;
begin
	j := to_integer(unsigned(addr)); -- Convert using numeric_std
	M <= rom(j);
end process;
end Behavioral;
