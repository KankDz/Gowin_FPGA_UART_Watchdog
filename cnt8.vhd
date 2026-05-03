library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity cnt8 is 
  port(
    clk : in std_logic;
    load : in std_logic_vector(15 downto 0);
    rst : in STD_LOGic;
    kq : out std_logic;
    clr : in std_logic;
    en : in std_logic
  );
end cnt8;

architecture rtl of cnt8 is 
  signal tmp : UNSIGNED (15 downto 0);
  begin 
    process (clk,rst) 
    begin 
      if (rst = '1') then 
        tmp <= (others => '0');
      elsif (rising_edge(clk))  then 
        if(clr = '1') then 
        tmp <= (others => '0');
        elsif (en = '1') then 
          tmp <= tmp +1;
        end if;
      end if;
    end process;
    kq <= '1' when (tmp >= UNSIGNED(load)) else '0';
end rtl;
