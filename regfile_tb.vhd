library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile_tb is
end entity;

architecture sim of regfile_tb is

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- BUS
    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';
    signal addr  : std_logic_vector(7 downto 0)  := (others => '0');
    signal wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal rdata : std_logic_vector(31 downto 0);

    -- 🔥 KICK signals
    signal kick_pulse_i : std_logic := '0'; -- từ UART
    signal btn_kick_i   : std_logic := '0'; -- từ button

    -- WATCHDOG input
    signal en_effective_i  : std_logic := '0';
    signal fault_active_i  : std_logic := '0';
    signal enout_i         : std_logic := '0';
    signal wdo_i           : std_logic := '1';

    -- OUTPUT
    signal en_sw_o           : std_logic;
    signal reset_sw_o        : std_logic;
    signal wdi_src_o         : std_logic;
    signal clr_fault_pulse_o : std_logic;
    signal twd_ms_o          : std_logic_vector(31 downto 0);
    signal trst_ms_o         : std_logic_vector(31 downto 0);
    signal arm_delay_us_o    : std_logic_vector(15 downto 0);
    signal wdi_o             : std_logic;

    constant REG_CTRL         : std_logic_vector(7 downto 0) := x"00";
    constant REG_TWD_MS       : std_logic_vector(7 downto 0) := x"04";
    constant REG_TRST_MS      : std_logic_vector(7 downto 0) := x"08";
    constant REG_ARM_DELAY_US : std_logic_vector(7 downto 0) := x"0C";
    constant REG_STATUS       : std_logic_vector(7 downto 0) := x"10";

begin

    -- DUT
    dut : entity work.regfile
        port map (
            clk               => clk,
            rst_n             => rst_n,
            wr_en             => wr_en,
            rd_en             => rd_en,
            addr              => addr,
            wdata             => wdata,
            rdata             => rdata,
            en_effective_i    => en_effective_i,
            fault_active_i    => fault_active_i,
            enout_i           => enout_i,
            wdo_i             => wdo_i,
            kick_pulse_i      => kick_pulse_i,
            btn_kick_i        => btn_kick_i,
            en_sw_o           => en_sw_o,
            reset_sw_o        => reset_sw_o,
            wdi_src_o         => wdi_src_o,
            clr_fault_pulse_o => clr_fault_pulse_o,
            twd_ms_o          => twd_ms_o,
            trst_ms_o         => trst_ms_o,
            arm_delay_us_o    => arm_delay_us_o,
            wdi_o             => wdi_o
        );

    -- CLOCK
    clk <= not clk after 5 ns;

    -- ================= STIM =================
    process
    begin
        -- RESET
        rst_n <= '0';
        wait for 20 ns;
        rst_n <= '1';
        wait for 20 ns;

        ----------------------------------------------------------------
        -- TEST 1: WRITE CTRL (EN=1, chọn nguồn UART)
        ----------------------------------------------------------------
        wr_en <= '1';
        addr  <= REG_CTRL;
        wdata <= x"00000003"; -- bit0=1, bit1=1 (UART)
        wait for 10 ns;
        wr_en <= '0';
        wait for 30 ns;

        ----------------------------------------------------------------
        -- TEST 2: WRITE TWD
        ----------------------------------------------------------------
        wr_en <= '1';
        addr  <= REG_TWD_MS;
        wdata <= std_logic_vector(to_unsigned(1000, 32));
        wait for 10 ns;
        wr_en <= '0';
        wait for 30 ns;

        ----------------------------------------------------------------
        -- TEST 3: KICK từ UART 
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        kick_pulse_i <= '1';   -- tạo xung
        wait until rising_edge(clk);
        kick_pulse_i <= '0';   -- về lại 0

        wait for 100 ns;

        ----------------------------------------------------------------
        -- TEST 4: nguồn BUTTON
        ----------------------------------------------------------------
        wr_en <= '1';
        addr  <= REG_CTRL;
        wdata <= x"00000001"; -- bit1=0 => BUTTON
        wait for 10 ns;
        wr_en <= '0';
        wait for 30 ns;

        ----------------------------------------------------------------
        -- TEST 5: KICK từ BUTTON
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        btn_kick_i <= '1';
        wait until rising_edge(clk);
        btn_kick_i <= '0';

        wait for 100 ns;

        ----------------------------------------------------------------
        -- TEST 6: STATUS
        ----------------------------------------------------------------
        en_effective_i <= '1';
        fault_active_i <= '1';
        enout_i        <= '1';
        wdo_i          <= '0';

        rd_en <= '1';
        addr  <= REG_STATUS;
        wait for 10 ns;
        rd_en <= '0';

        wait;

    end process;

end architecture;