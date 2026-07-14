`timescale 1ns/1ps

module expander(
	input clk_i,
	input rst_i,
	
	input hilo_i,
	input [7:0] operand_i,
	input store_i,
	output [15:0] result_o
);
	reg [7:0] filler;
	
	always @( posedge clk_i, posedge rst_i)begin
		if ( rst_i==1'b1 )begin
			filler<=8'h00;
		end else begin
			if (store_i==1'b1)begin
				filler<=operand_i;
			end	
		end	
			
	end	
	
	assign #0.1 result_o = ( hilo_i == 1'b1 )?{operand_i[7:0], filler}:{filler,operand_i[7:0]};

endmodule //expander