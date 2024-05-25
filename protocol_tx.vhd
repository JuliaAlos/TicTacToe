library ieee;
use ieee.std_logic_1164.all;

entity protocol_tx is
	port (
		clk50, nrst: in std_logic;
		SEND_RDY, SEND_MOVE, SEND_TIE, SEND_WIN: in std_logic;  -- Frame to transmit.
		tx_data : out std_logic_vector(7 downto 0);  -- Byte sent to the UART TX for transmission
		send : out std_logic; -- send: to the UART. Active to send a new byte.
		data_send : in std_logic_vector(3 downto 0);  -- Data to trasmit.
		ready_to_TX : out std_logic;  -- Flag. Active high if protocol is ready to tx (not transmiting a frame)
		tx_empty : in std_logic  -- Signal from the UART TX. Active if new byte can be transmitted.
		);
end protocol_tx;


architecture main of protocol_tx is
	type state_type is (pr_wait, pr_rdy, pr_move, pr_win, pr_tie, pr_s1, pr_w1, pr_s2, pr_w2,
	 pr_check_data, pr_s3, pr_w3, pr_set_TX );
	 
	 -- Definition of the diferent FRAME TYPE
	constant RDY_PLAY : std_logic_vector(7 downto 0) := x"A1";
	constant MOVE : std_logic_vector(7 downto 0) := x"B1";
	constant WIN : std_logic_vector(7 downto 0) := x"C1";
	constant TIE : std_logic_vector(7 downto 0) := x"C2";
	
	constant FRAME_ID : std_logic_vector(7 downto 0) := x"AA";

	-- Definition of the state register
	
	signal state : state_type;
	
	-- Definition of the registers in the process unit

	signal frame_type: std_logic_vector(7 downto 0);
	
begin

PROTOCOL_FSM : process (clk50, nrst) begin
	if nrst = '0' then
		state <= pr_wait;
		ready_to_tx <= '1';
	elsif clk50'EVENT and clk50 = '1' then
		case state is
			
			when pr_wait =>
				if SEND_RDY = '1' then state <= pr_rdy; 
				elsif SEND_MOVE = '1' then state <= pr_move;
				elsif SEND_TIE = '1' then state <= pr_tie; 
				elsif SEND_WIN = '1' then state <= pr_win; else state <= pr_wait; end if;

			-- Filling TX_DATA with frame ID and updating FRAME_TYPE.	
			when pr_rdy => 
				ready_to_tx <= '0';
				frame_type <= RDY_PLAY;
				tx_data <= FRAME_ID;
				state <= pr_s1;
			when pr_move => 
				ready_to_tx <= '0';
				frame_type <= MOVE;
				tx_data <= FRAME_ID;
				state <= pr_s1;	
			when pr_win => 
				ready_to_tx <= '0';
				frame_type <= WIN;
				tx_data <= FRAME_ID;
				state <= pr_s1;
			when pr_tie => 
				ready_to_tx <= '0';
				frame_type <= TIE;
				tx_data <= FRAME_ID;
				state <= pr_s1;
				
			-- Sending FRAME_ID. SEND should be activated with a combinational system. 
			when pr_s1 =>
				state <= pr_w1;
				
			when pr_w1 =>
				if tx_empty = '1' then 
					state <= pr_s2;
					tx_data <= frame_type;
				end if;
				
			-- Sending FRAME TYPE. Send should be activated with a combinational system.	
			when pr_s2 =>
				state <= pr_w2;
					
			when pr_w2 =>
				if tx_empty = '1' then 
					state <= pr_check_data;
				end if;
				
			-- Send 1 byte with the data.
			when pr_check_data => 
				state <= pr_s3;
				tx_data <= x"0" & data_send;
				
			-- IF DATA. Let's send the 3 data bytes.
			-- Sending hundreds. Send should be activated with a combinational system.
			when pr_s3 =>
				state <= pr_w3;
								
			when pr_w3 =>
				if tx_empty = '1' then 
					state <= pr_set_TX;
				end if;
			
			-- Final STATE. The frame has been sent. TX_EMPTY should be set to 1
			
			when pr_set_TX => 
				state <= pr_wait;
				ready_to_tx <= '1';
			when others =>
				end case;
	end if;
end process;

-- Activation of the signal SEND when the state is any of the pr_s

send <= '1' when state = pr_s1 or state = pr_s2 or state = pr_s3 else '0';
end;