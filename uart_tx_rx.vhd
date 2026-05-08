library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_rx is
  Port (
    clk         : in  std_logic;
    rx_i        : in  std_logic;
    tx_o        : out std_logic;
    read_rx     : in  std_logic;
    empty_rx    : out std_logic;
    ffrx_data_o : out std_logic_vector (7 downto 0);
    tx_w_data_i : in  std_logic_vector ( 7 downto 0);
    write_tx    : in  std_logic;
    tx_full     : out std_logic
  );
end uart_tx_rx;

architecture rtl of uart_tx_rx is 

  component baud_gen is
    Port (
        clk    : in  std_logic;
        s_tick : out std_logic
    );
  end component;
  component fifo is
    Port (
      clk    : in  std_logic;
      empty  : out std_logic;
      full   : out std_logic;
      wr_i   : in  std_logic;
      rd_i   : in  std_logic;
      w_data : in  std_logic_vector(7 downto 0);
      r_data : out std_logic_vector (7 downto 0)
    );
  end component;
  
  component rx is 
    Port (
      clk      : in  std_logic;      
      rx_i     : in  std_logic;
      s_tick   : in  std_logic;       
      rx_done  : out std_logic;
      data_o   : out std_logic_vector (7 downto 0)
    );
  end component;
  
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
  signal s_tick_sig    : std_logic;

  signal rx_done_sig   : std_logic;
  signal rx_data_sig   : std_logic_vector(7 downto 0);
  signal tx_done_sig   : std_logic;
  signal tx_empty_sig  : std_logic;
  signal tx_start_sig  : std_logic;
  signal tx_data_sig   : std_logic_vector(7 downto 0);

begin 
  u_baud : baud_gen port map (
    clk    => clk,
    s_tick => s_tick_sig
  );

  u_rx : rx port map (
    clk     => clk,
    rx_i    => rx_i,
    s_tick  => s_tick_sig,
    rx_done => rx_done_sig,
    data_o  => rx_data_sig
  );
  u_fifo_rx : fifo port map (
    clk    => clk,
    empty  => empty_rx,      
    full   => open,          
    wr_i   => rx_done_sig,   
    rd_i   => read_rx,       
    w_data => rx_data_sig,   
    r_data => ffrx_data_o    
  );
  u_fifo_tx : fifo port map (
    clk    => clk,
    empty  => tx_empty_sig, 
    full   => tx_full,      
    wr_i   => write_tx,   
    rd_i   => tx_done_sig, 
    w_data => tx_w_data_i,  
    r_data => tx_data_sig   
  );
  tx_start_sig <= not tx_empty_sig;
  u_tx : TX port map (
    clk      => clk,
    tx_start => tx_start_sig, 
    s_tick   => s_tick_sig,
    data_i   => tx_data_sig,  
    tx_o     => tx_o,
    tx_done  => tx_done_sig  
  );
end rtl;