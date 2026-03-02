
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.VGA_Generic_Package.ALL;

entity VGA_Basic_ROM_Top is
    Port ( clk : in  STD_LOGIC;
           btnR : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           sw: in  STD_LOGIC_VECTOR (11 downto 0);
           vgaRed : out  STD_LOGIC_VECTOR (3 downto 0);
           vgaGreen : out  STD_LOGIC_VECTOR (3 downto 0);
           vgaBlue : out  STD_LOGIC_VECTOR (3 downto 0));
end VGA_Basic_ROM_Top;

architecture Behavioral of VGA_Basic_ROM_Top is


signal rst, clk25, vidon: std_logic;
signal hc, vc: std_logic_vector(9 downto 0);
signal M :  STD_LOGIC_VECTOR (11 downto 0);
signal addr : STD_LOGIC_VECTOR (3 downto 0);
begin

rst <= btnR;

U1: VGA_Clock port map ( mclk => clk, reset => rst, clk25=> clk25);
U2: VGA_640_x_480 port map ( rst => rst, clk => clk25, hsync => Hsync, vsync => Vsync, hc => hc, vc => vc, vidon => vidon);
U3: VGA_Basic_ROM port map ( vidon => vidon, hc => hc, vc => vc, sw => sw, M => M, rom_addr4 => addr, red => vgaRed, green => vgaGreen, blue => vgaBlue);
U4: Basic_ROM    Port Map ( addr => addr, M => M);

end Behavioral;


