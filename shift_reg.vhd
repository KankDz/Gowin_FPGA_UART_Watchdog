library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_reg is 
  Port (
    data_i : in std_logic_vector (7 downto 0);
    clk : in std_logic;
    output : out std_logic;
    nhap : in std_logic;
    en : in std_logic
  );
end shift_reg;

architecture rtl of shift_reg is 
  signal temp : std_logic_vector ( 7 downto 0) := (others => '1');
  begin 
  
  process (clk)
    begin 
    if (rising_edge(clk)) then 
      if (nhap = '1') then 
        temp <= data_i;
      elsif (en = '1') then 
        temp <= '1' & temp (7 downto 1);
      end if;
    end if;
  end process;
  output <= temp (0);
end rtl;


