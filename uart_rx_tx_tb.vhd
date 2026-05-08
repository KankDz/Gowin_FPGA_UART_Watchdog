library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx_rx is
end tb_uart_tx_rx;

architecture behavior of tb_uart_tx_rx is
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

    signal clk         : std_logic := '0';
    signal rx_i        : std_logic := '1';
    signal tx_o        : std_logic;
    signal read_rx     : std_logic := '0';
    signal empty_rx    : std_logic;
    signal ffrx_data_o : std_logic_vector(7 downto 0);
    signal tx_w_data_i : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_full     : std_logic;
    signal write_tx    : std_logic := '0';
    constant clk_period : time := 37 ns;   
    constant bit_period : time := 8681 ns; 
    signal sim_done     : boolean := false;
    procedure send_byte (data : std_logic_vector(7 downto 0); signal rx : out std_logic) is
    begin
        rx <= '0'; 
        wait for bit_period;
        for i in 0 to 7 loop
            rx <= data(i);
            wait for bit_period;
        end loop;
        rx <= '1'; 
        wait for bit_period;
    end procedure;

begin
    uut: uart_tx_rx port map (
        clk => clk, rx_i => rx_i, tx_o => tx_o, read_rx => read_rx, 
        empty_rx => empty_rx, ffrx_data_o => ffrx_data_o, 
        tx_w_data_i => tx_w_data_i, tx_full => tx_full, write_tx => write_tx
    );

    clk_process :process
    begin
        while not sim_done loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        wait for 10 us;
        send_byte(x"48", rx_i); 
        send_byte(x"45", rx_i);
        send_byte(x"4C", rx_i); 
        send_byte(x"4C", rx_i); 
        send_byte(x"4F", rx_i); 
        wait for 10 us;
        while empty_rx = '0' loop
            read_rx <= '1';
            wait for clk_period;
            read_rx <= '0';
            wait for clk_period * 4; 
        end loop;

        tx_w_data_i <= x"46"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; 
        tx_w_data_i <= x"50"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; 
        tx_w_data_i <= x"47"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; 
        tx_w_data_i <= x"41"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; 
        wait for 400 us; 
        tx_w_data_i <= x"21"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- '!'
        wait for 200 us;
        sim_done <= true;
        wait;
    end process;

end behavior;