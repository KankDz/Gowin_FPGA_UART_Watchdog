library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dtp_rx is 
  Port (
    clk : in std_logic;
   rx_i : in  std_logic;
   data_o : out std_logic_vector ( 7 downto 0);

   clr_8b,clr_16b : in std_logic;
   xuat_bit : in  std_logic;
   en_8b,en_16b,en_shift : in std_logic;
   done_8b,done_16b : out std_logic;
   half : out std_logic
  );

end dtp_rx;
architecture rtl of dtp_rx is 
  component bit_cnt is 
    Port (
      clr  : in std_logic;
      done : out std_logic;
      clk  : in std_logic;
      en   : in std_logic
    );
  end component;
  component cnt_16b is 
  Port (
    clk  : in std_logic;
    clr  : in std_logic;
    en   : in std_logic;
    done : out std_logic;
    half : out std_logic
  );
end component;
component regis_rx is 
  Port (
    clk : in std_logic;
    inp : in std_logic;
    outp : out std_logic_vector (7 downto 0);
    en_shift : in std_logic;
    xuat : in std_logic
  );
end component;


  begin
u1 : bit_cnt port map (
    clk => clk,
    clr => clr_8b,
    done => done_8b,
    en => en_8b 

);
u2 : cnt_16b port map (
clk => clk,
clr => clr_16b,
en => en_16b,
done => done_16b,
half => half
);

u3 : regis_rx
 port map(
    clk => clk,
    inp => rx_i,
    outp => data_o,
    en_shift => en_shift,
    xuat => xuat_bit
);
end rtl;