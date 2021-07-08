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
