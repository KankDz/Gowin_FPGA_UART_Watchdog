
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_engine is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        empty_o    : in  std_logic;
        rdata_o    : in  std_logic_vector(7 downto 0);
        rd_i       : out std_logic;
        full_o     : in  std_logic;
        wdata_i    : out std_logic_vector(7 downto 0);
        wd_i       : out std_logic;
        wr_en      : out std_logic;
        rd_en      : out std_logic;
        addr       : out std_logic_vector(7 downto 0);
        wdata      : out std_logic_vector(31 downto 0);
        rdata      : in  std_logic_vector(31 downto 0);
        kick_pulse : out std_logic
    );
end;

architecture rtl of uart_engine is

    type state_type is (
        IDLE,
        WAIT_HEADER, 
        GET_CMD, WAIT_CMD,
        GET_ADDR, WAIT_ADDR,
        GET_LEN, WAIT_LEN,
        GET_DATA, WAIT_DATA,
        GET_CHK, WAIT_CHK,
        EXECUTE, WAIT_RDATA,
        SEND_RESP,
        SEND_ACK_DATA,  
        SEND_HEADER,
        SEND_B0, SEND_B1, SEND_B2, SEND_B3,
        SEND_CHK
    );

    signal state : state_type;

    signal cmd       : std_logic_vector(7 downto 0);
    signal addr_reg  : std_logic_vector(7 downto 0);
    signal data_reg  : std_logic_vector(31 downto 0);

    signal len       : integer range 0 to 4;
    signal byte_cnt  : integer range 0 to 4;

    signal chk_calc  : std_logic_vector(7 downto 0);
    signal chk_tx    : std_logic_vector(7 downto 0);

    type resp_type_t is (RESP_ACK, RESP_DATA, RESP_STATUS);
    signal resp_type : resp_type_t;

begin

process(clk, rst)
begin
    if rst = '1' then
        state      <= IDLE;
        rd_i       <= '0';
        wd_i       <= '0';
        wr_en      <= '0';
        rd_en      <= '0';
        kick_pulse <= '0';
        data_reg   <= (others => '0'); 
        addr       <= (others => '0');
        wdata      <= (others => '0');
        wdata_i    <= (others => '0');

    elsif rising_edge(clk) then
        rd_i       <= '0';
        wd_i       <= '0';
        wr_en      <= '0';
        rd_en      <= '0';
        kick_pulse <= '0';

        case state is

        when IDLE =>
            if empty_o = '0' then
                rd_i <= '1'; 
                if rdata_o = x"55" then
                    state <= WAIT_CMD;
                else
                    state <= WAIT_HEADER; 
                end if;
            end if;

        when WAIT_HEADER =>
            state <= IDLE; 

        when WAIT_CMD => state <= GET_CMD;
        when GET_CMD =>
            if empty_o = '0' then
                cmd <= rdata_o;
                chk_calc <= rdata_o;
                rd_i <= '1';
                state <= WAIT_ADDR;
            end if;

        when WAIT_ADDR => state <= GET_ADDR;
        when GET_ADDR =>
            if empty_o = '0' then
                addr_reg <= rdata_o;
                chk_calc <= chk_calc xor rdata_o;
                rd_i <= '1';
                state <= WAIT_LEN;
            end if;

        when WAIT_LEN => state <= GET_LEN;
        when GET_LEN =>
            if empty_o = '0' then
                if unsigned(rdata_o) <= 4 then
                    data_reg <= (others => '0'); 
                    len <= to_integer(unsigned(rdata_o));
                    chk_calc <= chk_calc xor rdata_o;
                    byte_cnt <= 0;
                    rd_i <= '1';
                    
                    if unsigned(rdata_o) = 0 then
                        state <= WAIT_CHK;
                    else
                        state <= WAIT_DATA;
                    end if;
                else
                    rd_i <= '1';
                    state <= WAIT_HEADER; 
                end if;
            end if;

        when WAIT_DATA => state <= GET_DATA;
        when GET_DATA =>
            if empty_o = '0' then
                case byte_cnt is
                    when 0 => data_reg(7 downto 0)   <= rdata_o;
                    when 1 => data_reg(15 downto 8)  <= rdata_o;
                    when 2 => data_reg(23 downto 16) <= rdata_o;
                    when 3 => data_reg(31 downto 24) <= rdata_o;
                    when others => null;
                end case;

                chk_calc <= chk_calc xor rdata_o;
                rd_i <= '1';

                if byte_cnt = len-1 then
                    state <= WAIT_CHK;
                else
                    byte_cnt <= byte_cnt + 1;
                    state <= WAIT_DATA;
                end if;
            end if;

        when WAIT_CHK => state <= GET_CHK;
        when GET_CHK =>
            if empty_o = '0' then
                rd_i <= '1';
                if chk_calc = rdata_o then
                    state <= EXECUTE;
                else
                    state <= WAIT_HEADER; 
                end if;
            end if;

      when EXECUTE =>
            case cmd is
                when x"01" => 
                    wr_en <= '1';
                    addr  <= addr_reg; 
                    wdata <= data_reg;
                    resp_type <= RESP_ACK;
                    state <= SEND_RESP;

                when x"02" | x"04" => 
                    rd_en <= '1';
                    addr  <= addr_reg;
                    if cmd = x"02" then resp_type <= RESP_DATA;
                    else resp_type <= RESP_STATUS; end if;
                    state <= WAIT_RDATA;
                          
                when x"03" =>
                    kick_pulse <= '1';  
                    addr  <= addr_reg;          
                    resp_type  <= RESP_ACK; 
                    state <= SEND_RESP;                 

                when others => state <= IDLE;
            end case;

        when WAIT_RDATA =>
            rd_en <= '1';
            addr  <= addr_reg;
            data_reg <= rdata;
            state <= SEND_RESP;

        when SEND_RESP =>
            case resp_type is
                when RESP_ACK =>
                    if full_o = '0' then
                        wdata_i <= x"55";    
                        wd_i <= '1';
                        state <= SEND_ACK_DATA; 
                    end if;
                when others =>
                    state <= SEND_HEADER;     
            end case;

        when SEND_ACK_DATA =>
            if full_o = '0' then
                wdata_i <= x"AA";       
                wd_i <= '1';
                state <= IDLE;          
            end if;

        when SEND_HEADER =>
            if full_o = '0' then
                wdata_i <= x"55";
                wd_i <= '1';
                state <= SEND_B0;
            end if;

        when SEND_B0 =>
            if full_o = '0' then
                wdata_i <= data_reg(7 downto 0);
                wd_i <= '1';
                state <= SEND_B1;
            end if;

        when SEND_B1 =>
            if full_o = '0' then
                wdata_i <= data_reg(15 downto 8);
                wd_i <= '1';
                state <= SEND_B2;
            end if;

        when SEND_B2 =>
            if full_o = '0' then
                wdata_i <= data_reg(23 downto 16);
                wd_i <= '1';
                state <= SEND_B3;
            end if;

        when SEND_B3 =>
            if full_o = '0' then
                wdata_i <= data_reg(31 downto 24);
                wd_i <= '1';
                chk_tx <= data_reg(7 downto 0) xor
                          data_reg(15 downto 8) xor
                          data_reg(23 downto 16) xor
                          data_reg(31 downto 24);
                state <= SEND_CHK;
            end if;

        when SEND_CHK =>
            if full_o = '0' then
                wdata_i <= chk_tx;
                wd_i <= '1';
                state <= IDLE;
            end if;

        when others =>
            state <= IDLE;
        end case;
    end if;
end process;

end architecture;