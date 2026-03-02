

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Basic_ROM is
    Port ( 
        clk              : in  STD_LOGIC;
        reset            : in  STD_LOGIC;
        game_reset       : in  STD_LOGIC; 
        vidon            : in  STD_LOGIC;
        hc               : in  STD_LOGIC_VECTOR (9 downto 0);
        vc               : in  STD_LOGIC_VECTOR (9 downto 0);
        
        -- Coordonnées
        x1, y1           : in  STD_LOGIC_VECTOR (31 downto 0);
        x2, y2           : in  STD_LOGIC_VECTOR (31 downto 0);
        x3, y3           : in  STD_LOGIC_VECTOR (31 downto 0);
        x4, y4           : in  STD_LOGIC_VECTOR (31 downto 0); 
        x5, y5           : in  STD_LOGIC_VECTOR (31 downto 0);
        x6, y6           : in  STD_LOGIC_VECTOR (31 downto 0); 
        
        background_color : in  STD_LOGIC_VECTOR (11 downto 0);
        
        -- Données Pixels
        sprite_1         : in  STD_LOGIC_VECTOR (10 downto 0);
        sprite_2         : in  STD_LOGIC_VECTOR (9 downto 0);
        sprite_3         : in  STD_LOGIC_VECTOR (9 downto 0);
        sprite_4         : in  STD_LOGIC_VECTOR (12 downto 0); 
        sprite_5         : in  STD_LOGIC_VECTOR (13 downto 0);
        sprite_6         : in  STD_LOGIC_VECTOR (9 downto 0); 
        
        -- Adresses ROM
        rom_addr4_s1     : out STD_LOGIC_VECTOR (10 downto 0);
        rom_addr4_s2     : out STD_LOGIC_VECTOR (9 downto 0);
        rom_addr4_s3     : out STD_LOGIC_VECTOR (9 downto 0);
        rom_addr4_s4     : out STD_LOGIC_VECTOR (12 downto 0);
        rom_addr4_s5     : out STD_LOGIC_VECTOR (13 downto 0);
        rom_addr4_s6     : out STD_LOGIC_VECTOR (9 downto 0);  
        
        red              : out STD_LOGIC_VECTOR (3 downto 0);
        green            : out STD_LOGIC_VECTOR (3 downto 0);
        blue             : out STD_LOGIC_VECTOR (3 downto 0)
    );
end VGA_Basic_ROM;

architecture Behavioral of VGA_Basic_ROM is

    -- CONSTANTES TIMING
    constant hbp : unsigned(9 downto 0) := "0010010000"; -- 144
    constant vbp : unsigned(9 downto 0) := "0000100001"; -- 33

    -- DIMENSIONS SPRITES
    constant w1 : unsigned(9 downto 0) := to_unsigned(38, 10); constant h1 : unsigned(9 downto 0) := to_unsigned(29, 10);
    constant w2 : unsigned(9 downto 0) := to_unsigned(25, 10); constant h2 : unsigned(9 downto 0) := to_unsigned(25, 10);
    constant w3 : unsigned(9 downto 0) := to_unsigned(25, 10); constant h3 : unsigned(9 downto 0) := to_unsigned(25, 10);
    constant w4 : unsigned(9 downto 0) := to_unsigned(85, 10); constant h4 : unsigned(9 downto 0) := to_unsigned(85, 10);
    constant w5 : unsigned(9 downto 0) := to_unsigned(168, 10); constant h5 : unsigned(9 downto 0) := to_unsigned(81, 10);
    constant w6 : unsigned(9 downto 0) := to_unsigned(29, 10); constant h6 : unsigned(9 downto 0) := to_unsigned(21, 10); 
    
   
    type t_map_array is array (0 to 14) of std_logic_vector(0 to 19);
   

    constant map_grid : t_map_array := (
        "11111111111111111111", -- 0
        "10000010000000100001", -- 1
        "10111010111110101111", -- 2 
        "10100000001000000001", -- 3
        "10101110101011101011", -- 4 
        "10000000101000000001", -- 5
        "11111011111110111111", -- 6
        "00000010000010000000", -- 7 
        "11111011111110111111", -- 8
        "10000000000000000001", -- 9
        "10111011101110111011", -- 10
        "10001000000000100001", -- 11
        "11101010111010101111", -- 12 
        "10000010000010000001", -- 13
        "11111111111111111111"  -- 14
    );

    constant init_dots : t_map_array := (
        "00000000000000000000", -- 0
        "01111101111111011110", -- 1
        "01000101000001010000", -- 2
        "01011111110111111110", -- 3
        "01010001010100010100", -- 4
        "01111111010111111110", -- 5
        "00000100000001000000", -- 6 
        "00000000000000000000", -- 7 
        "00000100000001000000", -- 8 
        "01111111111111111110", -- 9
        "01000100010001000100", -- 10
        "01110111111111011110", -- 11
        "00010101000101010000", -- 12
        "01111101111101111110", -- 13
        "00000000000000000000"  -- 14
    );

    signal dot_memory : t_map_array := init_dots;

    -- SIGNALS
    signal x1_u, y1_u, xpix1, ypix1, x2_u, y2_u, xpix2, ypix2, x3_u, y3_u, xpix3, ypix3 : unsigned(9 downto 0);
    signal x4_u, y4_u, xpix4, ypix4, x5_u, y5_u, xpix5, ypix5, x6_u, y6_u, xpix6, ypix6 : unsigned(9 downto 0);
    
    signal spriteon_1, spriteon_2, spriteon_3, spriteon_4, spriteon_5, spriteon_6 : STD_LOGIC;
    signal rom_addr_s1, rom_addr_s2, rom_addr_s3, rom_addr_s4, rom_addr_s5, rom_addr_s6 : std_logic_vector(19 downto 0);
    signal active_x, active_y : unsigned(9 downto 0);
    signal grid_col, grid_row, tile_x, tile_y : integer range 0 to 31;
    signal current_is_wall, wall_n, wall_s, wall_e, wall_w, draw_wall, draw_dot : STD_LOGIC;

begin
    -- SPRITES LOGIC
    x1_u <= unsigned(x1(9 downto 0)); 
    y1_u <= unsigned(y1(9 downto 0));
    x2_u <= unsigned(x2(9 downto 0)); 
    y2_u <= unsigned(y2(9 downto 0));
    x3_u <= unsigned(x3(9 downto 0)); 
    y3_u <= unsigned(y3(9 downto 0));
    x4_u <= unsigned(x4(9 downto 0)); 
    y4_u <= unsigned(y4(9 downto 0));
    x5_u <= unsigned(x5(9 downto 0)); 
    y5_u <= unsigned(y5(9 downto 0));
    x6_u <= unsigned(x6(9 downto 0)); 
    y6_u <= unsigned(y6(9 downto 0));

    xpix1 <= unsigned(hc)-(x1_u+hbp); 
    ypix1 <= unsigned(vc)-(y1_u+vbp);
    xpix2 <= unsigned(hc)-(x2_u+hbp); 
    ypix2 <= unsigned(vc)-(y2_u+vbp);
    xpix3 <= unsigned(hc)-(x3_u+hbp); 
    ypix3 <= unsigned(vc)-(y3_u+vbp);
    xpix4 <= unsigned(hc)-(x4_u+hbp); 
    ypix4 <= unsigned(vc)-(y4_u+vbp);
    xpix5 <= unsigned(hc)-(x5_u+hbp); 
    ypix5 <= unsigned(vc)-(y5_u+vbp);
    xpix6 <= unsigned(hc)-(x6_u+hbp); 
    ypix6 <= unsigned(vc)-(y6_u+vbp);

    -- ROM ADDRESSES
    rom_addr_s1 <= std_logic_vector((ypix1 * w1) + xpix1); rom_addr4_s1 <= rom_addr_s1(10 downto 0);
    rom_addr_s2 <= std_logic_vector((ypix2 * w2) + xpix2); rom_addr4_s2 <= rom_addr_s2(9 downto 0); 
    rom_addr_s3 <= std_logic_vector((ypix3 * w3) + xpix3); rom_addr4_s3 <= rom_addr_s3(9 downto 0); 
    
    -- ZOOM X2 pour Sprite 4
    rom_addr_s4 <= std_logic_vector(resize((unsigned(ypix4(9 downto 1)) * w4) + unsigned(xpix4(9 downto 1)), 20)); 
    rom_addr4_s4 <= rom_addr_s4(12 downto 0);
    
    rom_addr_s5 <= std_logic_vector((ypix5 * w5) + xpix5); rom_addr4_s5 <= rom_addr_s5(13 downto 0); 
    rom_addr_s6 <= std_logic_vector((ypix6 * w6) + xpix6); rom_addr4_s6 <= rom_addr_s6(9 downto 0);

    
    spriteon_1 <= '1' when (unsigned(hc)>x1_u+hbp) and (unsigned(hc)<=x1_u+hbp+w1) and (unsigned(vc)>=y1_u+vbp) and (unsigned(vc)<y1_u+vbp+h1) else '0';
    spriteon_2 <= '1' when (unsigned(hc)>x2_u+hbp) and (unsigned(hc)<=x2_u+hbp+w2) and (unsigned(vc)>=y2_u+vbp) and (unsigned(vc)<y2_u+vbp+h2) else '0';
    spriteon_3 <= '1' when (unsigned(hc)>x3_u+hbp) and (unsigned(hc)<=x3_u+hbp+w3) and (unsigned(vc)>=y3_u+vbp) and (unsigned(vc)<y3_u+vbp+h3) else '0';
    -- Sprite 4 x2
    spriteon_4 <= '1' when (unsigned(hc)>x4_u+hbp) and (unsigned(hc)<=x4_u+hbp+(w4*2)) and (unsigned(vc)>=y4_u+vbp) and (unsigned(vc)<y4_u+vbp+(h4*2)) else '0';
    spriteon_5 <= '1' when (unsigned(hc)>x5_u+hbp) and (unsigned(hc)<=x5_u+hbp+w5) and (unsigned(vc)>=y5_u+vbp) and (unsigned(vc)<y5_u+vbp+h5) else '0';
    spriteon_6 <= '1' when (unsigned(hc)>x6_u+hbp) and (unsigned(hc)<=x6_u+hbp+w6) and (unsigned(vc)>=y6_u+vbp) and (unsigned(vc)<y6_u+vbp+h6) else '0';

    -- LOGIC MAP
    active_x <= unsigned(hc)-hbp when unsigned(hc)>=hbp else (others=>'0'); 
    active_y <= unsigned(vc)-vbp when unsigned(vc)>=vbp else (others=>'0');
    grid_col <= to_integer(active_x(9 downto 5)); grid_row <= to_integer(active_y(9 downto 5));
    tile_x <= to_integer(active_x(4 downto 0)); tile_y <= to_integer(active_y(4 downto 0));
    
    -- GESTION GOMMES AVEC RESET
    process(clk, reset, game_reset)
        variable pm_grid_x, pm_grid_y : integer;
    begin
        if reset='1' or game_reset='1' then 
            dot_memory <= init_dots;
        elsif rising_edge(clk) then
            pm_grid_x := to_integer(x1_u+16)/32; pm_grid_y := to_integer(y1_u+16)/32;
            if (pm_grid_y>=0 and pm_grid_y<=14) and (pm_grid_x>=0 and pm_grid_x<=19) then 
                dot_memory(pm_grid_y)(pm_grid_x)<='0'; 
            end if;
        end if;
    end process;

    process(grid_col, grid_row) -- MURS
    begin
        current_is_wall <= '0'; wall_n <= '0'; wall_s <= '0'; wall_e <= '0'; wall_w <= '0';
        if (grid_row>=0 and grid_row<=14) and (grid_col>=0 and grid_col<=19) then
            current_is_wall <= map_grid(grid_row)(grid_col);
            if (grid_row=13 and grid_col=19) then current_is_wall <= '1'; end if;
            if grid_row>0 then wall_n<=map_grid(grid_row-1)(grid_col); else wall_n<='1'; end if;
            if grid_row<14 then wall_s<=map_grid(grid_row+1)(grid_col); else wall_s<='1'; end if;
            if grid_col>0 then wall_w<=map_grid(grid_row)(grid_col-1); else wall_w<='1'; if grid_row=7 then wall_w<='0'; end if; end if;
            if grid_col<19 then wall_e<=map_grid(grid_row)(grid_col+1); else wall_e<='1'; if grid_row=7 then wall_e<='0'; end if; end if;
        end if;
    end process;

    process(current_is_wall, tile_x, tile_y, wall_n, wall_s, wall_e, wall_w, grid_row, grid_col, dot_memory) -- DRAW
        variable draw_w : boolean; constant THICK : integer := 4; variable is_center_tile : boolean;
    begin
        draw_w:=false; draw_wall<='0'; draw_dot<='0';
        if current_is_wall='1' then
            if (tile_x<THICK and wall_w='0') or (tile_x>=32-THICK and wall_e='0') or (tile_y<THICK and wall_n='0') or (tile_y>=32-THICK and wall_s='0') then draw_w:=true; end if;
        end if;
        if (grid_row=0 and tile_y<THICK) or (grid_row=14 and tile_y>=32-THICK) then draw_w:=true; 
        end if;
        if (grid_col=0 and tile_x<THICK and grid_row/=7) or (grid_col=19 and tile_x>=32-THICK and grid_row/=7) then draw_w:=true; 
        end if;
        if draw_w then draw_wall<='1'; 
        end if;
        if (tile_x>=14 and tile_x<=17) and (tile_y>=14 and tile_y<=17) then is_center_tile:=true; 
        else is_center_tile:=false; 
        end if;
        if (grid_row>=0 and grid_row<=14) and (grid_col>=0 and grid_col<=19) then
            if is_center_tile and dot_memory(grid_row)(grid_col)='1' then draw_dot<='1'; 
            end if;
        end if;
    end process;

    process(vidon, spriteon_1, spriteon_2, spriteon_3, spriteon_4, spriteon_5, spriteon_6, sprite_1, sprite_2, sprite_3, sprite_4, sprite_5, sprite_6, background_color, draw_wall, draw_dot)
        variable is_black_1, is_black_2, is_black_3, is_black_4, is_black_5, is_black_6 : boolean;
    begin
        red <= (others => '0'); green <= (others => '0'); blue <= (others => '0');
        if vidon='1' then
            is_black_1:=(unsigned(sprite_1)=0); is_black_2:=(unsigned(sprite_2)=0); is_black_3:=(unsigned(sprite_3)=0);
            is_black_4:=(unsigned(sprite_4)=0); is_black_5:=(unsigned(sprite_5)=0); 
            is_black_6:=(unsigned(sprite_6)=0);

            if spriteon_4='1' and not is_black_4 then red<=sprite_4(11 downto 8); green<=sprite_4(7 downto 4); blue<=sprite_4(3 downto 0);
            
            -- Sprite 6 (Prioritaire sur les murs)
            elsif spriteon_6='1' and not is_black_6 then 
                red<=sprite_6(9 downto 7)&'0'; green<=sprite_6(6 downto 3); blue<=sprite_6(2 downto 0)&'0';

            elsif spriteon_1='1' and not is_black_1 then red<=sprite_1(10 downto 8)&'0'; 
            green<=sprite_1(7 downto 4); blue<=sprite_1(3 downto 0);
            elsif spriteon_2='1' and not is_black_2 then red<=sprite_2(9 downto 7)&'0'; 
            green<=sprite_2(6 downto 3); blue<=sprite_2(2 downto 0)&'0';
            elsif spriteon_3='1' and not is_black_3 then red<=sprite_3(9 downto 7)&'0'; 
            green<=sprite_3(6 downto 3); blue<=sprite_3(2 downto 0)&'0';
            elsif spriteon_5='1' and not is_black_5 then red<=sprite_5(11 downto 8); 
            green<=sprite_5(7 downto 4); blue<=sprite_5(3 downto 0);
            
            elsif draw_wall='1' then 
                red<=x"0"; green<=x"0"; blue<=x"F";
            elsif draw_dot='1' then 
                red<=x"F"; green<=x"F"; blue<=x"0";
            else 
                red<=x"0"; green<=x"0"; blue<=x"0"; end if;
        end if;
    end process;
end Behavioral;