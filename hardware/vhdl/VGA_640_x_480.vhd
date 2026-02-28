library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  -- Use numeric_std instead of std_logic_unsigned
use work.VGA_Generic_Package.ALL;

entity VGA_640_x_480 is
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC;
           hc : out  STD_LOGIC_VECTOR (9 downto 0);
           vc : out  STD_LOGIC_VECTOR (9 downto 0);
           vidon : out  STD_LOGIC);
end VGA_640_x_480;


architecture Behavioral of VGA_640_x_480 is

    -- ERREUR 2 : Les signaux doivent être déclarés ICI
    
    -- N (de votre package) doit être 10.
    -- Les compteurs internes doivent être 'unsigned' pour l'arithmétique (+)
    signal hcs : unsigned(N-1 downto 0); -- N = 10, donc (9 downto 0)
    signal vcs : unsigned(9 downto 0); -- En supposant que le compteur vertical tient aussi sur 10 bits
    
    signal vsenable: std_logic;

begin

process(clk, rst)
begin
    if rising_edge(clk) then
        if rst = '1' then
            hcs <= (others => '0');
        else
            if hcs = hpixels - 1 then
                hcs <= (others => '0');
            else
                hcs <= hcs + 1;
            end if;
        end if;
    end if;
end process;
------------------------------------------------------------
process(hcs)
begin
    if hcs = hpixels - 1 then
        vsenable <= '1';
    else
        vsenable <= '0';
    end if;
end process;

------------------------------------------------------------
-- Compteur pour le signal de synchronisation verticale
------------------------------------------------------------
process(clk, rst)
begin
    if rising_edge(clk) then
        if rst = '1' then
            vcs <= (others => '0');
        elsif vsenable = '1' then
            if vcs = vlines - 1 then
                vcs <= (others => '0');
            else
                vcs <= vcs + 1;
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------
-- GENERATION DES SIGNAUX DE SORTIE
------------------------------------------------------------
hsync <= '0' when hcs < 96 else '1';
vsync <= '0' when vcs < 2 else '1';

vidon <= '1' when ( ((hcs < hfp) and (hcs >= hbp)) and ((vcs < vfp) and (vcs >= vbp)) ) else '0';
    
hc <= std_logic_vector(hcs);
vc <= std_logic_vector(vcs);

end Behavioral;
