library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity in_FSM is
port(
	reset:					in std_logic;
	clk_phy:					in std_logic;
	
	data_in:					in std_logic_vector(3 downto 0);
	valid_in:				in std_logic;
	
	wren_FIFOs:				out std_logic;
	data_out:				out std_logic_vector(7 downto 0);
	start_stop_out:		out std_logic;
	valid_out:				out std_logic;
	discard_out:			out std_logic
);
end entity;

architecture rtl of in_FSM is

type state is (s_idle, s_stream);
signal my_state:	state;

signal count:		integer range 0 to 4095;
signal is_odd:		std_logic;

signal data:		std_logic_vector(7 downto 0);

-- Preamble and SFD
component sequence_detector is
port(
	reset:					in std_logic;
	clk:						in std_logic;
	
	valid_in:				in std_logic;
	data_in:					in std_logic_vector(7 downto 0);
	sequence_in:			in std_logic_vector(63 downto 0);
	data_out:				out std_logic_vector(7 downto 0);
	detected_out:			out std_logic
);
end component;

signal valid:					std_logic;
signal seq_data_out:			std_logic_vector(7 downto 0);
signal preamble_detected:	std_logic;

-- CRC32
component CRC is
port(
	CLOCK               :   in  std_logic;
	RESET               :   in  std_logic;
	DATA                :   in  std_logic_vector(7 downto 0);
	LOAD_INIT           :   in  std_logic;
	CALC                :   in  std_logic;
	D_VALID             :   in  std_logic;
	CRC                 :   out std_logic_vector(7 downto 0);
	CRC_REG             :   out std_logic_vector(31 downto 0);
	CRC_VALID           :   out std_logic
);
end component;

signal CRC_valid:			std_logic;
signal CRC_out:			std_logic_vector(7 downto 0); -- TODO: remove?
signal CRC_reg_out:		std_logic_vector(31 downto 0);

begin

-- Asynchronous signals
process(all) begin
	if(count mod 2 = 1) then
		is_odd <= '1';
	else
		is_odd <= '0';
	end if;
	
	valid <= not is_odd;
end process;

-- Synchronous signals
process(reset, clk_phy) begin
	if(reset = '1') then
		data <= X"00";
	elsif(rising_edge(clk_phy)) then
		if(is_odd = '1') then
			data(3 downto 0) <= data_in; -- TODO: check endianness
		else
			data(7 downto 4) <= data_in;
		end if;
	end if;
end process;

-- Moore machine
process(reset, clk_phy) begin
	if(reset = '1') then
		my_state <= s_idle;
		count <= 0;
	elsif(rising_edge(clk_phy)) then
		if(valid_in = '1' and preamble_detected = '1') then
			my_state <= s_stream;
			count <= 0;
		elsif(valid_in = '0') then
			my_state <= s_idle;
			count <= 0;
		elsif(valid_in = '1') then -- TODO: check pipeline
			count <= count + 1;
		end if;
	end if;
end process;

-- Output signals
process(reset, clk_phy) begin
	if(reset = '1') then
		
	elsif(rising_edge(clk_phy)) then
		
	end if;
end process;

process(all) begin
	if(my_state = s_stream or (my_state = s_idle and count = 0)) then
		wren_FIFOs <= valid; -- TODO: check
	else
		wren_FIFOs <= '0';
	end if;
	
	data_out <= seq_data_out;
	
	if(my_state = s_idle and count = 0) then
		valid_out <= '0';
	else
		valid_out <= valid;
	end if;
	
	case my_state is
	when s_stream =>
		discard_out <= not CRC_valid;
		start_stop_out <= '1';
	when others => -- s_idle
		discard_out <= '0';
		start_stop_out <= '0';
	end case;
end process;

-- Preamble and SDF
preamble_detector: sequence_detector port map(
	reset				=> reset,
	clk				=> clk_phy,
	
	valid_in			=> valid,
	data_in			=> data,
	sequence_in		=> X"AAAA_AAAA_AAAA_AAAB",
	
	data_out			=> seq_data_out,
	detected_out	=> preamble_detected
);

-- CRC32
CRC_detector: CRC port map(
	CLOCK				=> clk_phy,
	RESET				=> reset,
	DATA				=> data,
	LOAD_INIT		=> preamble_detected,
	CALC				=> valid, -- TODO: check
	D_VALID			=> valid_in,
	CRC				=> CRC_out,
	CRC_REG			=> CRC_reg_out,
	CRC_VALID		=> CRC_valid
);

end architecture;
