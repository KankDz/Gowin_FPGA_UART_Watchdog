library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_system is
end entity;

architecture behavior of tb_system is
    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal wr_en, rd_en   : std_logic := '0';
    signal addr           : std_logic_vector(7 downto 0) := (others => '0');
    signal wdata          : std_logic_vector(31 downto 0) := (others => '0');
    signal rdata          : std_logic_vector(31 downto 0);
    signal wdi_ext        : std_logic := '0';
    signal ctrl_ext       : std_logic := '0';
    signal en_effective_i : std_logic := '1';
    signal fault_active_i : std_logic := '0';
    signal wdo_o, enout_o : std_logic;

    constant clk_period : time := 37.037 ns; -- 27MHz

    -- Procedure ghi vào thanh ghi
    procedure cpu_write(
        constant a : in std_logic_vector(7 downto 0);
        constant d : in std_logic_vector(31 downto 0);
        signal s_addr : out std_logic_vector(7 downto 0);
        signal s_data : out std_logic_vector(31 downto 0);
        signal s_wr   : out std_logic
    ) is
    begin
        s_addr <= a; s_data <= d; s_wr <= '1';
        wait for clk_period;
        s_wr <= '0'; s_addr <= x"00";
    end procedure;

begin
    uut: entity work.system_top
        port map (
            clk => clk, rst_n => rst_n, wr_en => wr_en, rd_en => rd_en,
            addr => addr, wdata => wdata, rdata => rdata,
            wdi_ext => wdi_ext, ctrl_ext => ctrl_ext,
            en_effective_i => en_effective_i, fault_active_i => fault_active_i,
            wdo_o => wdo_o, enout_o => enout_o
        );

    clk_process: process begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        -- =========================================================
        -- GIAI ?O?N 1: SETUP BAN ??U
        -- =========================================================
        rst_n <= '0'; wait for 500 ns;
        rst_n <= '1'; wait for 1 us;
        
        -- C?u hình Twd=200 (~7.4us), Tarm=100 (~3.7us)
        cpu_write(x"04", x"000000C8", addr, wdata, wr_en); 
        cpu_write(x"0C", x"00000064", addr, wdata, wr_en); 
        
        -- B?t Dog (Enable)
        cpu_write(x"00", x"00000001", addr, wdata, wr_en); 
        wait for 15 us; -- ??i nó qua ARM và ch?y RUN m?t lúc

        -- =========================================================
        -- CASE 7: THAY ??I TWD ??T NG?T (Config Stress)
        -- ?ang ch?y Twd=200, ta n?p Twd=10 (r?t nh?)
        -- =========================================================
        report "Case 7: Updating Twd during RUN";
        cpu_write(x"04", x"0000000A", addr, wdata, wr_en);
        wait for 5 us; -- Xem nó có timeout s?m không

        -- Thoát kh?i l?i b?ng CTRL ?? test ti?p
        ctrl_ext <= '1'; wait for 200 ns; ctrl_ext <= '0';
        wait for 10 us; -- ??i qua ARM l?n n?a

        -- =========================================================
        -- CASE 8: L?I V?T LÝ T?C THÌ (Hard Fault)
        -- =========================================================
        report "Case 8: Immediate Hardware Fault";
        fault_active_i <= '1'; -- Gi? l?p c?m bi?n báo cháy/quá áp
        wait for 1 us;         -- wdo_o ph?i lên 1 ngay ?o?n này
        fault_active_i <= '0';
        
        -- Recovery
        ctrl_ext <= '1'; wait for 200 ns; ctrl_ext <= '0';
        wait for 10 us;

        -- =========================================================
        -- CASE 9: SOFTWARE RESET GI?A CH?NG
        -- ?ang ARM n?a ch?ng thì ph?n m?m ra l?nh Reset chip
        -- =========================================================
        report "Case 9: Software Reset during ARM";
        cpu_write(x"00", x"00000000", addr, wdata, wr_en); -- T?t Enable
        wait for 1 us;
        cpu_write(x"00", x"00000009", addr, wdata, wr_en); -- B?t Enable + Reset bit (bit 3)
        wait for 200 ns;
        cpu_write(x"00", x"00000001", addr, wdata, wr_en); -- Nh? bit Reset
        wait for 10 us;

        -- =========================================================
        -- CASE 10: C? TÌNH CLEAR L?I KHI FAULT V?N CÒN
        -- =========================================================
        report "Case 10: Clear attempt while Fault is persistent";
        fault_active_i <= '1'; -- L?i v?n ?ang x?y ra
        wait for 2 us;
        -- Ghi vào bit 2 c?a REG_CTRL ?? clr_fault_pulse_o nh?y lên
        cpu_write(x"00", x"00000005", addr, wdata, wr_en); 
        wait for 5 us; -- Ki?m tra: wdo_o v?n ph?i là '1' vì fault_active_i ch?a t?t
        
        fault_active_i <= '0'; -- Gi? m?i h?t l?i th?t
        cpu_write(x"00", x"00000005", addr, wdata, wr_en); -- Clear l?i l?n n?a
        wait for 10 us;

        report "Simulation All Cases Finished" severity note;
        wait;
    end process;

end architecture;