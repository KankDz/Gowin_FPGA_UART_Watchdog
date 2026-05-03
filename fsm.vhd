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
  type state_type is (s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10);
  signal state : state_type;
  begin 
    process (clk, rst) 
      begin 
        if (rst = '1') then 
          state <= s0;
        elsif (rising_edge(clk)) then 
          case state is 
            when s0 => 
              state <= s1;
            when s1 => 
              if (en = '1') then 
                state <= s2;
              else 
                state <= s1;
              end if;
            when s2 =>
              if(arm_done = '1') then 
                state <= s4;
              else 
                state <= s3;
              end if;
            when s3 => 
               state <= s2;
            when s4 =>
              state <= s5;
            when s5 =>
              if(twd_done = '1') then 
                state <= s9;
              else 
                state <= s6;
              end if;
            when s6 =>
              if (wdi_falling = '1') then 
                state <= s7;
              else 
                state <= s8;
              end if;
            when s7 =>
              state <= s5;
            when s8 =>
              state <= s5;
            when s9 => 
              if ((trst_done = '1') or (ctrl = '1')) then 
                state <= s0;
              else 
                state <= s10;
              end if;
            when s10 =>
              state <= s9;
            when others =>
              state <= s0;
            end case;
          end if;
    end process;
    en_arm <= '1' when state = s3 else '0';
    clr_twd <= '1' when ((state =s7)or (state = s0) or ((state = s9 and ctrl = '1'))) else '0';
    clr_wdi <= '1' when ((state = s7)or(state = s0) or (state = s9 and ctrl = '1')) else '0';
    en_twd <= '1' when (state = s8) else '0'; 
    en_trst <= '1' when (state = s10) else '0';
    clr_arm <= '1' when (state = s0) or (state = s9 and ctrl = '1')  else '0';
    clr_trst <= '1' when state = s0 or (state = s9 and ctrl = '1')  else '0';
    process (clk, rst)
    begin
        if (rst = '1') then
            en_out <= '0'; 
            wdo    <= '1'; 
        elsif (rising_edge(clk)) then
            if ((state = s0) or (state = s1) or (state = s2) or (state = s3)) then
                en_out <= '0';
            else
                en_out <= '1';
            end if;
            if ((state = s9) or (state = s10)) then
                wdo <= '0';
            else
                wdo <= '1';
            end if;
        end if;
    end process;
end rtl;