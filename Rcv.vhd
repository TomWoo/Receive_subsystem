library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: eliminate extra nibble at beginning of each packet
entity Rcv is
port(
	reset:					in std_logic;
	clk_phy:					in std_logic;
	clk_sys:					in std_logic;
	
	data_in:					in std_logic_vector(3 downto 0);
	valid_in:				in std_logic;
	
	data_out:				out std_logic_vector(7 downto 0);
	data_valid_out:		out std_logic;
	ctrl_out:				out std_logic_vector(23 downto 0);
	ctrl_valid_out:		out std_logic;
	discard_out:			out std_logic;
	seq_num_out:			out std_logic_vector(14 downto 0)
);
end entity;

architecture toplevel of Rcv is

-- Input FSM
component in_FSM is
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
end component;

-- Input FSM to FIFOs
signal wren_FIFOs:			std_logic;
signal data_FIFO_in:			std_logic_vector(7 downto 0);
signal start_stop_FIFO_in:	std_logic;
signal valid_FIFO_in:		std_logic;
signal discard_FIFO_in:		std_logic;

-- FIFOs
component FIFO_8 is
port(
	aclr		: IN STD_LOGIC := '0';
	data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	rdclk		: IN STD_LOGIC ;
	rdreq		: IN STD_LOGIC ;
	wrclk		: IN STD_LOGIC ;
	wrreq		: IN STD_LOGIC ;

	q				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
	rdempty		: OUT STD_LOGIC ;
	rdusedw		: OUT STD_LOGIC_VECTOR (14 DOWNTO 0);
	wrfull		: OUT STD_LOGIC
);
end component;

component FIFO_1 is
port(
	aclr		: IN STD_LOGIC := '0';
	data		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
	rdclk		: IN STD_LOGIC ;
	rdreq		: IN STD_LOGIC ;
	wrclk		: IN STD_LOGIC ;
	wrreq		: IN STD_LOGIC ;

	q				: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
	rdempty		: OUT STD_LOGIC ;
	wrfull		: OUT STD_LOGIC
);
end component;

-- FIFOs to Output FSM
signal rdempty_FIFOs:		std_logic;
signal num_used_w:			std_logic_vector(14 downto 0);
signal wrfull_FIFOs:			std_logic;

signal data_FIFO_out:			std_logic_vector(7 downto 0);
signal start_stop_FIFO_out:	std_logic;
signal valid_FIFO_out:			std_logic;
signal discard_FIFO_out:		std_logic;

signal rden_FIFOs:			std_logic;
signal rden_FIFOs_fsm:		std_logic; -- output of out_FSM

-- Output FSM
component out_FSM is
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
end component;

begin

-- Asynchronous signals
process(all) begin
	rden_FIFOs <= rden_FIFOs_fsm and not(rdempty_FIFOs);
end process;

-- Input FSM
input_FSM: in_FSM port map(
	reset					=> reset,
	clk_phy				=> clk_phy,
	
	data_in				=> data_in,
	valid_in				=> valid_in,
	
	wren_FIFOs			=> wren_FIFOs,
	data_out				=> data_FIFO_in,
	start_stop_out		=> start_stop_FIFO_in,
	valid_out			=> valid_FIFO_in,
	discard_out			=> discard_FIFO_in
);

-- FIFOs
data_FIFO: FIFO_8 port map(
	aclr		=> reset,
	data		=> data_FIFO_in,
	rdclk		=> clk_sys,
	rdreq		=> rden_FIFOs,
	wrclk		=> clk_phy,
	wrreq		=> wren_FIFOs,
	
	q			=> data_FIFO_out,
	rdempty	=> rdempty_FIFOs,
	rdusedw	=> num_used_w,
	wrfull	=> wrfull_FIFOs
);

start_stop_FIFO: FIFO_1 port map(
	aclr		=> reset,
	data(0)	=> start_stop_FIFO_in,
	rdclk		=> clk_sys,
	rdreq		=> rden_FIFOs,
	wrclk		=> clk_phy,
	wrreq		=> wren_FIFOs,
	
	q(0)		=> start_stop_FIFO_out
);

valid_FIFO: FIFO_1 port map(
	aclr		=> reset,
	data(0)	=> valid_FIFO_in,
	rdclk		=> clk_sys,
	rdreq		=> rden_FIFOs,
	wrclk		=> clk_phy,
	wrreq		=> wren_FIFOs,
	
	q(0)		=> valid_FIFO_out
);

discard_FIFO: FIFO_1 port map(
	aclr		=> reset,
	data(0)	=> discard_FIFO_in,
	rdclk		=> clk_sys,
	rdreq		=> rden_FIFOs,
	wrclk		=> clk_phy,
	wrreq		=> wren_FIFOs,
	
	q(0)		=> discard_FIFO_out
);

-- Output FSM
output_FSM: out_FSM port map(
	reset					=> reset,
	clk_sys				=> clk_sys,
	
	data_in				=> data_FIFO_out,
	start_stop_in		=> start_stop_FIFO_out,
	valid_in				=> valid_FIFO_out,
	discard_in			=> discard_FIFO_out,
	num_used_w_in		=> num_used_w,
	
	rden_FIFOs			=> rden_FIFOs_fsm,
	data_out				=> data_out,
	data_valid_out		=> data_valid_out,
	ctrl_out				=> ctrl_out,
	ctrl_valid_out		=> ctrl_valid_out,
	discard_out			=> discard_out,
	seq_num_out			=> seq_num_out
);

end architecture;
