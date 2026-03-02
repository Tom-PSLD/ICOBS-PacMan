library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
package VGA_Generic_Package is
    
    -- Declare functions
    function TotalPixels(width, height : integer) return integer;   --Used to calculate the Total Number of Pixels
    function log2(n : natural) return natural;                      --Used to calculate the size of the std_logic_vectors
    
----     Declare constants

    constant VGA_WIDTH :        integer := 640;
    constant VGA_HEIGHT :       integer := 480;
    
    constant HORIZONTAL_PULSE:  integer := 96;
    constant HORIZONTAL_BP:     integer := 48;
    constant HORIZONTAL_FP:     integer := 16;
    
    --Do the sale with VERTICAL constants, according to the specifications for a 640x480 VGA display
    constant VERTICAL_PULSE:  integer := 2; 
    constant VERTICAL_BP:     integer := 29; 
    constant VERTICAL_FP:     integer := 10; 
    
    --Find the constant value to be calculated depending on the above mentioned constants
    constant N:                 integer := log2(VGA_WIDTH + HORIZONTAL_PULSE + HORIZONTAL_BP +  HORIZONTAL_FP);
    
    constant hpixels:   unsigned(N-1 downto 0) := to_unsigned(VGA_WIDTH + HORIZONTAL_PULSE + HORIZONTAL_BP + HORIZONTAL_FP, N);     
    constant hbp:       unsigned(N-1 downto 0)  := to_unsigned(HORIZONTAL_PULSE + HORIZONTAL_BP, N);                                 
    constant hfp:       unsigned(N-1 downto 0)  := to_unsigned(VGA_WIDTH + HORIZONTAL_PULSE + HORIZONTAL_BP, N);                     
    
    constant vlines:    unsigned(N-1 downto 0)  := to_unsigned(VGA_HEIGHT + VERTICAL_PULSE + VERTICAL_BP +  VERTICAL_FP , N);
    constant vbp:       unsigned(N-1 downto 0) := to_unsigned(VERTICAL_BP + VERTICAL_BP , N );
    constant vfp:       unsigned(N-1 downto 0)  := to_unsigned(VGA_HEIGHT + VERTICAL_PULSE + VERTICAL_FP , N) ;
        
    
    --components
    component clk_wiz_0
        Port (reset:   in  STD_LOGIC;
           clk_in1 : in  STD_LOGIC;
           clk_out1 : out  STD_LOGIC);
    end component;
    
component clkdiv
    port(clk_in,rst: in std_logic; clk_out: out std_logic);
end component;

component mover
    port(x,y : out integer ; clk100 :in std_logic);
end component;

component prom_sprite
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END component;


component VGA_Basic_ROM
   Port ( vidon : in STD_LOGIC;
          hc : in STD_LOGIC_VECTOR (9 downto 0);
          vc : in STD_LOGIC_VECTOR (9 downto 0);
          x,y : in integer;
          rom_addr5: out std_logic_vector(15 downto 0);
          M: std_logic_vector(0 to 11);
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

component Basic_ROM
   Port ( addr : in  STD_LOGIC_VECTOR (3 downto 0);
          M : out  STD_LOGIC_VECTOR (11 downto 0));
end component;
    
end VGA_Generic_Package;

package body VGA_Generic_Package is

    -- Implementation of the TotalPixels function
    function TotalPixels(width, height : integer) return integer is
    begin
        return width * height;
    end TotalPixels;
    
    -- Implementation of the log2 function
    function log2(n : natural) return natural is
    variable count : natural := 0;
    variable value : natural := n;
    begin
        while value >= 1 loop
            value := value / 2;
            count := count + 1;
        end loop;
        return count;
    end log2;


end VGA_Generic_Package;
