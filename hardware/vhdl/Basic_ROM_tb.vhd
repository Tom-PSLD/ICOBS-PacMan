library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Basic_ROM_TB is
-- Testbench doesn't need ports
end Basic_ROM_TB;

architecture Behavioral of Basic_ROM_TB is

    -- Component Declaration
    component Basic_ROM
        Port ( addr : in  STD_LOGIC_VECTOR (3 downto 0);
               M : out  STD_LOGIC_VECTOR (11 downto 0));
    end component;

    -- Signal Declaration
    signal tb_addr : STD_LOGIC_VECTOR(3 downto 0);
    signal tb_M : STD_LOGIC_VECTOR(11 downto 0);

begin

    -- Component Instantiation
    UUT: Basic_ROM Port Map (
        addr => tb_addr,
        M => tb_M
    );

    -- Test Stimulus
stim_proc: process
begin
    report "Début de la simulation de Basic_ROM...";

    -- Boucle pour tester toutes les adresses de 0 à 15
    for i in 0 to 15 loop
        -- Convertit l'entier 'i' en un std_logic_vector de 4 bits
        tb_addr <= std_logic_vector(to_unsigned(i, 4));
        
        -- Attend 100 ns pour que le signal se propage et que le résultat soit visible
        wait for 100 ns;
    end loop;

    report "Fin de la simulation.";
    wait; -- Attend indéfiniment pour terminer la simulation proprement
end process stim_proc;

end Behavioral;
