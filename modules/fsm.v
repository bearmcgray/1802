`timescale 1ns/1ps

`include "modules/states.vh"

module fsm(
	input clk_i,
	input rst_i,
	
	input int_i,
	input dma_i,
	input idle_i,
	
	input long_i,
		
	output [2:0] state_o
);
	//internal signals
	reg [2:0] state;
	reg [2:0] state_next;
	
	assign state_o = state;
	
	always @( posedge clk_i, posedge rst_i ) begin
		if (rst_i==1'b1) begin
			state <= `reset_state;
		end else begin
			state <= state_next;
		end
	end	
	
	always @( state, int_i, dma_i, idle_i ,long_i) begin
		case ( state )
			
			`reset_state : begin
				state_next = `fetch_state; 
			end			
			
			`fetch_state : begin
				state_next = `execute1_state; 
			end
				
			`execute1_state : begin
				if ( long_i!=1'b1 )begin
					if ( dma_i==1'b1 )
						state_next = `dma_state; 
					else if ( int_i==1'b1 )
						state_next = `interrupt_state; 
					else if ( idle_i==1'b1  )
						state_next = `execute1_state; 
					else 
						state_next = `fetch_state; 
				end else begin
						state_next = `execute2_state; 
				end	
			end
				
			`execute2_state : begin
				if ( dma_i==1'b1 )
					state_next = `dma_state; 
				else if ( int_i==1'b1 )
					state_next = `interrupt_state; 
				else 
					state_next = `fetch_state; 
			end
				
			`dma_state : begin
				if ( dma_i==1'b1)
					state_next = `dma_state; 
				else if ( int_i==1'b1 )
					state_next = `interrupt_state; 
				else 
					state_next = `fetch_state; 
			end		
			
			`interrupt_state : begin
				if ( dma_i==1'b1)
					state_next = `dma_state; 
				else
					state_next = `fetch_state; 
			end

			default:begin
				state_next = `reset_state;
			end
			
		endcase	
	end	

endmodule //fsm