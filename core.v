`timescale 1ns/1ps

`include "modules/states.vh"
`include "modules/operations.vh"

module core( 
	input clk_i, 
	input rst_i,

	input int_i,

	input dmain_i,
	input dmaout_i,

	input [7:0]inline_i,
	output [7:0]outline_o,

	output [2:0]N_o,
	output wn_o,
	input [4:1]nEF_i,
	output Q_o
);

parameter rP = 3'h0;
parameter rX = 3'h1;
parameter rN = 3'h2;
parameter r0 = 3'h3;
parameter r1 = 3'h4;
parameter r2 = 3'h5;

parameter mwR = 3'h0;
parameter mwD = 3'h1;
parameter mwT = 3'h2;
parameter mwXP = 3'h3;
parameter mwI = 3'h4;

parameter dwA = 2'h0;
parameter dwR = 2'h1;
parameter dwM = 2'h2;
parameter dwI = 2'h3;

reg [3:0] P = 4'h0;
reg [3:0] X = 4'h0;
reg [3:0] N = 4'h0;
reg [3:0] I = 4'h0;
reg Q = 1'b0;
reg IE = 1'b0;

reg [7:0] T = 8'h00;

reg [2:0] N_o = 3'h0;
reg wn_o;

reg [8:0] D = 8'h00;
assign DF = D[8];

wire [15:0] address;
reg [7:0] wdata;
wire [7:0] rdata;
reg mwe;

wire [2:0] state;

wire [15:0] rreg;
wire [15:0] wreg;

reg [3:0] raddr;
reg [3:0] waddr;
reg [1:0] reg_we;

wire interrupt;
wire [4:1]nef;

reg do_exec2 = 1'b0;
reg do_idle = 1'b0;

reg id_op;
wire [15:0] id_in;
wire [15:0] id_out;

reg [1:0] ddw_mode = dwA;
reg drw_mode = 1'b0;
reg mds_mode = 1'b0;
reg [2:0] dmw_mode = mwR;
reg [2:0] prr_mode = rP;
reg [2:0] prw_mode = rP;

reg do_sex = 1'b0;
reg do_sep = 1'b0;

reg gethilo = 1'b0;
wire [7:0] regpart;

reg [3:0] aluop;
wire [8:0]  alures;
reg dwe;

reg [8:0] din;

reg sethilo;
wire [7:0] toexp;
wire [15:0] fromexp;

reg do_store;
reg do_io; 

reg do_int = 1'b0; 
reg do_mark = 1'b0; 
reg m2xp = 1'b0; 

reg setq = 1'b0; 
reg resetq = 1'b0;

reg setie = 1'b0; 
reg resetie = 1'b0; 

assign Q_o = Q;

assign address = rreg;
assign id_in = rreg;
assign outline_o = rdata;
//~ assign N_o = N[2:0];
//~ assign N_o = do_io?N[2:0]:3'h0;


// dmw data memory write
//assign wdata = (dmw_mode==1'b1) ? D[7:0] : regpart;
always @ *
	case( dmw_mode )
		mwR:wdata = regpart;
		mwD:wdata = D[7:0];
		mwT:wdata = T;
		mwXP:wdata = {X,P};
		mwI:wdata = inline_i;
		default:wdata = 8'h00;
	endcase

// ddw data d register write
always @ *
	case( ddw_mode )
		dwA:din = alures;
		dwR:din = {1'b0,regpart};
		dwM:din = {1'b0,rdata};
		dwI:din = {1'b0,inline_i};
	endcase

// drw data register write
assign wreg = (drw_mode==1'b1) ? fromexp : id_out;

// mds memory d register select
assign toexp = (mds_mode==1'b1) ? D[7:0] : rdata;

// prr pointer register read
always @ *
	case( prr_mode )
		rP:raddr=P;
		rX:raddr=X;
		rN:raddr=N;
		r0:raddr=4'h0;
		r1:raddr=4'h1;
		r2:raddr=4'h2;
		3'b110:raddr=P;
		3'b111:raddr=P;
	endcase

// prw pointer register write
always @ *
	case( prw_mode )
		rP:waddr=P;
		rX:waddr=X;
		rN:waddr=N;
		r0:waddr=4'h0;
		r1:waddr=4'h1;
		r2:waddr=4'h2;
		3'b110:waddr=P;
		3'b111:waddr=P;
	endcase

// I N process
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		I<=8'h00;
		N<=8'h00;
	end else begin
		if (state==`fetch_state) begin
			I<=rdata[7:4];
			N<=rdata[3:0];
		end
	end
end

// X process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		X<=8'h00;
	end else begin
		if (do_sex) begin
			X<=N;
		end else begin
			if (do_mark)begin
				X<=P;
			end	else begin
				if (m2xp)begin
					X<=rdata[7:4];
				end	else begin
					if (do_int) begin
						X<=4'h2;
					end
				end
			end
		end
	end
end

// P process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		P<=8'h00;
	end else begin
		if (do_sep) begin
			P<=N;
		end else begin
			if (m2xp)begin
				P<=rdata[3:0];
			end else begin
				if (do_int) begin
					P<=4'h1;
				end
			end
		end
	end
end

// D process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		D <= 9'h000;
	end else begin
		if (dwe) begin
			D <= din;
		end
	end
end

// T process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		T<=8'h00;
	end else begin
		if (do_mark||do_int) begin
			T<={X,P};
		end
	end
end

// Q process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		Q<=1'b0;
	end else begin
		if (setq) begin
			Q<=1'b1;
		end else begin
			if (resetq) begin
				Q<=1'b0;
			end
		end
	end
end

// IE process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		IE<=1'b0;
	end else begin
		if (setie) begin
			IE<=1'b1;
		end else begin
			if (resetie||do_int) begin
				IE<=1'b0;
			end
		end
	end
end

// IO process 
always @( posedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		//~ N_o <= 3'h0;
		wn_o <= 1'b0;
	end else begin
		if (do_io) begin
			//~ N_o <= N[2:0];
			wn_o <= 1'b1;
		end else begin
			//~ N_o <= 3'h0;
			wn_o <= 1'b0;
		end
	end
end

always @( negedge clk_i, posedge rst_i )begin
	if (rst_i==1'b1) begin
		N_o <= 3'h0;
		//~ //wn_o <= 1'b0;
	end else begin
		if (do_io) begin
			N_o <= N[2:0];
			//~ //wn_o <= 1'b1;
		end else begin
			N_o <= 3'h0;
			//~ //wn_o <= 1'b0;
		end
	end
end

always @( state, I, N, Q, D, DF, IE, nef )begin

	id_op = 1'b0; 
	prr_mode = rP; 
	prw_mode = rP; 
	drw_mode = 1'b0; 
	ddw_mode = dwA;
	mds_mode = 1'b0;
	dmw_mode = mwR;

	reg_we = 2'b00; 
	do_exec2 = 1'b0;
	do_sex = 1'b0;
	do_sep = 1'b0;

	aluop = `nop_op;
	dwe = 1'b0;
	sethilo = 1'b0;
	gethilo = 1'h0;
	do_idle = 1'b0;
	do_store = 1'b0;

	mwe = 1'b0;

	do_mark = 1'b0; 
	m2xp = 1'b0;

	setq = 1'b0;
	resetq = 1'b0;

	setie = 1'b0;
	resetie = 1'b0;
	do_int = 1'b0;
	do_io = 1'b0; 

	case(state)

	`fetch_state:begin
		id_op = 1'b1; 
		reg_we = 2'b11;  
	end

	`execute1_state:begin
		casez( {I,N} )
// ==== 0x ====+
		8'h0?:begin
			if (N==4'h0)begin 
				// idl
				do_idle = 1'b1;
			end else begin
				// ldn
				prr_mode = rN; 
				ddw_mode = dwM; 
				dwe=1'b1;
			end
		end

// ==== 1x ====+
		8'h1?:begin
			// inc
			id_op = 1'b1; 
			prr_mode = rN; 
			prw_mode = rN; 
			reg_we = 2'b11; 
		end

// ==== 2x ====+
		8'h2?:begin
			// dec
			id_op = 1'b0; 
			prr_mode = rN; 
			prw_mode = rN; 
			reg_we = 2'b11; 
		end

// ==== 3x ====
		8'b0011_?000:begin
			// br skp(bnr)
			if ( N[3]==1'b0 ) begin
				id_op = 1'b0; 
				drw_mode = 1'b1; 
				reg_we = 2'b01; 
				sethilo = 1'b0;
			end else	begin
				id_op = 1'b1; 
				prr_mode = rP; 
				prw_mode = rP; 
				reg_we = 2'b11;
			end
		end

		8'b0011_?001:begin
			// bq bnq
			if ( ((Q==1'b1)&&(N[3]==1'b0))||((Q==1'b0)&&(N[3]==1'b1))) begin
				id_op = 1'b0; 
				drw_mode = 1'b1; 
				reg_we = 2'b01; 
				sethilo = 1'b0;	
			end else	begin
				id_op = 1'b1; 
				prr_mode = rP; 
				prw_mode = rP; 
				reg_we = 2'b11; 	
			end
		end

		8'b0011_?011:begin
			// bdf bnf
			if ( ((DF==1'b1)&&(N[3]==1'b0))||((Q==1'b0)&&(N[3]==1'b1))) begin
				id_op = 1'b0; 
				drw_mode = 1'b1; 
				reg_we = 2'b01; 
				sethilo = 1'b0;	
			end else	begin
				id_op = 1'b1; 
				prr_mode = rP; 
				prw_mode = rP; 
				reg_we = 2'b11; 	
			end
		end

		8'b0011_?010:begin
			// bz bnz
			if ( ((D[7:0]==8'h00)&&(N[3]==1'b0))||((D[7:0]!=8'h00)&&(N[3]==1'b1)) ) begin
				id_op = 1'b0; 
				drw_mode = 1'b1; 
				reg_we = 2'b01; 
				sethilo = 1'b0;	
			end else	begin
				id_op = 1'b1; 
				prr_mode = rP; 
				prw_mode = rP; 
				reg_we = 2'b11; 	
			end
		end

		8'b0011_?1??:begin
			// b1 b2 b3 b4 bn1 bn2 bn3 bn4
			if ( 
				( (N[3] == 1'b1)&&(N[1:0] == 2'b00)&&(nef[1] == 1'b0) )||
				( (N[3] == 1'b1)&&(N[1:0] == 2'b01)&&(nef[2] == 1'b0) )||
				( (N[3] == 1'b1)&&(N[1:0] == 2'b10)&&(nef[3] == 1'b0) )||
				( (N[3] == 1'b1)&&(N[1:0] == 2'b11)&&(nef[4] == 1'b0) )||
			
				( (N[3] == 1'b0)&&(N[1:0] == 2'b00)&&(nef[1] == 1'b1) )||
				( (N[3] == 1'b0)&&(N[1:0] == 2'b01)&&(nef[2] == 1'b1) )||
				( (N[3] == 1'b0)&&(N[1:0] == 2'b10)&&(nef[3] == 1'b1) )||
				( (N[3] == 1'b0)&&(N[1:0] == 2'b11)&&(nef[4] == 1'b1) )
			) begin
				id_op = 1'b0; 
				drw_mode = 1'b1; 
				reg_we = 2'b01; 
				sethilo = 1'b0;	
			end else	begin
				id_op = 1'b1; 
				prr_mode = rP; 
				prw_mode = rP; 
				reg_we = 2'b11; 	
			end
		end

// ==== 4x ====+
		8'h4?:begin
			// lda
			id_op = 1'b1; 
			prr_mode = rN; 
			prw_mode = rN; 
			reg_we = 2'b11; 

			ddw_mode = dwM; 
			dwe=1'b1;
		end

// ==== 5x ====+
		8'h5?:begin
			// str
			prr_mode = rN; 
			dmw_mode = mwD; 
			mwe = 1'b1;
		end

// ==== 6x ====+
		8'b0110_0???:begin
			// irx ,out
			id_op = 1'b1; 
			prr_mode = rX; 
			prw_mode = rX; 
			reg_we = 2'b11; 
			if (N!=4'h0)begin
				do_io = 1'b1; 
			end	
		end

		8'b0110_1???:begin
			// 0x68 ,in
			if (N!=4'h8)begin
				//in
				id_op = 1'b0; 
				prr_mode = rX; 
				prw_mode = rX; 

				dmw_mode = mwI;
				ddw_mode = dwI;
				dwe = 1'b1; 
				mwe = 1'b1;
				do_io = 1'b1; 
			end
		end

// ==== 7x ====+
		8'h70:begin 
			// ret
			id_op = 1'b1; 
			prr_mode = rX;
			prw_mode = rX;
			m2xp = 1'b1;
			reg_we = 2'b11; 
			setie = 1'b1;
		end

		8'h71:begin 
			// dis
			id_op = 1'b1; 
			prr_mode = rX;
			prw_mode = rX;
			m2xp = 1'b1;
			reg_we = 2'b11; 
			resetie = 1'b1;
		end

		8'h72:begin 
			// ldxa
			id_op = 1'b1; 
			prr_mode = rX;
			prw_mode = rX;
			reg_we = 2'b11; 

			ddw_mode = dwM;
			dwe=1'b1;
		end

		8'h73:begin 
			// stxd
			id_op = 1'b0; 
			prr_mode = rX;
			prw_mode = rX;
			reg_we = 2'b11; 

			ddw_mode = dwM;
			dwe=1'b1;
		end

		8'h74:begin 
			// adc
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `adc_op;
			dwe=1'b1;
		end

		8'h75:begin 
			// sdb
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `sdb_op;
			dwe=1'b1;
		end

		8'h76:begin 
			// rshr
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `shrc_op;
			dwe=1'b1;
		end

		8'h77:begin 
			// smb
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `smb_op;
			dwe=1'b1;
		end

		8'h78:begin 
			// sav
			prr_mode = rX; 
			dmw_mode = mwT;
			mwe=1'b1;
		end

		8'h79:begin 
			// mark
			do_mark = 1'b1; 

			prr_mode = r2;
			prw_mode = r2;
			dmw_mode = mwXP;
			mwe=1'b1;

			id_op = 1'b0;
			reg_we = 2'b11;
		end

		8'h7A:begin 
			// req
			resetq = 1'b1;
		end

		8'h7B:begin 
			// seq
			setq = 1'b1;
		end

		8'h7C:begin
			// adci
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `adc_op;
			dwe=1'b1;
		end

		8'h7D:begin
			// sdbi
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `sdb_op;
			dwe=1'b1;
		end

		8'h7E:begin 
			// rshl
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `shlc_op;
			dwe=1'b1;
		end

		8'h7F:begin
			// sdbi
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `smb_op;
			dwe=1'b1;
		end

// ==== 8x ====+
		8'h8?:begin
			// glo 
			prr_mode = rN;
			ddw_mode = dwR;
			gethilo = 1'b0;
			dwe = 1'b1;
		end

// ==== 9x ====+
		8'h9?:begin
			// ghi
			prr_mode = rN;
			ddw_mode = dwR;
			gethilo = 1'b1;
			dwe = 1'b1;
		end

// ==== Ax ====+
		8'hA?:begin
			// plo 
			prw_mode = rN;
			mds_mode = 1'b1;
			drw_mode = 1'b1;
			sethilo = 1'b0;
			reg_we = 2'b01;
		end

// ==== Bx ====+
		8'hB?:begin
			// phi
			prw_mode = rN;
			mds_mode = 1'b1;
			drw_mode = 1'b1;
			sethilo = 1'b1;
			reg_we = 2'b10;
		end

// ==== Cx ====+
		8'hC0:begin
			// lbr
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 

			mds_mode = 1'b0;
			do_exec2 = 1'b1;
			do_store = 1'b1;
		end

		8'b1100_?010:begin
			// lbz
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 

			mds_mode = 1'b0;
			do_exec2 = 1'b1;
			do_store = 1'b1;
		end

		8'b1100_?011:begin
			// lbdf lbnf
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 

			mds_mode = 1'b0;
			do_exec2 = 1'b1;
			do_store = 1'b1;
		end

		8'b1100_?001:begin
			// lbq lbnq
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 

			mds_mode = 1'b0;
			do_exec2 = 1'b1;
			do_store = 1'b1;
		end

		8'hC4:begin
			// nop
			id_op = 1'b0; 
			do_exec2 = 1'b1;
		end

		8'hC8:begin
			// lskp
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 
			do_exec2 = 1'b1;
		end

		8'b1100?110:begin
			// lsz lsnz
			if ( ((D[7:0]==8'h00)&&(N[3]==1'b1))||((D[7:0]!=8'h00)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end 
			do_exec2 = 1'b1;
		end

		8'b1100?111:begin
			// lsdf lsnf
			if ( ((DF==1'b1)&&(N[3]==1'b1))||((DF==1'b0)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
			do_exec2 = 1'b1;
		end

		8'b1100?101:begin
			// lsq lsnq
			if ( ((Q==1'b1)&&(N[3]==1'b1))||((Q==1'b0)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
			do_exec2 = 1'b1;
		end

		8'hCC:begin
			// lsie
			if ( IE==1'b1 ) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
			do_exec2 = 1'b1;
		end

// ==== Dx ====+
		8'hD?:begin
			// sep
			id_op = 1'b0; 
			do_sep = 1'b1;
		end

// ==== Ex ====+
		8'hE?:begin
			// sex
			id_op = 1'b0; 
			do_sex = 1'b1;
		end

// ==== Fx ====+
		8'hF0:begin
			// ldx
			prr_mode = rX; 
			ddw_mode = dwM; 
			dwe=1'b1;
		end

		8'hF1:begin 
			// or
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `or_op;
			dwe=1'b1;
		end

		8'hF2:begin 
			// and
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `and_op;
			dwe=1'b1;
		end

		8'hF3:begin 
			// xor
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `xor_op;
			dwe=1'b1;
		end

		8'hF4:begin 
			// add
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `add_op;
			dwe=1'b1;
		end

		8'hF5:begin 
			// sd
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `sd_op;
			dwe=1'b1;
		end

		8'hF6:begin 
			// shr
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `shr_op;
			dwe=1'b1;
		end

		8'hF7:begin 
			// sm
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `sm_op;
			dwe=1'b1;
		end

		8'hF8:begin
			// ldi
			id_op = 1'b1;
			reg_we = 2'b11; 
			ddw_mode = dwM; 
			dwe=1'b1;
		end

		8'hF9:begin
			// ori
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `or_op;
			dwe=1'b1;
		end

		8'hFA:begin
			// ani
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `and_op;
			dwe=1'b1;
		end

		8'hFB:begin
			// xri
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `xor_op;
			dwe=1'b1;
		end

		8'hFC:begin
			// adi
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `add_op;
			dwe=1'b1;
		end

		8'hFD:begin
			// sdi
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `sd_op;
			dwe=1'b1;
		end

		8'hFE:begin 
			// shr
			prr_mode = rX;
			ddw_mode = dwA; 
			aluop = `shl_op;
			dwe=1'b1;
		end

		8'hFF:begin 
			// smi
			id_op = 1'b1;
			reg_we = 2'b11; 

			ddw_mode = dwA; 
			aluop = `sm_op;
			dwe=1'b1;
		end

		endcase
	end

	`execute2_state:begin
		casez({I,N})

		8'hC0:begin
			// lbr
			mds_mode = 1'b0;
			drw_mode = 1'b1;
			sethilo = 1'b0;
			reg_we = 2'b11; 
		end

		8'b1100_?010:begin
			// lbz lbnz
			if ( ((D[7:0]==8'h00)&&(N[3]==1'b0))||((D[7:0]!=8'h00)&&(N[3]==1'b1))) begin
				mds_mode = 1'b0;
				drw_mode = 1'b1;
				sethilo = 1'b0;
				reg_we = 2'b11; 
			end else begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'b1100_?011:begin
			// lbdf lbnf
			if ( ((DF==1'b1)&&(N[3]==1'b0))||((DF==1'b0)&&(N[3]==1'b1))) begin
				mds_mode = 1'b0;
				drw_mode = 1'b1;
				sethilo = 1'b0;
				reg_we = 2'b11; 
			end else begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'b1100_?001:begin
			// lbq lbnq
			if ( ((Q==1'b1)&&(N[3]==1'b0))||((Q==1'b0)&&(N[3]==1'b1))) begin
				mds_mode = 1'b0;
				drw_mode = 1'b1;
				sethilo = 1'b0;
				reg_we = 2'b11; 
			end else begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'hC8:begin
			// lskp
			id_op = 1'b1; 
			prw_mode = rP;
			prr_mode = rP;
			reg_we = 2'b11; 
		end

		8'b1100?110:begin
			// lsz lsnz
			if ( ((D[7:0]==8'h00)&&(N[3]==1'b1))||((D[7:0]!=8'h00)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'b1100?111:begin
			// lsdf lsnf
			if ( ((DF==1'b1)&&(N[3]==1'b1))||((DF==1'b0)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'b1100?101:begin
			// lsq lsnq
			if ( ((Q==1'b1)&&(N[3]==1'b1))||((Q==1'b0)&&(N[3]==1'b0))) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		8'hCC:begin
			// lsie
			if ( IE==1'b1 ) begin
				id_op = 1'b1; 
				prw_mode = rP;
				prr_mode = rP;
				reg_we = 2'b11; 
			end
		end

		default:begin
		end

		endcase
	end

	`dma_state:begin
	end

	`interrupt_state:begin
		do_int = 1'b1;
	end

	default:begin
	end

	endcase
end

memory mem_inst(
	.clk_i(clk_i), 
	.rst_i(rst_i),

	.we_i(mwe),
	.address_i(address),
	.data_i(wdata),
	.data_o(rdata)
);

regs regs_inst(
	.clk_i(clk_i),
	.rst_i(rst_i),

	.we_i(reg_we),
	.raddr_i(raddr),
	.waddr_i(waddr),
	.wreg_i(wreg),
	.rreg_o(rreg)
);

incdec incdec_inst(
	.ind_i(id_op),
	.operand_i(id_in),
	.result_o(id_out)
);

fsm fsm_inst(
	.clk_i(clk_i),
	.rst_i(rst_i),

	.dma_i(1'b0),
	.idle_i(do_idle),
	.int_i(interrupt),
	.long_i(do_exec2),

	.state_o(state)
);

hilo hilo_inst(
	.hilo_i(gethilo),
	.operand_i(rreg),
	.result_o(regpart)
);

expander exp_inst(
	.clk_i(clk_i), 
	.rst_i(rst_i),

	.store_i(do_store),

	.hilo_i(sethilo),
	.operand_i(toexp),
	.result_o(fromexp)
);

alu alu_inst(
	.d_i(D),
	.bus_i(rdata),
	.operation_i(aluop),
	.result_o(alures)
);

resync#(.W(1), .RV(1'b0)) int_inst(
	.clk_i(clk_i), 
	.rst_i(rst_i),

	.in_i(int_i),
	.out_o(interrupt)
);

resync#(.W(4), .RV(1'b1)) nef_inst(
	.clk_i(clk_i), 
	.rst_i(rst_i),

	.in_i(nEF_i),
	.out_o(nef)
);

endmodule // core
