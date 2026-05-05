library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_system is
    port (
        -- Tín hi?u h? th?ng c? b?n
        clk        : in  std_logic;
        rst        : in  std_logic; -- Reset này s? ch? c?p cho Engine, vì uart_tx_rx c?a bro ko có rst

        -- Giao ti?p UART v?i PC (c?m cáp USB)
        rx_i       : in  std_logic;
        tx_o       : out std_logic;

        -- Giao ti?p BUS 32-bit (N?i v?i các m?ch ngo?i vi khác)
        wr_en      : out std_logic;
        rd_en      : out std_logic;
        addr       : out std_logic_vector(7 downto 0);
        wdata      : out std_logic_vector(31 downto 0);
        rdata      : in  std_logic_vector(31 downto 0)
    );
end top_system;

architecture rtl of top_system is

    -- ==========================================
    -- 1. G?I TÊN 2 KH?I COMPONENT
    -- ==========================================
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
            rdata      : in  std_logic_vector(31 downto 0)
        );
    end component;

    -- ==========================================
    -- 2. KHAI BÁO DÂY ?I?N N?I B? ?? ??U N?I
    -- ==========================================
    -- Dây cho chi?u Nh?n (RX)
    signal w_rx_empty : std_logic;
    signal w_rx_data  : std_logic_vector(7 downto 0);
    signal w_rx_read  : std_logic;

    -- Dây cho chi?u Phát (TX)
    signal w_tx_full  : std_logic;
    signal w_tx_data  : std_logic_vector(7 downto 0);
    signal w_tx_write : std_logic;

begin

    -- ==========================================
    -- 3. RÁP KH?I UART_TX_RX (SHIPPER)
    -- ==========================================
    u_uart : uart_tx_rx port map (
        clk         => clk,
        rx_i        => rx_i,       -- Chân nh?n v?t lý
        tx_o        => tx_o,       -- Chân phát v?t lý
        
        -- Dây n?i vào Engine (Chi?u RX)
        empty_rx    => w_rx_empty,
        ffrx_data_o => w_rx_data,
        read_rx     => w_rx_read,
        
        -- Dây n?i t? Engine (Chi?u TX)
        tx_full     => w_tx_full,
        tx_w_data_i => w_tx_data,
        write_tx    => w_tx_write
    );

    -- ==========================================
    -- 4. RÁP KH?I UART_ENGINE (??I T??NG)
    -- ==========================================
    u_engine : uart_engine port map (
        clk        => clk,
        rst        => rst,
        
        -- Dây n?i v?i UART (Chi?u RX)
        empty_o    => w_rx_empty,
        rdata_o    => w_rx_data,
        rd_i       => w_rx_read,
        
        -- Dây n?i v?i UART (Chi?u TX)
        full_o     => w_tx_full,
        wdata_i    => w_tx_data,
        wd_i       => w_tx_write,
        
        -- Chân ??a ra Bus 32-bit bên ngoài
        wr_en      => wr_en,
        rd_en      => rd_en,
        addr       => addr,
        wdata      => wdata,
        rdata      => rdata
    );

end rtl;
