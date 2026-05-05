library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_system is
end tb_top_system;

architecture behavior of tb_top_system is

    -- G?I TOP MODULE
    component top_system is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            rx_i       : in  std_logic;
            tx_o       : out std_logic;
            wr_en      : out std_logic;
            rd_en      : out std_logic;
            addr       : out std_logic_vector(7 downto 0);
            wdata      : out std_logic_vector(31 downto 0);
            rdata      : in  std_logic_vector(31 downto 0)
        );
    end component;

    -- DÂY K?T N?I
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal rx_i        : std_logic := '1'; -- Idle c?a UART luôn là '1'
    signal tx_o        : std_logic;
    
    -- Dây Bus gi? l?p
    signal wr_en       : std_logic;
    signal rd_en       : std_logic;
    signal addr        : std_logic_vector(7 downto 0);
    signal wdata       : std_logic_vector(31 downto 0);
    signal rdata       : std_logic_vector(31 downto 0) := x"12345678"; -- Data gi? l?p lúc b? ??c

    -- THÔNG S? TH?I GIAN (Clock 27MHz, Baud 115200)
    constant clk_period : time := 37 ns;   
    constant bit_period : time := 8681 ns; 
    signal sim_done     : boolean := false;

    -- TH? T?C B?N BYTE QUA ???NG SERIAL (Gi? l?p PC)
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
    -- RÁP M?CH
    uut: top_system port map (
        clk => clk, rst => rst, rx_i => rx_i, tx_o => tx_o,
        wr_en => wr_en, rd_en => rd_en, addr => addr,
        wdata => wdata, rdata => rdata
    );

    -- T?O CLOCK 27MHz
    clk_process :process
    begin
        while not sim_done loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- K?CH B?N ??I CHI?N
    stim_proc: process
    begin
        -- 0. Reset h? th?ng
        wait for 100 ns;
        rst <= '0';
        wait for 10 us;

        -- =========================================================
        -- TEST CASE 1: MÁY TÍNH RA L?NH "GHI" QUA UART
        -- L?nh: Ghi giá tr? 0x1122 vào ??a ch? 0x10
        -- Checksum = CMD(01) ^ ADDR(10) ^ LEN(02) ^ D0(11) ^ D1(22) = 0x20
        -- =========================================================
        -- B?n n?i ti?p t?ng bit qua dây cáp (rx_i)
        send_byte(x"55", rx_i); -- Header
        send_byte(x"01", rx_i); -- CMD (Write)
        send_byte(x"10", rx_i); -- ADDR
        send_byte(x"02", rx_i); -- LEN (2 bytes)
        send_byte(x"11", rx_i); -- DATA 0
        send_byte(x"22", rx_i); -- DATA 1
        send_byte(x"20", rx_i); -- CHECKSUM
        
        -- ??i h? th?ng x? lý, ??y ra Bus, và m?ch TX t? ??ng b?n mã ACK (0xAA) v? PC
        -- M?t kho?ng 1 khung truy?n TX (86us) + th?i gian x? lý
        wait for 200 us; 

        -- =========================================================
        -- TEST CASE 2: MÁY TÍNH RA L?NH "??C" QUA UART
        -- L?nh: ??c d? li?u t? ??a ch? 0xA5
        -- Checksum = CMD(02) ^ ADDR(A5) ^ LEN(00) = 0xA7
        -- =========================================================
        send_byte(x"55", rx_i); -- Header
        send_byte(x"02", rx_i); -- CMD (Read)
        send_byte(x"A5", rx_i); -- ADDR
        send_byte(x"00", rx_i); -- LEN (0 bytes)
        send_byte(x"A7", rx_i); -- CHECKSUM

        -- M?ch Engine s? ??c cái x"12345678" ? Bus, b?m nh?, tính Checksum m?i 
        -- r?i nhét vào TX FIFO. Kh?i TX s? tu?n t? b?n 6 bytes v? PC.
        -- 6 bytes * 86.8us = ~520us
        wait for 800 us;

        -- Ch?m d?t mô ph?ng
        sim_done <= true;
        wait;
    end process;

end behavior;
