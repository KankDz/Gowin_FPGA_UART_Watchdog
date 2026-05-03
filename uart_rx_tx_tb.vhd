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

    -- Clock 27MHz và Baudrate 115200
    constant clk_period : time := 37 ns;   
    constant bit_period : time := 8681 ns; 
    signal sim_done     : boolean := false;

    -- Hàm t? ??ng b?n byte t? PC (RX_i)
    procedure send_byte (data : std_logic_vector(7 downto 0); signal rx : out std_logic) is
    begin
        rx <= '0'; -- Start bit
        wait for bit_period;
        for i in 0 to 7 loop
            rx <= data(i);
            wait for bit_period;
        end loop;
        rx <= '1'; -- Stop bit
        wait for bit_period;
    end procedure;

begin
    -- Ráp m?ch
    uut: uart_tx_rx port map (
        clk => clk, rx_i => rx_i, tx_o => tx_o, read_rx => read_rx, 
        empty_rx => empty_rx, ffrx_data_o => ffrx_data_o, 
        tx_w_data_i => tx_w_data_i, tx_full => tx_full, write_tx => write_tx
    );

    -- T?o Clock 27MHz
    clk_process :process
    begin
        while not sim_done loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- K?CH B?N ??I CHI?N 1ms
    stim_proc: process
    begin
        wait for 10 us;

        -- 1. MÁY TÍNH B?N LIÊN PHANH 5 BYTES "HELLO" VÀO RX
        -- Th?i gian: 5 * 86.8us = 434 us.
        send_byte(x"48", rx_i); -- 'H'
        send_byte(x"45", rx_i); -- 'E'
        send_byte(x"4C", rx_i); -- 'L'
        send_byte(x"4C", rx_i); -- 'L'
        send_byte(x"4F", rx_i); -- 'O'

        -- ??i thêm xíu cho ch?c ?n là byte cu?i ?ã chui h?n vào FIFO
        wait for 10 us;

        -- 2. PARSER HÚT S?CH SÀNH SANH FIFO RX
        -- Vòng l?p: C? th?y kho có ?? (empty_rx = '0') là kích read_rx hút ra
        while empty_rx = '0' loop
            read_rx <= '1';
            wait for clk_period;
            read_rx <= '0';
            wait for clk_period * 4; -- Ngh? vài nh?p ?? soi k?t qu? trên GtkWave
        end loop;

        -- 3. PARSER N?P LIÊN PHANH 4 BYTES "FPGA" VÀO TX
        -- Vi?c n?p vào FIFO c?c k? nhanh (vài nano-giây)
        tx_w_data_i <= x"46"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- 'F'
        tx_w_data_i <= x"50"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- 'P'
        tx_w_data_i <= x"47"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- 'G'
        tx_w_data_i <= x"41"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- 'A'

        -- 4. ??I M?CH TX T? ??NG B?N H?T 4 BYTE NÀY LÊN PC
        -- Th?i gian: 4 * 86.8us = 347 us
        wait for 400 us; 

        -- 5. CÚ CH?T: B?N THÊM CH? "!" (0x21) ? M?C TH?I GIAN MU?N
        tx_w_data_i <= x"21"; write_tx <= '1'; wait for clk_period; write_tx <= '0'; wait for clk_period*2; -- '!'

        -- 6. CH?Y THÊM ?? ??M B?O V??T QUA M?C 1,000 MICRO-GIÂY (1 ms)
        wait for 200 us;

        -- Ch?m d?t k?ch b?n
        sim_done <= true;
        wait;
    end process;

end behavior;