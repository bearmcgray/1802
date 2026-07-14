`timescale 1ns/1ps

module resync(
	input clk_i,
	input rst_i,
	
	input [ W-1:0 ] in_i,
	output [W-1:0] out_o
);
	parameter RV = 1'b0;
	parameter W = 1;
		
	reg [W-1:0] inter1;
	//~ reg [W-1:0] inter2;
	reg [W-1:0] out_o;
	
always @ ( posedge clk_i, posedge rst_i ) begin
	
	if (rst_i == 1'b1)begin
		out_o<= {W{RV}};
		inter1<= {W{RV}};
		//~ inter2<= {W{RV}};
	end else begin 
		out_o<=inter1;
		//~ inter2<=inter1;
		inter1<=in_i;
	end
	
	
end	
	

endmodule //resync