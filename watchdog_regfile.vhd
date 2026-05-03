library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_top is
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic; -- Reset c?ng h? th?ng (active low)
        
        -- Giao ti?p Bus (gi? l?p t? UART)
        wr_en          : in  std_logic;
        rd_en          : in  std_logic;
        addr           : in  std_logic_vector(7 downto 0);
        wdata          : in  std_logic_vector(31 downto 0);
        rdata          : out std_logic_vector(31 downto 0);

        -- Watchdog External Signals
        wdi_ext        : in  std_logic;
        ctrl_ext       : in  std_logic;
        en_effective_i : in  std_logic;
        fault_active_i : in  std_logic;
        
        -- Outputs
        wdo_o          : out std_logic;
        enout_o        : out std_logic
    );
end entity;

architecture rtl of system_top is
    -- Tín hi?u n?i gi?a Regfile và Watchdog
    signal sig_en_sw           : std_logic;
    signal sig_wdi_src         : std_logic;
    signal sig_clr_fault       : std_logic;
    signal sig_reset_sw        : std_logic;
    signal sig_twd             : std_logic_vector(31 downto 0);
    signal sig_trst            : std_logic_vector(31 downto 0);
    signal sig_tarm            : std_logic_vector(15 downto 0);
    signal sig_wdo             : std_logic;
    signal sig_enout           : std_logic;

    -- Reset cho Watchdog (M?c 1 là Reset)
    signal wdt_rst_combined    : std_logic;

begin
    -- Watchdog reset khi: Reset c?ng (rst_n=0) HO?C Reset m?m t? software
    wdt_rst_combined <= (not rst_n) or sig_reset_sw;

    wdo_o   <= sig_wdo;
    enout_o <= sig_enout;

    -- Instantiation: Regfile
    u_regfile: entity work.regfile
        port map (
            clk => clk, rst_n => rst_n,
            wr_en => wr_en, rd_en => rd_en, addr => addr, wdata => wdata, rdata => rdata,
            en_effective_i => en_effective_i, fault_active_i => fault_active_i,
            enout_i => sig_enout, wdo_i => sig_wdo,
            en_sw_o => sig_en_sw, wdi_src_o => sig_wdi_src,
            clr_fault_pulse_o => sig_clr_fault, reset_sw_o => sig_reset_sw,
            twd_ms_o => sig_twd, trst_ms_o => sig_trst, arm_delay_us_o => sig_tarm
        );

    -- Instantiation: Watchdog
    u_watchdog: entity work.watchdog
        port map (
            clk => clk, rst => wdt_rst_combined,
            ctrl => ctrl_ext,
            en => sig_en_sw,
            wdi => wdi_ext, -- ? ?ây t?m th?i n?i tr?c ti?p chân ngoài
            wdo => sig_wdo, enout => sig_enout,
            Twd => sig_twd, trst => sig_trst, tarm => sig_tarm
        );

end architecture;