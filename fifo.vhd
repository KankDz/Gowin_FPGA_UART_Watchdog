library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
  Port (
    clk : in std_logic;
    empty, full : out std_logic;
    wr_i, rd_i : in std_logic;
    w_data : in std_logic_vector(7 downto 0);
    r_data : out std_logic_vector (7 downto 0)
  );
end fifo;

architecture rtl of fifo is 
    type ram_type is array (0 to 15 ) of std_logic_vector (7 downto 0);
    signal ram_block : ram_type := (others => (others => '0'));
    signal wr_ptr : integer range 0 to 15 := 0;
    signal rd_ptr : integer range 0 to 15 := 0;
    signal count : integer range 0 to 16 := 0;
    signal is_full, is_empty, wr_valid, rd_valid : std_logic;
begin 
    is_empty <= '1' when count = 0 else '0';
    is_full  <= '1' when count = 16 else '0';
    empty    <= is_empty;
    full     <= is_full;
    wr_valid <= '1' when (wr_i = '1' and is_full = '0') else '0';
    rd_valid <= '1' when (rd_i = '1' and is_empty = '0') else '0';
    r_data <= ram_block(rd_ptr);
    process (clk)
    begin 
      if (rising_edge(clk)) then 
        if (wr_valid = '1') then 
          ram_block(wr_ptr) <= w_data;
          if (wr_ptr = 15) then 
            wr_ptr <= 0;
          else 
            wr_ptr <= wr_ptr + 1;
          end if;
        end if;
        
        if rd_valid = '1' then
          if rd_ptr = 15 then
            rd_ptr <= 0;
          else
            rd_ptr <= rd_ptr + 1;
          end if;
        end if;
        if (wr_valid = '1' and rd_valid = '0') then
          count <= count + 1;
        elsif (wr_valid = '0' and rd_valid = '1') then
          count <= count - 1;
        end if;
      end if;
    end process;

end rtl;