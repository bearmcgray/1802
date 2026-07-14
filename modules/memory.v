`timescale 1ns/1ps

module memory(
	input clk_i,
	input rst_i,
	input we_i,
	input [15:0 ] address_i,
	input [7:0] data_i,
	output [7:0] data_o
);

	//internal signals
	reg [7:0] mem [0:65536];
	
	//~ assign #0.3 data_o = ( we_i==1'b0 && rst_i==1'b0 )? mem[address_i] : 8'h00;
	reg [7:0]data_o;
	
	always @(negedge clk_i, posedge rst_i)begin
		if ( rst_i == 1'b1 ) begin
			$readmemh( `FIRMWARE, mem, 0 );
			data_o <= 8'h00;
		end else begin 
			if ( we_i == 1'b1 ) begin
				mem[address_i] <= data_i;
			end	
			data_o <= mem[address_i];
		end	
	end

endmodule //memory