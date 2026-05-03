library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_watchdog is
-- Testbench không có port
end tb_watchdog;

architecture behavior of tb_watchdog is

    -- Khai báo component DUT (Device Under Test)
    component watchdog
    port(
        ctrl  : in std_logic;
        en    : in std_logic;
        clk   : in std_logic;
        wdi   : in std_logic;
        rst   : in std_logic;
        wdo   : out std_logic;
        enout : out std_logic;
        Twd   : in std_logic_vector (31 downto 0);
        trst  : in std_logic_vector (31 downto 0);
        tarm  : in std_logic_vector (15 downto 0)
    );
    end component;

    -- Khai báo tín hi?u ??u vào (Inputs)
    signal ctrl_tb  : std_logic := '0';
    signal en_tb    : std_logic := '0';
    signal clk_tb   : std_logic := '0';
    signal wdi_tb   : std_logic := '1'; -- Default wdi ?? ? m?c 1
    signal rst_tb   : std_logic := '1'; -- Tích c?c m?c cao
    signal Twd_tb   : std_logic_vector(31 downto 0) := (others => '0');
    signal trst_tb  : std_logic_vector(31 downto 0) := (others => '0');
    signal tarm_tb  : std_logic_vector(15 downto 0) := (others => '0');

    -- Khai báo tín hi?u ??u ra (Outputs)
    signal wdo_tb   : std_logic;
    signal enout_tb : std_logic;

    -- H?ng s? chu k? xung nh?p
    constant clk_period : time := 10 ns; -- Clock 100MHz

begin

    -- Instantiate Device Under Test (DUT)
    uut: watchdog port map (
        ctrl  => ctrl_tb,
        en    => en_tb,
        clk   => clk_tb,
        wdi   => wdi_tb,
        rst   => rst_tb,
        wdo   => wdo_tb,
        enout => enout_tb,
        Twd   => Twd_tb,
        trst  => trst_tb,
        tarm  => tarm_tb
    );

    -- Quá trình t?o xung nh?p (Clock Process)
    clk_process :process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Quá trình t?o d? li?u ki?m tra (Stimulus Process)
    stim_proc: process
    begin
        -- =========================================================
        -- GIAI ?O?N 0: Kh?i t?o và Thi?t l?p thông s?
        -- =========================================================
        -- Cài ??t th?i gian cho các b? ??m (Giá tr? nh? ?? mô ph?ng nhanh)
        Twd_tb  <= std_logic_vector(to_unsigned(20, 32)); -- Time watchdog = 20
        trst_tb <= std_logic_vector(to_unsigned(5, 32));  -- Time reset = 5
        tarm_tb <= std_logic_vector(to_unsigned(10, 16)); -- Time arming = 10
        
        -- Kích ho?t Reset h? th?ng ban ??u
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        wait for clk_period * 2;

        -- =========================================================
        -- GIAI ?O?N 1: B?t Watchdog và C?p xung bình th??ng (Feed the Dog)
        -- =========================================================
        -- K? v?ng: wdo luôn ? m?c 1 (không báo ??ng) do wdi liên t?c t?o c?nh xu?ng
        ctrl_tb <= '0'; -- ??m b?o KHÔNG nh?n nút ng?t báo ??ng th? công
        en_tb   <= '1'; -- B?t h? th?ng
        
        -- ??i qua th?i gian kh?i ??ng (arming time)
        wait for clk_period * 10; 
        
        -- T?o thao tác "Feed the dog" 3 l?n liên ti?p
        for i in 0 to 2 loop
            wait for clk_period * 15; 
            -- T?o c?nh xu?ng cho WDI (Feeding)
            wdi_tb <= '0';
            wait for clk_period * 2;
            wdi_tb <= '1';
        end loop;

        -- =========================================================
        -- GIAI ?O?N 2: B? ?ói Watchdog (Timeout Error)
        -- =========================================================
        -- K? v?ng: Không c?p xung wdi n?a. 
        -- FSM c?n 3 clock cycle cho m?i l?n t?ng bi?n ??m, nên ?? ??m t?i 20 c?n 60 chu k?.
        
        wait for clk_period * 80; -- Ch? 80 chu k? (?? lâu ?? m?ch c?n và wdo r?t xu?ng 0)
        
        -- Lúc này wdo_tb s? xu?ng m?c 0. ??i m?t lúc ?? quan sát trên ?? th?.
        wait for clk_period * 15; 

        -- Reset l?i h? th?ng ?? làm l?i t? ??u
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        wait for clk_period * 5;

        -- =========================================================
        -- GIAI ?O?N 3: Vô hi?u hóa tín hi?u ?i?u khi?n (Disable)
        -- =========================================================
        -- K? v?ng: Khi en = 0, dù có b? ?ói watchdog thì wdo v?n b?ng 1 (không báo ??ng)
        ctrl_tb <= '0';
        en_tb   <= '0'; -- Vô hi?u hóa (T?t Watchdog)
        
        wait for clk_period * 80; 
        
        -- =========================================================
        -- GIAI ?O?N 4: Test ch?c n?ng ng?t báo ??ng th? công (Tùy ch?n)
        -- =========================================================
        en_tb <= '1';
        wait for clk_period * 80; -- ??i cho m?ch báo ??ng (wdo = 0)
        
        -- B?m nút ctrl = 1 ?? xem m?ch có l?p t?c t?t báo ??ng và reset không
        ctrl_tb <= '1';
        wait for clk_period * 5;
        ctrl_tb <= '0';
        
        -- K?t thúc mô ph?ng
        wait for clk_period * 10;

        -- =========================================================
        -- GIAI ?O?N 5: Thay ??i giá tr? Twd gi?a ch?ng (On-the-fly change)
        -- =========================================================
        -- Reset và thi?t l?p ban ??u
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        
        Twd_tb <= std_logic_vector(to_unsigned(30, 32)); -- Cài Twd dài (30)
        en_tb  <= '1'; 
        wait for clk_period * 10; -- Ch? h?t th?i gian arming
        
        -- Cho h? th?ng ??m th? m?t ?o?n (VD: ??m ???c 15 chu k?)
        wait for clk_period * 45; -- (15 l?n ??m * 3 clock/vòng l?p FSM)
        
        -- ??t ng?t thay ??i Twd xu?ng m?c th?p h?n giá tr? ?ang ??m!
        -- ??i Twd t? 30 xu?ng 10 (trong khi bi?n ??m bên trong ?ã v??t qua 10)
        Twd_tb <= std_logic_vector(to_unsigned(10, 32));
        
        -- Ch? xem h? th?ng x? lý th? nào (có báo ??ng ngay, hay b? treo ??m tràn?)
        wait for clk_period * 100;
        assert false report "End of Simulation" severity failure;
        
    end process;

end behavior;