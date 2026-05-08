library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_TX is
end tb_TX;

architecture sim of tb_TX is
    component TX is 
      Port (
        clk      : in  std_logic;
        tx_start : in  std_logic;
        s_tick   : in  std_logic;
        data_i   : in  std_logic_vector(7 downto 0);
        tx_o     : out std_logic; 
        tx_done  : out std_logic
      );
    end component;
    signal clk      : std_logic := '0';
    signal tx_start : std_logic := '0';
    signal s_tick   : std_logic := '0';
    signal data_i   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_out   : std_logic; 
    signal tx_done  : std_logic;
    constant CLK_PERIOD : time := 20 ns; 
begin

    DUT : TX port map (
        clk      => clk,
        tx_start => tx_start,
        s_tick   => s_tick,
        data_i   => data_i,
        tx_o     => tx_out, 
        tx_done  => tx_done
    );
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    baud_process : process
    begin
        s_tick <= '0';
        wait for CLK_PERIOD * 15;
        s_tick <= '1';
        wait for CLK_PERIOD * 1;
    end process;
    stim_proc: process
    begin
        tx_start <= '0';
        wait for 200 ns;
        data_i <= x"41";     
        tx_start <= '1';       
        wait until rising_edge(tx_done);     
        tx_start <= '0';
        wait for CLK_PERIOD * 100; 
        data_i <= x"55";
        tx_start <= '1';  
        wait until rising_edge(tx_done);
        tx_start <= '0';      
        wait for 1 us;
        wait;
    end process;
end sim;