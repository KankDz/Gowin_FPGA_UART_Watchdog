library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_cnt is 
  Port (
    clr  : in std_logic;
    done : out std_logic;
    clk  : in std_logic;
    en   : in std_logic
  );
end bit_cnt;

architecture rtl of bit_cnt is 
  signal temp : UNSIGNED (2 downto 0) := "000";
begin 

  
  process (clk)
  begin 
    if (rising_edge(clk)) then 
      if (clr = '1') then         
        temp <= "000";
      elsif (en = '1') then 
        temp <= temp + 1;
      end if;
    end if;
  end process;

  
  done <= '1' when temp = "111" else '0';

end rtl;