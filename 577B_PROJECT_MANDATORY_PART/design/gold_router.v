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

							//arbiter sequential logic 
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
