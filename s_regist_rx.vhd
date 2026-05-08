library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regis_rx is 
  Port (
    clk : in std_logic;
    inp : in std_logic;
    outp : out std_logic_vector (7 downto 0);
    en_shift : in std_logic;
    xuat : in std_logic
  );
end regis_rx;

architecture rtl of regis_rx is 
signal temp : std_logic_vector (7 downto 0) := (others => '1');
  begin 
    process (clk)
      begin 
        if (rising_edge(clk)) then 
          if (en_shift = '1') then 
            temp <= inp& temp(7 downto 1);
          end if;
        end if;
    end process;
  outp <= temp;


end rtl;