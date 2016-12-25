library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Rcv is
port(
	reset:					in std_logic;
	clk_phy:					in std_logic;
	clk_sys:					in std_logic;
	
	data_in:					in std_logic_vector(3 downto 0);
	valid_in:				in std_logic;
	
	data_out:				out std_logic_vector(8 downto 0);
	ctrl_out:				out std_logic_vector(23 downto 0);
	valid_out:				out std_logic
);
end entity;

architecture toplevel of Rcv is

-- FIFOs
component FIFO_4_to_8
PORT(
	aclr					: IN STD_LOGIC := '0';
	data					: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
	rdclk					: IN STD_LOGIC ;
	rdreq					: IN STD_LOGIC ;
	wrclk					: IN STD_LOGIC ;
	wrreq					: IN STD_LOGIC ;
	
	q						: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
	rdempty				: OUT STD_LOGIC ;
	wrfull				: OUT STD_LOGIC
);
end component;

signal data_FIFO_in:		std_logic_vector(3 downto 0);
signal data_FIFO_out:	std_logic_vector(7 downto 0);
signal wren_FIFO:			std_logic;
signal rdempty_FIFO:		std_logic;
signal wrfull_FIFO:		std_logic;

-- CRC
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
end entity;

signal CRC_detected:			std_logic;
signal CRC_valid:				std_logic;

begin

data_FIFO: FIFO_4_to_8 PORT MAP(
	aclr		=> reset,
	data		=> data_FIFO_in,
	rdclk		=> clk_phy,
	rdreq		=> rdempty_FIFO,
	wrclk		=> clk_sys,
	wrreq		=> wren_FIFO,
	
	q			=> data_FIFO_out,
	rdempty	=> rdempty_FIFO,
	wrfull	=> wrfull_FIFO
);

CRC_detector: CRC port map(
	CLOCK				=> clk_sys,
	RESET				=> reset,
	DATA				=> data_out,
	LOAD_INIT		=> ,
	CALC				=> ,
	D_VALID			=> ,
	CRC				=> crc_out,
	CRC_REG			=> crc_reg_out,
	CRC_VALID		=> crc_valid_out
);

end architecture;
