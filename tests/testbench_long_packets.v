`timescale 1ns/100ps
`define CLK_PER 40

module testbench_long_packets;

// POR and Clocks
reg rst, clk_sys, clk_phy;
integer gap_len;
integer i, num_packets;
integer j, packet_len;

initial begin
	// Parameters
	gap_len = 1000;
	packet_len = 512;
	num_packets = 64;

	// Clocks
	clk_sys = 1'b1;
	clk_phy = 1'b1;
end

always begin
	clk_phy <= !clk_phy;
	#(`CLK_PER/2);
end

always begin
	clk_sys <= !clk_sys;
	#(`CLK_PER/4);
end

// Input signals
reg	 [ 3:0]	data_in;
reg			valid_in;

// Output signals
wire [ 7:0]	data_out;
wire		data_valid_out;
wire [23:0] ctrl_out;
wire		ctrl_valid_out;
wire		discard_out;
wire [14:0] seq_num_out;

// UUT
Rcv Rcv_inst(
	.reset(rst),
	.clk_phy(clk_phy),
	.clk_sys(clk_sys),
	
	.data_in(data_in),
	.valid_in(valid_in),
	
	.data_out(data_out),
	.data_valid_out(data_valid_out),
	.ctrl_out(ctrl_out),
	.ctrl_valid_out(ctrl_valid_out),
	.discard_out(discard_out),
	.seq_num_out(seq_num_out)
);

initial begin

data_in = 4'h0;
valid_in = 1'b0;

// POR
rst = 1'b1;
#(6*`CLK_PER);
rst = 1'b0;

// Stimuli
for (i=0; i<num_packets; i=i+1) begin
	for (j=0; j<packet_len; j=j+1) begin
		valid_in <= 1'b1;
		if(j<15) begin
			data_in <= 4'hA;
		end else if(j==15) begin
			data_in <= 4'hB;
		end else if(j<20 || j>=packet_len-4) begin
			data_in <= 4'hC;
		end else if(j%2 == 1) begin
			data_in <= j[8:5];
		end else begin
			data_in <= j/2;
		end

		#(`CLK_PER);
	end

	valid_in <= 1'b0;
	data_in <= 4'h0;
	#(gap_len*`CLK_PER);
end

end

endmodule
