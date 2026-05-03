library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx is 
  Port (
    clk      : in  std_logic;      
    rx_i     : in  std_logic;
    s_tick   : in  std_logic;       
    rx_done  : out std_logic;
    data_o   : out std_logic_vector (7 downto 0)
  );
end rx;

architecture rtl of rx is 
  component controller_rx is 
    Port (
      rx_i     : in  std_logic;
      clk      : in  std_logic;
      s_tick   : in  std_logic;
      rx_done  : out std_logic;
      clr_8b   : out std_logic;
      clr_16b  : out std_logic;
      xuat_bit : out std_logic;
      en_8b    : out std_logic;
      en_16b   : out std_logic;
      en_shift : out std_logic;
      done_8b  : in  std_logic;
      done_16b : in  std_logic;
      half     : in  std_logic
    );
  end component;

  component dtp_rx is 
    Port (
      clk      : in  std_logic;
      rx_i     : in  std_logic;
      data_o   : out std_logic_vector ( 7 downto 0);
      clr_8b   : in  std_logic;
      clr_16b  : in  std_logic;
      xuat_bit : in  std_logic;
      en_8b    : in  std_logic;
      en_16b   : in  std_logic;
      en_shift : in  std_logic;
      done_8b  : out std_logic;
      done_16b : out std_logic;
      half     : out std_logic
    );
  end component;
  signal clr_8b_sig, clr_16b_sig   : std_logic;
  signal xuat_bit_sig              : std_logic;
  signal en_8b_sig, en_16b_sig     : std_logic;
  signal en_shift_sig              : std_logic;
  signal done_8b_sig, done_16b_sig : std_logic;
  signal half_sig                  : std_logic;

begin


  u_ctrl : controller_rx port map (
    clk      => clk,
    rx_i     => rx_i,
    s_tick   => s_tick,
    rx_done  => rx_done,
    clr_8b   => clr_8b_sig,    
    clr_16b  => clr_16b_sig,
    xuat_bit => xuat_bit_sig,
    en_8b    => en_8b_sig,
    en_16b   => en_16b_sig,
    en_shift => en_shift_sig,
    done_8b  => done_8b_sig,   
    done_16b => done_16b_sig,
    half     => half_sig
  );

 
  u_dtp : dtp_rx port map (
    clk      => clk,
    rx_i     => rx_i,
    data_o   => data_o,
    clr_8b   => clr_8b_sig,    
    clr_16b  => clr_16b_sig,
    xuat_bit => xuat_bit_sig,
    en_8b    => en_8b_sig,
    en_16b   => en_16b_sig,
    en_shift => en_shift_sig,
    done_8b  => done_8b_sig,   
    done_16b => done_16b_sig,
    half     => half_sig
  );

end rtl;