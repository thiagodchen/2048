library ieee;
use ieee.std_logic_1164.all;

entity shift_register is
port(
    clk     : in  std_logic;
	en		: in	std_logic;
    par_in  : in  std_logic_vector(11 downto 0);
    par_out : out std_logic_vector(11 downto 0)
  );
end shift_register;

architecture rtl of shift_register is
begin

	with par_in select 
		par_out <=  "000000000010" when "000000000001",
						"000000000100" when "000000000010",
						"000000001000" when "000000000100",
						"000000010000" when "000000001000",
						"000000100000" when "000000010000",
						"000001000000" when "000000100000",
						"000010000000" when "000001000000",
						"000100000000" when "000010000000",
						"001000000000" when "000100000000",
						"010000000000" when "001000000000",
						"100000000000" when "010000000000",
						"000000000000" when others;
end rtl;
