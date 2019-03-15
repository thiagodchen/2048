-------------------------------------------------------------------------------
-- Title      : exemplo
-- Project    : 
-------------------------------------------------------------------------------
-- File       : exemplo.vhd
-- Author     : Rafael Auler
-- Company    : 
-- Created    : 2010-03-26
-- Last update: 2018-04-05
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Fornece um exemplo de uso do módulo VGACON para a disciplina
--              MC613.
--              Este módulo possui uma máquina de estados simples que se ocupa
--              de escrever na memória de vídeo (atualizar o quadro atual) e,
--              em seguida, de atualizar a posição de uma "bola" que percorre
--              toda a tela, quicando pelos cantos.
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2010-03-26  1.0      Rafael Auler    Created
-- 2018-04-05  1.1      IBFelzmann      Adapted for DE1-SoC
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
use work.Common.all;

entity controle is
  port (    
    CLOCK_50                  : in  std_logic;
    KEY                       : in  std_logic_vector(3 downto 0);
	 SW								: in 	std_logic_vector(0 downto 0);
    VGA_R, VGA_G, VGA_B       : out std_logic_vector(7 downto 0);
    VGA_HS, VGA_VS            : out std_logic;
    VGA_BLANK_N, VGA_SYNC_N   : out std_logic;
    VGA_CLK                   : out std_logic
    );
end controle;

architecture comportamento of controle is
  ---------------------- COMPONENTES ----------------------
  
  component random
	port (
	    clk : in std_logic;
        random_num : out std_logic_vector (3 downto 0);
		random_int : out integer range 0 to 15
	);
  end component;
  
  component ram_block
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
  end component;  
    
	component multiplexador
	port (
		clock_50			: in std_logic;
		linha				: in integer range 0 to 95;
		coluna			: in integer range 0 to 127;
		Q_in				: in Q_array;
		pixel				: out std_logic_vector(2 downto 0)
	);
	end component; 
	
	component junta_cima 
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component junta_baixo
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component junta_direita
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component junta_esquerda
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component combina_cima 
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component combina_baixo
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component combina_direita
	port(
		clock_50	: in std_logic;
      enable	: in std_logic;
		Q_in		: in Q_array;
		Q_out		: out Q_array;
		fim		: out std_logic
	);
	end component;
	
	component combina_esquerda
    port(
        clock_50    : in std_logic;
      enable    : in std_logic;
        Q_in        : in Q_array;
        Q_out        : out Q_array;
        fim        : out std_logic := '0'
    );
	end component;
	
	component gera_random
	port(
		clk : in std_logic;
		en		: in std_logic;
		Q				: in Q_array;
		pos_out		: out std_logic_vector(3 downto 0);
		fim			: out std_logic
	);
	end component;
 
  ---------------------- FIM COMPONENTES ----------------------
  
  signal rstn : std_logic;              -- reset active low
  -- Interface com a memória de vídeo do controlador
  signal we : std_logic;                        -- write enable ('1' p/ escrita)
  signal addr : integer range 0 to 12287;       -- endereco mem. vga
  signal pixel : std_logic_vector(2 downto 0);  -- valor de cor do pixel

  -- Sinais dos contadores de linhas e colunas utilizados para percorrer
  -- as posições da memória de vídeo (pixels) no momento de construir um quadro.
  
  signal line : integer range 0 to 95 :=0;  -- linha atual
  signal col : integer range 0 to 127 :=0;  -- coluna atual

  signal col_rstn : std_logic;          -- reset do contador de colunas
  signal col_enable : std_logic;        -- enable do contador de colunas

  signal line_rstn : std_logic;          -- reset do contador de linhas
  signal line_enable : std_logic;        -- enable do contador de linhas											 

  -- Especificação dos tipos e sinais da máquina de estados de controle
  type estado_t is (show_splash, inicio, constroi_quadro, est_junta_cima, est_junta_baixo, est_junta_esquerda, est_junta_direita, 
							 est_combina_cima, est_combina_baixo, est_combina_esquerda, est_combina_direita, inicializa_tab,
							 est_seg_cima, est_seg_baixo, est_seg_esq, est_seg_dir, est_gera_rand, est_escreve_rand, est_desliga_comb_esq);
  signal estado: estado_t := show_splash;
  signal proximo_estado: estado_t := show_splash;

  -- Sinais para um contador utilizado para atrasar a atualização da
  -- posição da bola, a fim de evitar que a animação fique excessivamente
  -- veloz. Aqui utilizamos um contador de 0 a 1250000, de modo que quando
  -- alimentado com um clock de 50MHz, ele demore 25ms (40fps) para contar até o final.
  
  signal contador : integer range 0 to 1250000 - 1;  -- contador
  signal timer : std_logic;        -- vale '1' quando o contador chegar ao fim
  signal timer_rstn, timer_enable : std_logic;
  
  signal sync, blank: std_logic;
  
  	-- nossas variaveis
	signal reseta : std_logic;
	signal MemEn			: std_logic := '0';
	signal AlEn				: std_logic;
	signal PosAl			: std_logic_vector(3 downto 0);
	signal pos_int			: integer range 0 to 15;
	signal fim_ini_tab 	: std_logic;
	signal contador_ini 	: integer range 0 to 3 := 0;
	signal reseta_ini 	: std_logic;
	signal escreve_ini	: std_logic;
	signal quadrante		: integer range 0 to 15;
	
	signal Add_random		: std_logic_vector(3 downto 0);
	signal Q_random		: std_logic_vector(11 downto 0);
	
	-- Q_array is array(0 to 15) of std_logic_vector(11 downto 0);
	signal Q 				: Q_array;
	signal Q_junta_baixo, Q_comb_baixo1, Q_baixo: Q_array;
	signal Q_junta_cima, Q_comb_cima, Q_cima	: Q_array;
	signal Q_junta_esquerda, Q_comb_esquerda1, Q_esquerda	: Q_array;
	signal Q_junta_direita, Q_comb_direita1, Q_direita	: Q_array;

	-- sinais de controle de direcao
	signal sobe, desce, esq, dir : std_logic;

	signal EsqEn, SegEsqEn, fim_junta_esquerda, fim_1_comb_esquerda, fim_combina_esquerda : std_logic;
	signal BaixoEn, SegBaixoEn, fim_junta_baixo, fim_1_comb_baixo, fim_combina_baixo : std_logic;
	signal cimaEn, juntacima2En, SegCimaEn, fim_junta_cima, fim_comb_cima, fim_seg_junta_cima : std_logic;
	signal dirEn, SegDirEn, fim_junta_direita, fim_1_comb_direita, fim_combina_direita : std_logic;
	
	signal RandMemEn, RandEn, fim_random, fim_ram			: std_logic;
	signal pos_vazia		: std_logic_vector(3 downto 0);
	
begin  -- comportamento


  -- Aqui instanciamos o controlador de vídeo, 128 colunas por 96 linhas
  -- (aspect ratio 4:3). Os sinais que iremos utilizar para comunicar
  -- com a memória de vídeo (para alterar o brilho dos pixels) são
  -- write_clk (nosso clock), write_enable ('1' quando queremos escrever
  -- o valor de um pixel), write_addr (endereço do pixel a escrever)
  -- e data_in (valor do brilho do pixel RGB, 1 bit pra cada componente de cor)
  vga_controller: entity work.vgacon port map (
    clk50M       => CLOCK_50,
    rstn         => '1',
    red          => VGA_R,
    green        => VGA_G,
    blue         => VGA_B,
    hsync        => VGA_HS,
    vsync        => VGA_VS,
    write_clk    => CLOCK_50,
    write_enable => we,
    write_addr   => addr,
    data_in      => pixel,
    vga_clk      => VGA_CLK,
    sync         => sync,
    blank        => blank);
  VGA_SYNC_N <= NOT sync;
  VGA_BLANK_N <= NOT blank;

  -----------------------------------------------------------------------------
  -- Processos que controlam contadores de linhas e coluna para varrer
  -- todos os endereços da memória de vídeo, no momento de construir um quadro.
  -----------------------------------------------------------------------------

  -- purpose: Este processo conta o número da coluna atual, quando habilitado
  --          pelo sinal "col_enable".
  -- type   : sequential
  -- inputs : CLOCK_50, col_rstn
  -- outputs: col
  conta_coluna: process (CLOCK_50, col_rstn)
  begin  -- process conta_coluna
    if col_rstn = '0' then                  -- asynchronous reset (active low)
      col <= 0;
    elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      if col_enable = '1' then
        if col = 127 then               -- conta de 0 a 127 (128 colunas)
          col <= 0;
        else
          col <= col + 1;  
        end if;
      end if;
    end if;
  end process conta_coluna;
    
  -- purpose: Este processo conta o número da linha atual, quando habilitado
  --          pelo sinal "line_enable".
  -- type   : sequential
  -- inputs : CLOCK_50, line_rstn
  -- outputs: line
  conta_linha: process (CLOCK_50, line_rstn)
  begin  -- process conta_linha
    if line_rstn = '0' then                  -- asynchronous reset (active low)
      line <= 0;
		
    elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      -- o contador de linha só incrementa quando o contador de colunas
      -- chegou ao fim (valor 127)
      if line_enable = '1' and col = 127 then
        if line = 95 then               -- conta de 0 a 95 (96 linhas)
          line <= 0;
        else
          line <= line + 1;  
        end if;        
      end if;
    end if;
  end process conta_linha;
  
	-- escreve no pixel indicado no endereco
	addr <= col + (128 * line);
	
  -----------------------------------------------------------------------------
  -- Processos que definem a FSM (finite state machine), nossa máquina
  -- de estados de controle.
  -----------------------------------------------------------------------------

  -- purpose: Esta é a lógica combinacional que calcula sinais de saída a partir
  --          do estado atual e alguns sinais de entrada (Máquina de Mealy).
  -- type   : combinational
  -- inputs : estado, fim_escrita, timer
  -- outputs: proximo_estado, atualiza_pos_x, atualiza_pos_y, line_rstn,
  --          line_enable, col_rstn, col_enable, we, timer_enable, timer_rstn
  logica_mealy: process (estado, timer, fim_ini_tab, sobe, desce, esq, dir,
									fim_junta_cima, fim_comb_cima, fim_combina_baixo, fim_junta_baixo,
									fim_junta_esquerda, fim_combina_esquerda, fim_junta_direita, fim_combina_direita,
									fim_seg_junta_cima, fim_random)
  begin  -- process logica_mealy
  case estado is
    when inicio         => if timer = '1' then              
                               proximo_estado <= inicializa_tab;
                             else
                               proximo_estado <= inicio;
                             end if;
                             line_rstn      <= '0';  -- reset é active low!
                             line_enable    <= '0';
                             col_rstn       <= '0';  -- reset é active low!
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '1';  -- reset é active low!
                             timer_enable   <= '1';
									  reseta_ini	  <= '1';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
		
		when inicializa_tab => 
									 if (fim_ini_tab = '1') then
											proximo_estado <= constroi_quadro;
									  else
											proximo_estado <= inicializa_tab;
									  end if;
                             line_rstn      <= '0';
                             line_enable    <= '0';
                             col_rstn       <= '0';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '1'; 
                             timer_enable   <= '1';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '1';
									  MemEn			  <= '1';									  
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
									  
		-- escreve no vga e permite o jogador clicar as Direcoes
      when constroi_quadro=> if sobe = '1' then
                               proximo_estado <= est_junta_cima;
										 elsif desce = '1' then
										 proximo_estado <= est_junta_baixo;
										 elsif esq = '1' then
										 proximo_estado <= est_junta_esquerda;
										 elsif dir = '1' then
										 proximo_estado <= est_junta_direita;
                             else
                               proximo_estado <= constroi_quadro;
                             end if;
                             line_rstn      <= '1';
                             line_enable    <= '1';
                             col_rstn       <= '1';
                             col_enable     <= '1';
                             we             <= '1';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
						  
		when est_junta_cima		  => if fim_junta_cima = '1' then
										proximo_estado <= est_combina_cima;
									  else
										proximo_estado <= est_junta_cima;
									  end if;
									  line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
		when est_combina_cima		  => if fim_seg_junta_cima = '1' then
										proximo_estado <= est_gera_rand;
										cimaen <= '0';
									  else
										proximo_estado <= est_combina_cima;
									  end if;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';									  
									  CimaEn			  <= '1';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
		when est_junta_baixo		  => if fim_junta_baixo = '1' then
										proximo_estado <= est_combina_baixo; --TODO
									  else
										proximo_estado <= est_junta_baixo;
									  end if;
									  line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
		when est_combina_baixo		=> if fim_combina_baixo = '1' then
										proximo_estado <= est_gera_rand;
										BaixoEn <= '0';
									  else
										proximo_estado <= est_combina_baixo;
									  end if;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';									  
									  CimaEn			  <= '0';
									  BaixoEn		  <= '1';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
		when est_junta_esquerda		  => if fim_junta_esquerda = '1' then
										proximo_estado <= est_combina_esquerda;
									  else
										proximo_estado <= est_junta_esquerda;
									  end if;
									  line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  
		when est_combina_esquerda		=> if fim_combina_esquerda = '1' then
										proximo_estado <= est_gera_rand;
										EsqEn <= '0';
									  else
										proximo_estado <= est_combina_esquerda;
									  end if;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';									  
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '1';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
		
		when est_junta_direita		  => if fim_junta_direita = '1' then
										proximo_estado <= est_combina_direita;
									  else
										proximo_estado <= est_junta_direita;
									  end if;
									  line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
									  

									  
		when est_combina_direita		=> if fim_combina_direita = '1' then
										proximo_estado <= est_gera_rand;
										DirEn <= '0';
									  else
										proximo_estado <= est_combina_direita;
									  end if;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0';
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
								     EsqEn			  <= '0';
									  DirEn			  <= '1';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';

		when est_gera_rand		=> if fim_random = '1' then				-- sinal recebido da componente GERA_RANDOM
										proximo_estado <= est_escreve_rand;
										RandEn <= '0';
									  else
										proximo_estado <= est_gera_rand;
									  end if;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0';
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
								     EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '1';
									  RandMemEn		  <= '0';
									  
		when est_escreve_rand	=>
										proximo_estado <= constroi_quadro;
		                       line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '0';
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
								     EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '1';-- en na memoria							  					  

      when others         => proximo_estado <= inicio;
                             line_rstn      <= '1';
                             line_enable    <= '0';
                             col_rstn       <= '1';
                             col_enable     <= '0';
                             we             <= '0';
                             timer_rstn     <= '1'; 
                             timer_enable   <= '0';
									  reseta_ini	  <= '0';
									  escreve_ini	  <= '0';
									  MemEn			  <= '0';									  
									  CimaEn			  <= '0';
									  BaixoEn		  <= '0';
									  EsqEn			  <= '0';
									  DirEn			  <= '0';
									  RandEn			  <= '0';
									  RandMemEn		  <= '0';
		end case;
  end process logica_mealy;
  
  -- purpose: Avança a FSM para o próximo estado
  -- type   : sequential
  -- inputs : CLOCK_50, rstn, proximo_estado
  -- outputs: estado
  seq_fsm: process (CLOCK_50, rstn, reseta_ini)
  begin  -- process seq_fsm
    if rstn = '0' then                  -- asynchronous reset (active low)
      estado <= inicio;
		
    elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      estado <= proximo_estado;
		
    end if;
	 reseta <= not(rstn) or reseta_ini;
  end process seq_fsm;

  -----------------------------------------------------------------------------
  -- Processos do contador utilizado para atrasar a animação (evitar
  -- que a atualização de quadros fique excessivamente veloz).
  -----------------------------------------------------------------------------
  -- purpose: Incrementa o contador a cada ciclo de clock
  -- type   : sequential
  -- inputs : CLOCK_50, timer_rstn
  -- outputs: contador, timer
  p_contador: process (CLOCK_50, timer_rstn)
  begin  -- process p_contador
    if timer_rstn = '0' then            -- asynchronous reset (active low)
      contador <= 0;    
	 elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      if timer_enable = '1' then       
        if contador = 1250000 - 1 then
          contador <= 0;
        else
          contador <=  contador + 1;        
        end if;
      end if;
    end if;
  end process p_contador;

  -- purpose: Calcula o sinal "timer" que indica quando o contador chegou ao
  --          final
  -- type   : combinational
  -- inputs : contador
  -- outputs: timer
  p_timer: process (contador)
  begin  -- process p_timer
    if contador = 1250000 - 1 then
      timer <= '1';
    else
      timer <= '0';
    end if;
  end process p_timer;

  -----------------------------------------------------------------------------
  -- Processos que sincronizam sinais assíncronos, de preferência com mais
  -- de 1 flipflop, para evitar metaestabilidade.
  -----------------------------------------------------------------------------
  -- purpose: Aqui sincronizamos nosso sinal de reset vindo do botão da DE1
  -- type   : sequential
  -- inputs : CLOCK_50
  -- outputs: rstn
  build_rstn: process (CLOCK_50)
    variable temp, temp0, temp1, temp2, temp3  : std_logic;          -- flipflop intermediario
  begin  -- process build_rstn
    if CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
      rstn <= temp;
      temp := not(sw(0));
		
		temp3 := not (key(3));
		esq <= temp3;
		
		temp2 := not(key(2));
		desce <= temp2;
		
		temp1 := not (key(1));
		sobe <= temp1;
		
		temp0 := not(key(0));
		dir <= temp0;
		
    end if;
  end process build_rstn;
	---------------------- instanciacao das componentes ----------------------
	memoria: ram_block port map (
		CLOCK_50,
		Q_baixo, Q_cima, Q_esquerda, Q_direita, 			-- combina								TODO
		add_random,																				-- Posicao aleatorio do inicio (cria 2 quadrados)
		pos_vazia,																				-- Posicao aleatorio na hora de movimentar uma peca
		x"002",																					-- VALOR a ser escrito
		Q,
		reseta,
		MemEn,
		BaixoEn,CimaEn,EsqEn,DirEn,														-- En do combina
		RandMemEn																					--AlEn
	);
	
	randommmmm: random port map (CLOCK_50, PosAl, Pos_int);
	
	comp_random: gera_random port map (clock_50, RandEn, Q, pos_Vazia, fim_random);
	
	conv_pixel: multiplexador port map (clock_50, line, col, Q, pixel);
	
	-- ESQ
	junta_esq1: junta_esquerda port map (clock_50, esq, Q, Q_junta_esquerda,
		fim_junta_esquerda);	
	
	comb_esq1: combina_esquerda port map (clock_50, fim_junta_esquerda, Q_junta_esquerda,
		Q_comb_esquerda1, fim_1_comb_esquerda);

	junta_esq2: junta_esquerda port map (clock_50, fim_1_comb_esquerda, Q_comb_esquerda1,
		Q_esquerda, fim_combina_esquerda);
	
	junta_baixo1: junta_baixo port map (clock_50, desce, Q, Q_junta_baixo, fim_junta_baixo);
	
	comb_baixo: combina_baixo port map (clock_50, fim_junta_baixo, Q_junta_baixo, Q_comb_baixo1,
		fim_1_comb_baixo);

	junta_baixo2: junta_baixo port map (clock_50, fim_1_comb_baixo, Q_comb_baixo1, Q_baixo,
		fim_combina_baixo);

	junta_cima1: junta_cima port map (clock_50, sobe, Q, Q_junta_cima, fim_junta_cima);
	
	comb_cima: combina_cima port map (clock_50, fim_junta_cima, Q_junta_cima, Q_comb_cima,
		fim_comb_cima);

	junta_cima2: junta_cima port map (clock_50, fim_comb_cima, Q_comb_cima, Q_cima,
		fim_seg_junta_cima);
	
	juntadir1: junta_direita port map (clock_50, dir, Q, Q_junta_direita, fim_junta_direita);
	
	comb1_direita: combina_direita port map (clock_50, fim_junta_direita, Q_junta_direita,
		Q_comb_direita1, fim_1_comb_direita);

	juntadir2: junta_direita port map (clock_50, fim_1_comb_direita, Q_comb_direita1,
		Q_direita, fim_combina_direita);
	
	
	---------------------- fim instanciacao das componentes ----------------------
	
	process(clock_50)
		variable postemp : std_logic_vector(3 downto 0);
		variable inttemp : integer range 0 to 15;
	begin

		if clock_50'event and clock_50 = '1' then
					postemp := posal;	-- muda
					inttemp := pos_int;
			if escreve_ini = '1' then
				if (Q(inttemp) = x"000") then
					add_random <= postemp;
				end if;
			end if;
		end if;
		
	end process;
	
	-- contador
	process(clock_50)
		variable temp : integer := 0;
	begin
		if clock_50'event and clock_50 = '1' then
			temp := contador_ini;
			if escreve_ini = '1' then
				if MemEn = '1' then
					temp := temp + 1;		
					if (temp = 2) then
						temp := 0;
						fim_ini_tab <= '1';
					else
						fim_ini_tab <= '0';
					end if;
				else
					fim_ini_tab <= fim_ini_tab;
				end if;
			end if;
		end if;
		contador_ini <= temp;
	end process;
	
end comportamento;
