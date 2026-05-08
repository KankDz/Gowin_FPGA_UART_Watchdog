library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cnt_uart is 
  Port (
    clk  : in std_logic;
    clr  : in std_logic;
    en   : in std_logic;
    done : out std_logic
  );
end cnt_uart;

architecture rtl of cnt_uart is 
  signal temp : UNSIGNED (3 downto 0) := "0000";
begin 


  process (clk)
  begin 
    if (rising_edge(clk)) then 
      if (clr = '1') then         
        temp <= "0000";
      elsif (en = '1') then 
        temp <= temp + 1;
      end if;
    end if;
  end process;

  
  done <= '1' when temp = "1111" else '0';

end rtl;