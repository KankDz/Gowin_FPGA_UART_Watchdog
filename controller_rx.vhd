library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_rx is 
  Port (
    rx_i : in std_logic;
   clk : in std_logic;
   s_tick : in  std_logic;
   rx_done : out std_logic;

   

   clr_8b,clr_16b : out std_logic;
   xuat_bit : out  std_logic;
   en_8b,en_16b,en_shift : out std_logic;
   done_8b,done_16b : in std_logic;
   half : in std_logic

  );

end controller_rx;
architecture rtl of controller_rx is 
type state_type is (idle,bit_start,bit_data,bit_stop);
signal state : state_type := idle;
  begin
process (clk) 
begin 
    if(rising_edge(clk)) then 
      case state is
        when idle =>
          if (rx_i = '0') then 
          state <= bit_start;
         end if;
        when bit_start =>
          if((s_tick = '1') and (half = '1' )) then 
            if (rx_i = '0') then 
              state <= bit_data;
            else 
              state <= idle;
            end if;
          end if;
        when bit_data =>
          if ((s_tick = '1') and (done_16b = '1') and (done_8b = '1')) then 
             state <= bit_stop;
          end if;
        when bit_stop =>
          if ((s_tick = '1') and (done_16b = '1')) then 
            state <= idle;
          end if;
        when others =>
         state <= idle;
        end case;
      end if;
    end process;
en_16b <= '1' when (state /= idle) and (s_tick = '1') else '0';
clr_16b <= '1' when (state = idle) or ((state = bit_start) and (s_tick = '1') and (half = '1') and (rx_i = '0')) else '0';
clr_8b <= '1' when (state = idle) else '0';
en_shift <= '1' when (state = bit_data) and (s_tick = '1') and (done_16b = '1') else '0';
en_8b <= '1' when (state = bit_data) and (s_tick = '1') and (done_16b = '1') else '0';
rx_done  <= '1' when (state = bit_stop) and (s_tick = '1') and (done_16b = '1') else '0';
  xuat_bit <= '1' when (state = bit_stop) else '0'; 
end rtl;