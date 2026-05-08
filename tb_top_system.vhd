library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_system is
end tb_top_system;

architecture behavior of tb_top_system is
    component top_system
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            rx_i       : in  std_logic;
            tx_o       : out std_logic;
            btn_kick_i : in  std_logic;
            btn_en_i   : in  std_logic;
            wdo_o      : out std_logic;
            enout_o    : out std_logic
        );
    end component;
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1'; 
    signal rx_i       : std_logic := '1'; 
    signal btn_kick_i : std_logic := '0';
    signal btn_en_i   : std_logic := '0';

    signal tx_o       : std_logic;
    signal wdo_o      : std_logic;
    signal enout_o    : std_logic;
    constant clk_period : time := 37.037 ns; 
    constant bit_period : time := 8.680 us;  
    procedure send_byte(data_in : in std_logic_vector(7 downto 0); signal tx_line : out std_logic) is
    begin
        tx_line <= '0'; wait for bit_period; 
        for i in 0 to 7 loop
            tx_line <= data_in(i); wait for bit_period; 
        end loop;
        tx_line <= '1'; wait for bit_period; 
    end procedure;
    procedure uart_write_reg(addr: std_logic_vector(7 downto 0); data: std_logic_vector(31 downto 0); signal tx_line : out std_logic) is
        variable cs : std_logic_vector(7 downto 0);
    begin
        cs := x"01" xor addr xor x"04" xor data(7 downto 0) xor data(15 downto 8) xor data(23 downto 16) xor data(31 downto 24);
        send_byte(x"55", tx_line);
        send_byte(x"01", tx_line);
        send_byte(addr, tx_line);
        send_byte(x"04", tx_line);
        send_byte(data(7 downto 0), tx_line);
        send_byte(data(15 downto 8), tx_line);
        send_byte(data(23 downto 16), tx_line);
        send_byte(data(31 downto 24), tx_line);
        send_byte(cs, tx_line);
    end procedure;
    procedure uart_read_reg(addr: std_logic_vector(7 downto 0); signal tx_line : out std_logic) is
        variable cs : std_logic_vector(7 downto 0);
    begin
        cs := x"02" xor addr xor x"00";
        send_byte(x"55", tx_line);
        send_byte(x"02", tx_line);
        send_byte(addr, tx_line);
        send_byte(x"00", tx_line);
        send_byte(cs, tx_line);
    end procedure;
    procedure uart_kick(signal tx_line : out std_logic) is
        variable cs : std_logic_vector(7 downto 0);
    begin
        cs := x"03" xor x"00" xor x"00";
        send_byte(x"55", tx_line);
        send_byte(x"03", tx_line);
        send_byte(x"00", tx_line);
        send_byte(x"00", tx_line);
        send_byte(cs, tx_line);
    end procedure;
    procedure uart_read_status(signal tx_line : out std_logic) is
        variable cs : std_logic_vector(7 downto 0);
    begin
        cs := x"04" xor x"00" xor x"00";
        send_byte(x"55", tx_line);
        send_byte(x"04", tx_line);
        send_byte(x"00", tx_line);
        send_byte(x"00", tx_line);
        send_byte(cs, tx_line);
    end procedure;

begin
    uut: top_system port map (
        clk        => clk,
        rst        => rst,
        rx_i       => rx_i,
        tx_o       => tx_o,
        btn_kick_i => btn_kick_i,
        btn_en_i   => btn_en_i,
        wdo_o      => wdo_o,
        enout_o    => enout_o
    );
    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;
    stim_proc: process
    begin
        report "--- TEST 1: KHOI DONG VA RESET MACH ---";
        rst <= '1'; rx_i <= '1'; btn_en_i <= '0'; btn_kick_i <= '0';
        wait for 100 ns;
        rst <= '0'; 
        wait for 20 us;

        report "--- TEST 2: GHI CAU HINH QUA UART (RUT NGAN TWD/TRST) ---";
        uart_write_reg(x"04", x"0000D2F0", rx_i);
        wait for 100 us;
        uart_write_reg(x"08", x"000034BC", rx_i);
        wait for 100 us;

        report "--- TEST 3: DOC LAI THANH GHI TWD ---";
        uart_read_reg(x"04", rx_i);
        wait for 150 us;
        report "--- TEST 4: TEST ENABLE & KICK BANG PHAN CUNG ---";
        btn_en_i <= '1'; 
        wait for 1 ms;      
        btn_kick_i <= '1'; 
        wait for 10 us;
        btn_kick_i <= '0';
        wait for 100 us;
        report "--- TEST 5: CHUYEN QUYEN CHO PHAN MEM (UART ENABLE & KICK) ---";
        btn_en_i <= '0'; 
        uart_write_reg(x"00", x"00000003", rx_i);
        wait for 100 us;
        uart_kick(rx_i);
        wait for 100 us;
        report "--- TEST 6: CO TINH BO DOI DE TAO LOI (TIME-OUT FAULT) ---";
        wait for 2.5 ms;
        report "--- TEST 7: DOC TRANG THAI LOI VA XOA LOI ---";
        uart_read_status(rx_i);
        wait for 150 us;
        uart_write_reg(x"00", x"00000007", rx_i);
        wait for 150 us;
        uart_write_reg(x"00", x"00000003", rx_i);
        wait for 100 us;
        report "--- TEST 8: TEST CHONG NHIEU (GOI TIN SAI CHECKSUM) ---";
        send_byte(x"55", rx_i);
        send_byte(x"02", rx_i);
        send_byte(x"00", rx_i);
        send_byte(x"00", rx_i);
        send_byte(x"FF", rx_i); 
        wait for 150 us;
        report "--- HOAN THANH TOAN BO BAI TEST! ---";
        assert false report "SIMULATION SUCCESSFUL" severity failure;
        wait;
    end process;
end behavior;