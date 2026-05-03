library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_rx is
end tb_rx;

architecture behavior of tb_rx is
    -- 1. Khai báo v? h?p RX
    component rx is
        Port (
            clk      : in  std_logic;
            rx_i     : in  std_logic;
            s_tick   : in  std_logic;
            rx_done  : out std_logic;
            data_o   : out std_logic_vector (7 downto 0)
        );
    end component;

    -- 2. Khai báo dây n?i (Tín hi?u m?c ??nh c?a UART rx luôn là '1')
    signal clk     : std_logic := '0';
    signal rx_i    : std_logic := '1'; 
    signal s_tick  : std_logic := '0';
    signal rx_done : std_logic;
    signal data_o  : std_logic_vector(7 downto 0);

    -- 3. C?u hình ??nh th?i gian
    constant clk_period  : time := 20 ns;   -- Clock 50MHz
    constant tick_period : time := 542 ns;  -- Kho?ng cách gi?a 2 s_tick
    constant baud_period : time := tick_period * 16; -- Th?i gian c?a 1 bit (16 ticks)
    
    -- C? d?ng mô ph?ng
    signal sim_done : boolean := false;

begin
    -- 4. C?m dây vào m?ch RX
    uut: rx port map (
        clk      => clk,
        rx_i     => rx_i,
        s_tick   => s_tick,
        rx_done  => rx_done,
        data_o   => data_o
    );

    -- 5. B? phát Xung nh?p Clock (Ch?y liên t?c)
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

    -- 6. B? phát s_tick (C? m?i tick_period l?i nháy 1 nh?p clk)
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

    -- 7. K?CH B?N TEST CHÍNH
    stim_proc: process
        
        -- Công c? t? ??ng t?o sóng UART ?? g?i vào chân rx_i
        procedure send_uart_byte(data : std_logic_vector(7 downto 0)) is
        begin
            -- Kéo xu?ng 0 làm Start bit
            rx_i <= '0';
            wait for baud_period;
            
            -- Truy?n 8 bit Data (T? LSB ??n MSB)
            for i in 0 to 7 loop
                rx_i <= data(i);
                wait for baud_period;
            end loop;
            
            -- Kéo lên 1 làm Stop bit
            rx_i <= '1';
            wait for baud_period;
        end procedure;

    begin
        -- ??i 10 us cho m?ch ?n ??nh
        wait for 10 us;
        
        -- K?ch b?n 1: G?i ch? 'A' (Mã Hex: 41)
        send_uart_byte(x"41");
        
        -- ??i ngh? gi?a hi?p
        wait for 20 us;
        
        -- K?ch b?n 2: G?i ch? 'U' (Mã Hex: 55)
        send_uart_byte(x"55");
        
        -- ??i m?ch x? lý n?t byte cu?i
        wait for 20 us;
        
        -- Ra l?nh d?ng toàn b? các b? ??m gi?
        sim_done <= true;
        wait;
    end process;

end behavior;