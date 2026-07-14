`timescale 1ns/1ps

module hilo(
	input hilo_i,
	input [15:0 ] operand_i,
	output [7:0] result_o
);

	assign #0.1 result_o = ( hilo_i == 1'b1 )?operand_i[15:8]:operand_i[7:0];

endmodule //hilo