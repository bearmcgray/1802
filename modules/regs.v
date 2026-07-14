`timescale 1ns/1ps

module regs(
	input clk_i,
	input rst_i,
	
	input [1:0] we_i,
	
	input [3:0] raddr_i,
	output [15:0] rreg_o,
	
	input [3:0] waddr_i,
	input [15:0] wreg_i
);

	//internal signals
	reg [15:0] regs [15:0] ;
	integer i;
	
	assign rreg_o = regs[raddr_i];
	
	always @(posedge clk_i, posedge rst_i)begin
		if ( rst_i == 1'b1 ) begin
			for (i=0; i<16; i=i+1)begin
				regs[i]<=16'h0000;
			end	
		end else begin 
			case(we_i)
				2'b01 : regs[waddr_i] <= { regs[waddr_i][15:8], wreg_i[7:0] };
				2'b10 : regs[waddr_i] <= { wreg_i[15:8], regs[waddr_i][7:0] };
				2'b11 : regs[waddr_i] <= wreg_i;
				2'b00 : regs[waddr_i] <= regs[waddr_i];
			endcase	
		end 
	end	
	
endmodule //regs