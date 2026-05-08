
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    port (
        clk               : in  std_logic;
        rst_n             : in  std_logic;
        wr_en             : in  std_logic;
        rd_en             : in  std_logic;
        addr              : in  std_logic_vector(7 downto 0);
        wdata             : in  std_logic_vector(31 downto 0);
        rdata             : out std_logic_vector(31 downto 0);
        kick_pulse_i      : in std_logic;  
        btn_kick_i        : in std_logic;  
        wdi_o             : out std_logic; 
        en_effective_i    : in std_logic;
        fault_active_i    : in std_logic;
        enout_i           : in std_logic;
        wdo_i             : in std_logic;
        en_sw_o           : out std_logic;
        wdi_src_o         : out std_logic;
        clr_fault_pulse_o : out std_logic;
        reset_sw_o        : out std_logic;
        twd_ms_o          : out std_logic_vector(31 downto 0);
        trst_ms_o         : out std_logic_vector(31 downto 0);
        arm_delay_us_o    : out std_logic_vector(15 downto 0) 
    );
end entity;

architecture rtl of regfile is
    constant REG_CTRL         : std_logic_vector(7 downto 0) := x"00";
    constant REG_TWD_MS       : std_logic_vector(7 downto 0) := x"04";
    constant REG_TRST_MS      : std_logic_vector(7 downto 0) := x"08";
    constant REG_ARM_DELAY_US : std_logic_vector(7 downto 0) := x"0C";
    constant REG_STATUS       : std_logic_vector(7 downto 0) := x"10";
    constant DEFAULT_TWD_MS       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(135000000, 32));
    constant DEFAULT_TRST_MS      : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(5400000, 32));
    constant DEFAULT_ARM_DELAY_US : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(4050, 16));
    signal ctrl_en_sw_r           : std_logic := '0';
    signal ctrl_wdi_src_r         : std_logic := '0';
    signal ctrl_clr_fault_pulse_r : std_logic := '0';
    signal ctrl_reset_sw_r        : std_logic := '0';
    signal twd_ms_r       : std_logic_vector(31 downto 0) := DEFAULT_TWD_MS;
    signal trst_ms_r      : std_logic_vector(31 downto 0) := DEFAULT_TRST_MS;
    signal arm_delay_us_r : std_logic_vector(15 downto 0) := DEFAULT_ARM_DELAY_US; -- 16-BIT
    signal status_r : std_logic_vector(31 downto 0);
    signal rdata_r  : std_logic_vector(31 downto 0);
    signal kick_sel : std_logic;
    signal kick_d   : std_logic := '0';
    signal wdi_r    : std_logic := '1';

begin
process(clk, rst_n)
begin
    if rst_n = '0' then
        ctrl_en_sw_r           <= '0';
        ctrl_wdi_src_r         <= '0';
        ctrl_clr_fault_pulse_r <= '0';
        ctrl_reset_sw_r        <= '0';
        twd_ms_r               <= DEFAULT_TWD_MS;
        trst_ms_r              <= DEFAULT_TRST_MS;
        arm_delay_us_r         <= DEFAULT_ARM_DELAY_US;

    elsif rising_edge(clk) then
        ctrl_clr_fault_pulse_r <= '0';
        if wr_en = '1' then
            case addr is
                when REG_CTRL =>
                    ctrl_en_sw_r    <= wdata(0);
                    ctrl_wdi_src_r  <= wdata(1);
                    ctrl_reset_sw_r <= wdata(3);        
                    if wdata(2) = '1' then
                        ctrl_clr_fault_pulse_r <= '1';
                    end if;
                when REG_TWD_MS =>
                    twd_ms_r <= wdata;
                when REG_TRST_MS =>
                    trst_ms_r <= wdata;
                when REG_ARM_DELAY_US =>
                    arm_delay_us_r <= wdata(15 downto 0); 
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;
process(en_effective_i, fault_active_i, enout_i, wdo_i)
begin
    status_r <= (others => '0');
    status_r(0) <= en_effective_i;
    status_r(1) <= fault_active_i;
    status_r(2) <= enout_i;
    status_r(3) <= wdo_i;
end process;
process(rd_en, addr,fault_active_i,ctrl_en_sw_r, ctrl_wdi_src_r, ctrl_reset_sw_r,
        twd_ms_r, trst_ms_r, arm_delay_us_r, status_r)
begin
    rdata_r <= (others => '0');

    if rd_en = '1' then
        case addr is
            when REG_CTRL =>
                rdata_r(0) <= ctrl_en_sw_r;
                rdata_r(1) <= ctrl_wdi_src_r;
                rdata_r(2) <= fault_active_i; 
                rdata_r(3) <= ctrl_reset_sw_r;
            when REG_TWD_MS =>
                rdata_r <= twd_ms_r;
            when REG_TRST_MS =>
                rdata_r <= trst_ms_r;
            when REG_ARM_DELAY_US =>
                rdata_r(15 downto 0) <= arm_delay_us_r; 
            when REG_STATUS =>
                rdata_r <= status_r;
            when others =>
                null;
        end case;
    end if;
end process;
    kick_sel <= btn_kick_i when ctrl_wdi_src_r = '0' else kick_pulse_i;
process(clk, rst_n)
    begin
    if rst_n = '0' then
        kick_d <= '0';
        wdi_r  <= '1';

    elsif rising_edge(clk) then
        kick_d <= kick_sel;

        if (kick_d = '1' and kick_sel = '0') then
            wdi_r <= '0';
        else
            wdi_r <= '1';
        end if;
    end if;
end process;
rdata             <= rdata_r;
en_sw_o           <= ctrl_en_sw_r;
wdi_src_o         <= ctrl_wdi_src_r;
clr_fault_pulse_o <= ctrl_clr_fault_pulse_r;
reset_sw_o        <= ctrl_reset_sw_r;
twd_ms_o          <= twd_ms_r;
trst_ms_o         <= trst_ms_r;
arm_delay_us_o    <= arm_delay_us_r;
wdi_o             <= wdi_r;
end architecture;