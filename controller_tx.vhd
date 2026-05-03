library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_tx is 
  Port (
  tx_start : in std_logic;
  s_tick : in std_Logic;
  clk : in std_logic;
  done_tick, done_bit : in std_logic;
  tx_done : out std_logic;
  clr_bit, clr_tick : out std_logic;
  en_tick, en_bit : out std_logic;
  nhap_reg,en_shift : out std_logic;
  controll_out : out std_logic_vector ( 1 downto 0)
  );
end controller_tx;
architecture rtl of controller_tx is 
  type state_type is (idle,bit_start,bit_data, bit_stop);
  signal state : state_type := idle;
  begin 
  process (clk) 
    begin 
    if (rising_edge(clk)) then 
      case state is 
        when idle =>
          if (tx_start = '1') then 
            state <= bit_start;
          end if;
        when bit_start =>
          if (done_tick = '1') then 
            state <= bit_data;
          end if;
        when bit_data =>
          if (done_bit = '1') then 
            state <= bit_stop;
          end if;
        when bit_stop =>
          if (done_tick = '1') then 
            state <= idle;
          end if;
        when others =>
          state <= idle;
      end case;
    end if;
   
  end process;
  tx_done <= '1' when ((state = bit_stop) and (s_tick = '1'))  else '0';
  clr_bit <= '1' when (state = idle) else '0';
  clr_tick <= '1' when (state = idle) or ((state = bit_start) and (done_tick = '1')) or ((state = bit_data) and (done_tick = '1')) else '0';
  en_tick <= '1' when   ((state = bit_start) and (s_tick = '1') and (done_tick = '0')) 
                        or ((state = bit_data) and  (s_tick = '1') and (done_tick = '0')) 
                        or ((state = bit_stop) and(s_tick = '1') and (done_tick = '0')) else '0';
  en_bit <= '1' when ((state = bit_data) and (done_tick = '1') and (done_bit = '0')) else '0';
  nhap_reg <= '1' when (state = idle) and (tx_start = '1') else '0';
  en_shift <= '1' when (state = bit_data) and (done_tick = '1') else '0' ;
  controll_out <= "00" when (state = bit_start)  else 
                  "01" when (state = bit_data) else 
                  "10";

end rtl;
