library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Common.all;

entity ram_block is

  port (
     Clock : in std_logic;
	 Data_Baixo: in Q_array;
	 Data_Cima : in Q_array;
	 Data_Esquerda: in Q_array;
	 Data_Direita : in Q_array;
     Address : in std_logic_vector(3 downto 0);
	 Address_Al: in std_logic_vector(3 downto 0);
   	 Data : in std_logic_vector(11 downto 0);
     DataOut : out Q_array;
	 reset: in std_logic;
     WrEn : in std_logic;
	 BaixoEn : in std_logic;
	 CimaEn : in std_logic;
	 EsqEn : in std_logic;
	 DirEn : in std_logic;
	 
	 AlEn	: in std_logic
  );
end ram_block;

architecture direct of ram_block is

	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector(11 downto 0);
	type memory_t is array(15 downto 0) of word_t;

	-- Declare the RAM signal.	
	signal ram : memory_t;
	signal flag: std_logic;
begin

	process(Clock, reset)
	begin
	if reset = '1' then
		ram(0) <= "000000000000";
		ram(1) <= "000000000000";
		ram(2) <= "000000000000";
		ram(3) <= "000000000000";
		ram(4) <= "000000000000";
		ram(5) <= "000000000000";
		ram(6) <= "000000000000";
		ram(7) <= "000000000000";
		ram(8) <= "000000000000";
		ram(9) <= "000000000000";
		ram(10) <= "000000000000";
		ram(11) <= "000000000000";
		ram(12) <= "000000000000";
		ram(13) <= "000000000000";
		ram(14) <= "000000000000";
		ram(15) <= "000000000000";
		
		
	elsif(clock'event and clock = '1') then
		-----------------------
		if (CimaEn = '1') then 
			for i in 0 to 15 loop
				ram(i) <= Data_Cima(i);
			end loop;
		elsif (BaixoEn = '1') then 
			for i in 0 to 15 loop
				ram(i) <= Data_Baixo(i);
			end loop;
		elsif (EsqEn = '1') then 
			for i in 0 to 15 loop
				ram(i) <= Data_Esquerda(i);
			end loop;		
		elsif (DirEn = '1') then 
			for i in 0 to 15 loop
				ram(i) <= Data_Direita(i);
			end loop;
		--------------------------------------	
		elsif(WrEn = '1') then
			ram(to_integer(unsigned(Address))) <= Data;
		elsif (AlEn = '1') then
			ram(to_integer(unsigned(Address_al))) <= Data;
		end if;	
	end if;
	end process;

	-- retorno das posicoes da memoria
	DataOut(0) <= ram(0);
	DataOut(1) <= ram(1);
	DataOut(2) <= ram(2);
	DataOut(3) <= ram(3);
	DataOut(4) <= ram(4);
	DataOut(5) <= ram(5);
	DataOut(6) <= ram(6);
	DataOut(7) <= ram(7);
	DataOut(8) <= ram(8);
	DataOut(9) <= ram(9);
	DataOut(10) <= ram(10);
	DataOut(11) <= ram(11);
	DataOut(12) <= ram(12);
	DataOut(13) <= ram(13);
	DataOut(14) <= ram(14);
	DataOut(15) <= ram(15);
	
end direct;
