-- Main Block
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity main is
    port(nrst, clk50, hash, end_game : in std_logic;		-- Single Inputs
        key_read, new_game, LED_GAME_OVER   : out std_logic);	-- Single Outputs
end main;

architecture dev3 of main is
    -- State definitions:
    type state_list is (main_wait, main_read, main_startgame, main_wgame);
    --State machine internal states:
    signal state : state_list;

Begin

-- Description of the block
Process (clk50)
    Begin
        if (clk50'event and clk50='1') then
            if (nrst = '0') then	-- Reset
                state <= main_wait;
                LED_GAME_OVER  <= '1';
            else
                case state is
                    when main_wait =>
                        if (hash = '1') then
                            state <= main_read;
                        end if;
                    when main_read =>
						state <= main_startgame;
                    when main_startgame =>
                        state  <= main_wgame; 
                        LED_GAME_OVER  <= '0';
                    when main_wgame =>
						if end_game = '1' then
							state  <= main_wait;
							LED_GAME_OVER  <= '1';
						end if;
                end case;
            end if;
        end if;
    end Process;

-- Outputs of the state machine
key_read <= '1' when state = main_read else '0';
new_game <= '1' when state = main_read else '0';
end dev3;