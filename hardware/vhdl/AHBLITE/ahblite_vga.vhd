library ieee;
use ieee.std_logic_1164.all;
library amba3;
use amba3.ahblite.all;
use IEEE.NUMERIC_STD.ALL;

entity ahblite_vga is
    port (
        HRESETn, HCLK, HSEL, HREADY : in std_logic;
        hsync, vsync : out std_logic;
        red, green, blue : out std_logic_vector(3 downto 0);
        AHBLITE_IN : in AHBLite_master_vector;
        AHBLITE_OUT : out AHBLite_slave_vector
    );
end entity;

architecture arch of ahblite_vga is
    component VGA_Clock is port (reset: in std_logic; clk50: in std_logic; clk_25: out std_logic); end component;
    component VGA_640_x_480 is port (rst, clk: in std_logic; hsync, vsync: out std_logic; hc, vc: out std_logic_vector(9 downto 0); vidon: out std_logic); end component;

    component prom_sprite_1 port (addra: in std_logic_vector(10 downto 0); clka: in std_logic; douta: out std_logic_vector(10 downto 0)); end component;
    component prom_sprite_2 port (addra: in std_logic_vector(9 downto 0); clka: in std_logic; douta: out std_logic_vector(9 downto 0)); end component;
    component prom_sprite_3 port (addra: in std_logic_vector(9 downto 0); clka: in std_logic; douta: out std_logic_vector(9 downto 0)); end component;
    component prom_sprite_4 port (addra: in std_logic_vector(12 downto 0); clka: in std_logic; douta: out std_logic_vector(12 downto 0)); end component;
    component prom_sprite_5 port (addra: in std_logic_vector(13 downto 0); clka: in std_logic; douta: out std_logic_vector(13 downto 0)); end component;
    component prom_sprite_6 port (addra: in std_logic_vector(9 downto 0); clka: in std_logic; douta: out std_logic_vector(9 downto 0)); end component;

    component VGA_Basic_ROM is
        port (
            clk, reset, vidon: in std_logic; 
            game_reset: in std_logic; -- PORT CONNECTÉ AU BIT 31
            hc, vc: in std_logic_vector(9 downto 0);
            x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6: in std_logic_vector(31 downto 0);
            background_color: in std_logic_vector(11 downto 0);
            sprite_1: in std_logic_vector(10 downto 0);
            sprite_2, sprite_3: in std_logic_vector(9 downto 0);
            sprite_4: in std_logic_vector(12 downto 0);
            sprite_5: in std_logic_vector(13 downto 0);
            sprite_6: in std_logic_vector(9 downto 0);
            rom_addr4_s1: out std_logic_vector(10 downto 0);
            rom_addr4_s2, rom_addr4_s3: out std_logic_vector(9 downto 0);
            rom_addr4_s4: out std_logic_vector(12 downto 0);
            rom_addr4_s5: out std_logic_vector(13 downto 0);
            rom_addr4_s6: out std_logic_vector(9 downto 0);
            red, green, blue: out std_logic_vector(3 downto 0)
        );
    end component;

    signal transfer, invalid, lastwr, RST, vidon, clk_25: std_logic;
    signal SlaveIn: AHBLite_master; signal SlaveOut: AHBLite_slave;
    signal address, lastaddr: std_logic_vector(9 downto 2);
    signal hc, vc: std_logic_vector(9 downto 0);
    signal background_color: std_logic_vector(31 downto 0);
    signal X1_pos, Y1_pos, X2_pos, Y2_pos, X3_pos, Y3_pos, X4_pos, Y4_pos, X5_pos, Y5_pos, X6_pos, Y6_pos : std_logic_vector(31 downto 0);
    
    signal addr_s1, sprite_1: std_logic_vector(10 downto 0);
    signal addr_s2, addr_s3: std_logic_vector(9 downto 0); signal sprite_2, sprite_3: std_logic_vector(9 downto 0);
    signal addr_s4: std_logic_vector(12 downto 0); signal sprite_4: std_logic_vector(12 downto 0);
    signal addr_s5: std_logic_vector(13 downto 0); signal sprite_5: std_logic_vector(13 downto 0);
    signal addr_s6: std_logic_vector(9 downto 0);  signal sprite_6: std_logic_vector(9 downto 0);

begin
    U_VGA_CLOCK: VGA_Clock port map(reset=>RST, clk50=>HCLK, clk_25=>clk_25);
    U_VGA_640x480: VGA_640_x_480 port map(rst=>RST, clk=>clk_25, hsync=>hsync, vsync=>vsync, hc=>hc, vc=>vc, vidon=>vidon);
    
    U_VGA_BASIC_ROM: VGA_Basic_ROM port map(
        clk=>clk_25, reset=>RST, vidon=>vidon, hc=>hc, vc=>vc,
        game_reset => background_color(31), -- CONNEXION CRUCIALE ICI
        x1=>X1_pos, y1=>Y1_pos, x2=>X2_pos, y2=>Y2_pos, x3=>X3_pos, y3=>Y3_pos, x4=>X4_pos, y4=>Y4_pos, x5=>X5_pos, y5=>Y5_pos, x6=>X6_pos, y6=>Y6_pos,
        background_color=>background_color(11 downto 0),
        sprite_1=>sprite_1, sprite_2=>sprite_2, sprite_3=>sprite_3, sprite_4=>sprite_4, sprite_5=>sprite_5, sprite_6=>sprite_6,
        rom_addr4_s1=>addr_s1, rom_addr4_s2=>addr_s2, rom_addr4_s3=>addr_s3, rom_addr4_s4=>addr_s4, rom_addr4_s5=>addr_s5, rom_addr4_s6=>addr_s6,
        red=>red, green=>green, blue=>blue
    );

    U_PROM_SPRITE_1: prom_sprite_1 port map(addra=>addr_s1, clka=>HCLK, douta=>sprite_1);
    U_PROM_SPRITE_2: prom_sprite_2 port map(addra=>addr_s2, clka=>HCLK, douta=>sprite_2);
    U_PROM_SPRITE_3: prom_sprite_3 port map(addra=>addr_s3, clka=>HCLK, douta=>sprite_3);
    U_PROM_SPRITE_4: prom_sprite_4 port map(addra=>addr_s4, clka=>HCLK, douta=>sprite_4);
    U_PROM_SPRITE_5: prom_sprite_5 port map(addra=>addr_s5, clka=>HCLK, douta=>sprite_5);
    U_PROM_SPRITE_6: prom_sprite_6 port map(addra=>addr_s6, clka=>HCLK, douta=>sprite_6);

    AHBLITE_OUT <= to_vector(SlaveOut); SlaveIn <= to_record(AHBLITE_IN); RST <= not HRESETn;
    transfer <= HSEL and SlaveIn.HTRANS(1) and HREADY;
    invalid <= transfer and (SlaveIn.HSIZE(2) or (not SlaveIn.HSIZE(1)) or SlaveIn.HSIZE(0) or SlaveIn.HADDR(1) or SlaveIn.HADDR(0));
    address <= SlaveIn.HADDR(address'range);

    process (HCLK, HRESETn) 
    begin
        if HRESETn = '0' then
            SlaveOut.HREADYOUT<='1'; SlaveOut.HRESP<='0'; SlaveOut.HRDATA<=(others=>'0'); lastwr<='0';
            X1_pos<=std_logic_vector(to_unsigned(565,32)); Y1_pos<=std_logic_vector(to_unsigned(10,32));
            X2_pos<=std_logic_vector(to_unsigned(10,32)); Y2_pos<=std_logic_vector(to_unsigned(10,32));
            X3_pos<=std_logic_vector(to_unsigned(300,32)); Y3_pos<=std_logic_vector(to_unsigned(240,32));
            X4_pos<=(others=>'0'); Y4_pos<=(others=>'0');
            X5_pos<=std_logic_vector(to_unsigned(251,32)); Y5_pos<=std_logic_vector(to_unsigned(199,32));
            X6_pos<=std_logic_vector(to_unsigned(600,32)); Y6_pos<=std_logic_vector(to_unsigned(450,32)); -- Init S6
        elsif rising_edge(HCLK) then
            SlaveOut.HREADYOUT<=not invalid; SlaveOut.HRESP<=invalid or not SlaveOut.HREADYOUT;
            if SlaveOut.HRESP='0' and lastwr='1' then
                case lastaddr is
                    when x"00"=>background_color<=SlaveIn.HWDATA;
                    when x"01"=>X1_pos<=SlaveIn.HWDATA; when x"02"=>Y1_pos<=SlaveIn.HWDATA;
                    when x"03"=>X2_pos<=SlaveIn.HWDATA; when x"04"=>Y2_pos<=SlaveIn.HWDATA;
                    when x"05"=>X3_pos<=SlaveIn.HWDATA; when x"06"=>Y3_pos<=SlaveIn.HWDATA;
                    when x"07"=>X4_pos<=SlaveIn.HWDATA; when x"08"=>Y4_pos<=SlaveIn.HWDATA;
                    when x"09"=>X5_pos<=SlaveIn.HWDATA; when x"0A"=>Y5_pos<=SlaveIn.HWDATA;
                    when x"0B"=>X6_pos<=SlaveIn.HWDATA; when x"0C"=>Y6_pos<=SlaveIn.HWDATA;
                    when others=>null;
                end case;
            end if;
            if transfer='1' and invalid='0' then
                if SlaveIn.HWRITE='0' then
                    case address is
                        when x"00"=>SlaveOut.HRDATA<=background_color;
                        when x"01"=>SlaveOut.HRDATA<=X1_pos; when x"02"=>SlaveOut.HRDATA<=Y1_pos;
                        when x"03"=>SlaveOut.HRDATA<=X2_pos; when x"04"=>SlaveOut.HRDATA<=Y2_pos;
                        when x"05"=>SlaveOut.HRDATA<=X3_pos; when x"06"=>SlaveOut.HRDATA<=Y3_pos;
                        when x"07"=>SlaveOut.HRDATA<=X4_pos; when x"08"=>SlaveOut.HRDATA<=Y4_pos;
                        when x"09"=>SlaveOut.HRDATA<=X5_pos; when x"0A"=>SlaveOut.HRDATA<=Y5_pos;
                        when x"0B"=>SlaveOut.HRDATA<=X6_pos; when x"0C"=>SlaveOut.HRDATA<=Y6_pos;
                        when others=>SlaveOut.HRDATA<=(others=>'0');
                    end case;
                end if;
                lastaddr<=address; lastwr<=SlaveIn.HWRITE;
            else lastwr<='0'; end if;
        end if;
    end process;
end architecture;