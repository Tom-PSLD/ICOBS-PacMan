
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VGA_Display_Top is
    Port ( clk : in  STD_LOGIC;
           btnR : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           sw: in  STD_LOGIC_VECTOR (11 downto 0);
           vgaRed : out  STD_LOGIC_VECTOR (3 downto 0);
           vgaGreen : out  STD_LOGIC_VECTOR (3 downto 0);
           vgaBlue : out  STD_LOGIC_VECTOR (3 downto 0));
end VGA_Display_Top;

architecture Behavioral of VGA_Display_Top is

component VGA_Clock 
        Port (reset:   in  STD_LOGIC;
           mclk : in  STD_LOGIC;
           clk25 : out  STD_LOGIC);
end component;

component VGA_Display
    Port ( vidon : in STD_LOGIC;
           hc : in STD_LOGIC_VECTOR (9 downto 0);
           vc : in STD_LOGIC_VECTOR (9 downto 0);
           sw: in  STD_LOGIC_VECTOR (11 downto 0);
           red : out STD_LOGIC_VECTOR (3 downto 0);
           green : out STD_LOGIC_VECTOR (3 downto 0);
           blue : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component VGA_640_x_480
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC;
           hc : out  STD_LOGIC_VECTOR (9 downto 0);
           vc : out  STD_LOGIC_VECTOR (9 downto 0);
           vidon : out  STD_LOGIC);
end component;

signal rst, clk25, vidon: std_logic;
signal hc, vc: std_logic_vector(9 downto 0);


begin

rst <= btnR;

U1: VGA_Clock port map ( mclk => clk, reset => rst, clk25=> clk25);
U2: VGA_640_x_480 port map ( rst => rst, clk => clk25, hsync => Hsync, vsync => Vsync, hc => hc, vc => vc, vidon => vidon);
U3: VGA_Display port map ( vidon => vidon, hc => hc, vc => vc, sw => sw, red => vgaRed, green => vgaGreen, blue => vgaBlue);

end Behavioral;




