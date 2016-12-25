library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity in_FSM is
port(
	reset:					in std_logic;
	clk_phy:					in std_logic;
	
	data_in:					in std_logic_vector(3 downto 0);
	valid_in:				in std_logic;
	
	data_out:				out std_logic_vector(3 downto 0);
	start_out:				out std_logic;
	stop_out:				out std_logic;
	valid_out:				out std_logic;
	discard_out:			out std_logic
);
end entity;

architecture rtl of in_FSM is
type state is (s_idle, s_stream, s_discard);
signal my_state: state;

signal count: integer range 0 to 4095;

component sequence_detector is
port(
	reset:					in std_logic;
	clk:						in std_logic;
	
	data_in:					in std_logic_vector(3 downto 0);
	sequence_in:			in std_logic_vector(63 downto 0);
	data_out:				out std_logic_vector(3 downto 0);
	detected_out:			out std_logic
);
end component;
signal seq_data_out:			std_logic_vector(3 downto 0);
signal preamble_detected:	std_logic;

begin

process(all) begin

end process;

-- Moore machine
process(reset, clk_phy) begin
	if(reset = '1') then
		my_state <= s_idle;
		count <= 0;
	elsif(rising_edge(clk_phy)) then
		if(preamble_detected = '1') then
			my_state <= s_stream;
			count <= 0;
		elsif(CRC_detected = '1' and CRC_valid = '1') then
			my_state <= s_idle;
			count <= 0;
		elsif(CRC_detected = '1') then
			my_state <= s_discard;
			count <= 0;
		elsif(valid_in = '1') then -- TODO: check pipeline
			count <= count + 1;
		end if;
	end if;
end process;

process(my_state) begin
	case my_state is
	when s_stream =>
		valid_out <= '1';
		discard_out <= '0';
	when s_discard =>
		valid_out <= '0';
		discard_out <= '1';
	when others =>
		valid_out <= '0';
		discard_out <= '0';
	end case;
end process;

process(all) begin
	data_out <= seq_data_out;
	start_out <= preamble_detected;
	stop_out <= CRC_valid;
end process;

preamble_detector: sequence_detector port map(
	reset				=> reset,
	clk				=> clk_phy,
	data_in			=> data_in,
	sequence_in		=> X"AAAA_AAAA_AAAA_AAAB",
	
	data_out			=> seq_data_out,
	detected_out	=> preamble_detected
);

end architecture;
