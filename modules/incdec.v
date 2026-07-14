`timescale 1ns/1ps

module incdec(
	input ind_i,
	input [15:0 ] operand_i,
	output [15:0] result_o
);

	//~ assign #0.1 result_o = ( ind_i == 1'b1 )?(operand_i + 16'h0001):(operand_i - 16'h0001);
	assign #0.1 result_o = operand_i + ( ( ind_i == 1'b1 )? 16'h0001:16'hffff );

endmodule //incdec