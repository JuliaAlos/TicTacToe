--Serial receiver. 
--Default baud rate is 56000 bps from a 50MHz clock.
--Version 1.2 october 2016.

library ieee;
use ieee.std_logic_1164.all;

entity rx_module is
port( clk, nrst, rx : in std_logic;
	   rx_data : out std_logic_vector(7 downto 0);   
	   rx_new  : out std_logic );
end rx_module;

architecture main of rx_module is

type state_type is (rx_idle, rx_start, rx_shift, rx_stop);
signal state : state_type;

signal bit_count : integer range 0 to 7;   -- bit count within the received data word
--constant max : integer range 0 to 7 := 4;		-- set to 4 only for simulation purposes
constant max : integer range 0 to 8191 := 891;  -- 50M/5208~9600, /1302~38400, /892~56000, etc.
signal baud : integer range 0 to max; -- rx counter at the baud rate

begin

--------- RECEIVER_FSM ---------
RX_FSM: process(clk, nrst) begin

if nrst = '0' then
	state <= rx_idle;
	baud <= 0;
	rx_new <= '0';

elsif clk'event and clk = '1' then
	case state is
	when rx_idle => bit_count <= 0;
					rx_new <= '0';
					if rx = '0' then
						baud <= 0;
						state <= rx_start;
					end if;
	when rx_start => if (baud = (max-1)/2) then
						baud <= 0;
						if rx = '0' then
							state <= rx_shift;
							bit_count <= 0;
						else
							state <= rx_idle;
						end if;
					else
						baud <= baud + 1;
					end if;
	when rx_shift => if (baud = max) then
						baud <= 0;
						bit_count <= bit_count+1;
						rx_data(bit_count) <= rx;							
						if (bit_count = 7) then
							bit_count <= 0;
							state <= rx_stop;
							rx_new <='1';
						end if;
					 else
						baud <= baud + 1;
					 end if;
	when rx_stop => rx_new <= '0';
					if (baud = max) then
						baud <= 0;
						bit_count <= 0;
						state <= rx_idle;
					else
						baud <= baud + 1;
					end if;
	when others =>
	end case;
end if;
end process;

end;
