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

  -- G?i nguyên c?c UART c?a bro vào ?ây
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

  -- Dây ?i?n n?i ? gi?a
  signal read_sig   : std_logic := '0';
  signal write_sig  : std_logic := '0';
  signal empty_sig  : std_logic;
  signal full_sig   : std_logic;
  signal data_bus   : std_logic_vector(7 downto 0);

  -- FSM khuân vác ??n gi?n
  type state_type is (IDLE, TRANSFER);
  signal state : state_type := IDLE;

begin

  -- Ráp c?c UART vào m?ch
  u_uart : uart_tx_rx port map (
    clk         => clk,
    rx_i        => rx_i,
    tx_o        => tx_o,
    read_rx     => read_sig,
    empty_rx    => empty_sig,
    ffrx_data_o => data_bus,  -- ??u ra RX...
    tx_w_data_i => data_bus,  -- ...c?m th?ng vào ??u vào TX!
    tx_full     => full_sig,
    write_tx    => write_sig
  );

  -- Th?ng khuân vác (Dummy Parser)
  process(clk)
  begin
    if rising_edge(clk) then
      -- M?c ??nh không ?n nút
      read_sig  <= '0';
      write_sig <= '0';
      
      case state is
        when IDLE =>
          -- N?u kho RX có hàng VÀ kho TX ch?a ??y
          if empty_sig = '0' and full_sig = '0' then
            read_sig  <= '1'; -- B?m nút l?y hàng
            write_sig <= '1'; -- B?m nút nhét hàng
            state     <= TRANSFER;
          end if;
          
        when TRANSFER =>
          -- Ngh? 1 nh?p Clock ?? các c? FIFO c?p nh?t l?i tr?ng thái
          state <= IDLE;
          
      end case;
    end if;
  end process;

end rtl;