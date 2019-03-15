library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.Common.all;
 
entity junta_cima is
	port(
		clock_50	: in std_logic;
        enable		: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim			: out std_logic := '0'
	);
end junta_cima;
 
architecture Behavioral of junta_cima is

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
			-- caso clicou para cima
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						if (Q_temp(i + (j*4))=x"000") then							-- verifica o quadrado se eh 0
							k := i + ((j+1) * 4);										-- k eh o proximo valor abaixo 
							while ((k < (13+i)) and (Q_temp(k)=x"000")) loop		-- procura o proximo numero abaixo diferente de 0
								k:=k+4;
							end loop;			
							if (k<(16)) then
								if (not(Q_temp(k) = x"000")) then					-- verifica o quadrado atual Q_temp(k) eh diferente de 0 TODO
									temp:= Q_temp(k);
									Q_temp(k):=x"000";
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
