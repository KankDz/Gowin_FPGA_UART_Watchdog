library ieee;
use ieee.std_logic_1164.all;

entity uart_subsystem is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic; -- Reset m?c cao (c?p cho Engine)

        -- UART Physical
        rx_i     : in  std_logic;
        tx_o     : out std_logic;

        -- BUS Interface (N?i sang Regfile)
        bus_wr_en : out std_logic;
        bus_rd_en : out std_logic;
        bus_addr  : out std_logic_vector(7 downto 0);
        bus_wdata : out std_logic_vector(31 downto 0);
        bus_rdata : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of uart_subsystem is
    -- Tín hi?u trung gian n?i gi?a 2 kh?i
    signal empty_sig : std_logic;
    signal rdata_sig : std_logic_vector(7 downto 0);
    signal rd_en_sig : std_logic;

    signal full_sig  : std_logic;
    signal wdata_sig : std_logic_vector(7 downto 0);
    signal wr_en_sig : std_logic;

begin

    -- 1. Kh?i V?t lı & FIFO (Physical Layer)
    u_phy : entity work.uart_tx_rx
    port map (
        clk         => clk,
        rx_i        => rx_i,
        tx_o        => tx_o,
        -- ??c t? RX FIFO sang Engine
        read_rx     => rd_en_sig,
        empty_rx    => empty_sig,
        ffrx_data_o => rdata_sig,
        -- Ghi t? Engine xu?ng TX FIFO
        tx_w_data_i => wdata_sig,
        write_tx    => wr_en_sig,
        tx_full     => full_sig
    );

    -- 2. Kh?i X? lı Giao th?c (Protocol Layer)
    u_engine : entity work.uart_engine
    port map (
        clk      => clk,
        rst      => rst,
        -- RX Interface
        empty_o  => empty_sig,
        rdata_o  => rdata_sig,
        rd_i     => rd_en_sig,
        -- TX Interface
        full_o   => full_sig,
        wdata_i  => wdata_sig,
        wd_i     => wr_en_sig,
        -- BUS Interface
        wr_en    => bus_wr_en,
        rd_en    => bus_rd_en,
        addr     => bus_addr,
        wdata    => bus_wdata,
        rdata    => bus_rdata
    );

end architecture;