library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity watchdog is 
  port(
    ctrl : in std_logic;
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
end watchdog;

architecture rtl of watchdog is 
  signal clr_twd, clr_wdi, en_arm, en_twd, en_trst, clr_arm, clr_trst : std_logic;
  signal arm_done, twd_done,trst_done,wdi_falling : std_logic;
  component datapath is 
  Port (
    rst, clk,wdi : in std_logic;
    arm_delay : in std_Logic_vector (15 downto 0);
    twd,tRst : in std_logic_vector (31 downto 0);
    clr_twd, clr_wdi, en_arm, en_twd, en_trst, clr_arm, clr_trst : in std_logic;
    arm_done, twd_done,trst_done,wdi_falling : out std_logic
  );
end component;
  component controller is   
  port (
    rst,clk : in std_logic;
    ctrl : in std_logic;
    wdo, en_out : out std_logic;
    clr_wdi,clr_twd,en_arm,en_twd,en_trst,clr_arm,clr_trst : out std_logic;
    arm_done,twd_done,trst_done,wdi_falling,en : in std_logic
  );
end component;
  begin
  U1 : datapath port map (
    rst,clk,wdi,tarm,twd,trst,clr_twd,clr_wdi, en_arm,
    en_twd, en_trst, clr_arm, clr_trst ,arm_done, twd_done,
    trst_done,wdi_falling
  );
  U2 : controller port map (
    rst,clk,ctrl,wdo,enout,clr_wdi,clr_twd,en_arm, en_twd,en_trst,clr_arm,clr_trst,
    arm_done,twd_done,trst_done,wdi_falling,en 
  );
end rtl;