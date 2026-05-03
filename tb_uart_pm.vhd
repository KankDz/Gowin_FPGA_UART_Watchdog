library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_subsystem is
end entity;

architecture behavior of tb_uart_subsystem is
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal rx_i       : std_logic := '1';
    signal tx_o       : std_logic;
    signal bus_wr_en  : std_logic;
    signal bus_rd_en  : std_logic;
    signal bus_addr   : std_logic_vector(7 downto 0);
    signal bus_wdata  : std_logic_vector(31 downto 0);
    signal bus_rdata  : std_logic_vector(31 downto 0) := x"DEADBEEF"; -- Gi? l?p data t? Regfile

    constant clk_period  : time := 37.037 ns; -- 27 MHz
    constant baud_period : time := 8.68 us;   -- 115200 bps

    -- Procedure g?i 1 byte chu?n
    procedure uart_send_byte(data : std_logic_vector(7 downto 0); signal rx : out std_logic) is
    begin
        rx <= '0'; wait for baud_period; -- Start bit
        for i in 0 to 7 loop
            rx <= data(i); wait for baud_period;
        end loop;
        rx <= '1'; wait for baud_period; -- Stop bit
    end procedure;

begin
    uut: entity work.uart_subsystem
    port map (
        clk => clk, rst => rst, rx_i => rx_i, tx_o => tx_o,
        bus_wr_en => bus_wr_en, bus_rd_en => bus_rd_en,
        bus_addr => bus_addr, bus_wdata => bus_wdata, bus_rdata => bus_rdata
    );

    clk_process: process begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        -- RESET
        rst <= '1'; wait for 200 ns;
        rst <= '0'; wait for 10 us;

        -- CASE 1: SAI HEADER (G?i 0xA5 thay vì 0x55)
        -- Engine ph?i b? qua toàn b? và quay v? IDLE
        report "Case 1: Wrong Header Test";
        uart_send_byte(x"A5", rx_i);
        wait for 100 us;

        -- CASE 2: GÓI TIN CHU?N (L?nh Write 0x01)
        -- 0x55 (Hdr), 0x01 (CMD), 0x0A (Addr), 0x04 (Len), 0x12, 0x34, 0x56, 0x78 (Data), 0x48 (CHK)
        report "Case 2: Valid Write Packet";
        uart_send_byte(x"55", rx_i); -- Header
        uart_send_byte(x"01", rx_i); -- CMD Write
        uart_send_byte(x"0A", rx_i); -- ADDR
        uart_send_byte(x"04", rx_i); -- LEN
        uart_send_byte(x"12", rx_i); -- D0
        uart_send_byte(x"34", rx_i); -- D1
        uart_send_byte(x"56", rx_i); -- D2
        uart_send_byte(x"78", rx_i); -- D3
        uart_send_byte(x"48", rx_i); -- CHK (XOR c?a CMD..Data)
        wait for 1 ms; -- ??i Engine x? lý và TX g?i ACK (0xAA)

        -- CASE 3: SAI CHECKSUM
        report "Case 3: Checksum Error Test";
        uart_send_byte(x"55", rx_i);
        uart_send_byte(x"01", rx_i);
        uart_send_byte(x"00", rx_i);
        uart_send_byte(x"00", rx_i);
        uart_send_byte(x"FF", rx_i); -- Checksum sai (?úng ra ph?i là 0x01 xor 0x00...)
        wait for 200 us;

        -- CASE 4: L?NH READ (CMD 0x02)
        -- 0x55, 0x02, 0x10, 0x00, 0x12 (CHK)
        report "Case 4: Valid Read Packet";
        uart_send_byte(x"55", rx_i);
        uart_send_byte(x"02", rx_i);
        uart_send_byte(x"10", rx_i);
        uart_send_byte(x"00", rx_i);
        uart_send_byte(x"12", rx_i);
        wait for 2 ms; -- Xem TX có b?n l?i Header 0x55 + Data 0xDEADBEEF không

        report "Simulation Complete" severity note;
        wait;
    end process;

end architecture;