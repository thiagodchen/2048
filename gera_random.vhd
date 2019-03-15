library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.Common.all;
 
entity gera_random is
	port(
		clk			: in std_logic;
		en			: in std_logic;
		Q			: in Q_array;
		pos_out		: out std_logic_vector(3 downto 0);
		fim			: out std_logic
	);
end gera_random;
 
architecture Behavioral of gera_random is

	component random
	port (
		clk : in std_logic;
		random_num : out std_logic_vector (3 downto 0);
		random_int : out integer range 0 to 15
		);
	end component;

	signal counter 	: integer range 0 to 1 := 0;
	signal temp			: std_logic  := '0';
	signal flag 		: std_logic_vector (15 downto 0):=x"0000";
	signal posal		: std_logic_vector (3 downto 0);
	signal posint		: integer range 15 downto 0;
	
begin
	process(clk)
		variable postemp : std_logic_vector(3 downto 0);
		variable inttemp : integer;
		variable fim_process: std_logic := '0';
	begin
	
		if clk'event and clk = '1' then
			-- segura o valor da memoria
			postemp := posal;
			inttemp := posint;
			fim_process := '0';
			
			if en = '1' then
				if (Q(inttemp) = x"000") then
					pos_out <= postemp;
					fim_process := '1';
				end if;
			end if;
		end if;
		fim <= fim_process;
	end process;

	c_random: random port map(clk, posal, posint);	

end Behavioral;
