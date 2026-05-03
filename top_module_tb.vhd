library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module_tb is
end entity;

architecture tb of top_module_tb is

    -- =====================================================
    -- Clock 27 MHz
    -- 1 / 27 MHz = 37.037 ns
    -- =====================================================
    constant CLK_PERIOD : time := 37037 ps;

    -- =====================================================
    -- baud_gen c?a b?n:
    -- MAX_COUNT = 15
    -- s_tick m?i 15 chu k? clk
    -- UART dùng 16 s_tick cho 1 bit
    --
    -- BIT_PERIOD = 15 * 16 * CLK_PERIOD = 240 * CLK_PERIOD
    -- =====================================================
    constant BIT_PERIOD : time := 240 * CLK_PERIOD;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    signal rx_i  : std_logic := '1';
    signal tx_o  : std_logic;

    signal wr_en : std_logic;
    signal rd_en : std_logic;
    signal addr  : std_logic_vector(7 downto 0);
    signal wdata : std_logic_vector(31 downto 0);
    signal rdata : std_logic_vector(31 downto 0) := (others => '0');

    signal sim_done : boolean := false;

    -- =====================================================
    -- G?i 1 byte UART vào chân rx_i
    -- UART format:
    -- Start bit = 0
    -- 8 data bits, LSB first
    -- Stop bit = 1
    -- =====================================================
    procedure uart_send_byte(
        signal rx_line : out std_logic;
        constant data  : in  std_logic_vector(7 downto 0)
    ) is
    begin
        -- Start bit
        rx_line <= '0';
        wait for BIT_PERIOD;

        -- 8 data bits, LSB first
        for i in 0 to 7 loop
            rx_line <= data(i);
            wait for BIT_PERIOD;
        end loop;

        -- Stop bit
        rx_line <= '1';
        wait for BIT_PERIOD;

        -- Ngh? nh? gi?a 2 byte
        wait for BIT_PERIOD;
    end procedure;

    -- =====================================================
    -- ??c 1 byte UART t? chân tx_o
    -- UART format:
    -- Start bit = 0
    -- 8 data bits, LSB first
    -- Stop bit = 1
    -- =====================================================
    procedure uart_read_byte(
        signal tx_line : in  std_logic;
        variable data  : out std_logic_vector(7 downto 0)
    ) is
    begin
        -- ??i start bit
        wait until tx_line = '0';

        -- ?i t?i gi?a start bit
        wait for BIT_PERIOD / 2;

        assert tx_line = '0'
            report "TX ERROR: Start bit khong bang 0"
            severity error;

        -- ?i t?i gi?a data bit 0
        wait for BIT_PERIOD;

        -- ??c 8 data bits
        for i in 0 to 7 loop
            data(i) := tx_line;
            wait for BIT_PERIOD;
        end loop;

        -- Ki?m tra stop bit
        assert tx_line = '1'
            report "TX ERROR: Stop bit khong bang 1"
            severity error;

        wait for BIT_PERIOD;
    end procedure;

begin

    -- =====================================================
    -- T?o clock 27 MHz
    -- =====================================================
    clk_process : process
    begin
        while sim_done = false loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;

        wait;
    end process;

    -- =====================================================
    -- DUT: top_module
    -- =====================================================
    dut : entity work.top_module
        port map (
            clk   => clk,
            rst   => rst,

            rx_i  => rx_i,
            tx_o  => tx_o,

            wr_en => wr_en,
            rd_en => rd_en,
            addr  => addr,
            wdata => wdata,
            rdata => rdata
        );

    -- =====================================================
    -- Test chính
    -- =====================================================
    stim_proc : process
        variable tx_byte : std_logic_vector(7 downto 0);
    begin

        -- =================================================
        -- RESET
        -- =================================================
        report "========== RESET ==========";

        rx_i <= '1';
        rst  <= '1';

        wait for 20 * CLK_PERIOD;

        rst <= '0';

        wait for 50 * CLK_PERIOD;

        -- =================================================
        -- TEST 1: WRITE COMMAND
        --
        -- Frame:
        -- [55][CMD][ADDR][LEN][DATA][CHK]
        --
        -- CMD  = 01
        -- ADDR = 04
        -- LEN  = 01
        -- DATA = AA
        --
        -- CHK = CMD xor ADDR xor LEN xor DATA
        -- CHK = 01 xor 04 xor 01 xor AA = AE
        --
        -- Frame g?i:
        -- 55 01 04 01 AA AE
        -- =================================================
        report "========== TEST 1: WRITE COMMAND ==========";

        uart_send_byte(rx_i, x"55"); -- HEADER
        uart_send_byte(rx_i, x"01"); -- CMD WRITE
        uart_send_byte(rx_i, x"04"); -- ADDR
        uart_send_byte(rx_i, x"01"); -- LEN
        uart_send_byte(rx_i, x"AA"); -- DATA
        uart_send_byte(rx_i, x"AE"); -- CHK

        -- ??i uart_engine t?o xung wr_en
        wait until rising_edge(clk) and wr_en = '1';

        assert addr = x"04"
            report "WRITE ERROR: addr sai"
            severity error;

        assert wdata = x"000000AA"
            report "WRITE ERROR: wdata sai"
            severity error;

        report "WRITE BUS OK";

        -- Sau WRITE, uart_engine g?i ACK = AA qua TX
        uart_read_byte(tx_o, tx_byte);

        assert tx_byte = x"AA"
            report "WRITE ERROR: ACK sai"
            severity error;

        report "WRITE ACK OK";

        wait for 2 ms;

        -- =================================================
        -- TEST 2: READ COMMAND
        --
        -- Frame:
        -- [55][CMD][ADDR][LEN][CHK]
        --
        -- CMD  = 02
        -- ADDR = 04
        -- LEN  = 00
        --
        -- CHK = CMD xor ADDR xor LEN
        -- CHK = 02 xor 04 xor 00 = 06
        --
        -- Frame g?i:
        -- 55 02 04 00 06
        -- =================================================
        report "========== TEST 2: READ COMMAND ==========";

        -- Gi? l?p d? li?u tr? v? t? BUS
        rdata <= x"12345678";

        uart_send_byte(rx_i, x"55"); -- HEADER
        uart_send_byte(rx_i, x"02"); -- CMD READ
        uart_send_byte(rx_i, x"04"); -- ADDR
        uart_send_byte(rx_i, x"00"); -- LEN
        uart_send_byte(rx_i, x"06"); -- CHK

        -- ??i uart_engine t?o xung rd_en
        wait until rising_edge(clk) and rd_en = '1';

        assert addr = x"04"
            report "READ ERROR: addr sai"
            severity error;

        report "READ BUS OK";

        -- =================================================
        -- rdata = 12345678
        --
        -- uart_engine g?i byte th?p tr??c:
        -- DATA0 = 78
        -- DATA1 = 56
        -- DATA2 = 34
        -- DATA3 = 12
        --
        -- Response mong ??i:
        -- 55 78 56 34 12 08
        --
        -- CHK = 78 xor 56 xor 34 xor 12 = 08
        -- =================================================

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"55"
            report "READ RESP ERROR: HEADER sai"
            severity error;

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"78"
            report "READ RESP ERROR: DATA byte 0 sai"
            severity error;

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"56"
            report "READ RESP ERROR: DATA byte 1 sai"
            severity error;

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"34"
            report "READ RESP ERROR: DATA byte 2 sai"
            severity error;

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"12"
            report "READ RESP ERROR: DATA byte 3 sai"
            severity error;

        uart_read_byte(tx_o, tx_byte);
        assert tx_byte = x"08"
            report "READ RESP ERROR: CHECKSUM sai"
            severity error;

        report "READ RESPONSE OK";

        wait for 2 ms;

        -- =================================================
        -- TEST DONE
        -- =================================================
        report "========== ALL TESTS PASSED ==========";

        sim_done <= true;
        wait;

    end process;

end architecture;
