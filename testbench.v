`timescale 1ns/1ps

module testbench;

	reg reset = 1'b1;
	reg clk = 1'b0;
	reg interrupt = 1'b0;
	reg [7:0]inp = 8'h88;
	reg [3:0]nef = 4'h1;
	
	wire [2:0]N;
	
initial begin
	$dumpfile( `DUMP_FILE_NAME );
	$dumpvars( 0, testbench );

	# 3.8 reset <= 1'b0;
	# 210.02 interrupt <= 1'b1;
	# 1.9 interrupt <= 1'b0;
	# 40 nef<=4'he;
	# 411.02 interrupt <= 1'b1;
	# 5.1 interrupt <= 1'b0;
	
	# 1000 $finish;
end

	always #1 clk <= !clk;

	always @(negedge clk)begin
		if (N)
			inp = inp + 1;
		
	end	

	core c1 (
		.clk_i(clk), 
		.rst_i(reset),
		.int_i(interrupt),
		.inline_i(inp),
		.N_o(N),
		.nEF_i(nef)
	);

endmodule // testbench