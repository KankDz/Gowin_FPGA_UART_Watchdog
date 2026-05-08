library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_system is
end tb_top_system;

architecture behavior of tb_top_system is

    -- 1. KHAI BAO UUT (Unit Under Test)
    component top_system
        port (
            clk        : in  std_logic;
       
            rx_i       : in  std_logic;
            tx_o       : out std_logic;
            btn_kick_i : in  std_logic;
            btn_en_i   : in  std_logic;
            wdo_o      : out std_logic;
            enout_o    : out std_logic
        );
    end component;

    -- 2. KHAI BAO TIN HIEU
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1'; 
    signal rx_i       : std_logic := '1'; 
    signal btn_kick_i : std_logic := '0';
    signal btn_en_i   : std_logic := '0';

    signal tx_o       : std_logic;
    signal wdo_o      : std_logic;
    signal enout_o    : std_logic;

    -- 3. CAU HINH THOI GIAN (Thach anh 27MHz, Baud 115200)
    constant clk_period : time := 37.037 ns; 
    constant bit_period : time := 8.680 us;  


    -- =========================================================
    -- B? CÔNG C? PROCEDURE GI? L?P MÁY TÍNH (AUTO CHECKSUM)
    -- =========================================================
    
    -- Thu tuc gui 1 byte co ban
    procedure send_byte(data_in : in std_logic_vector(7 downto 0); signal tx_line : out std_logic) is
    begin
        tx_line <= '0'; wait for bit_period; -- Start bit
        for i in 0 to 7 loop
            tx_line <= data_in(i); wait for bit_period; -- Data bits
        end loop;
        tx_line <= '1'; wait for bit_period; -- Stop bit
    end procedure;

    -- Thu tuc gui lenh GHI (CMD = 0x01)
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

    -- Thu tuc gui lenh DOC (CMD = 0x02)
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

    -- Thu tuc gui lenh KICK (CMD = 0x03)
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

    -- Thu tuc gui lenh DOC STATUS (CMD = 0x04)
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

    -- RAP MACH
    uut: top_system port map (
        clk        => clk,
        rx_i       => rx_i,
        tx_o       => tx_o,
        btn_kick_i => btn_kick_i,
        btn_en_i   => btn_en_i,
        wdo_o      => wdo_o,
        enout_o    => enout_o
    );

    -- TAO XUNG CLOCK 27MHz
    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- =========================================================
    -- K?CH B?N TEST CHÍNH
    -- =========================================================
    stim_proc: process
    begin
        report "--- TEST 1: KHOI DONG VA RESET MACH ---";
       rx_i <= '1'; btn_en_i <= '0'; btn_kick_i <= '0';
        wait for 100 ns;
    
        wait for 20 us;

        report "--- TEST 2: GHI CAU HINH QUA UART (RUT NGAN TWD/TRST) --";
        -- Set Twd = 2 mili-giay (54.000 xung clock = x"0000D2F0")
        uart_write_reg(x"04", x"0000D2F0", rx_i);
        wait for 100 us;
        
        -- Set tRst = 0.5 mili-giay (13.500 xung clock = x"000034BC")
        uart_write_reg(x"08", x"000034BC", rx_i);
        wait for 100 us;

        report "--- TEST 3: DOC LAI THANH GHI TWD ---";
        -- Kiem tra tren GTKWave xem tx_o co tra ve F0 D2 00 00 khong
        uart_read_reg(x"04", rx_i);
        wait for 150 us;

        report "--- TEST 4: TEST ENABLE & KICK BANG PHAN CUNG ---";
        btn_en_i <= '1'; -- Bat cong tac S2
        wait for 1 ms;   -- Cho chay 1 nua thoi gian Twd
        
        btn_kick_i <= '1'; -- Bam nut S1
        wait for 10 us;
        btn_kick_i <= '0';
        wait for 100 us;

        report "--- TEST 5: CHUYEN QUYEN CHO PHAN MEM (UART ENABLE & KICK) ---";
        btn_en_i <= '0'; -- Tat cong tac cung
        -- Ghi CTRL: en_sw = 1, wdi_src = 1 (Bit 0 va Bit 1 = 1 -> Value = 0x03)
        uart_write_reg(x"00", x"00000003", rx_i);
        wait for 100 us;
        
        -- Thuc hien da Watchdog bang UART (CMD = 0x03)
        uart_kick(rx_i);
        wait for 100 us;

        report "--- TEST 6: CO TINH BO DOI DE TAO LOI (TIME-OUT FAULT) ---";
        -- Chung ta da set Twd = 2ms. Bây gio doi > 2ms de wdo_o bi keo xuong 0
        wait for 2.5 ms;

        report "--- TEST 7: DOC TRANG THAI LOI VA XOA LOI ---";
        -- 1. Doc STATUS xem he thong co ghi nhan loi wdo = 0 khong
        uart_read_status(rx_i);
        wait for 150 us;

        -- 2. Ghi CTRL de xoa loi (Clear Fault Pulse - Bit 2 = 1 -> Value = 0x07)
        uart_write_reg(x"00", x"00000007", rx_i);
        wait for 150 us;
        
        -- 3. Tra lai CTRL binh thuong (Tat Clear, giu Enable & Wdi_src -> Value = 0x03)
        uart_write_reg(x"00", x"00000003", rx_i);
        wait for 100 us;

        report "--- TEST 8: TEST CHONG NHIEU (GOI TIN SAI CHECKSUM) ---";
        -- Gui thu cong mot goi tin DOC thanh ghi nhung co tinh lam sai bit cuoi
        send_byte(x"55", rx_i);
        send_byte(x"02", rx_i);
        send_byte(x"00", rx_i);
        send_byte(x"00", rx_i);
        send_byte(x"FF", rx_i); -- Checksum that su phai la 02, nhung gui FF
        wait for 150 us;
        -- Tren GTKWave, mach se KHONG phan hoi gi o tx_o cho goi tin nay!

        report "--- HOAN THANH TOAN BO BAI TEST! ---";
        assert false report "SIMULATION SUCCESSFUL" severity failure;
        wait;
    end process;

end behavior;