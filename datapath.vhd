library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is 
  Port (
    rst, clk,wdi : in std_logic;
    arm_delay : in std_Logic_vector (15 downto 0);
    twd,tRST : in std_logic_vector (31 downto 0);
    clr_twd, clr_wdi, en_arm, en_twd, en_trst, clr_arm, clr_trst : in std_logic;
    arm_done, twd_done,trst_done,wdi_falling : out std_logic
  );
end datapath;

architecture rtl of datapath is 
signal wdi_prev,wdi_pres : std_logic;
  component cnt8 is 
  port(
    clk : in std_logic;
    load : in std_logic_vector(15 downto 0);
    rst : in STD_LOGic;
    kq : out std_logic;
    clr : in std_logic;
    en : in std_logic
  );
end component;
 component cnt11 is 
  port(
    clk : in std_logic;
    load : in std_logic_vector(31 downto 0);
    rst : in STD_LOGic;
    kq : out std_logic;
    clr : in std_logic;
    en : in std_logic
  );
end component; 
  begin 
  u1 : cnt8 port map (clk,arm_delay,rst,arm_done,clr_arm,en_arm);
  u2 : cnt11 port map (clk,trst,rst,trst_done,clr_trst,en_trst);
  u3 : cnt11 port map (clk,twd,rst,twd_done,clr_twd,en_twd);

 process (rst,clk) 
  begin 
    if (rst = '1') then 
      wdi_prev <= '1';
      wdi_pres <='1';
      wdi_falling <= '0';
    elsif (rising_edge(clk)) then 
      wdi_prev <= wdi_pres;
      wdi_pres <= wdi;
      if(clr_wdi = '1') then 
         wdi_falling <= '0';
      elsif ((wdi_prev = '1')and (wdi_pres = '0')) then 
        wdi_falling <= '1';
      end if;
    end if;
  end process;
end rtl;