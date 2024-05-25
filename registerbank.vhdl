library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity statistics is
    port(clk, nrst, new_game, win, lose, tie, rst_statistics : in std_logic;
          Games, Wins, Loses, Ties : out std_logic_vector(3 downto 0));
end statistics;

architecture dev2 of statistics is
    signal Games_int, Wins_int, Loses_int, Ties_int : std_logic_vector(3 downto 0);
begin
    Process (clk)
    Begin
        if (clk'event and clk='1') then
            if (nrst = '0') then	-- Reset
                Games_int <= "0000";
                Wins_int <= "0000";
                Loses_int <= "0000";
                Ties_int <= "0000";
            else
                if (new_game = '1') then Games_int <= Games_int + 1; end if;
                if (win = '1') then Wins_int <= Wins_int + 1; end if;
                if (tie = '1') then Ties_int <= Ties_int + 1; end if;
                if (lose = '1') then Loses_int <= Loses_int + 1; end if;
                if (rst_statistics = '1') then 
                    Games_int <= "0000";
                    Wins_int <= "0000";
                    Loses_int <= "0000";
                    Ties_int <= "0000"; 
                end if;
            end if;
        end if;
    end Process;
    Games <= Games_int;
    Wins <= Wins_int;
    Loses <= Loses_int;
    Ties <= Ties_int;
end dev2;