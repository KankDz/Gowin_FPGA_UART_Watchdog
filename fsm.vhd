
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is   
  port (
    rst,clk : in std_logic;
    ctrl : in std_logic;
    wdo, en_out : out std_logic;
    clr_wdi,clr_twd,en_arm,en_twd,en_trst,clr_arm,clr_trst : out std_logic;
    arm_done,twd_done,trst_done,wdi_falling,en : in std_logic
  );
end controller;

architecture rtl of controller is  
  type state_type is (IDLE, ARM_DELAY, TWD_RUN, FAULT);
  signal state : state_type := IDLE;

begin 
  process (clk, rst) 
  begin 
    if (rst = '1') then 
      state <= IDLE;
    elsif (rising_edge(clk)) then 
      if (en = '1') then
        state <= IDLE;
      else
        case state is 
          when IDLE => 
            state <= ARM_DELAY;
          when ARM_DELAY =>
            if (arm_done = '1') then state <= TWD_RUN; end if;
          when TWD_RUN =>
            if (twd_done = '1') then state <= FAULT; end if;
          when FAULT => 
            if (trst_done = '1' or ctrl = '1') then state <= IDLE; end if;
        end case;
      end if;
    end if;
  end process;
  clr_arm  <= '1' when (state = IDLE) else '0';
  clr_trst <= '1' when (state = IDLE) else '0';
  clr_twd  <= '1' when (state = IDLE) or (state = TWD_RUN and wdi_falling = '1') else '0';
  clr_wdi  <= '1' when (state = IDLE) or (state = TWD_RUN and wdi_falling = '1') else '0';
  en_arm   <= '1' when (state = ARM_DELAY) else '0';
  en_trst  <= '1' when (state = FAULT) else '0';
  en_twd   <= '1' when (state = TWD_RUN and wdi_falling = '0') else '0'; 
  en_out   <= '0' when (state = IDLE) or (state = ARM_DELAY) else '1';
  wdo      <= '0' when (state = FAULT) else '1';

end rtl;