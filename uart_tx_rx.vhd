library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_rx is
  Port (
    clk         : in  std_logic;
    rx_i        : in  std_logic;
    tx_o        : out std_logic;
    
    -- Giao ti?p v?i kh?i gi?i mã (??c t? RX)
    read_rx     : in  std_logic;
    empty_rx    : out std_logic;
    ffrx_data_o : out std_logic_vector (7 downto 0);
    
    -- Giao ti?p v?i kh?i gi?i mã (Ghi xu?ng TX)
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
  
  -- Dùng chung 1 Component FIFO cho c? RX và TX
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

  -- ==========================================
  -- KHAI BÁO DÂY ?I?N N?I B? (SIGNALS)
  -- ==========================================
  signal s_tick_sig    : std_logic;
  
  -- Dây c?a b? RX
  signal rx_done_sig   : std_logic;
  signal rx_data_sig   : std_logic_vector(7 downto 0);
  
  -- Dây c?a b? TX
  signal tx_done_sig   : std_logic;
  signal tx_empty_sig  : std_logic;
  signal tx_start_sig  : std_logic;
  signal tx_data_sig   : std_logic_vector(7 downto 0);

begin 

  -- 1. Máy t?o nh?p tim
  u_baud : baud_gen port map (
    clk    => clk,
    s_tick => s_tick_sig
  );

  -- 2. B? thu UART (RX)
  u_rx : rx port map (
    clk     => clk,
    rx_i    => rx_i,
    s_tick  => s_tick_sig,
    rx_done => rx_done_sig,
    data_o  => rx_data_sig
  );

  -- 3. FIFO cho RX (Ch?a ?? t? PC g?i xu?ng)
  u_fifo_rx : fifo port map (
    clk    => clk,
    empty  => empty_rx,      -- N?i th?ng ra ngoài cho kh?i Parser bi?t
    full   => open,          -- [TRICK] B? tr?ng chân full, không lo báo l?i!
    wr_i   => rx_done_sig,   -- C? nh?n xong 1 byte là RX t? ??ng ghi vào FIFO
    rd_i   => read_rx,       -- L?nh ??c t? kh?i Parser c?p vào
    w_data => rx_data_sig,   -- Data t? RX
    r_data => ffrx_data_o    -- Data xu?t ra cho Parser
  );

  -- 4. FIFO cho TX (Ch?a ?? t? m?ch g?i lên PC)
  u_fifo_tx : fifo port map (
    clk    => clk,
    empty  => tx_empty_sig,  -- Kéo ra xài n?i b? ?? kích ho?t TX
    full   => tx_full,       -- Báo ra ngoài ?? Parser d?ng ghi n?u ??y
    wr_i   => write_tx,      -- L?nh ghi t? kh?i Parser
    rd_i   => tx_done_sig,   -- C? TX b?n xong 1 byte là t? ??ng l?y byte ti?p
    w_data => tx_w_data_i,   -- Data t? Parser ghi vào
    r_data => tx_data_sig    -- Data ??y sang cho TX
  );

  -- ==========================================
  -- LOGIC "C?NG NOT" T? ??NG PHÁT (AUTO-TX)
  -- ==========================================
  -- H? FIFO TX không r?ng -> Có ?? -> B?n tín hi?u tx_start!
  tx_start_sig <= not tx_empty_sig;

  -- 5. B? phát UART (TX)
  u_tx : TX port map (
    clk      => clk,
    tx_start => tx_start_sig, -- L?y t? C?ng NOT
    s_tick   => s_tick_sig,
    data_i   => tx_data_sig,  -- Data hút t? FIFO
    tx_o     => tx_o,
    tx_done  => tx_done_sig   -- Báo xong ?? FIFO x? hàng
  );

end rtl;