library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequence_detector is
port(
	reset:					in std_logic;
	clk:						in std_logic;
	
	valid_in:				in std_logic;
	data_in:					in std_logic_vector(7 downto 0);
	sequence_in:			in std_logic_vector(63 downto 0);
	data_out:				out std_logic_vector(7 downto 0);
	detected_out:			out std_logic
);
end entity;

architecture struct of sequence_detector is
	type data_arr is array (0 to 7) of std_logic_vector(7 downto 0);
	signal data_reg: data_arr;
	
	signal i: integer range data_reg'range;
	
begin

-- Shift register
process(reset, clk) begin
	if(reset = '1') then
		for i in data_reg'range loop
			data_reg(i) <= X"00";
		end loop;
	elsif(rising_edge(clk) and valid_in = '1') then -- TODO: check wren_FIFOs
		for i in data_reg'range loop
			if(i = 0) then
				data_reg(i) <= data_in;
			else
				data_reg(i) <= data_reg(i-1);
			end if;
		end loop;
	end if;
end process;

-- Detector output
process(all) begin
	data_out <= data_reg(0);
	
	if(data_reg(0) = sequence_in(7 downto 0) and
		data_reg(1) = sequence_in(15 downto 8) and
		data_reg(2) = sequence_in(23 downto 16) and
		data_reg(3) = sequence_in(31 downto 24) and
		data_reg(4) = sequence_in(39 downto 32) and
		data_reg(5) = sequence_in(47 downto 40) and
		data_reg(6) = sequence_in(55 downto 48) and
		data_reg(7) = sequence_in(63 downto 56)) then
		detected_out <= '1';
	else
		detected_out <= '0';
	end if;
end process;

end architecture;
