----------------------------------------------------------------
-- Peripheral Example
-- Theo Soriano
-- Update: 15-05-23
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library amba3;
use amba3.ahblite.all;

----------------------------------------------------------------
entity ahblite_my_periph is
port (
	HRESETn     : in  std_logic;
	HCLK        : in  std_logic;

	HSEL        : in  std_logic;
	HREADY      : in  std_logic;
	
	seg         : out std_logic_vector(0 to 6);
	dp          :out std_logic;
	an          : out std_logic_vector(3 downto 0);
	-- AHB-Lite interface
	AHBLITE_IN  : in  AHBLite_master_vector;
	AHBLITE_OUT : out AHBLite_slave_vector);

end;

----------------------------------------------------------------
architecture arch of ahblite_my_periph is

	signal transfer : std_logic;
	signal invalid  : std_logic;
	signal SlaveIn  : AHBLite_master;
	signal SlaveOut : AHBLite_slave;

	signal address  : std_logic_vector(9 downto 2);
	signal lastaddr : std_logic_vector(9 downto 2);
	signal lastwr   : std_logic;
	signal RST : std_logic;

	-- Memory organization:
	-- +--------+--------+---------------------------+
	-- | OFFSET | NAME   | DESCRIPTION               |
	-- +--------+--------+---------------------------+
	-- |  x000  | REG1   | First Register       	 |
	-- |  x004  | REG2   | Second Register      	 |
	-- +--------+--------+---------------------------+

	signal Reg1    : std_logic_vector(31 downto 0);
	signal Reg2    : std_logic_vector(31 downto 0);
	signal Reg3    : std_logic_vector(31 downto 0);
	signal Reg4    : std_logic_vector(31 downto 0);

component seg_top is
    Port ( mclk : in STD_LOGIC;
           rst : in STD_LOGIC;
           E1 : in STD_LOGIC_VECTOR (3 downto 0);
           E2 : in STD_LOGIC_VECTOR (3 downto 0);
           E3 : in STD_LOGIC_VECTOR (3 downto 0);
           E4 : in STD_LOGIC_VECTOR (3 downto 0);
           seg : out STD_LOGIC_VECTOR (0 to 6);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           dp : out STD_LOGIC);
end component;
----------------------------------------------------------------
begin

	AHBLITE_OUT <= to_vector(SlaveOut);
	SlaveIn <= to_record(AHBLITE_IN);

	transfer <= HSEL and SlaveIn.HTRANS(1) and HREADY;
	-- Invalid if not a 32-bit aligned transfer
	invalid  <= transfer and (SlaveIn.HSIZE(2) or (not SlaveIn.HSIZE(1)) or SlaveIn.HSIZE(0) or SlaveIn.HADDR(1) or SlaveIn.HADDR(0));

	address <= SlaveIn.HADDR(address'range);

    U_SEG_CTRL: seg_top
    Port map (
        mclk => HCLK,
        rst => RST,
        --E1 => Reg1(3 downto 0),
--        E2 => Reg2(3 downto 0),
--        E3 => Reg3(3 downto 0),
--        E4 => Reg4(3 downto 0),
          E1 => Reg1(15 downto 12), 
          E2 => Reg1(11 downto 8),
          E3 => Reg1(7 downto 4),
          E4 => Reg1(3 downto 0),

        seg => seg,
        an => an,
        dp => dp);

    RST <= not HRESETn;
	----------------------------------------------------------------
	process (HCLK, HRESETn) begin
		if HRESETn = '0' then
			-- Reset
			SlaveOut.HREADYOUT <= '1';
			SlaveOut.HRESP <= '0';
			SlaveOut.HRDATA <= (others => '0');

			lastwr <= '0';
			lastaddr <= (others => '0');

			-- Reset values
			Reg1 <= (others => '0');
			Reg2 <= (others => '0');
			Reg3 <= (others => '0');
			Reg4 <= (others => '0');


		--------------------------------
		elsif rising_edge(HCLK) then
			-- Error management
			SlaveOut.HREADYOUT <= not invalid;
			SlaveOut.HRESP <= invalid or not SlaveOut.HREADYOUT;

			-- Performe write if requested last cycle and no error occured
			if SlaveOut.HRESP = '0' and lastwr = '1' then
				case lastaddr is
					when x"00" => Reg1    <= SlaveIn.HWDATA;
					when x"01" => Reg2    <= SlaveIn.HWDATA;
					when x"02" => Reg3   <= SlaveIn.HWDATA;
					when x"03" => Reg4    <= SlaveIn.HWDATA;

					when others =>
				end case;
			end if;

			-- Check for transfer
			if transfer = '1' and invalid = '0' then
				-- Read operation: retrieve data and fill empty spaces with '0'
				if SlaveIn.HWRITE = '0' then
					SlaveOut.HRDATA <= (others => '0');
					case address is
						when x"00" => SlaveOut.HRDATA    <= Reg1;
						when x"01" => SlaveOut.HRDATA    <= Reg2;
						when x"02" => SlaveOut.HRDATA    <= Reg3;
						when x"03" => SlaveOut.HRDATA    <= Reg4;
						when others =>
					end case;
				end if;

				-- Keep address and write command for next cycle
				lastaddr <= address;
				lastwr <= SlaveIn.HWRITE;
			else
				lastwr <= '0';
			end if;
		end if;
	end process;

end;
