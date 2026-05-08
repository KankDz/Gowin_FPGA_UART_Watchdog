
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_system is
    port (
        clk               : in  std_logic;
        rx_i              : in  std_logic;
        tx_o              : out std_logic;
        btn_kick_i        : in  std_logic; 
        btn_en_i          : in  std_logic;        
        wdo_o             : out std_logic; 
        enout_o           : out std_logic  
    );
end top_system;

architecture rtl of top_system is
    component uart_tx_rx is
        Port (
            clk         : in  std_logic;
            rx_i        : in  std_logic;
            tx_o        : out std_logic;
            read_rx     : in  std_logic;
            empty_rx    : out std_logic;
            ffrx_data_o : out std_logic_vector (7 downto 0);
            tx_w_data_i : in  std_logic_vector ( 7 downto 0);
            write_tx    : in  std_logic;
            tx_full     : out std_logic
        );
    end component;
    component uart_engine is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            empty_o    : in  std_logic;
            rdata_o    : in  std_logic_vector(7 downto 0);
            rd_i       : out std_logic;
            full_o     : in  std_logic;
            wdata_i    : out std_logic_vector(7 downto 0);
            wd_i       : out std_logic;
            wr_en      : out std_logic;
            rd_en      : out std_logic;
            addr       : out std_logic_vector(7 downto 0);
            wdata      : out std_logic_vector(31 downto 0);
            rdata      : in  std_logic_vector(31 downto 0);
            kick_pulse : out std_logic
        );
    end component;
    component regfile is
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
    end component;
    component watchdog is 
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
    signal w_rx_empty : std_logic;
    signal w_rx_data  : std_logic_vector(7 downto 0);
    signal w_rx_read  : std_logic;
    signal w_tx_full  : std_logic;
    signal w_tx_data  : std_logic_vector(7 downto 0);
    signal w_tx_write : std_logic;
    signal bus_wr_en  : std_logic;
    signal bus_rd_en  : std_logic;
    signal bus_addr   : std_logic_vector(7 downto 0);
    signal bus_wdata  : std_logic_vector(31 downto 0);
    signal bus_rdata  : std_logic_vector(31 downto 0);
    signal bus_kick_pulse : std_logic;
    signal reg_wdi    : std_logic;
    signal reg_en_sw  : std_logic;
    signal reg_twd    : std_logic_vector(31 downto 0);
    signal reg_trst   : std_logic_vector(31 downto 0);
    signal reg_arm    : std_logic_vector(15 downto 0); 
    signal wdt_wdo    : std_logic;
    signal wdt_enout  : std_logic;
    signal wdt_fault  : std_logic;
    signal reg_clr_fault   : std_logic;
    signal wdt_en_combined : std_logic;
    signal rst_tie_low  : std_logic := '0'; 
    signal rst_tie_high : std_logic := '1'; 
begin

    wdt_fault <= not wdt_wdo;
    wdt_en_combined <= btn_en_i or reg_en_sw;
    u_uart : uart_tx_rx port map (
        clk         => clk,
        rx_i        => rx_i,
        tx_o        => tx_o,
        empty_rx    => w_rx_empty,
        ffrx_data_o => w_rx_data,
        read_rx     => w_rx_read,
        tx_full     => w_tx_full,
        tx_w_data_i => w_tx_data,
        write_tx    => w_tx_write
    );

    u_engine : uart_engine port map (
        clk        => clk,
        rst        => rst_tie_low,  
        empty_o    => w_rx_empty,
        rdata_o    => w_rx_data,
        rd_i       => w_rx_read,
        full_o     => w_tx_full,
        wdata_i    => w_tx_data,
        wd_i       => w_tx_write,
        wr_en      => bus_wr_en,
        rd_en      => bus_rd_en,
        addr       => bus_addr,
        wdata      => bus_wdata,
        rdata      => bus_rdata,
        kick_pulse => bus_kick_pulse
    );
    u_regfile : regfile port map (
        clk               => clk,
        rst_n             => rst_tie_high, 
        wr_en             => bus_wr_en,
        rd_en             => bus_rd_en,
        addr              => bus_addr,
        wdata             => bus_wdata,
        rdata             => bus_rdata,
        
        kick_pulse_i      => bus_kick_pulse,
        btn_kick_i        => btn_kick_i,
        wdi_o             => reg_wdi,
        
        en_effective_i    => btn_en_i,
        fault_active_i    => wdt_fault,
        enout_i           => wdt_enout,
        wdo_i             => wdt_wdo,
        
        en_sw_o           => reg_en_sw,
        wdi_src_o         => open,              
        clr_fault_pulse_o => reg_clr_fault,     
        reset_sw_o        => open,              
        twd_ms_o          => reg_twd,
        trst_ms_o         => reg_trst,
        arm_delay_us_o    => reg_arm
    );
    u_watchdog : watchdog port map (
        clk   => clk,
        rst   => rst_tie_low,      
        en    => wdt_en_combined, 
        wdi   => reg_wdi,
        ctrl  => reg_clr_fault,   
        Twd   => reg_twd,
        trst  => reg_trst,
        tarm  => reg_arm,
        wdo   => wdt_wdo,
        enout => wdt_enout
    );
    wdo_o   <= wdt_wdo;
    enout_o <= wdt_enout;
end rtl;