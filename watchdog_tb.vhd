library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_watchdog is
-- Testbench không có port
end tb_watchdog;

architecture behavior of tb_watchdog is

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

    signal ctrl_tb  : std_logic := '0';
    signal en_tb    : std_logic := '0';
    signal clk_tb   : std_logic := '0';
    signal wdi_tb   : std_logic := '1'; 
    signal rst_tb   : std_logic := '1'; 
    signal Twd_tb   : std_logic_vector(31 downto 0) := (others => '0');
    signal trst_tb  : std_logic_vector(31 downto 0) := (others => '0');
    signal tarm_tb  : std_logic_vector(15 downto 0) := (others => '0');

    signal wdo_tb   : std_logic;
    signal enout_tb : std_logic;
    constant clk_period : time := 10 ns; 

begin
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

    clk_process :process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;
    stim_proc: process
    begin
        Twd_tb  <= std_logic_vector(to_unsigned(20, 32)); 
        trst_tb <= std_logic_vector(to_unsigned(5, 32));  
        tarm_tb <= std_logic_vector(to_unsigned(10, 16)); 
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        wait for clk_period * 2;
        ctrl_tb <= '0';
        en_tb   <= '1'; 
        wait for clk_period * 10; 
        for i in 0 to 2 loop
            wait for clk_period * 15; 

            wdi_tb <= '0';
            wait for clk_period * 2;
            wdi_tb <= '1';
        end loop;
        wait for clk_period * 80;
        wait for clk_period * 15; 
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        wait for clk_period * 5;
        ctrl_tb <= '0';
        en_tb   <= '0';     
        wait for clk_period * 80; 
        en_tb <= '1';
        wait for clk_period * 80; 
        ctrl_tb <= '1';
        wait for clk_period * 5;
        ctrl_tb <= '0';
        
        wait for clk_period * 10;
        rst_tb <= '1';
        wait for clk_period * 5;
        rst_tb <= '0';
        
        Twd_tb <= std_logic_vector(to_unsigned(30, 32)); 
        en_tb  <= '1'; 
        wait for clk_period * 10; 

        wait for clk_period * 45; 

        Twd_tb <= std_logic_vector(to_unsigned(10, 32));
        
        wait for clk_period * 100;
        assert false report "End of Simulation" severity failure;
        
    end process;

end behavior;