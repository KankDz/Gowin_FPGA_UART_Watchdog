library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_engine_fwft is
end tb_uart_engine_fwft;

architecture behavior of tb_uart_engine_fwft is

    -- Khai báo kh?i uart_engine (FSM m?i)
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
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal empty_o  : std_logic;
    signal rdata_o  : std_logic_vector(7 downto 0);
    signal rd_i     : std_logic;
    signal full_o   : std_logic := '0';
    signal wdata_i  : std_logic_vector(7 downto 0);
    signal wd_i     : std_logic;
    signal wr_en    : std_logic;
    signal rd_en    : std_logic;
    signal addr     : std_logic_vector(7 downto 0);
    signal wdata    : std_logic_vector(31 downto 0);
    signal rdata    : std_logic_vector(31 downto 0) := x"DEADBEEF";
    constant clk_period : time := 20 ns;
    signal sim_done : boolean := false;
    type mem_t is array (0 to 255) of std_logic_vector(7 downto 0);
    signal rx_mem  : mem_t := (others => x"00");
    signal rx_head : integer := 0;
    signal rx_tail : integer := 0;
begin

    uut: uart_engine port map (
        clk => clk, rst => rst,
        empty_o => empty_o, rdata_o => rdata_o, rd_i => rd_i,
        full_o => full_o, wdata_i => wdata_i, wd_i => wd_i,
        wr_en => wr_en, rd_en => rd_en, addr => addr,
        wdata => wdata, rdata => rdata
    );
    process
    begin
        while not sim_done loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;
    empty_o <= '1' when rx_head = rx_tail else '0';
    rdata_o <= rx_mem(rx_head) when rx_head /= rx_tail else x"00";
    process(clk)
    begin
        if rising_edge(clk) then
            if rd_i = '1' and rx_head /= rx_tail then
                rx_head <= rx_head + 1;
            end if;
        end if;
    end process;
    process
        variable v_tail : integer := 0;
        procedure push (data : std_logic_vector(7 downto 0)) is
        begin
            rx_mem(v_tail) <= data;
            v_tail := v_tail + 1;
            rx_tail <= v_tail; 
        end procedure;
    begin
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        push(x"55"); 
        push(x"01"); 
        push(x"10"); 
        push(x"02"); 
        push(x"11"); 
        push(x"22"); 
        push(x"20"); 
        wait for 600 ns;
        push(x"55"); 
        push(x"02"); 
        push(x"A5"); 
        push(x"00"); 
        push(x"A7");
        wait for 1 us;
        sim_done <= true;
        wait;
    end process;
end behavior;