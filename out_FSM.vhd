library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity out_FSM is
port(
	reset:					in std_logic;
	clk_sys:					in std_logic;
	
	data_in:					in std_logic_vector(7 downto 0);
	start_stop_in:			in std_logic;
	valid_in:				in std_logic;
	discard_in:				in std_logic;
	num_used_w_in:			in std_logic_vector(14 downto 0);
	
	rden_FIFOs:				out std_logic;
	data_out:				out std_logic_vector(7 downto 0);
	data_valid_out:		out std_logic;
	ctrl_out:				out std_logic_vector(23 downto 0);
	ctrl_valid_out:		out std_logic;
	discard_out:			out std_logic;
	seq_num_out:			out std_logic_vector(14 downto 0)
);
end entity;

architecture rtl of out_FSM is

signal num_used_w:	integer range 0 to 32767;

type state is (s_idle, s_metadata, s_length, s_data);
signal my_state:	state;

signal seq_num:	integer range 0 to 32767; -- Frame sequence number (one-indexed)
signal count:		integer range 0 to 4095; -- Octet count (zero-indexed)

-- TODO: find out why Valid bit needs a 1-cycle delay
signal data_valid_1: std_logic;
begin

-- Asynchronous signals
process(all) begin
	num_used_w <= to_integer(unsigned(num_used_w_in));
end process;

-- Moore machine
process(reset, clk_sys) begin
	if(reset = '1') then
		my_state <= s_idle;
		seq_num <= 0;
		count <= 0;
	elsif(rising_edge(clk_sys)) then
		case my_state is
		when s_idle =>
			if(start_stop_in = '1' and valid_in = '1' and num_used_w > 4095) then
				my_state <= s_metadata;
				seq_num <= seq_num + 1;
			end if;
			count <= 0;
		when s_metadata =>
			if(count = 15) then
				my_state <= s_length;
				count <= 0;
			else
				count <= count + 1;
			end if;
		when s_length =>
			if(count = 1) then
				my_state <= s_data;
				count <= 0;
			else
				count <= count + 1;
			end if;
		when others => -- s_data
			if(start_stop_in = '0' and valid_in = '0') then -- TODO: check
				my_state <= s_idle;
				count <= 0;
			else
				count <= count + 1;
			end if;
		end case;
	end if;
end process;

-- Output signals
process(reset, clk_sys) begin
	if(reset = '1') then
		data_out <= X"00";
		
		ctrl_out <= X"000000";
		ctrl_valid_out <= '0';
	elsif(rising_edge(clk_sys)) then
		data_out <= data_in;
		
		if(my_state = s_length) then
			if(count = 0) then
				ctrl_out(7 downto 0) <= data_in; -- TODO: check endianness
				ctrl_valid_out <= '0';
			else -- count = 1
				ctrl_out(15 downto 8) <= data_in;
				ctrl_valid_out <= '1';
			end if;
		else
			ctrl_out <= X"000000";
			ctrl_valid_out <= '0';
		end if;
	end if;
end process;

-- Valid bit needs a 1-cycle delay
process(reset, clk_sys) begin
	if(reset = '1') then
		data_valid_1 <= '0';
		data_valid_out <= '0';
	elsif(rising_edge(clk_sys)) then
		if(not(my_state = s_idle)) then -- TODO: check
			data_valid_1 <= '1';
		else
			data_valid_1 <= '0';
		end if;
		data_valid_out <= data_valid_1;
	end if;
end process;

process(all) begin
	if(not(my_state = s_idle)) then -- TODO: check
		rden_FIFOs <= '1';
	else
		if(valid_in = '1') then
			rden_FIFOs <= '0';
		else
			rden_FIFOs <= '1';
		end if;
	end if;
	
	if(not(my_state = s_idle)) then -- TODO: check
		discard_out <= discard_in;
	else
		discard_out <= '0';
	end if;
	
	seq_num_out <= std_logic_vector(to_unsigned(seq_num, 15));
end process;

end architecture;
