library ieee;    -- [FIXED] Thêm ch? 'l'
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
    Port (
        clk    : in  std_logic;
        s_tick : out std_logic
    );
end baud_gen;

architecture rtl of baud_gen is
    constant MAX_COUNT : integer := 15;
    
    -- [T?I ?U] Ép ki?u range ?? Synthesizer ch? dùng thanh ghi 4-bit thay vì 32-bit
    signal count       : integer range 0 to MAX_COUNT := 0; 
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if count = (MAX_COUNT - 1) then 
                count <= 0;
                s_tick <= '1';
            else
                count <= count + 1;
                s_tick <= '0';
            end if;
        end if;
    end process;

end rtl;