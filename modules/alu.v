`timescale 1ns/1ps

`include "modules/operations.vh"

module alu(
	input [8:0] d_i,
	input [7:0] bus_i,
	
	input [3:0] operation_i,
	
	output [8:0] result_o
);

reg [8:0]result_o;

always @* begin
	case(operation_i)
		`or_op:begin
			result_o = {d_i[8], bus_i[7:0] | d_i[7:0]};
		end	
		
		`xor_op:begin
			result_o = {d_i[8], bus_i[7:0] ^ d_i[7:0]};
		end
		
		`and_op:begin
			result_o = {d_i[8], bus_i[7:0] & d_i[7:0]};
		end	
		
		`shr_op:begin
			result_o = {d_i[0], 1'b0, d_i[7], d_i[6], d_i[5], d_i[4], d_i[3], d_i[2], d_i[1]};
		end	
		
		`shrc_op:begin
			result_o = {d_i[0], d_i[8], d_i[7], d_i[6], d_i[5], d_i[4], d_i[3], d_i[2], d_i[1]};
		end	

		`shl_op:begin
			result_o = {d_i[7], d_i[6], d_i[5], d_i[4], d_i[3], d_i[2], d_i[1], d_i[0], 1'b0 };
		end	
		
		`shlc_op:begin
			result_o = {d_i[7], d_i[6], d_i[5], d_i[4], d_i[3], d_i[2], d_i[1], d_i[0], d_i[8] };
		end	
		
		`add_op:begin
			result_o = {1'b0, bus_i[7:0]}+{1'b0, d_i[7:0]};
		end	
		
		`adc_op:begin
			result_o = {1'b0, bus_i[7:0]}+{1'b0, d_i[7:0]}+{8'h00,d_i[8]};
		end	
		
		`sd_op:begin
			result_o = {1'b1, bus_i[7:0]}-{1'b0, d_i[7:0]};
		end	
		
		`sdb_op:begin
			result_o = {1'b0, bus_i[7:0]} - {1'b0, d_i[7:0]} - (d_i[8]==1'b1)?9'b000000000:9'b111111111;
		end	
		
		`sm_op:begin
			result_o = {1'b1, d_i[7:0]} - {1'b0, bus_i[7:0]};		
		end	
		
		`smb_op:begin
			result_o = {1'b0, d_i[7:0]} - {1'b0, bus_i[7:0]} - (d_i[8]==1'b1)?9'b000000000:9'b111111111;
		end			
		
		default:begin
			result_o = 9'b000000000;
		end
		
	endcase	
end	

endmodule //alu
