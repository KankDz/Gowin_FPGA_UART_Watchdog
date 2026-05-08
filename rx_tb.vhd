library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_rx is
end tb_rx;

architecture behavior of tb_rx is
    component rx is
        Port (
            clk      : in  std_logic;
            rx_i     : in  std_logic;
            s_tick   : in  std_logic;
            rx_done  : out std_logic;
            data_o   : out std_logic_vector (7 downto 0)
        );
    end component;
    signal clk     : std_logic := '0';
    signal rx_i    : std_logic := '1'; 
    signal s_tick  : std_logic := '0';
    signal rx_done : std_logic;
    signal data_o  : std_logic_vector(7 downto 0);
    constant clk_period  : time := 20 ns;  
    constant tick_period : time := 542 ns;  
    constant baud_period : time := tick_period * 16; 
    signal sim_done : boolean := false;

begin
    uut: rx port map (
        clk      => clk,
        rx_i     => rx_i,
        s_tick   => s_tick,
        rx_done  => rx_done,
        data_o   => data_o
    );
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;
    tick_process : process
    begin
        while not sim_done loop
            s_tick <= '0';
            wait for tick_period - clk_period;
            s_tick <= '1';
            wait for clk_period;
        end loop;
        wait;
    end process;
    stim_proc: process
        procedure send_uart_byte(data : std_logic_vector(7 downto 0)) is
        begin
            rx_i <= '0';
            wait for baud_period;
            for i in 0 to 7 loop
                rx_i <= data(i);
                wait for baud_period;
            end loop;
            rx_i <= '1';
            wait for baud_period;
        end procedure;
    begin
        wait for 10 us;
        send_uart_byte(x"41");
        wait for 20 us;
        send_uart_byte(x"55");
        wait for 20 us;
        sim_done <= true;
        wait;
    end process;
end behavior;