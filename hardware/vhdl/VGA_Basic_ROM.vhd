library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Basic_ROM is
    Port ( vidon : in STD_LOGIC;                         -- '1' lorsque dans la zone d'affichage active de l'�cran
           hc : in STD_LOGIC_VECTOR (9 downto 0);        -- Compteur de pixels horizontal du contr�leur VGA
           vc : in STD_LOGIC_VECTOR (9 downto 0);        -- Compteur de lignes vertical du contr�leur VGA
           rom_addr5: out std_logic_vector(15 downto 0); -- Adresse de 4 bits pour la ROM externe du sprite
           x,y : in integer;
           M: in std_logic_vector(11 downto 0);        -- Donn�e de couleur 12 bits lue depuis la ROM
           red : out STD_LOGIC_VECTOR (3 downto 0);      -- Sortie de couleur Rouge 4 bits pour le DAC (Convertisseur Num�rique-Analogique)
           green : out STD_LOGIC_VECTOR (3 downto 0);    -- Sortie de couleur Verte 4 bits pour le DAC
           blue : out STD_LOGIC_VECTOR (3 downto 0));     -- Sortie de couleur Bleue 4 bits pour le DAC
end VGA_Basic_ROM;

architecture Behavioral of VGA_Basic_ROM is
    
    -- Cette architecture d�crit un module pour afficher un petit sprite de 4x4 pixels sur un �cran VGA.
    -- Il calcule l'adresse ROM pour le sprite en fonction de sa position et des compteurs VGA,
    -- puis multiplexe entre la couleur du sprite et une couleur de fond.

    -- Signaux & Constantes
    
    -- Constantes de synchronisation VGA pour d�finir le d�but de la zone visible
    constant hbp: unsigned(9 downto 0) := "0010010000"; -- back porch horizontal (144 pixels)
    constant vbp: unsigned(9 downto 0) := "0000011111"; -- Back porch vertical (31 lignes)

    -- Dimensions du sprite
    constant w: unsigned(9 downto 0) := to_unsigned(240, 10); -- Largeur du sprite = 4 pixels
    constant h: unsigned(9 downto 0) := to_unsigned(160, 10); -- Hauteur du sprite = 4 pixels

    -- Signaux interm�diaires pour les calculs
    signal spriteon: STD_LOGIC;                          -- Drapeau : '1' si le pixel courant est dans la zone du sprite
    signal xpix, ypix: unsigned(9 downto 0);             -- Coordonn�es relatives du pixel � l'int�rieur du sprite (x,y)
    signal R1, C1: UNSIGNED (9 downto 0);                 -- Coordonn�es du coin sup�rieur gauche du sprite (Ligne, Colonne)
    signal rom_addr_s: std_logic_vector(19 downto 0);     -- Adresse compl�te lin�aris�e pour la m�moire des pixels du sprite

begin


    R1 <= TO_UNSIGNED (x,10); 
    C1 <= TO_UNSIGNED(Y,10); 

    xpix <= unsigned(hc) - (hbp + C1);
    ypix <= unsigned(vc) - (vbp + R1);

    -- ## 3. Calcul de l'Adresse ROM (Conversion 2D vers 1D) ##
    -- Convertit les coordonn�es relatives 2D (ypix, xpix) en une seule adresse m�moire lin�aire.
    -- La formule est : adresse = (ligne * largeur) + colonne
    rom_addr_s <= std_logic_vector((ypix * w) + xpix);

    -- Ne sort que les 4 bits de poids faible de l'adresse.
    -- C'est parce que notre sprite fait 4x4 = 16 pixels, ce qui ne n�cessite que 4 bits d'adresse (2^4 = 16).
    rom_addr5 <= rom_addr_s(15 downto 0);

    -- ## 4. D�tection de la Zone du Sprite ##
    -- C'est une v�rification de limites. Elle active le drapeau 'spriteon' � '1' uniquement lorsque
    -- le balayage VGA se trouve � l'int�rieur du rectangle du sprite. Sinon, il est � '0'.
    spriteon <= '1' when (unsigned(hc) >= C1 + hbp and unsigned(hc) < C1 + hbp + w and
                         unsigned(vc) >= R1 + vbp and unsigned(vc) < R1 + vbp + h)
                else '0';

    -- ## 5. Multiplexeur de Couleur Final ##
    -- Ce processus d�termine la couleur RVB finale � envoyer � l'�cran pour chaque pixel.
    process(spriteon, vidon, M)
    begin
        -- La couleur par d�faut est le noir. Elle est utilis�e pour les zones non visibles (quand vidon = '0').
        red <= (others => '0');
        green <= (others => '0');
        blue <= (others => '0');
    
        if vidon = '1' and spriteon = '1' then
            -- Condition : Nous sommes dans la zone d'affichage active ET � l'int�rieur des limites du sprite.
            -- Action : Afficher la couleur du pixel du sprite lue depuis la ROM (M).
            red <= M(11 downto 8);
            green <= M(7 downto 4);
            blue <= M(3 downto 0);
            
        elsif vidon = '1' then
            -- Condition : Nous sommes dans la zone d'affichage active MAIS � l'ext�rieur des limites du sprite.
            -- Action : Afficher la couleur de fond unie (ici, le bleu).
            red <= (others => '0');
            green <= (others => '0');
            blue <= "1111"; -- Bleu uni
        end if;
    end process;

end Behavioral;