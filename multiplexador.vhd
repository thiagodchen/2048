library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Common.all;
--
--cores:
--black	 	000
--blue		001
--green 		010
--red			100
--magenta	101
--yellow		110
--white		111

entity multiplexador is
	port (
		clock_50			: in std_logic;
		linha				: in integer range 0 to 95;
		coluna			: in integer range 0 to 127;
		Q_in				: in Q_array;
		pixel				: out std_logic_vector(2 downto 0)
	);
end multiplexador;

architecture beh of multiplexador is
	signal quadrante : integer range 0 to 16;
begin
	-- marca o quadrante que esta passar na hora de ler os pixeis
	process(clock_50, linha, coluna)
	begin
		if clock_50'event and clock_50 = '1' then
			if		(linha >= 4 and linha <= 22 and coluna >= 4 and coluna <= 22) then
				quadrante <= 0;
			elsif	(linha >= 4 and linha <= 22 and coluna >= 27 and coluna <= 45) then
				quadrante <= 1;
			elsif	(linha >= 4 and linha <= 22 and coluna >= 50 and coluna <= 68) then
				quadrante <= 2;
			elsif	(linha >= 4 and linha <= 22 and coluna >= 73 and coluna <= 91) then
				quadrante <= 3;
			elsif	(linha >= 27 and linha <= 45 and coluna >= 4 and coluna <= 22) then
				quadrante <= 4;
			elsif	(linha >= 27 and linha <= 45 and coluna >= 27 and coluna <= 45) then
				quadrante <= 5;
			elsif	(linha >= 27 and linha <= 45 and coluna >= 50 and coluna <= 68) then
				quadrante <= 6;
			elsif	(linha >= 27 and linha <= 45 and coluna >= 73 and coluna <= 91) then
				quadrante <= 7;
			elsif	(linha >= 50 and linha <= 68 and coluna >= 4 and coluna <= 22) then
				quadrante <= 8;
			elsif	(linha >= 50 and linha <= 68 and coluna >= 27 and coluna <= 45) then
				quadrante <= 9;
			elsif	(linha >= 50 and linha <= 68 and coluna >= 50 and coluna <= 68) then
				quadrante <= 10;
			elsif	(linha >= 50 and linha <= 68 and coluna >= 73 and coluna <= 91) then
				quadrante <= 11;
			elsif	(linha >= 73 and linha <= 91 and coluna >= 4 and coluna <= 22) then
				quadrante <= 12;
			elsif	(linha >= 73 and linha <= 91 and coluna >= 27 and coluna <= 45) then
				quadrante <= 13;
			elsif	(linha >= 73 and linha <= 91 and coluna >= 50 and coluna <= 68) then
				quadrante <= 14;
			elsif	(linha >= 73 and linha <= 91 and coluna >= 73 and coluna <= 91) then
				quadrante <= 15;
			else
				quadrante <= 16;
			end if;
		end if;
	end process;

	process(clock_50)
		variable line_n : integer := 0;		-- linha normalizada para o primeiro quadrante
		variable col_n : integer := 0;		-- coluna normalizada para o primeiro quadrante
	begin
		
		if  clock_50'event and clock_50 = '1' then
			-- Normalizacao da linha
			if quadrante = 16 then
				pixel <= "000";
			else
				if ((linha>3) and (linha<23))	then
					line_n := linha;
				elsif ((linha>26) and (linha<46))	then
					line_n := linha - 23;
				elsif ((linha>49) and (linha<69))	then
					line_n := linha - 46;
				elsif ((linha>72) and (linha<92))	then
					line_n := linha - 69;
				end if;
				-- Normalizacao da coluna
				if ((coluna>3) and (coluna<23))	then
					col_n := coluna;
				elsif ((coluna>26) and (coluna<46))	then
					col_n := coluna - 23;
				elsif ((coluna>49) and (coluna<69))	then
					col_n := coluna - 46;
				elsif ((coluna>72) and (coluna<92))	then
					col_n := coluna - 69;
				end if;
			
				if 	(Q_in(quadrante) = x"000") then		-- 0
					pixel <= "111";
				elsif (Q_in(quadrante) = x"002") then		-- 2
					if (line_n = 11 and (col_n = 12 or col_n = 13 or col_n = 14)) or
						(line_n = 12 and (col_n = 14)) or
						(line_n = 13 and (col_n = 12 or col_n = 13 or col_n = 14)) or
						(line_n = 14 and col_n = 12) or
						(line_n = 15 and (col_n = 12 or col_n = 13 or col_n = 14)) then
						pixel <= "000";
					else
						pixel <= "001";
					end if;
				elsif (Q_in(quadrante) = x"004") then		-- 4
					if (line_n = 11 and (col_n = 12 or col_n = 14)) or
						(line_n = 12 and (col_n = 12 or col_n = 14)) or
						(line_n = 13 and (col_n = 12 or col_n = 13 or col_n = 14)) or
						(line_n = 14 and (col_n = 14)) or
						(line_n = 15 and (col_n = 14)) then
						pixel <= "000";
					else
						pixel <= "010";
					end if;
				elsif (Q_in(quadrante) = x"008") then		-- 8
					if (line_n = 11 and (col_n = 12 or col_n = 13 or col_n = 14)) or
						(line_n = 12 and (col_n = 12 or col_n = 14)) or
						(line_n = 13 and (col_n = 12 or col_n = 13 or col_n = 14)) or
						(line_n = 14 and (col_n = 12 or col_n = 14)) or
						(line_n = 15 and (col_n = 12 or col_n = 13 or col_n = 14)) then
						pixel <= "000";
					else
						pixel <= "011";
					end if;
				elsif (Q_in(quadrante) = x"010") then		-- 16
					if (line_n = 11 and (col_n = 11 or col_n = 14 or col_n = 15 or col_n = 16)) or
						(line_n = 12 and (col_n = 10 or col_n = 11 or col_n = 14)) or
						(line_n = 13 and (col_n = 11 or col_n = 14 or col_n = 15 or col_n = 16)) or
						(line_n = 14 and (col_n = 11 or col_n = 14 or col_n = 16)) or
						(line_n = 15 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16)) then
						pixel <= "000";
					else
						pixel <= "100";
					end if;
				elsif (Q_in(quadrante) = x"020") then		-- 32
					if (line_n = 11 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16)) or
						(line_n = 12 and (col_n = 12 or col_n = 16)) or
						(line_n = 13 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16)) or
						(line_n = 14 and (col_n = 12 or col_n = 14)) or
						(line_n = 15 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16)) then
						pixel <= "000";
					else
						pixel <= "101";
					end if;
				elsif (Q_in(quadrante) = x"040") then		-- 64
					if (line_n = 11 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 16)) or
						(line_n = 12 and (col_n = 10 or col_n = 14 or col_n = 16)) or
						(line_n = 13 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16)) or
						(line_n = 14 and (col_n = 10 or col_n = 12 or col_n = 16)) or
						(line_n = 15 and (col_n = 10 or col_n = 11 or col_n = 12 or col_n = 16)) then
						pixel <= "000";
					else
						pixel <= "110";
					end if;
				elsif (Q_in(quadrante) = x"080") then		-- 128
					if (line_n = 11 and (col_n = 9 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 12 and (col_n = 8 or col_n = 9 or col_n = 14 or col_n = 16 or col_n = 18)) or
						(line_n = 13 and (col_n = 9 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 14 and (col_n = 9 or col_n = 12 or col_n = 16 or col_n = 18)) or
						(line_n = 15 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) then
						pixel <= "000";
					else
						pixel <= "001";
					end if;
				elsif (Q_in(quadrante) = x"100") then		-- 256
					if (line_n = 11 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 12 and (col_n = 10 or col_n = 12 or col_n = 16)) or
						(line_n = 13 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 14 and (col_n = 8 or col_n = 14 or col_n = 16 or col_n = 18)) or
						(line_n = 15 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) then
						pixel <= "000";
					else
						pixel <= "010";
					end if;
				elsif (Q_in(quadrante) = x"200") then		-- 512
					if (line_n = 11 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 13 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 12 and (col_n = 8 or col_n = 12 or col_n = 13 or col_n = 18)) or
						(line_n = 13 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 13 or col_n = 16 or col_n = 17 or col_n = 18)) or
						(line_n = 14 and (col_n = 10 or col_n = 13 or col_n = 16)) or
						(line_n = 15 and (col_n = 8 or col_n = 9 or col_n = 10 or col_n = 12 or col_n = 13 or col_n = 14 or col_n = 16 or col_n = 17 or col_n = 18)) then
						pixel <= "000";
					else
						pixel <= "011";
					end if;
				elsif (Q_in(quadrante) = x"400") then		-- 1024
					if (line_n = 11 and (col_n = 7 or col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16 or col_n = 18 or col_n = 20)) or
						(line_n = 12 and (col_n = 6 or col_n = 7 or col_n = 10 or col_n = 12 or col_n = 16 or col_n = 18 or col_n = 20)) or
						(line_n = 13 and (col_n = 7 or col_n = 10 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16 or col_n = 18 or col_n = 19 or col_n = 20)) or
						(line_n = 14 and (col_n = 7 or col_n = 10 or col_n = 12 or col_n = 14 or col_n = 20)) or
						(line_n = 15 and (col_n = 6 or col_n = 7 or col_n = 8 or col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16  or col_n = 20)) then
						pixel <= "000";
					else
						pixel <= "100";
					end if;
				elsif (Q_in(quadrante) = x"800") then		-- 2048
					if (line_n = 11 and (col_n = 6 or col_n = 7 or col_n = 8 or col_n = 10 or col_n = 11 or col_n = 12 or col_n = 14 or col_n = 16 or col_n = 18 or col_n = 19 or col_n = 20)) or
						(line_n = 12 and (col_n = 8 or col_n = 10 or col_n = 12 or col_n = 14 or col_n = 16 or col_n = 18 or col_n = 20)) or
						(line_n = 13 and (col_n = 6 or col_n = 7 or col_n = 8 or col_n = 10 or col_n = 12 or col_n = 14 or col_n = 15 or col_n = 16 or col_n = 18 or col_n = 19 or col_n = 20)) or
						(line_n = 14 and (col_n = 6 or col_n = 10 or col_n = 12 or col_n = 16 or col_n = 18 or col_n = 20)) or
						(line_n = 15 and (col_n = 6 or col_n = 7 or col_n = 8 or col_n = 10 or col_n = 11 or col_n = 12 or col_n = 16 or col_n = 18 or col_n = 19 or col_n = 20)) then
						pixel <= "000";
					else
						pixel <= "101";
					end if;
				end if;
			end if;
		end if;

	end process;
end beh;
