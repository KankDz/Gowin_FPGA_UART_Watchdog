
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TX is 
  Port (
    clk      : in  std_logic; 
  
    tx_start : in  std_logic; 
    s_tick   : in  std_logic;
    data_i   : in  std_logic_vector(7 downto 0);
    tx_o     : out std_logic;
    tx_done  : out std_logic
  );
end TX;

architecture rtl of TX is 

  component dtp_tx is 
    Port (
      clk          : in  std_logic;
      data_i       : in  std_logic_vector(7 downto 0);
      tx           : out std_logic;
      clr_bit      : in  std_logic;
      clr_tick     : in  std_logic;
      done_tick    : out std_logic;
      done_bit     : out std_logic;
      en_tick      : in  std_logic;
      en_bit       : in  std_logic;
      nhap_reg     : in  std_logic;
      en_shift     : in  std_logic;
      controll_out : in  std_logic_vector(1 downto 0)
    );
  end component;

  component controller_tx is 
    Port (
      -- ?  B? CH N rst TRONG COMPONENT
      clk          : in  std_logic;
      tx_start     : in  std_logic;
      s_tick       : in  std_logic;
      done_tick    : in  std_logic;
      done_bit     : in  std_logic;
      tx_done      : out std_logic;
      clr_bit      : out std_logic;
      clr_tick     : out std_logic;
      en_tick      : out std_logic;
      en_bit       : out std_logic;
      nhap_reg     : out std_logic;
      en_shift     : out std_logic;
      controll_out : out std_logic_vector(1 downto 0)
    );
  end component;

  signal w_clr_bit, w_clr_tick   : std_logic;
  signal w_done_tick, w_done_bit : std_logic;
  signal w_en_tick, w_en_bit     : std_logic;
  signal w_nhap_reg, w_en_shift  : std_logic;
  signal w_controll_out          : std_logic_vector(1 downto 0);

begin 

  U1_DATAPATH : dtp_tx 
    port map (
      clk          => clk,
      data_i       => data_i,
      tx           => tx_o,
      
      clr_bit      => w_clr_bit,
      clr_tick     => w_clr_tick,
      en_tick      => w_en_tick,
      en_bit       => w_en_bit,
      nhap_reg     => w_nhap_reg,
      en_shift     => w_en_shift,
      controll_out => w_controll_out,
 
      done_tick    => w_done_tick,
      done_bit     => w_done_bit
    );

  U2_CONTROLLER : controller_tx 
    port map (
      -- ?  B? D Y N?I rst
      clk          => clk,
      tx_start     => tx_start,
      s_tick       => s_tick,
      tx_done      => tx_done,
      
      done_tick    => w_done_tick,
      done_bit     => w_done_bit,
      
      clr_bit      => w_clr_bit,
      clr_tick     => w_clr_tick,
      en_tick      => w_en_tick,
      en_bit       => w_en_bit,
      nhap_reg     => w_nhap_reg,
      en_shift     => w_en_shift,
      controll_out => w_controll_out
    );

end rtl;