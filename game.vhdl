library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity game is
	port (nrst, clk, start_game, RDY_RECEIVED, MOVE_RECEIVED, TIE_RECEIVED, WIN_RECEIVED : in std_logic;
		received_data : in std_logic_vector (3 downto 0);
		keycode : in std_logic_vector (3 downto 0);
		bcd, ready_to_TX, new_frame : in std_logic;
		SEND_RDY, SEND_MOVE, SEND_WIN, SEND_TIE : out std_logic;
		send_data : out std_logic_vector (3 downto 0);
		frame_received : out std_logic;
		LED_READY, LED_NUM, LED_WAIT, LED_MOVE, LED_WIN, LED_LOSE, LED_TIE : out std_logic;
		start, game_end, new_game, win, tie, lose, key_read : out std_logic;
		OurCells, OppCells : out std_logic_vector (8 downto 0) );
end game;

architecture dev4 of game is

--state defenitions
type state_list is (g_wait, g_num, read_num, modify_num, wtx, srdy, wrdy, fr_rdy, check_num, g_new, wait_bcd, read_key,
					check_cell, wtx2, check_results, sd_move, sd_win, sd_tie, end_check, g_finish,
					wait_move, fr_bcd, fr_lose, fr_tie);


--state machine internal states
signal state: state_list;

--internal signals for outputs
signal our_cells, opp_cells, selected_cell: std_logic_vector (8 downto 0);
signal total_games, num_cell: std_logic_vector (3 downto 0);
signal num, opp_num : std_logic_vector (3 downto 0);
signal start_turn: std_logic;

Begin

--Describing state transition	
Process (clk, nrst)
	Begin 
		if (clk'event and clk='1') then
			if (nrst = '0') then	-- Reset
				state <= g_wait;
				-- All Outputs = 0
				start_turn <= '0';
				num <= "0000";
				opp_num <= "0000";
				send_data <= "0000";
				total_games <= "0000";
				num_cell <= "0000";
				our_cells <= "000000000";
				opp_cells <= "000000000";
				selected_cell <= "000000000";
				-- All lights  = 0
				LED_READY 		<= '0';
				LED_NUM			<= '0';
				LED_WAIT 		<= '0';
				LED_MOVE 		<= '0';
				LED_WIN 		<= '0';
				LED_LOSE		<= '0';
				LED_TIE 		<= '0';
			else
				case state is
					when g_wait =>
						if start_game = '1' then
							state <= g_num;
							start_turn <= '0';
							total_games <= "0000";
							start_turn <= '0';
							LED_READY <= '1';
							LED_NUM	<= '1';
						end if;
					when g_num =>
						if bcd = '1' then
							state <= read_num;
							num <= keycode;
							LED_NUM	<= '0';
						end if;
					when read_num =>
						state <= modify_num;
					when modify_num =>
						num <= num(1 downto 0) & num(3 downto 2);
						state <= wtx;
					when wtx =>
						if ready_to_TX = '1' then		-- Check if we can transmit
							state <= srdy;	
							send_data <= num; 		-- Activation of SEND_RDY
						end if;
					when srdy => 
						state <= wrdy;
					when wrdy =>					-- Once we send ready we wait for ready
						if (RDY_RECEIVED = '1' and new_frame = '1') then
							opp_num <= received_data;
							state <= fr_rdy;			-- Once we receive the ready we can introduce the code
						end if;
					when fr_rdy =>
						state <= check_num;
					when check_num =>
						if opp_num = num then 
							state <= g_num;
							LED_NUM	<= '1';
						elsif opp_num > num then 
							start_turn <= '0';
						else
							start_turn <= '1';
						end if;
						LED_READY <= '0';
						state <= g_new;
					when g_new =>
						start_turn <= not start_turn;
						total_games <= total_games + 1;
						our_cells <= "000000000";
						opp_cells <= "000000000";
						if start_turn = '1' then
							LED_MOVE <= '1';
							state <= wait_bcd;
						else
							LED_WAIT <= '1';
							state <= wait_move;
						end if;
					when wait_bcd =>
						if (bcd = '1') then
							state <= read_key;
							num_cell <= keycode;
							LED_WIN <= '0';
							LED_LOSE <= '0';
							LED_TIE <= '0';
						end if;
					when read_key =>
						case num_cell is
							when "0001" => selected_cell <= "100000000";state <= check_cell;
							when "0010" => selected_cell <= "010000000";state <= check_cell;
							when "0011" => selected_cell <= "001000000";state <= check_cell;
							when "0100" => selected_cell <= "000100000";state <= check_cell;
							when "0101" => selected_cell <= "000010000";state <= check_cell;
							when "0110" => selected_cell <= "000001000";state <= check_cell;
							when "0111" => selected_cell <= "000000100";state <= check_cell;
							when "1000" => selected_cell <= "000000010";state <= check_cell;
							when "1001" => selected_cell <= "000000001";state <= check_cell;
							when others => state <= wait_bcd;
						end case;
						
					when check_cell =>
						if ((selected_cell AND our_cells) OR (selected_cell AND opp_cells)) = "000000000" then -- Cell selected correct position
							our_cells <= our_cells OR selected_cell;
							LED_MOVE <= '0';
							LED_WIN  <= '0';
							LED_LOSE <= '0';
							LED_TIE  <= '0';
							LED_WAIT <= '1';
							send_data <= num_cell;
							state <= wtx2;
						else
							state <= wait_bcd;
						end if;
					when wtx2 => 
						if (ready_to_TX = '1') then
							state <= check_results;
						end if;
					when check_results =>
						if ((our_cells AND "111000000") = "111000000") OR
							  ((our_cells AND "000111000") = "000111000") OR
							  ((our_cells AND "000000111") = "000000111") OR
							  ((our_cells AND "100100100") = "100100100") OR
							  ((our_cells AND "010010010") = "010010010") OR
							  ((our_cells AND "001001001") = "001001001") OR
							  ((our_cells AND "100010001") = "100010001") OR
							  ((our_cells AND "001010100") = "001010100") then
							LED_WIN <= '1';
							LED_WAIT <= '0';
							state <= sd_win;
						elsif (our_cells OR opp_cells) = "111111111" then
							LED_TIE <= '1';
							LED_WAIT <= '0';
							state <= sd_tie;
						else
							state <= sd_move;
						end if;
					when sd_move =>
						state <= wait_move;				-- Activation of SEND_MOVE
					when sd_win =>
						state <= end_check;			-- Activation of SEND_WIN
					when sd_tie =>
						state <= end_check;			-- Activation of SEND_TIE
					when end_check =>
						if total_games = 10 then
							state <= g_finish;
						else
							state <= g_new;
						end if;
					when g_finish =>
						state <= g_wait;
					when wait_move => 
						if (new_frame = '1') then
							if (MOVE_RECEIVED = '1') then
								LED_WIN  <= '0';
								LED_LOSE <= '0';
								LED_TIE  <= '0';
								LED_WAIT <= '0';
								LED_MOVE <= '1';
								state <= fr_bcd;
							elsif (TIE_RECEIVED = '1') then
								LED_TIE  <= '1';
								LED_WAIT <= '0';
								state <= fr_tie;
							elsif (WIN_RECEIVED = '1') then
								LED_LOSE  <= '1';
								LED_WAIT <= '0';
								state <= fr_lose;		-- Activation of frame_received
							end if;
							case received_data is
								when "0001" => selected_cell <= "100000000";
								when "0010" => selected_cell <= "010000000";
								when "0011" => selected_cell <= "001000000";
								when "0100" => selected_cell <= "000100000";
								when "0101" => selected_cell <= "000010000";
								when "0110" => selected_cell <= "000001000";
								when "0111" => selected_cell <= "000000100";
								when "1000" => selected_cell <= "000000010";
								when "1001" => selected_cell <= "000000001";
								when others => selected_cell <= "000000000";
							end case;
						end if;

					when fr_bcd  =>
						state <= wait_bcd;
						opp_cells <= opp_cells OR selected_cell;
					when fr_lose  =>
						state <= end_check;
						opp_cells <= opp_cells OR selected_cell;
					when fr_tie  =>
						state <= end_check;
						opp_cells <= opp_cells OR selected_cell;
					end case;
			end if;
		end if;
	end Process;

frame_received <= '1' when state = fr_rdy or state = fr_bcd or state = fr_lose or state = fr_tie else '0';
new_game <= '1' when state = g_new else '0';
key_read <= '1' when state = read_key or state = read_num else '0';
game_end <= '1' when state = g_finish else '0';
tie <= '1' when state = fr_tie or state = sd_tie else '0';
win <= '1' when state = sd_win else '0';
lose <= '1' when state = fr_lose else '0';

SEND_RDY  <= '1' when state = srdy else '0';
SEND_MOVE  <= '1' when state = sd_move else '0';
SEND_TIE  <= '1' when state = sd_tie else '0';
SEND_WIN  <= '1' when state = sd_win else '0';

start <= start_turn;
OurCells <= our_cells;
OppCells <= opp_cells;

end dev4;