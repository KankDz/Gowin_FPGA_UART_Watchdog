library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dtp_tx is 
Port (
  clk : in std_logic;
  data_i : in std_logic_vector( 7 downto 0);
  tx : out std_logic;
  clr_bit, clr_tick : in std_logic;
  done_tick, done_bit : out std_logic;
  en_tick, en_bit : in std_logic;
  nhap_reg,en_shift : in std_logic;
  controll_out : in std_logic_vector ( 1 downto 0)
);
end dtp_tx;

architecture rtl of dtp_tx is 
signal temp : std_logic;
  component bit_cnt is 
  Port (
    clr : in std_logic;
    done : out std_logic;
    clk : in std_logic;
    en : in std_logic
  );
end component;
component shift_reg is 
  Port (
    data_i : in std_logic_vector (7 downto 0);
    clk : in std_logic;
    output : out std_logic;
    nhap : in std_logic;
    en : in std_logic
  );
end component;
   component  cnt_uart is 
  Port (
    clr : in std_logic;
    done : out std_logic;
    clk : in std_logic;
    en : in std_logic
  );
end component;
  begin 
  u1 : bit_cnt port map (
    clr => clr_bit,
    done => done_bit,
    clk => clk,
    en => en_bit
  );
  u2 : cnt_uart port map (
    clr => clr_tick,
    done => done_tick,
    clk => clk,
    en => en_tick
  );
  u3 : shift_reg port map (
    data_i => data_i,
    clk => clk,
    output => temp,
    nhap => nhap_reg,
    en => en_shift
  );
  tx <= '0' when controll_out = "00" else 
         temp when controll_out = "01" else 
         '1';
end rtl;