library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.Common.all;
 
entity junta_baixo is
	port(
		clock_50	: in std_logic;
        enable		: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim			: out std_logic := '0'
	);
end junta_baixo;
 
architecture Behavioral of junta_baixo is
	signal Q_saida: Q_array;
begin 
	process (clock_50)
		variable k: integer;
		variable Q_temp: Q_array;
		variable temp: std_logic_vector (11 downto 0);
		variable fim_process: std_logic := '0';
	begin
		if clock_50'event and clock_50 = '1' then
			fim_process := '0';
			Q_temp := Q_in;
			if (enable = '1') then	
				for i in 3 downto 0 loop
					for j in 3 downto 0 loop
						if (Q_temp(i+(j*4))=x"000") then
							k:=i+((j-1)*4);
							while (k >= 0 and (Q_temp(k)=x"000")) loop
								k:=k-4;
							end loop;
							if (k>=(0)) then
								if (not(Q_temp(k)=x"000")) then
									temp:= Q_temp(k);
									Q_temp(k) := x"000";
									Q_temp(i+(j*4)):=temp;
								end if;
							end if;
						end if;
					end loop;
				end loop;
				fim_process := '1';
			end if;	
			fim <= fim_process;	
		end if;
		Q_saida <= Q_temp;
	end process;
	Q_out<=Q_saida;
	
end Behavioral;
