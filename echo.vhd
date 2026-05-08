library ieee;
use ieee.std_logic_1164.all;

entity top_echo is
  Port (
    clk  : in  std_logic;
    rx_i : in  std_logic;
    tx_o : out std_logic
  );
end top_echo;

architecture rtl of top_echo is

  component uart_tx_rx is
    Port (
      clk         : in  std_logic;
      rx_i        : in  std_logic;
      tx_o        : out std_logic;
      read_rx     : in  std_logic;
      empty_rx    : out std_logic;
      ffrx_data_o : out std_logic_vector (7 downto 0);
      tx_w_data_i : in  std_logic_vector ( 7 downto 0);
      tx_full     : out std_logic;
      write_tx    : in  std_logic
    );
  end component;

  signal read_sig   : std_logic := '0';
  signal write_sig  : std_logic := '0';
  signal empty_sig  : std_logic;
  signal full_sig   : std_logic;
  signal data_bus   : std_logic_vector(7 downto 0);
  type state_type is (IDLE, TRANSFER);
  signal state : state_type := IDLE;

begin
  u_uart : uart_tx_rx port map (
    clk         => clk,
    rx_i        => rx_i,
    tx_o        => tx_o,
    read_rx     => read_sig,
    empty_rx    => empty_sig,
    ffrx_data_o => data_bus,  
    tx_w_data_i => data_bus,  
    tx_full     => full_sig,
    write_tx    => write_sig
  );
  process(clk)
  begin
    if rising_edge(clk) then
      read_sig  <= '0';
      write_sig <= '0';   
      case state is
        when IDLE =>
          if empty_sig = '0' and full_sig = '0' then
            read_sig  <= '1'; 
            write_sig <= '1';
            state     <= TRANSFER;
          end if; 
        when TRANSFER =>
          state <= IDLE;        
      end case;
    end if;
  end process;

end rtl;