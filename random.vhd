library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
 
entity random is
port (
      clk : in std_logic;
      random_num : out std_logic_vector (3 downto 0);   --output vector  
		random_int : out integer range 0 to 15
    );
end random;
 
architecture Behavioral of random is
	signal contador : std_logic_vector(3 downto 0) := "0000";
begin
  process(clk)
  begin
    if clk'event and clk='1' then
      contador <= contador + '1'; 
    end if;
    random_num <= contador;
	random_int <= to_integer(unsigned(contador));
  end process;
end Behavioral;
