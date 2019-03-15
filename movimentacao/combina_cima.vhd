library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.Common.all;

-- combina os valores recebidos
entity combina_cima is
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic := '0'
	);
end combina_cima;
 
architecture Behavioral of combina_cima is

	component shift_register
		port(
			clk     : in  std_logic;
			en	: in  std_logic;
			par_in  : in  std_logic_vector(11 downto 0);
			par_out : out std_logic_vector(11 downto 0)
		);
	end component;
	
	signal Q_shift: Q_array;
--	signal fim_comb : std_logic := '0';
	signal fim_cima			: std_logic := '0';
	
	
begin 
	process (clock_50)
		variable comb : std_logic_vector (11 DOWNTO 0) := x"000";	
		variable Q_mid : Q_array;
		variable fim_comb : std_logic := '0';
	begin

		if clock_50'event and clock_50 = '1' then
			fim_comb := '0';
			Q_mid := Q_in;
			if (enable = '1') then								-- caso clicou para cima
				--trata primeira coluna
				if((Q_in(0) = Q_in(4)) and (Q_in(0) > x"000")) then --TODO or
					comb(0) := '1'; 
					Q_mid(0):=Q_shift(0);
					Q_mid(4):=x"000";
				else 
					comb(0) := '0';
				end if;
				
				if((Q_in(4) = Q_in(8)) and (Q_in(4) > x"000")) then
					if (comb(0) = '0') then
						comb(1) := '1'; 
						Q_mid(4):=Q_shift(4);
						Q_mid(8):=x"000";
					else
						comb(1):='0';
					end if;
				else 
					comb(1):='0';
				end if;
				
				if((Q_in(8) = Q_in(12)) and (Q_in(8) > x"000")) then
					if (comb(1)='0') then
						comb(2):='1';
						Q_mid(8):=Q_shift(8);
						Q_mid(12):=x"000";
					else
						comb(2):='0';
					end if;
				else 
					comb(2):='0';
				end if;
				
				--trata segunda coluna
				if((Q_in(1) = Q_in(5)) and (Q_in(1) > x"000")) then
					comb(3):='1'; 
					Q_mid(1):=Q_shift(1);
					Q_mid(5):=x"000";
				else 
					comb(3):='0';
				end if;
				
				if((Q_in(5) = Q_in(9)) and (Q_in(5) > x"000")) then
					if (comb(3)='0') then
						comb(4):='1'; 
						Q_mid(5):=Q_shift(5);
						Q_mid(9):=x"000";
					else 
						comb(4):='0';
					end if;
				else 
					comb(4):='0';
				end if;
				
				if((Q_in(9) = Q_in(13)) and (Q_in(9) > x"000")) then
					if (comb(4)='0') then
						comb(5):='1';
						Q_mid(9):=Q_shift(9);
						Q_mid(13):=x"000";
					else
						comb(5):='0';
					end if;
				else 
					comb(5):='0';
				end if;
				
				--trata terceira coluna
				if((Q_in(2) = Q_in(6)) and (Q_in(2) > x"000")) then
					comb(6):='1';
					Q_mid(2):=Q_shift(2);
					Q_mid(6):=x"000"; 
				else 
					comb(6):='0';
				end if;
				
				if((Q_in(6) = Q_in(10)) and (Q_in(6) > x"000")) then
					if (comb(6)='0') then
						comb(7):='1'; 
						Q_mid(6):=Q_shift(6);
						Q_mid(10):=x"000";
					else 
						comb(7):='0';
					end if;
				else 
					comb(7):='0';
				end if;
				
				if((Q_in(10) = Q_in(14)) and (Q_in(10) > x"000")) then
					if (comb(7)='0') then
						comb(8):='1';
						Q_mid(10):=Q_shift(10);
						Q_mid(14):=x"000";
					else
						comb(8):='0';
					end if;
				else 
					comb(8):='0';
				end if;

				--trata quarta coluna
				if((Q_in(3) = Q_in(7)) and (Q_in(3) > x"000")) then
					comb(9):='1';
					Q_mid(3):=Q_shift(3);
					Q_mid(7):=x"000";
				else 
					comb(9):='0';
				end if;
				
				if((Q_in(7) = Q_in(11)) and (Q_in(7) > x"000")) then
					if (comb(9)='0') then
						comb(10):='1'; 
						Q_mid(7):=Q_shift(7);
						Q_mid(11):=x"000";
					else 
						comb(10):='0';
					end if;
				else 
					comb(10):='0';
				end if;
				
				if((Q_in(11) = Q_in(15)) and (Q_in(11) > x"000")) then
					if (comb(10)='0') then
						comb(11):='1';
						Q_mid(11):=Q_shift(11);
						Q_mid(15):=x"000";
					else
						comb(11):='0';
					end if;
				else 
					comb(11):='0';
				end if;
				fim_comb := '1';
				fim_cima <= fim_comb;
			end if;	
		Q_out<=Q_mid;
		end if;

	end process;
	
	
	with fim_cima select
		fim <= '1' when '1',
				 '0' when others;

	
	---------------------------------------------------------------------------
	
	-- Quadrado 0 e 4
	shift_left_0: shift_register port map (
		clock_50,
		'1',
		Q_in(0),
		Q_shift(0)
	);	

	-- Quadrado 4 e 8
	shift_left_1: shift_register port map (
		clock_50,
		'1',
		Q_in(4),
		Q_shift(4)
	);	
	
	-- Quadrado 8 e 12
	shift_left_2: shift_register port map (
		clock_50,
		'1',
		Q_in(8),
		Q_shift(8)
	);	

	-- Quadrado 1 e 5
	shift_left_3: shift_register port map (
		clock_50,
		'1',
		Q_in(1),
		Q_shift(1)
	);	
	
	-- Quadrado 5 e 9
	shift_left_4: shift_register port map (
		clock_50,
		'1',
		Q_in(5),
		Q_shift(5)
	);	
	
	-- Quadrado 9 e 13
	shift_left_5: shift_register port map (
		clock_50,
		'1',
		Q_in(9),
		Q_shift(9)
	);	
	
	-- Quadrado 2 e 6
	shift_left_6: shift_register port map (
		clock_50,
		'1',
		Q_in(2),
		Q_shift(2)
	);	
		
	-- Quadrado 6 e 10
	shift_left_7: shift_register port map (
		clock_50,
		'1',
		Q_in(6),
		Q_shift(6)
	);	
	
	-- Quadrado 10 e 14
	shift_left_8: shift_register port map (
		clock_50,
		'1',
		Q_in(10),
		Q_shift(10)
	);
	
	-- Quadrado 3 e 7
	shift_left_9: shift_register port map (
		clock_50,
		'1',
		Q_in(3),
		Q_shift(3)
	);	
	
	-- Quadrado 7 e 11
	shift_left_10: shift_register port map (
		clock_50,
		'1',
		Q_in(7),
		Q_shift(7)
	);	
		
	-- Quadrado 11 e 15
	shift_left_11: shift_register port map (
		clock_50,
		'1',
		Q_in(11),
		Q_shift(11)
	);	

 end Behavioral;