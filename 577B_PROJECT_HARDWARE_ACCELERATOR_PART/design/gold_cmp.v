//////////////////////////////////////////////////////////////////////////////////////////////////////////////////NIC////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////NIC////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////NIC////////////////////////////////////////////////////////////////////////////////////////////////
module gold_nic(clk, reset,addr,d_in,d_out,nicEn,nicEnWr, net_so,net_ro,net_do,net_polarity, net_si,net_ri,net_di);
input clk, reset;
input [0:1]addr;		// from processor -- reg to read
input [0:63]d_in;		// input packet from processor to inject to router
output reg [0:63]d_out; // content of reg data to be sent to processor
input nicEn;			// Enable signal to NIC, if '0', d_out = 0
input nicEnWr; 			// if '1' along with nicEn, write to out_ch_buff
output reg net_so;			// valid packet to send to router ready
input net_ro;			// router ready to accept paket from NIC
output reg [0:63]net_do;	// output packet data from NIC to router
input net_polarity;		// polarity indication
input net_si;			// indicates router wants to send data to in_ch_buff
output reg net_ri;			//indicates if in_ch_buff is empty
input [0:63]net_di;

reg [0:63] inp_buffer;
reg [0:1] reg_addr;
reg reg_nicEn;
reg reg_nicEnWr;
reg inp_stat_reg;
reg out_stat_reg;
reg inp_bufferRdEn; 
reg inp_bufferWrEn;
reg out_bufferRdEn;
reg out_bufferWrEn;
reg packet_polarity;

// combinational block 
always @(*) 
	begin
		if (reg_nicEn == 1'b0)
			begin
				d_out = 0;
			end
		else 
			begin
				case(reg_addr)
					2'b00: d_out = 64'b0;  //processor to router data ; processor knows the data it is writin to the NIC so I have put d_out = 0.
					2'b01: d_out = {63'b0, out_stat_reg};
					2'b10: d_out = inp_buffer;
					2'b11: d_out = {63'b0, inp_stat_reg};
					default: d_out= 64'b0;
				endcase
			end
		net_ri = (inp_stat_reg == 1'b0); //ready should be enable/1 when the input buffer is not full/ is empty i.e input status register is 0
		packet_polarity = net_do[0];
		
		//Send from nic to ring when buffer full, net_ready, and  opposite polarity exteral to router
		net_so =  (net_ro==1) & (out_stat_reg == 1'b1) & (net_polarity!=packet_polarity);
		inp_bufferRdEn = (addr == 2'b10) && nicEn;
		inp_bufferWrEn = (net_si==1) && (inp_stat_reg == 1'b0);
		out_bufferRdEn = net_so;
		out_bufferWrEn = nicEn && nicEnWr && (addr == 2'b00) && (out_stat_reg == 1'b0);
	end

// sequential block 
always @(posedge clk) begin
	if (reset)
		begin

			inp_buffer <= 0;
			inp_stat_reg <= 0;
			reg_nicEn <= 0;
			out_stat_reg <= 0;
			net_do <= 0;
			reg_addr <= 0;
			reg_nicEnWr <= 0;
		end
	else
		begin
			reg_addr <= addr;
			reg_nicEnWr <= nicEnWr;
			reg_nicEn <= nicEn;

			if (out_bufferRdEn && out_bufferWrEn)           
				begin
					net_do <=d_in;
					out_stat_reg <= 0;
				end	

			else if (out_bufferRdEn && !out_bufferWrEn)
				begin
					out_stat_reg <= 0;
				end
			else if ( !out_bufferRdEn && out_bufferWrEn)
				begin
					net_do <= d_in;
					out_stat_reg <= 1;
				end
				                                              // if (out_bufferRdEn == 0 && out_bufferWrEn == 0) then no change should happen to the out_stat_reg value to prevent any overwrite of data
			if (inp_bufferRdEn && inp_bufferWrEn)
				begin
					inp_buffer <= net_di;
					inp_stat_reg <= 0;
				end
			else if(inp_bufferRdEn && !inp_bufferWrEn)
				begin
					inp_stat_reg <= 0;
				end			
			else if (!inp_bufferRdEn && inp_bufferWrEn)
				begin
					inp_buffer <= net_di;
					inp_stat_reg <= 1;
				end            								  // if (inp_bufferRdEn == 0 && inp_bufferWrEn == 0) then no change should happen to the in_stat_reg value to prevent any overwrite of data
				
		end
	end	
	
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////router//////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////router//////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////router//////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////router//////////////////////////////////////////////////////////////////////////////

`define HC 55:48   //HC HOPCOUNT
`define BEFORE_HC 63:56
`define AFTER_HC 47:0
`define DIR 62
module gold_router(clk,reset,polarity,
                   cwsi,cwri,cwdi,ccwsi,ccwri,ccwdi,pesi,peri,pedi,
				   cwso,cwro,cwdo,ccwso,ccwro,ccwdo,peso,pero,pedo);
input cwsi,cwdi,ccwsi,ccwdi,pesi,cwro,ccwro,pero,clk,reset,pedi;
output cwri, ccwri, peri, cwso, cwdo, ccwso, ccwdo, peso, pedo, polarity;

wire [63:0]cwdi;
wire [63:0]ccwdi;
wire [63:0]pedi;

wire [63:0]cwdo;
wire [63:0]ccwdo;
wire [63:0]pedo;

reg polarity;
//cwri,ccwri,peri,cwso,ccwso, peso, polarity;

wire [1:0] req0, req1, req2;
wire [1:0] gnt0, gnt1, gnt2;
wire [63:0] in_buffer_out0;    
wire [63:0] in_buffer_out1;
wire [63:0] in_buffer_out2;

//parameter PE_ib2 = 1;
//parameter PE_ib0_ib1 = 0;

always @(posedge clk)
begin
    if (reset)
        begin
            //cwri  <=0;
			//ccwri <=0;
			//peri  <=0;
			//cwso  <=0;
			//ccwso <=0;
		    //peso  <=0;
			polarity <=0;
        end
	else
	    polarity <= !polarity;
end

out_buffer ob2(.clk(clk), .reset(reset), .polarity(polarity), .inp_buffer_req( {req1[1], req0[1]} ), 
			.data_in0(in_buffer_out0), .data_in1(in_buffer_out1), .send_out(peso), .ready_out(pero), 
			.data_out(pedo), .inp_buffer_gnt(gnt2) );
			
out_buffer ob1(.clk(clk), .reset(reset), .polarity(polarity), .inp_buffer_req( {req2[1], req1[0]} ), 
			.data_in0(in_buffer_out1), .data_in1(in_buffer_out2), .send_out(ccwso), .ready_out(ccwro), 
			.data_out(ccwdo), .inp_buffer_gnt(gnt1) );
					
out_buffer ob0(.clk(clk), .reset(reset), .polarity(polarity), .inp_buffer_req( {req2[0], req0[0]} ), 
			.data_in0(in_buffer_out0), .data_in1(in_buffer_out2), .send_out(cwso), .ready_out(cwro), 
			.data_out(cwdo), .inp_buffer_gnt(gnt0) );


inp_buffer_PE ib2(.clk(clk), .reset(reset), .polarity(polarity), .send_in(pesi), .ready_in(peri), 
			.data_in(pedi), .data_out(in_buffer_out2), .out_buffer_gnt( {gnt1[1], gnt0[1]} ),.req(req2));

inp_buffer ib1(.clk(clk),.reset(reset),.polarity(polarity),.ready_in(ccwri),.send_in(ccwsi), 
               .data_in(ccwdi),.data_out(in_buffer_out1),.out_buffer_gnt({gnt2[1], gnt1[0]}),.req(req1));

inp_buffer ib0(.clk(clk),.reset(reset),.polarity(polarity),.ready_in(cwri),.send_in(cwsi), 
               .data_in(cwdi),.data_out(in_buffer_out0),.out_buffer_gnt({gnt2[0], gnt0[0]}),.req(req0));

endmodule

			
module out_buffer(clk, reset, polarity, inp_buffer_req, data_in0, data_in1, send_out, ready_out, data_out, inp_buffer_gnt);
	input clk, reset, polarity, inp_buffer_req, data_in0, data_in1, ready_out;
	output data_out, inp_buffer_gnt, send_out;
	wire [1:0] inp_buffer_req;
	wire [63:0] data_in0, data_in1;
	reg [63:0] data_out;
	reg [1:0] inp_buffer_gnt;	
    
	reg [63:0]even_buffer, odd_buffer;
	reg even_buffer_f, odd_buffer_f;
	reg even_pr, odd_pr;
	reg send_out;
	parameter EVEN = 1'b0;
	parameter ODD = 1'b1;
	
	always @(*)
		begin
			if (polarity == EVEN)
				begin
					send_out = odd_buffer_f & ready_out;
					data_out = odd_buffer;
				end
			else //  else if polarity == ODD
				begin
					send_out = even_buffer_f & ready_out;
					data_out = even_buffer;
				end
				
			if (inp_buffer_req == 2'b00)
				begin
					 inp_buffer_gnt = 2'b00;
				end
			else if (inp_buffer_req == 2'b01)
				begin
					if( ((polarity == EVEN) && (!even_buffer_f)) | ((polarity == ODD) && (!odd_buffer_f)) )
						inp_buffer_gnt = 2'b01;
					else
						inp_buffer_gnt = 2'b00;
				end
			else if (inp_buffer_req == 2'b10)
				begin
					if( ((polarity == EVEN) && (!even_buffer_f)) | ((polarity == ODD) && (!odd_buffer_f)) )
						inp_buffer_gnt = 2'b10;
					else
						inp_buffer_gnt = 2'b00;
				end
			else if (inp_buffer_req == 2'b11)
				begin
					if( (polarity == EVEN) && (!even_buffer_f)) 
						begin
							if(even_pr == 1'b0)
								inp_buffer_gnt = 2'b01;
							else
								inp_buffer_gnt = 2'b10;
						end 
					else if((polarity == ODD) && (!odd_buffer_f)) 
							begin
								if(odd_pr == 1'b0)
									inp_buffer_gnt = 2'b01;
								else
									inp_buffer_gnt = 2'b10;
							end 
					else 
						begin
							inp_buffer_gnt = 2'b00;
						end
				end
			else
				begin
					inp_buffer_gnt = 2'b00;
		        end
		end
	
	always @(posedge clk)
		begin
			if (reset) 
				begin
					even_buffer <= 0;
					even_buffer_f <= 0;
					odd_buffer <= 0;
					odd_pr <= 0;
					odd_buffer_f <= 0;
					even_pr <= 0;
				end
			else 
				begin
					if(polarity == EVEN)
						begin
							if (inp_buffer_gnt[0]==1)
								begin
									even_buffer_f <= 1;
									even_buffer <= data_in0;
									
								end
							else if (inp_buffer_gnt[1]==1)
								begin
								    even_buffer_f <= 1;
									even_buffer <= data_in1;
								end

							
							if (((inp_buffer_req[1]==1) && (inp_buffer_req[0]==1)) && ((inp_buffer_gnt[1]==1)||(inp_buffer_gnt[0]==1)))
								even_pr <= ~even_pr;
								
							if(send_out==1) 
								begin
								    odd_buffer <= 0;
									odd_buffer_f <= 0;
								end
					    end
					else  //else if polarity == ODD
						begin
							if (inp_buffer_gnt[0]==1)
								begin
								    odd_buffer_f <= 1;
									odd_buffer <= data_in0;
								end
							else if (inp_buffer_gnt[1]==1)
								begin
								    odd_buffer_f <= 1;
									odd_buffer <= data_in1;
								end
							
							if (((inp_buffer_req[1]==1)&&(inp_buffer_req[0]==1)) && ((inp_buffer_gnt[1]==1)||(inp_buffer_gnt[1]==0)))
								begin
									odd_pr <= ~odd_pr;
								end
							
							if(send_out==1)
								begin
									even_buffer <= 0;
									even_buffer_f <= 0;
								end
							
						end
					
       		    end
        end
endmodule

module inp_buffer (clk, reset, polarity, send_in, ready_in, data_in, data_out, out_buffer_gnt, req);
    parameter PE = 0;
	input clk, reset, polarity;
	input send_in;
	output ready_in;
	input data_in;
	output data_out;
	output req;
	input out_buffer_gnt;
    
	wire [1:0] out_buffer_gnt;
	reg [1:0]req;
	reg [63:0] data_out;
	wire [63:0]data_in;
	reg ready_in;
	reg [7:0] updated_HC;
	
	reg [63:0] even_buffer, odd_buffer;
	reg even_buffer_f, odd_buffer_f;
	
	parameter EVEN = 1'b0;
	parameter ODD = 1'b1;
	parameter CW = 1'b0;
	parameter CCW = 1'b1;
	
	always @(*)
		begin
			if(polarity == EVEN) 
				begin
					ready_in = (!reset)&&(!odd_buffer_f);
					updated_HC = even_buffer[`HC]-1;
					
					if(PE==1)
						begin
							data_out = {even_buffer[`BEFORE_HC], updated_HC, even_buffer[`AFTER_HC]};
							if (even_buffer[`DIR]==CW)
								begin
									req = {1'b0, even_buffer_f};
								end
							else
								begin
									req = {even_buffer_f, 1'b0};
								end
						end
					else if (even_buffer[`HC]==0)
						begin
							data_out = even_buffer;
							req = {even_buffer_f, 1'b0};
						end
					else
						begin
							data_out = {even_buffer[`BEFORE_HC], updated_HC, even_buffer[`AFTER_HC]};
							req = {1'b0, even_buffer_f};   //by default assuming clockwise
						end
				end
			else //else if polarity== ODD
				begin
					ready_in = (!reset)&&(!even_buffer_f);
					updated_HC = odd_buffer[`HC] - 1;
					
					if (PE) 
						begin
							data_out = {odd_buffer[`BEFORE_HC], updated_HC , odd_buffer[`AFTER_HC]};
							if (odd_buffer[`DIR] == CW)
								begin
									req = {1'b0, odd_buffer_f};
								end
							else
								begin
									req = {odd_buffer_f,1'b0};
								end
						end
					else if (odd_buffer[`HC]==0)
						begin
							data_out = odd_buffer;
							req = {odd_buffer_f, 1'b0};
						end
					else 
						begin
							data_out = {odd_buffer[`BEFORE_HC], updated_HC, odd_buffer[`AFTER_HC]};
							req = {1'b0, odd_buffer_f};
						end
					
				end
		end
	
	always @(posedge clk)
		begin
			if (reset) 
				begin
					even_buffer <= 0;
					odd_buffer <= 0;
					even_buffer_f <= 0;
					odd_buffer_f <= 0;
				end
			
			else 
				begin
					if(polarity == EVEN)
						begin
							if (send_in)
								begin
									odd_buffer_f <= 1;
									odd_buffer <= data_in;
								end
						   
							if((out_buffer_gnt[0]==1) || (out_buffer_gnt[1]==1)) 
								begin
									even_buffer <= 0;
									even_buffer_f <= 0;
									
									
								end
						end
					else 
						begin
							if (send_in)
								begin
									even_buffer_f <=1;
									even_buffer <= data_in;
								end	
							if(out_buffer_gnt[0]==1 || out_buffer_gnt[1]==1) 
								begin
									odd_buffer <= 0;
									odd_buffer_f <= 0;
								end
		                end		
				end
		end
endmodule

module inp_buffer_PE (clk, reset, polarity, send_in, ready_in, data_in, data_out, out_buffer_gnt, req);
    parameter PE = 1;
	input clk, reset, polarity;
	input send_in;
	output ready_in;
	input data_in;
	output data_out;
	output req;
	input out_buffer_gnt;
    
	wire [1:0] out_buffer_gnt;
	reg [1:0]req;
	reg [63:0] data_out;
	wire [63:0]data_in;
	reg ready_in;
	reg [7:0] updated_HC;
	
	reg [63:0] even_buffer, odd_buffer;
	reg even_buffer_f, odd_buffer_f;
	
	parameter EVEN = 1'b0;
	parameter ODD = 1'b1;
	parameter CW = 1'b0;
	parameter CCW = 1'b1;
	
	always @(*)
		begin
			if(polarity == EVEN) 
				begin
					ready_in = (!reset)&&(!odd_buffer_f);
					updated_HC = even_buffer[`HC]-1;
					
					if(PE==1)
						begin
							data_out = {even_buffer[`BEFORE_HC], updated_HC, even_buffer[`AFTER_HC]};
							if (even_buffer[`DIR]==CW)
								begin
									req = {1'b0, even_buffer_f};
								end
							else
								begin
									req = {even_buffer_f, 1'b0};
								end
						end
					else if (even_buffer[`HC]==0)
						begin
							data_out = even_buffer;
							req = {even_buffer_f, 1'b0};
						end
					else
						begin
							data_out = {even_buffer[`BEFORE_HC], updated_HC, even_buffer[`AFTER_HC]};
							req = {1'b0, even_buffer_f};   //by default assuming clockwise
						end
				end
			else //else if polarity== ODD
				begin
					ready_in = (!reset)&&(!even_buffer_f);
					updated_HC = odd_buffer[`HC] - 1;
					
					if (PE) 
						begin
							data_out = {odd_buffer[`BEFORE_HC], updated_HC , odd_buffer[`AFTER_HC]};
							if (odd_buffer[`DIR] == CW)
								begin
									req = {1'b0, odd_buffer_f};
								end
							else
								begin
									req = {odd_buffer_f,1'b0};
								end
						end
					else if (odd_buffer[`HC]==0)
						begin
							data_out = odd_buffer;
							req = {odd_buffer_f, 1'b0};
						end
					else 
						begin
							data_out = {odd_buffer[`BEFORE_HC], updated_HC, odd_buffer[`AFTER_HC]};
							req = {1'b0, odd_buffer_f};
						end
					
				end
		end
	
	always @(posedge clk)
		begin
			if (reset) 
				begin
					even_buffer <= 0;
					odd_buffer <= 0;
					even_buffer_f <= 0;
					odd_buffer_f <= 0;
				end
			
			else 
				begin
					if(polarity == EVEN)
						begin
							if (send_in)
								begin
									odd_buffer_f <= 1;
									odd_buffer <= data_in;
								end
						   
							if((out_buffer_gnt[0]==1) || (out_buffer_gnt[1]==1)) 
								begin
									even_buffer <= 0;
									even_buffer_f <= 0;
									
									
								end
						end
					else 
						begin
							if (send_in)
								begin
									even_buffer_f <=1;
									even_buffer <= data_in;
								end	
							if(out_buffer_gnt[0]==1 || out_buffer_gnt[1]==1) 
								begin
									odd_buffer <= 0;
									odd_buffer_f <= 0;
								end
		                end		
				end
		end
endmodule



/////////////////////////////////////////////////////////////////////////////////////////////////////////ring/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////ring/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////ring/////////////////////////////////////////////////////////////////////////////////////

//`include "gold_router.v"
module gold_ring(clk, reset, node0_pesi, node0_peri, node0_pedi, node0_peso, node0_pero, node0_pedo,
              node1_pesi, node1_peri, node1_pedi, node1_peso, node1_pero, node1_pedo,
			  node2_pesi, node2_peri, node2_pedi, node2_peso, node2_pero, node2_pedo,
			  node3_pesi, node3_peri, node3_pedi, node3_peso, node3_pero, node3_pedo,
			  node0_polarity, node1_polarity, node2_polarity, node3_polarity);
			  
output node0_peri, node0_peso, node0_pedo, node1_peri, node1_peso, node1_pedo, node2_peri, node2_peso, node2_pedo, node3_peri, node3_peso, node3_pedo;
input node0_pesi, node0_pedi, node0_pero, node1_pesi, node1_pedi, node1_pero, node2_pesi, node2_pedi, node2_pero, node3_pesi, node3_pedi, node3_pero, clk, reset;
output node0_polarity, node1_polarity, node2_polarity, node3_polarity;


wire [3:0] cws, cwr, ccws, ccwr;
wire [63:0] cwd [0:3];
wire [63:0] ccwd [0:3];

wire [63:0] node0_pedi, node1_pedi, node2_pedi, node3_pedi;
wire [63:0] node0_pedo, node1_pedo, node2_pedo, node3_pedo;


	gold_router node3(.clk(clk), .reset(reset), .polarity(node3_polarity),
	.cwsi(cws[2]), .cwri(cwr[2]), .cwdi(cwd[2]), 
	.ccwsi(ccws[3]), .ccwri(ccwr[3]), .ccwdi(ccwd[3]),
	.pesi(node3_pesi),.peri(node3_peri), .pedi(node3_pedi), 
	.cwso(cws[3]), .cwro(cwr[3]),  .cwdo(cwd[3]), 
	.ccwso(ccws[2]), .ccwro(ccwr[2]),.ccwdo(ccwd[2]), 
	.peso(node3_peso), .pero(node3_pero), .pedo(node3_pedo));
		
	gold_router node2(.clk(clk), .reset(reset), .polarity(node2_polarity),
	.cwsi(cws[1]), .cwri(cwr[1]), .cwdi(cwd[1]), 
	.ccwsi(ccws[2]), .ccwri(ccwr[2]), .ccwdi(ccwd[2]),
	.pesi(node2_pesi),.peri(node2_peri), .pedi(node2_pedi), 
	.cwso(cws[2]), .cwro(cwr[2]),  .cwdo(cwd[2]), 
	.ccwso(ccws[1]), .ccwro(ccwr[1]),.ccwdo(ccwd[1]), 
	.peso(node2_peso), .pero(node2_pero), .pedo(node2_pedo));

	gold_router node1(.clk(clk), .reset(reset), .polarity(node1_polarity),
	.cwsi(cws[0]), .cwri(cwr[0]), .cwdi(cwd[0]), 
	.ccwsi(ccws[1]), .ccwri(ccwr[1]), .ccwdi(ccwd[1]),
	.pesi(node1_pesi),.peri(node1_peri), .pedi(node1_pedi), 
	.cwso(cws[1]), .cwro(cwr[1]),  .cwdo(cwd[1]), 
	.ccwso(ccws[0]), .ccwro(ccwr[0]),.ccwdo(ccwd[0]), 
	.peso(node1_peso), .pero(node1_pero), .pedo(node1_pedo));

	gold_router node0(.clk(clk), .reset(reset), .polarity(node0_polarity),
	.cwsi(cws[3]), .cwri(cwr[3]), .cwdi(cwd[3]), 
	.ccwsi(ccws[0]), .ccwri(ccwr[0]), .ccwdi(ccwd[0]),
	.pesi(node0_pesi),.peri(node0_peri), .pedi(node0_pedi), 
	.cwso(cws[0]), .cwro(cwr[0]),  .cwdo(cwd[0]), 
	.ccwso(ccws[3]), .ccwro(ccwr[3]),.ccwdo(ccwd[3]), 
	.peso(node0_peso), .pero(node0_pero), .pedo(node0_pedo));

endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////ALU//////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////ALU//////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////ALU//////////////////////////////////////////////////////////////////////

//`include "DW02_mult_2_stage.v"
//N - Nibble 
//B-Byte 
//W - Word
//DW - DoubleWord

`define WW_B 0
`define WW_H 1
`define WW_W 2
`define WW_D 3

`define N0 	0:3
`define N1 	4:7
`define N2 	8:11
`define N3 	12:15
`define N4 	16:19
`define N5 	20:23
`define N6 	24:27
`define N7 	28:31
`define N8 	32:35
`define N9 	36:39
`define N10 	40:43
`define N11 	44:47
`define N12 	48:51
`define N13 	52:55
`define N14 	56:59
`define N15 	60:63

`define B0 0:7
`define B1 8:15
`define B2 16:23
`define B3 24:31
`define B4 32:39
`define B5 40:47
`define B6 48:55
`define B7 56:63

`define HW0 0:15
`define HW1 16:31
`define HW2 32:47
`define HW3 48:63

`define W0 0:31
`define W1 32:63

`define DW 0:63

//module alu (clk, oprA, oprB, shift_amount, op, ww, result); //mult32_result);
module alu (oprA, oprB, shift_amount, op, ww, result); //mult32_result);
	
	//input clk;
	input [0:63] oprA, oprB;
	input [0:4] shift_amount;
	input [0:5] op;
	input [0:1] ww;
	output reg [0:63] result;
	//output reg [0:63] mult32_result;
	
	parameter A32_width = 32;
	parameter B32_width = 32;
	
	//reg [0:A32_width-1] mult32_A; 
	//reg [0:B32_width-1] mult32_B;
	
	//wire [0:A32_width+B32_width-1] mult32_res;

	
	//parameter TC_ZERO = 1'b0;
	
	// instantiating a two-stage pipelined multiplier from Synopsis DesignWare library
	//DW02_mult_2_stage  ALU_MUL32(.A(mult32_A), .B(mult32_B), .TC(TC_ZERO), .CLK(clk), .PRODUCT(mult32_res));
	
	always @(*)
	begin
		//mult32_A = 0;
		//mult32_B = 0;
		//mult32_result = mult32_res;
		
		case (op)
			
			0:     // VAND
				begin
					result = oprA & oprB;
				end
			
			1:     // VOR
				begin
					result = oprA | oprB;
				end
			
			2:      // VXOR
				begin
					result = oprA ^ oprB;
				end
			
			3:      // VNOT
				begin
					result = ~oprA;
				end
			
			4:      // VMOV
				begin
					result = oprA;
				end
			
			5:      // VADD
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] + oprB[`B0];
								result[`B1] 	= oprA[`B1] + oprB[`B1];
								result[`B2] 	= oprA[`B2] + oprB[`B2];
								result[`B3] 	= oprA[`B3] + oprB[`B3];
								result[`B4] 	= oprA[`B4] + oprB[`B4];
								result[`B5] 	= oprA[`B5] + oprB[`B5];
								result[`B6] 	= oprA[`B6] + oprB[`B6];
								result[`B7] 	= oprA[`B7] + oprB[`B7];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] + oprB[`HW0];
								result[`HW1] 	= oprA[`HW1] + oprB[`HW1];
								result[`HW2] 	= oprA[`HW2] + oprB[`HW2];
								result[`HW3] 	= oprA[`HW3] + oprB[`HW3];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] + oprB[`W0];
								result[`W1] 	= oprA[`W1] + oprB[`W1];
							end
						`WW_D: 
							begin
								result = oprA + oprB;
							end
						default: result = 0;
					endcase 
				end
			
			6:     // VSUB
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] - oprB[`B0];
								result[`B1] 	= oprA[`B1] - oprB[`B1];
								result[`B2] 	= oprA[`B2] - oprB[`B2];
								result[`B3] 	= oprA[`B3] - oprB[`B3];
								result[`B4] 	= oprA[`B4] - oprB[`B4];
								result[`B5] 	= oprA[`B5] - oprB[`B5];
								result[`B6] 	= oprA[`B6] - oprB[`B6];
								result[`B7] 	= oprA[`B7] - oprB[`B7];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] - oprB[`HW0];
								result[`HW1] 	= oprA[`HW1] - oprB[`HW1];
								result[`HW2] 	= oprA[`HW2] - oprB[`HW2];
								result[`HW3] 	= oprA[`HW3] - oprB[`HW3];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] - oprB[`W0];
								result[`W1] 	= oprA[`W1] - oprB[`W1];
							end
						`WW_D: 
							begin
								result = oprA - oprB;
							end
						default: result = 0;
					endcase 
				end
			
			7:      // VMULEU
				begin
					case (ww)
						`WW_B: 
							begin
								result[`HW0] 	= oprA[`B0] * oprB[`B0];
								result[`HW1] 	= oprA[`B2] * oprB[`B2];
								result[`HW2] 	= oprA[`B4] * oprB[`B4];
								result[`HW3] 	= oprA[`B6] * oprB[`B6];
							end
						`WW_H: 
							begin
								result[`W0] 	= oprA[`HW0] * oprB[`HW0];
								result[`W1] 	= oprA[`HW2] * oprB[`HW2];
							end
						`WW_W: 
							begin
								//mult32_A = oprA[`W0];
								//mult32_B = oprB[`W0];
								result[`DW] = oprA[`W0] * oprB[`W0];
								//result = 0;
							end
						default: result = 0;
					endcase 
				end
			
			8:      // VMULOU
				begin
					case (ww)
						`WW_B: 
							begin
								result[`HW0] 	= oprA[`B1] * oprB[`B1];
								result[`HW1] 	= oprA[`B3] * oprB[`B3];
								result[`HW2] 	= oprA[`B5] * oprB[`B5];
								result[`HW3] 	= oprA[`B7] * oprB[`B7];
							end
						`WW_H: 
							begin
								result[`W0] 	= oprA[`HW1] * oprB[`HW1];
								result[`W1] 	= oprA[`HW3] * oprB[`HW3];
							end
						`WW_W: 
							begin
								result[`DW] 	= oprA[`W1] * oprB[`W1];
								//mult32_A = oprA[`W1];
								//mult32_B = oprB[`W1];
								//result = 0;
							end
						default: result = 0;
					endcase 
				end
			
			9:         // VRTTH
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= {oprA[`N1], oprA[`N0]};
								result[`B1] 	= {oprA[`N3], oprA[`N2]};
								result[`B2] 	= {oprA[`N5], oprA[`N4]};
								result[`B3] 	= {oprA[`N7], oprA[`N6]};
								result[`B4] 	= {oprA[`N9], oprA[`N8]};
								result[`B5] 	= {oprA[`N11], oprA[`N10]};
								result[`B6] 	= {oprA[`N13], oprA[`N12]};
								result[`B7] 	= {oprA[`N15], oprA[`N14]};
							end
						`WW_H: 
							begin
								result[`HW0] 	= {oprA[`B1], oprA[`B0]};
								result[`HW1] 	= {oprA[`B3], oprA[`B2]};
								result[`HW2] 	= {oprA[`B5], oprA[`B4]};
								result[`HW3] 	= {oprA[`B7], oprA[`B6]};
							end
						`WW_W: 
							begin
								result[`W0] 	= {oprA[`HW1], oprA[`HW0]};
								result[`W1] 	= {oprA[`HW3], oprA[`HW2]};
							end
						`WW_D:
							begin
								result = {oprA[`W1], oprA[`W0]};
							end 
						default: result = 0;
					endcase
				end
			
			10:        // VSLL
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] << oprB[5:7];
								result[`B1] 	= oprA[`B1] << oprB[13:15];
								result[`B2] 	= oprA[`B2] << oprB[21:23];
								result[`B3] 	= oprA[`B3] << oprB[29:31];
								result[`B4] 	= oprA[`B4] << oprB[37:39];
								result[`B5] 	= oprA[`B5] << oprB[45:47];
								result[`B6] 	= oprA[`B6] << oprB[53:55];
								result[`B7] 	= oprA[`B7] << oprB[61:63];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] << oprB[12:15];
								result[`HW1] 	= oprA[`HW1] << oprB[28:31];
								result[`HW2] 	= oprA[`HW2] << oprB[44:47];
								result[`HW3] 	= oprA[`HW3] << oprB[60:63];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] << oprB[27:31];
								result[`W1] 	= oprA[`W1] << oprB[59:63];
							end
						`WW_D:
							begin
								result = oprA << oprB[58:63];
							end 
						default: result = 0;
					endcase
				end
			
			11:    // VSLLI
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] << shift_amount[2:4];
								result[`B1] 	= oprA[`B1] << shift_amount[2:4];
								result[`B2] 	= oprA[`B2] << shift_amount[2:4];
								result[`B3] 	= oprA[`B3] << shift_amount[2:4];
								result[`B4] 	= oprA[`B4] << shift_amount[2:4];
								result[`B5] 	= oprA[`B5] << shift_amount[2:4];
								result[`B6] 	= oprA[`B6] << shift_amount[2:4];
								result[`B7] 	= oprA[`B7] << shift_amount[2:4];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] << shift_amount[1:4];
								result[`HW1] 	= oprA[`HW1] << shift_amount[1:4];
								result[`HW2] 	= oprA[`HW2] << shift_amount[1:4];
								result[`HW3] 	= oprA[`HW3] << shift_amount[1:4];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] << shift_amount[0:4];
								result[`W1] 	= oprA[`W1] << shift_amount[0:4];
							end
						`WW_D:
							begin
								result = oprA << shift_amount[0:4];
							end 
						default: result = 0;
					endcase
				end
			
			12:         // VSRL
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] >> oprB[5:7];
								result[`B1] 	= oprA[`B1] >> oprB[13:15];
								result[`B2] 	= oprA[`B2] >> oprB[21:23];
								result[`B3] 	= oprA[`B3] >> oprB[29:31];
								result[`B4] 	= oprA[`B4] >> oprB[37:39];
								result[`B5] 	= oprA[`B5] >> oprB[45:47];
								result[`B6] 	= oprA[`B6] >> oprB[53:55];
								result[`B7] 	= oprA[`B7] >> oprB[61:63];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] >> oprB[12:15];
								result[`HW1] 	= oprA[`HW1] >> oprB[28:31];
								result[`HW2] 	= oprA[`HW2] >> oprB[44:47];
								result[`HW3] 	= oprA[`HW3] >> oprB[60:63];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] >> oprB[27:31];
								result[`W1] 	= oprA[`W1] >> oprB[59:63];
							end
						`WW_D:
							begin
								result = oprA >> oprB[58:63];
							end 
						default: result = 0;
					endcase
				end
			
			13:        // VSRLI
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= oprA[`B0] >> shift_amount[2:4];
								result[`B1] 	= oprA[`B1] >> shift_amount[2:4];
								result[`B2] 	= oprA[`B2] >> shift_amount[2:4];
								result[`B3] 	= oprA[`B3] >> shift_amount[2:4];
								result[`B4] 	= oprA[`B4] >> shift_amount[2:4];
								result[`B5] 	= oprA[`B5] >> shift_amount[2:4];
								result[`B6] 	= oprA[`B6] >> shift_amount[2:4];
								result[`B7] 	= oprA[`B7] >> shift_amount[2:4];
							end
						`WW_H: 
							begin
								result[`HW0] 	= oprA[`HW0] >> shift_amount[1:4];
								result[`HW1] 	= oprA[`HW1] >> shift_amount[1:4];
								result[`HW2] 	= oprA[`HW2] >> shift_amount[1:4];
								result[`HW3] 	= oprA[`HW3] >> shift_amount[1:4];
							end
						`WW_W: 
							begin
								result[`W0] 	= oprA[`W0] >> shift_amount[0:4];
								result[`W1] 	= oprA[`W1] >> shift_amount[0:4];
							end
						`WW_D:
							begin
								result = oprA >> shift_amount[0:4];
							end 
						default: result = 0;
					endcase
				end
			
			14:           // VSRA
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= $signed(oprA[`B0]) >>> oprB[5:7];
								result[`B1] 	= $signed(oprA[`B1]) >>> oprB[13:15];
								result[`B2] 	= $signed(oprA[`B2]) >>> oprB[21:23];
								result[`B3] 	= $signed(oprA[`B3]) >>> oprB[29:31];
								result[`B4] 	= $signed(oprA[`B4]) >>> oprB[37:39];
								result[`B5] 	= $signed(oprA[`B5]) >>> oprB[45:47];
								result[`B6] 	= $signed(oprA[`B6]) >>> oprB[53:55];
								result[`B7] 	= $signed(oprA[`B7]) >>> oprB[61:63];
							end
						`WW_H: 
							begin
								result[`HW0] 	= $signed(oprA[`HW0]) >>> oprB[12:15];
								result[`HW1] 	= $signed(oprA[`HW1]) >>> oprB[28:31];
								result[`HW2] 	= $signed(oprA[`HW2]) >>> oprB[44:47];
								result[`HW3] 	= $signed(oprA[`HW3]) >>> oprB[60:63];
							end
						`WW_W: 
							begin
								result[`W0] 	= $signed(oprA[`W0]) >>> oprB[27:31];
								result[`W1] 	= $signed(oprA[`W1]) >>> oprB[59:63];
							end
						`WW_D:
							begin
								result = $signed(oprA) >>> oprB[58:63];
							end 
						default: result = 0;
					endcase
				end
			
			15:            // VSRAI
				begin
					case (ww)
						`WW_B: 
							begin
								result[`B0] 	= $signed(oprA[`B0]) >>> shift_amount[2:4];
								result[`B1] 	= $signed(oprA[`B1]) >>> shift_amount[2:4];
								result[`B2] 	= $signed(oprA[`B2]) >>> shift_amount[2:4];
								result[`B3] 	= $signed(oprA[`B3]) >>> shift_amount[2:4];
								result[`B4] 	= $signed(oprA[`B4]) >>> shift_amount[2:4];
								result[`B5] 	= $signed(oprA[`B5]) >>> shift_amount[2:4];
								result[`B6] 	= $signed(oprA[`B6]) >>> shift_amount[2:4];
								result[`B7] 	= $signed(oprA[`B7]) >>> shift_amount[2:4];
							end
						`WW_H: 
							begin
								result[`HW0] 	= $signed(oprA[`HW0]) >>> shift_amount[1:4];
								result[`HW1] 	= $signed(oprA[`HW1]) >>> shift_amount[1:4];
								result[`HW2] 	= $signed(oprA[`HW2]) >>> shift_amount[1:4];
								result[`HW3] 	= $signed(oprA[`HW3]) >>> shift_amount[1:4];
							end
						`WW_W: 
							begin
								result[`W0] 	= $signed(oprA[`W0]) >>> shift_amount[0:4];
								result[`W1] 	= $signed(oprA[`W1]) >>> shift_amount[0:4];
							end
						`WW_D:
							begin
								result = $signed(oprA) >>> shift_amount[0:4];
							end 
						default: result = 0;
					endcase
				end
			default: result = 0;
		endcase
	end 

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////CRC32//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC32//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC32//////////////////////////////////////////////////////////////////////////////////////
module crc32(
  input [0:63] data_in,
  input [0:31] CRC_packet,
  input verCRCflag,
  output [0:63] crc_out,
  input rst,
  input clk);
  
  wire [0:31] pad = 32'b0; 
  reg [0:31] lfsr_q,lfsr_c;

  assign crc_out[0:63] = {pad,lfsr_q};

  always @(*) begin
    lfsr_c[31-0] = data_in[63-0] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-12] ^ data_in[63-16] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-1] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-2] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-44] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-3] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-45] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60];
    lfsr_c[31-5] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-4] = data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-15] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-63];
    lfsr_c[31-6] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-14] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-25] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-7] = data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60];
    lfsr_c[31-8] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-17] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-63];
    lfsr_c[31-9] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-18] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[31-10] =data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-19] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-11] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-20] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-12] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-13] =data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-22] ^ data_in[63-25] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-14] =data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-23] ^ data_in[63-26] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-15] =data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-16] =data_in[63-0] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-8] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-51] ^ data_in[63-56] ^ data_in[63-57];
    lfsr_c[31-17] =data_in[63-1] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-57] ^ data_in[63-58];
    lfsr_c[31-18] =data_in[63-2] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-46] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-19] =data_in[63-3] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-35] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-59] ^ data_in[63-60];
    lfsr_c[31-20] =data_in[63-4] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-36] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[31-21] =data_in[63-5] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-22] =data_in[63-0] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-23] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-24] =data_in[63-1] ^ data_in[63-2] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-25] =data_in[63-2] ^ data_in[63-3] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-26] =data_in[63-0] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-10] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-27] =data_in[63-1] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-11] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-28] =data_in[63-2] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-8] ^ data_in[63-12] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-29] =data_in[63-3] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-30] =data_in[63-4] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-48] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-31] =data_in[63-5] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
  end // always

  always @(posedge clk, posedge rst)
  begin
    if(rst) 
	begin
      lfsr_q <= {32{1'b1}};
    end
    
	else 
	begin
	  if(verCRCflag)			// if verCRCflag =1 : verifyCRC instruction, else calculate CRC flag
	  begin
		if(lfsr_c [0:31] == CRC_packet[0:31])
			lfsr_q <= 32'd1;		// if output is 1, then pass
		else
			lfsr_q <= 32'd3;		// if output is 3, then fail
	  end
	  
	  else
		lfsr_q <= lfsr_c;
    end
  end // always
endmodule // crc

///////////////////////////////////////////////////////////////////////////////////////////////////CRC32_PCIe//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC32_PCIe//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC32_PCIe//////////////////////////////////////////////////////////////////////////////////////
module crc32PCIe(
  input [0:63] data_in,
  input [0:31] CRC_packet,
  input verCRCflag,
  output [0:63] crc_out,
  input rst,
  input clk);
  
  wire [0:31] pad = 32'b0; 
  reg [0:31] lfsr_q,lfsr_c;

  assign crc_out[0:63] = {pad,lfsr_q};

  always @(*) begin
    lfsr_c[31-0] = data_in[63-0] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-12] ^ data_in[63-16] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-1] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-2] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-44] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-3] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-45] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60];
    lfsr_c[31-5] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-4] = data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-15] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-63];
    lfsr_c[31-6] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-14] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-25] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-7] = data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60];
    lfsr_c[31-8] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-17] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-63];
    lfsr_c[31-9] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-18] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[31-10] =data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-19] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-11] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-20] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-12] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-13] =data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-22] ^ data_in[63-25] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-14] =data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-23] ^ data_in[63-26] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-15] =data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-24] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-16] =data_in[63-0] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-8] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-51] ^ data_in[63-56] ^ data_in[63-57];
    lfsr_c[31-17] =data_in[63-1] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-57] ^ data_in[63-58];
    lfsr_c[31-18] =data_in[63-2] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-46] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-58] ^ data_in[63-59];
    lfsr_c[31-19] =data_in[63-3] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-35] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-59] ^ data_in[63-60];
    lfsr_c[31-20] =data_in[63-4] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-12] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-36] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[31-21] =data_in[63-5] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-13] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-22] =data_in[63-0] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-23] =data_in[63-0] ^ data_in[63-1] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
    lfsr_c[31-24] =data_in[63-1] ^ data_in[63-2] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-25] =data_in[63-2] ^ data_in[63-3] ^ data_in[63-8] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-26] =data_in[63-0] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-10] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[31-27] =data_in[63-1] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-7] ^ data_in[63-11] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-28] =data_in[63-2] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-8] ^ data_in[63-12] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-29] =data_in[63-3] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-9] ^ data_in[63-13] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-47] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-60] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[31-30] =data_in[63-4] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-48] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-61] ^ data_in[63-63];
    lfsr_c[31-31] =data_in[63-5] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-36] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-57] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-62];
  end // always

   always @(posedge clk, posedge rst)
  begin
    if(rst) 
	begin
      lfsr_q <= {32{1'b1}};
    end
    
	else 
	begin
	  if(verCRCflag)			// if verCRCflag =1 : verifyCRC instruction, else calculate CRC flag
	  begin
		if(lfsr_c [0:31] == CRC_packet[0:31])
			lfsr_q <= 32'd1;		// if output is 1, then pass
		else
			lfsr_q <= 32'd3;		// if output is 3, then fail
	  end
	  
	  else
		lfsr_q <= lfsr_c;
    end
  end // always
endmodule // crc

///////////////////////////////////////////////////////////////////////////////////////////////////CRC16//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC16//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC16//////////////////////////////////////////////////////////////////////////////////////
module crc16(
  input [0:63] data_in,
  input [0:31] CRC_packet,
  input verCRCflag,
  output [0:63] crc_out,
  input rst,
  input clk);
  
  wire [0:47] pad = 48'b0; 
  reg [0:15] lfsr_q,lfsr_c;

  assign crc_out[0:63] = {pad,lfsr_q};

  always @(*) begin
    lfsr_c[15-0] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-43] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[15-1] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-27] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-55] ^ data_in[63-56] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[15-2] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-14] ^ data_in[63-16] ^ data_in[63-28] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-56] ^ data_in[63-57] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[15-3] = data_in[63-1] ^ data_in[63-2] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-57] ^ data_in[63-58] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[15-4] = data_in[63-2] ^ data_in[63-3] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-58] ^ data_in[63-59] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[15-5] = data_in[63-3] ^ data_in[63-4] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-45] ^ data_in[63-49] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-63];
    lfsr_c[15-6] = data_in[63-4] ^ data_in[63-5] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-46] ^ data_in[63-50] ^ data_in[63-60] ^ data_in[63-61];
    lfsr_c[15-7] = data_in[63-5] ^ data_in[63-6] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-47] ^ data_in[63-51] ^ data_in[63-61] ^ data_in[63-62];
    lfsr_c[15-8] = data_in[63-6] ^ data_in[63-7] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-48] ^ data_in[63-52] ^ data_in[63-62] ^ data_in[63-63];
    lfsr_c[15-9] = data_in[63-7] ^ data_in[63-8] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-49] ^ data_in[63-53] ^ data_in[63-63];
    lfsr_c[15-10] = data_in[63-8] ^ data_in[63-9] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-50] ^ data_in[63-54];
    lfsr_c[15-11] = data_in[63-9] ^ data_in[63-10] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-51] ^ data_in[63-55];
    lfsr_c[15-12] = data_in[63-10] ^ data_in[63-11] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-52] ^ data_in[63-56];
    lfsr_c[15-13] = data_in[63-11] ^ data_in[63-12] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-53] ^ data_in[63-57];
    lfsr_c[15-14] = data_in[63-12] ^ data_in[63-13] ^ data_in[63-26] ^ data_in[63-28] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-54] ^ data_in[63-58];
    lfsr_c[15-15] = data_in[63-0] ^ data_in[63-1] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-24] ^ data_in[63-25] ^ data_in[63-26] ^ data_in[63-29] ^ data_in[63-30] ^ data_in[63-31] ^ data_in[63-32] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-42] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-59] ^ data_in[63-60] ^ data_in[63-61] ^ data_in[63-62] ^ data_in[63-63];

  end // always

  
  always @(posedge clk) begin
    if(rst) 
	begin
      lfsr_q <= {16{1'b0}};
    end
	
	
    else 
	begin
      if(verCRCflag)			// if verCRCflag =1 : verifyCRC instruction, else calculate CRC flag
	  begin
		if(CRC_packet[16:31] == lfsr_c [0:15])
			lfsr_q <= 16'd1;		// if output is 1, then pass
		else
			lfsr_q <= 16'd3;		// if output is 3, then fail
	  end
	  
	  else
		lfsr_q <= lfsr_c;
    end
  end // always
endmodule // crc



///////////////////////////////////////////////////////////////////////////////////////////////////CRC5//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC5//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CRC5//////////////////////////////////////////////////////////////////////////////////////



module crc5(
  input [0:63] data_in,
  input [0:31] CRC_packet,
  input verCRCflag,
  output [0:63] crc_out,
  input rst,
  input clk);
  
  wire [0:58] pad = 59'b0; 
  reg [0:4] lfsr_q,lfsr_c;

  assign crc_out[0:63] = {pad,lfsr_q};

  always @(*) begin
    lfsr_c[4-0] = data_in[63-0] ^ data_in[63-3] ^ data_in[63-5] ^ data_in[63-6] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-26] ^ data_in[63-31] ^ data_in[63-34] ^ data_in[63-36] ^ data_in[63-37] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-57] ^ data_in[63-62];
    lfsr_c[4-1] = data_in[63-1] ^ data_in[63-4] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-13] ^ data_in[63-14] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-22] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-27] ^ data_in[63-32] ^ data_in[63-35] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-44] ^ data_in[63-45] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-53] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-58] ^ data_in[63-63];
    lfsr_c[4-2] = data_in[63-0] ^ data_in[63-2] ^ data_in[63-3] ^ data_in[63-6] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-14] ^ data_in[63-15] ^ data_in[63-17] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-28] ^ data_in[63-31] ^ data_in[63-33] ^ data_in[63-34] ^ data_in[63-37] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-45] ^ data_in[63-46] ^ data_in[63-48] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-59] ^ data_in[63-62];
    lfsr_c[4-3] = data_in[63-1] ^ data_in[63-3] ^ data_in[63-4] ^ data_in[63-7] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-15] ^ data_in[63-16] ^ data_in[63-18] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-22] ^ data_in[63-24] ^ data_in[63-29] ^ data_in[63-32] ^ data_in[63-34] ^ data_in[63-35] ^ data_in[63-38] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-46] ^ data_in[63-47] ^ data_in[63-49] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-53] ^ data_in[63-55] ^ data_in[63-60] ^ data_in[63-63];
    lfsr_c[4-4] = data_in[63-2] ^ data_in[63-4] ^ data_in[63-5] ^ data_in[63-8] ^ data_in[63-9] ^ data_in[63-10] ^ data_in[63-11] ^ data_in[63-12] ^ data_in[63-16] ^ data_in[63-17] ^ data_in[63-19] ^ data_in[63-20] ^ data_in[63-21] ^ data_in[63-23] ^ data_in[63-25] ^ data_in[63-30] ^ data_in[63-33] ^ data_in[63-35] ^ data_in[63-36] ^ data_in[63-39] ^ data_in[63-40] ^ data_in[63-41] ^ data_in[63-42] ^ data_in[63-43] ^ data_in[63-47] ^ data_in[63-48] ^ data_in[63-50] ^ data_in[63-51] ^ data_in[63-52] ^ data_in[63-54] ^ data_in[63-56] ^ data_in[63-61];

  end // always

  always @(posedge clk, posedge rst) begin
    if(rst) 
	begin
      lfsr_q <= {5{1'b0}};
    end
    else 
	begin
       if(verCRCflag)			// if verCRCflag =1 : verifyCRC instruction, else calculate CRC flag
	   begin
		if(lfsr_c [0:4] == CRC_packet[27:31])
			lfsr_q <= 5'd1;		// if output is 1, then pass
		else
			lfsr_q <= 5'd3;		// if output is 3, then fail
	  end
	  
	  else
		lfsr_q <= lfsr_c;
    end
  end // always
endmodule // crc

///////////////////////////////////////////////////////////////////////////////////////////////////CPU//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CPU//////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////CPU//////////////////////////////////////////////////////////////////////////////////////


`define LOAD_OPCODE 6'b100000
`define STORE_OPCODE 6'b100001
module gold_processor (clk, reset, pc, instruction, memAddr, memEn, memWrEn, dataIn, dataOut, addr, d_in, d_out, nicEn, nicEnWr, CRC_in, CRC_packet, verCRCflag, CRC_result);
	input         		clk;            // System Clock
	input         		reset;          // System Reset
	input  		[0:31] 	instruction;    // Instruction from Instruction Memory
	input  		[0:63] 	dataIn;         // Data from Data Memory
	output 		[0:31] 	pc;             // Program Counter
	output reg 	[0:63] 	dataOut;        // Write Data to Data Memory
	output reg 	[0:31] 	memAddr;        // Write Address for Data Memory
	output reg       	memEn;          // Data Memory Enable
	output reg       	memWrEn;        // Data Memory Write Enable
	output reg	[0:63]  CRC_in;			// input to CRC module
	output reg  [0:31]  CRC_packet;		//extracted CRC sent to CRC module for verification
	output reg 			verCRCflag;
	input 		[0:63]  CRC_result;		// result from the CRC module

	
	output reg	[0:1]	addr;			// NIC register select
	output reg 	[0:63]	d_in;			// NIC output buffer data 
	input 		[0:63]  d_out;			// NIC input buffer output
	output reg			nicEn;			// NIC enable signal 
	output reg			nicEnWr;		// NIC write enable signal 
	
	reg [0:31]	IF_instruction;
	reg [0:31] 	ID_instruction;
	reg [0:15]	ID_immediate;
	reg [0:4]	ID_regA, ID_regB, ID_regD;
	reg [0:5] 	ID_alu_func;
	reg 		ID_flush;
	wire [0:63]	ID_oprA, ID_oprB;
	reg [0:4]	ID_shift_amount;
	reg [0:4]	ID_rf_rd1_addr;
	reg [0:2]	ID_PPP;
	reg [0:1]	ID_WW;
	
	reg 		ID_rtype, ID_mem_ld, ID_mem_sd, ID_branch_bn, ID_branch_bz, ID_nop;
	reg 		ID_illegal, ID_illegal_PPP, ID_illegal_func, ID_illegal_opcode, ID_illegal_unary, ID_illegal_mul, ID_CRC_valid;
	reg 		ID_nic_type;  //nic related
	reg 		ID_nic_str;   //nic related
	reg			ID_branch;
	reg 		ID_store, ID_load, ID_reg_wr; //, ID_is_mul32;
	reg 		ID_CRC_load;
	reg 		ID_bnez, ID_bez;
	reg [0:63] 	EX_oprA, EX_oprB, EX_alu_A, EX_alu_B;
	reg [0:2] 	EX_PPP;
	reg [0:1] 	EX_WW;
	reg [0:4] 	EX_dest_reg, EX_regA, EX_regB;
	reg [0:4] 	EX_shift_amount;
	reg 		EX_reg_wr;
	reg 		EX_load;
	reg 		EX_CRC_load;
	reg 		EX_store;
	reg [0:15]  EX_immediate;
	reg [0:5] 	EX_alu_func;
	wire [0:63]	EX_alu_res;
	reg 		EX_nic_ld;
	reg 		EX_nic_type;	
	
	reg [0:63]	WB_alu_res;
	wire [0:63]	WB_CRC_res;
	
	
	reg [0:63] 	WB_data;
	reg [0:4] 	WB_dest_reg;
	reg [0:2] 	WB_PPP;
	reg [0:1] 	WB_WW;
	reg 		WB_reg_wr;
	reg 		WB_load;
	reg 		WB_CRC_load;
	reg 		WB_reg_write_load;
	reg 		WB_nic_load;
	reg [0:63]	WB_nic_ld_data;
	
	reg stall, last_stall, last_2_stall;
	reg store_dependency, branch_dependency;
	
	alu ALU(.oprA(EX_alu_A), .oprB(EX_alu_B), .op(EX_alu_func), .shift_amount(EX_shift_amount),.ww(EX_WW), 
			.result(EX_alu_res) );			
	 
	register_file reg_file(.clk(clk), .reset(reset), .write_en(WB_reg_write_load), .read1_addr(ID_rf_rd1_addr),
	.read2_addr(ID_regB), .write_addr(WB_dest_reg), .Din(WB_data),
	.Dout1(ID_oprA), .Dout2(ID_oprB), .PPP(WB_PPP));
	
	program_counter PC(.clk(clk), .reset(reset), .stall(stall), .pc_load(ID_branch), .data_in(ID_immediate), .data_out(pc));

	always@(posedge clk)
	begin
		if (reset) begin
			ID_instruction <= 32'hF0000000;	// VNOP
			ID_flush<= 0;
			EX_PPP <= 0;
			EX_WW <= 0;
			EX_oprA <= 0;
			EX_oprB <= 0;
			EX_dest_reg <= 0;
			EX_nic_ld <= 0;	
			EX_shift_amount<= 0;
			EX_alu_func <= 0;
			EX_load <= 0;
			EX_CRC_load <= 0;
			EX_store<= 0;
			EX_immediate<=0;
			EX_reg_wr <= 0;
			WB_PPP <= 0;
			WB_WW <= 0;
			WB_reg_wr <= 0;
			WB_dest_reg <= 0;
			WB_alu_res <= 0;
			WB_load <= 0;
			WB_CRC_load <= 0;
			WB_nic_load	<= 0;
			WB_nic_ld_data <= 0;
			last_stall <= 0;
			last_2_stall <= 0;
			EX_nic_type<=0;
		end 
		else begin
			last_2_stall <= last_stall;
			if (!stall) begin
				ID_instruction <= IF_instruction;
				ID_flush<= ID_branch;
				EX_PPP <= ID_PPP;
				EX_WW <= ID_WW;
				EX_oprA <= ID_oprA;
				EX_oprB <= ID_oprB;
				EX_load	<= ID_load;
				EX_CRC_load <= ID_CRC_load;
				EX_store <= ID_store;
				EX_immediate<= ID_immediate;
				EX_reg_wr <= ID_reg_wr & (!stall);
				EX_shift_amount	<= ID_shift_amount;
				EX_dest_reg <= ID_regD;
				EX_alu_func <= ID_alu_func;
				EX_regA	<= ID_regA;
				EX_regB	<= ID_regB;
			
				EX_nic_ld <= (ID_nic_type && ID_load);
				EX_nic_type<= ID_nic_type;
				last_stall <= 0;
			end
			else begin
				last_stall <= 1;
			end

			WB_PPP <= EX_PPP;
			WB_WW <= EX_WW;
			WB_load	<= EX_load; 
			WB_CRC_load <= EX_CRC_load;
			WB_nic_load	<= EX_nic_ld;  //nic related
			WB_nic_ld_data <= d_out;   //nic related
			WB_dest_reg	<= EX_dest_reg;
			WB_reg_wr <= EX_reg_wr;
			WB_alu_res <= EX_alu_res;

		end 
	end 

	always@(*)
	begin
		IF_instruction = instruction;
		ID_immediate = ID_instruction[16:31];
		ID_regD = ID_instruction[6:10];
		ID_regA = ID_instruction[11:15];
		ID_regB = ID_instruction[16:20];
		ID_shift_amount	= ID_instruction[16:20];
		ID_alu_func = ID_instruction[26:31];
		
		ID_rtype = (ID_instruction[0:5] == 6'b101010);
		ID_PPP 	= ID_rtype ? ID_instruction[21:23] : 3'd0;
		ID_WW = ID_rtype ? ID_instruction[24:25] : 2'b11;
		ID_mem_ld = (ID_instruction[0:5] == 6'b100000) && (ID_regA == 0);
		ID_mem_sd = (ID_instruction[0:5] == 6'b100001) && (ID_regA == 0);
		ID_branch_bz = (ID_instruction[0:5] == 6'b100010) && (ID_regA == 0);
		ID_branch_bn = (ID_instruction[0:5] == 6'b100011) && (ID_regA == 0);
		ID_nop = (ID_instruction == 32'hF0000000);
		
		ID_illegal_PPP = ID_rtype && ((ID_PPP > 3'b100));
		
		ID_illegal_func = ID_rtype && (ID_alu_func > 6'b010001);
		ID_illegal_unary = ID_rtype &&(ID_shift_amount != 0) && ((ID_alu_func == 6'b000011) || (ID_alu_func == 6'b000100) || (ID_alu_func == 6'b001001));
		ID_illegal_opcode=  !(ID_branch_bz || ID_rtype || ID_branch_bn || ID_mem_ld || ID_nop || ID_mem_sd); 
		//ID_illegal_mul = (ID_rtype && ID_instruction[26:29] == 4'b0010 && ID_WW == 2'b11) ? 1'b1 : 1'b0;
		ID_illegal_mul = (ID_rtype && ((ID_instruction[26:31] == 6'b000111)||(ID_instruction[26:31] == 6'b001000)) && ID_WW == 2'b11) ? 1'b1 : 1'b0;
		
		ID_illegal = (ID_illegal_PPP || ID_illegal_func || ID_illegal_opcode || ID_illegal_unary || ID_illegal_mul);
		ID_CRC_valid = (((ID_alu_func == 6'b010000) || (ID_alu_func == 6'b010001)) 	&& (ID_PPP == 3'b000) && (ID_WW == 2'b11));
		ID_reg_wr = (!ID_illegal && ID_rtype && !ID_flush) ? 1'b1 : 1'b0;	
		ID_load = (!ID_illegal && ID_mem_ld && !ID_flush) ? 1'b1 : 1'b0;
		ID_CRC_load = (ID_rtype && (ID_CRC_valid));
		ID_store = (!ID_illegal && ID_mem_sd && !ID_flush) ? 1'b1 : 1'b0;
		ID_bez = (!ID_illegal && ID_branch_bz && !ID_flush) ? 1'b1 : 1'b0;
		ID_bnez = (!ID_illegal && ID_branch_bn && !ID_flush) ? 1'b1 : 1'b0;		
		ID_rf_rd1_addr = (ID_reg_wr) ? ID_regA : ID_regD;
		ID_branch = (ID_oprA == 0 && ID_bez) || (ID_oprA != 0 && ID_bnez) ? 1'b1 : 1'b0;
		ID_nic_type	 = (ID_load || ID_store) && (ID_immediate[0:1] == 2'b11);    //NIC related or not 
		ID_nic_str	 = ID_store && (ID_immediate[0:1] == 2'b11);
		
		store_dependency =	(EX_dest_reg != 0) && (EX_dest_reg == ID_regD) &&(EX_reg_wr || EX_load) && (ID_store || ID_nic_str);
		//store_dependency =	(EX_dest_reg != 0) && (EX_dest_reg == ID_regD)&&(EX_reg_wr || EX_load) && (ID_store);
		branch_dependency = (EX_dest_reg != 0) && (EX_dest_reg == ID_regD) && (ID_bez || ID_bnez);
		
		if ( (store_dependency || branch_dependency) & (!last_stall) )
			stall = 1'b1;
		else
			stall = 1'b0;

		nicEn = ID_nic_type & (!stall) ;
		nicEnWr = ID_nic_str & (!stall);
		addr = ID_immediate[14:15];//nic
		d_in = ID_oprA;            //nic
		//memEn = (ID_load | ID_store) & (!ID_nic_type) & (!stall);
		memEn = (EX_load | EX_store) & (!EX_nic_type) & (!last_stall);
		//memWrEn = (ID_store) & (!ID_nic_type) & (!stall) ;
		memWrEn = (EX_store) & (!EX_nic_type) & (!last_stall) ;
		memAddr = {16'b0, EX_immediate};
		dataOut = EX_oprA;
		
		CRC_in = EX_oprA;
		CRC_packet[0:31] = EX_oprB[32:63];	//sending the CRC extracted from the packet to the CRC module for verification
		
		verCRCflag = ((EX_alu_func[0:5] == 6'b010001) &&(EX_CRC_load));
		
			
		
		 
		
		
		//mux
		if (WB_nic_load) 
			begin
				WB_data = WB_nic_ld_data;
			end 
		else if (WB_load) 
			begin
				WB_data = dataIn;
			end 
		else if(WB_CRC_load)
			begin
				WB_data = CRC_result;
			end
		else
			begin
				WB_data = WB_alu_res;
			end 
		WB_reg_write_load = (WB_nic_load | WB_reg_wr | WB_load) & (WB_dest_reg != 0) & (!last_2_stall) ;
		//WB_reg_write_load = (WB_reg_wr | WB_load) & (!last_2_stall) ;
		
		if ((EX_reg_wr && WB_reg_write_load && (WB_dest_reg == EX_regA))& !last_stall ) 
			begin
				case (WB_PPP)
					3'b000: // All bytes participate
						EX_alu_A = WB_data;
					3'b001: // Upper 32-bits participate
						EX_alu_A = {WB_data[0:31], EX_oprA[32:63]} ;
					3'b010: // Lower 32-bits participate
						EX_alu_A = {EX_oprA[0:31], WB_data[32:63]} ;
					3'b011: // Bytes with even index participate
						EX_alu_A = {WB_data[0:7],   EX_oprA[8:15], WB_data[16:23], EX_oprA[24:31],
									WB_data[32:39], EX_oprA[40:47], WB_data[48:55], EX_oprA[56:63]};
					3'b100: // Bytes with odd index participate
						EX_alu_A = {EX_oprA[0:7],   WB_data[8:15], EX_oprA[16:23], WB_data[24:31],
									EX_oprA[32:39], WB_data[40:47], EX_oprA[48:55], WB_data[56:63]};
					default: EX_alu_A = EX_oprA;	// illegal PPP - don't forward 
				endcase 
			end
		else 
			begin 
				EX_alu_A = EX_oprA;
			end 
		
		if ((EX_reg_wr && WB_reg_write_load && (WB_dest_reg == EX_regB))& !last_stall )	
			begin
				case (WB_PPP)
					3'b000: // All bytes participate
						EX_alu_B = WB_data;
					3'b001: // Upper 32-bits participate
						EX_alu_B = {WB_data[0:31], EX_oprB[32:63]} ;
					3'b010: // Lower 32-bits participate
						EX_alu_B = {EX_oprB[0:31], WB_data[32:63]} ;
					3'b011: // Bytes with even index participate
						EX_alu_B = {WB_data[0:7],   EX_oprB[8:15], WB_data[16:23], EX_oprB[24:31],
									WB_data[32:39], EX_oprB[40:47], WB_data[48:55], EX_oprB[56:63]};
					3'b100: // Bytes with odd index participate
						EX_alu_B = {EX_oprB[0:7],   WB_data[8:15], EX_oprB[16:23], WB_data[24:31],
									EX_oprB[32:39], WB_data[40:47], EX_oprB[48:55], WB_data[56:63]};
					default: EX_alu_B = EX_oprB;	// illegal PPP - don't forward 
				endcase 
			end
		else 
			begin 
				EX_alu_B = EX_oprB;	
			end
		//----------------------------------------------------------------------
		
	end 
endmodule

module program_counter(clk, reset, stall, pc_load, data_in, data_out);
	input clk, reset;
	input pc_load;
	input stall; 
	input [0:15] data_in; // Branch address to load = instruction[16:31]
	output reg [0:31] data_out;

	always@(posedge clk) 
		begin
			if(reset)
				data_out <= 0;
			else if(stall == 1'b0) 
				begin
					if(pc_load)
						data_out <= {16'b0, data_in};
					else
						data_out <= data_out + 3'd4;
				end
		end
endmodule

module register_file(clk, reset, write_en, read1_addr, read2_addr, write_addr, Din, Dout1, Dout2, PPP);
	localparam data_width = 64; // Width of Din and data_out buses
	localparam depth = 32;
	localparam addr_width = 5; // number of bits in address bus

	input clk, reset, write_en;

	input [0:addr_width-1] write_addr;
	input [0:addr_width-1] read1_addr;
	input [0:addr_width-1] read2_addr;
	

	input [0:data_width-1] Din;
	output reg [0:data_width-1] Dout1;
	output reg [0:data_width-1] Dout2;

	input [0:2] PPP;

	reg [0:data_width-1] ram [0:depth-1];
	reg [0:data_width-1] current_ram, next_ram_value;
	reg [0:5] i;

	always @(posedge clk) begin
		if(reset == 1'b1) begin
			for (i=0; i < depth; i=i+1)
				ram[i] <= {data_width{1'b0}};
		end else begin
			if( (write_en == 1'b1) && (write_addr != 5'd0) ) begin // Ignore writing to register 0
				ram[write_addr] <= next_ram_value;
			end
		end
	end	
		
	always @(*) begin
		current_ram = ram[write_addr];
		next_ram_value = calc_ram_value(current_ram, Din , PPP);
		
		if(write_en &&(write_addr == read1_addr)&& (write_addr != 5'd0))
			Dout1 = next_ram_value;
		else
			Dout1 = ram[read1_addr];
			
		if(write_en &&(write_addr == read2_addr)&& (write_addr != 5'd0))
			Dout2 = next_ram_value;
		else
			Dout2 = ram[read2_addr];		
	end
		
		function [0:data_width-1] calc_ram_value;
		input [0:data_width-1] current_ram;
		input [0:data_width-1] Din;
		input [0:2] PPP;
		reg [0:data_width-1] next_ram;
		begin
			case(PPP)
				3'b000: // All bytes participate
					next_ram = Din;
				3'b001: // Upper 32-bits participate
					next_ram = {Din[0:31], current_ram[32:63]};
				3'b010: // Lower 32-bits participate
					next_ram = {current_ram[0:31], Din[32:63]};
				3'b011: // Bytes with even index participate
					next_ram = {Din[0:7],   current_ram[8:15], Din[16:23], current_ram[24:31],
								Din[32:39], current_ram[40:47], Din[48:55], current_ram[56:63]};
				3'b100: // Bytes with odd index participate
					next_ram = {current_ram[0:7],   Din[8:15], current_ram[16:23], Din[24:31],
								current_ram[32:39], Din[40:47], current_ram[48:55], Din[56:63]};
				default: next_ram = current_ram;
			endcase
			calc_ram_value = next_ram;
		end
	endfunction
endmodule
















/////////////////////////////////////////////////////////////////////////////////////////////////////CMP//////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////CMP//////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////CMP//////////////////////////////////////////////////////////////////////////////////////


module cmp(CLK, RESET, 
		node0_inst_in, node0_d_in, node0_pc_out, node0_d_out, node0_addr_out, node0_memEn, node0_memWrEn, node0_addr_nic, node0_din_nic, node0_dout_nic, node0_nicEn, node0_nicWrEn, 
		node1_inst_in, node1_d_in, node1_pc_out, node1_d_out, node1_addr_out, node1_memEn, node1_memWrEn, node1_addr_nic, node1_din_nic, node1_dout_nic, node1_nicEn, node1_nicWrEn, 
		node2_inst_in, node2_d_in, node2_pc_out, node2_d_out, node2_addr_out, node2_memEn, node2_memWrEn, node2_addr_nic, node2_din_nic, node2_dout_nic, node2_nicEn, node2_nicWrEn, 
		node3_inst_in, node3_d_in, node3_pc_out, node3_d_out, node3_addr_out, node3_memEn, node3_memWrEn, node3_addr_nic, node3_din_nic, node3_dout_nic, node3_nicEn, node3_nicWrEn);

	input			CLK;
	input			RESET;
	input	[0:31]	node0_inst_in;
	input	[0:63]	node0_d_in;
	output	[0:31]	node0_pc_out;
	output	[0:63]	node0_d_out;
	output	[0:31]	node0_addr_out;
	output			node0_memWrEn;
	output			node0_memEn;
	output	[0:1]	node0_addr_nic;
	output	[0:63]	node0_din_nic;
	output	[0:63]	node0_dout_nic;
	output			node0_nicEn;
	output			node0_nicWrEn;
	
	input	[0:31]	node1_inst_in;
	input	[0:63]	node1_d_in;
	output	[0:31]	node1_pc_out;
	output	[0:63]	node1_d_out;
	output	[0:31]	node1_addr_out;
	output			node1_memEn;
	output			node1_memWrEn;
	output	[0:1]	node1_addr_nic;
	output	[0:63]	node1_din_nic;
	output	[0:63]	node1_dout_nic;
	output			node1_nicEn;
	output			node1_nicWrEn;
	
	input	[0:31]	node2_inst_in;
	input	[0:63]	node2_d_in;
	output	[0:31]	node2_pc_out;
	output	[0:63]	node2_d_out;
	output	[0:31]	node2_addr_out;
	output			node2_memEn;
	output			node2_memWrEn;
	output	[0:1]	node2_addr_nic;
	output	[0:63]	node2_din_nic;
	output	[0:63]	node2_dout_nic;
	output			node2_nicEn;
	output			node2_nicWrEn;
	
	input	[0:31]	node3_inst_in;
	input	[0:63]	node3_d_in;
	output	[0:31]	node3_pc_out;
	output	[0:63]	node3_d_out;
	output	[0:31]	node3_addr_out;
	output			node3_memEn;
	output			node3_memWrEn;
	output	[0:1]	node3_addr_nic;
	output	[0:63]	node3_din_nic;
	output	[0:63]	node3_dout_nic;
	output			node3_nicEn;
	output			node3_nicWrEn;

	wire node0_pesi, node1_pesi, node2_pesi, node3_pesi;
	wire node0_peri, node1_peri, node2_peri, node3_peri;
	wire [63:0] node0_pedi, node1_pedi, node2_pedi, node3_pedi;
	wire node0_peso, node1_peso, node2_peso, node3_peso;
	wire node0_pero, node1_pero, node2_pero, node3_pero;
	wire [63:0] node0_pedo, node1_pedo, node2_pedo, node3_pedo;
	wire node0_polarity, node1_polarity, node2_polarity, node3_polarity;
	wire [0:63] CRC_in0, CRC_in1, CRC_in2, CRC_in3;
	wire [0:63] CRC_result0,CRC_result1, CRC_result2, CRC_result3;
	wire [0:31] CRC_packet0, CRC_packet1, CRC_packet2, CRC_packet3;
	wire verCRCflag0, verCRCflag1, verCRCflag2, verCRCflag3;
	
	gold_nic nic_0(.clk(CLK), .reset(RESET), .addr(node0_addr_nic), .d_in(node0_din_nic), .d_out(node0_dout_nic), .nicEn(node0_nicEn), .nicEnWr(node0_nicWrEn), .net_si(node0_peso), .net_ri(node0_pero), .net_di(node0_pedo), .net_so(node0_pesi), .net_ro(node0_peri), .net_do(node0_pedi), .net_polarity(node0_polarity));
	gold_nic nic_1(.clk(CLK), .reset(RESET), .addr(node1_addr_nic), .d_in(node1_din_nic), .d_out(node1_dout_nic), .nicEn(node1_nicEn), .nicEnWr(node1_nicWrEn), .net_si(node1_peso), .net_ri(node1_pero), .net_di(node1_pedo), .net_so(node1_pesi), .net_ro(node1_peri), .net_do(node1_pedi), .net_polarity(node1_polarity));
	gold_nic nic_2(.clk(CLK), .reset(RESET), .addr(node2_addr_nic), .d_in(node2_din_nic), .d_out(node2_dout_nic), .nicEn(node2_nicEn), .nicEnWr(node2_nicWrEn), .net_si(node2_peso), .net_ri(node2_pero), .net_di(node2_pedo), .net_so(node2_pesi), .net_ro(node2_peri), .net_do(node2_pedi), .net_polarity(node2_polarity));
	gold_nic nic_3(.clk(CLK), .reset(RESET), .addr(node3_addr_nic), .d_in(node3_din_nic), .d_out(node3_dout_nic), .nicEn(node3_nicEn), .nicEnWr(node3_nicWrEn), .net_si(node3_peso), .net_ri(node3_pero), .net_di(node3_pedo), .net_so(node3_pesi), .net_ro(node3_peri), .net_do(node3_pedi), .net_polarity(node3_polarity));
	
	crc32 CRC0(.clk(CLK),.rst(RESET),.data_in(CRC_in0), .CRC_packet(CRC_packet0), .verCRCflag(verCRCflag0), .crc_out(CRC_result0));
	crc32 CRC1(.clk(CLK),.rst(RESET),.data_in(CRC_in1), .CRC_packet(CRC_packet1), .verCRCflag(verCRCflag1), .crc_out(CRC_result1));
	crc16 CRC2(.clk(CLK),.rst(RESET),.data_in(CRC_in2), .CRC_packet(CRC_packet2), .verCRCflag(verCRCflag2), .crc_out(CRC_result2));
	crc5  CRC3(.clk(CLK),.rst(RESET),.data_in(CRC_in3), .CRC_packet(CRC_packet3), .verCRCflag(verCRCflag3), .crc_out(CRC_result3));
	
	
	
	
	gold_processor proc_0(.clk(CLK), .reset(RESET), .pc(node0_pc_out), .instruction(node0_inst_in),	.memAddr(node0_addr_out), .memEn(node0_memEn), .memWrEn(node0_memWrEn), .dataIn(node0_d_in), .dataOut(node0_d_out), .addr(node0_addr_nic), .d_in(node0_din_nic), .d_out(node0_dout_nic), .nicEn(node0_nicEn), .nicEnWr(node0_nicWrEn),.CRC_in(CRC_in0), .CRC_packet(CRC_packet0), .verCRCflag(verCRCflag0), .CRC_result(CRC_result0));
	gold_processor proc_1(.clk(CLK), .reset(RESET), .pc(node1_pc_out), .instruction(node1_inst_in),	.memAddr(node1_addr_out), .memEn(node1_memEn), .memWrEn(node1_memWrEn), .dataIn(node1_d_in), .dataOut(node1_d_out), .addr(node1_addr_nic), .d_in(node1_din_nic), .d_out(node1_dout_nic), .nicEn(node1_nicEn), .nicEnWr(node1_nicWrEn),.CRC_in(CRC_in1), .CRC_packet(CRC_packet1), .verCRCflag(verCRCflag1), .CRC_result(CRC_result1));
	gold_processor proc_2(.clk(CLK), .reset(RESET), .pc(node2_pc_out), .instruction(node2_inst_in),	.memAddr(node2_addr_out), .memEn(node2_memEn), .memWrEn(node2_memWrEn), .dataIn(node2_d_in), .dataOut(node2_d_out), .addr(node2_addr_nic), .d_in(node2_din_nic), .d_out(node2_dout_nic), .nicEn(node2_nicEn), .nicEnWr(node2_nicWrEn),.CRC_in(CRC_in2), .CRC_packet(CRC_packet2), .verCRCflag(verCRCflag2), .CRC_result(CRC_result2));
	gold_processor proc_3(.clk(CLK), .reset(RESET), .pc(node3_pc_out), .instruction(node3_inst_in),	.memAddr(node3_addr_out), .memEn(node3_memEn), .memWrEn(node3_memWrEn), .dataIn(node3_d_in), .dataOut(node3_d_out), .addr(node3_addr_nic), .d_in(node3_din_nic), .d_out(node3_dout_nic), .nicEn(node3_nicEn), .nicEnWr(node3_nicWrEn),.CRC_in(CRC_in3), .CRC_packet(CRC_packet3), .verCRCflag(verCRCflag3), .CRC_result(CRC_result3));

	gold_ring ring(CLK, RESET, 
	        node0_pesi, node0_peri, node0_pedi, node0_peso, node0_pero, node0_pedo, 
	        node1_pesi, node1_peri, node1_pedi, node1_peso, node1_pero, node1_pedo, 
		    node2_pesi, node2_peri, node2_pedi, node2_peso, node2_pero, node2_pedo, 
			node3_pesi, node3_peri, node3_pedi, node3_peso, node3_pero, node3_pedo, 
			node0_polarity, node1_polarity, node2_polarity, node3_polarity);

endmodule





