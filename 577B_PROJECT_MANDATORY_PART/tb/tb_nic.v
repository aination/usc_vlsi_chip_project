`timescale 1ns/1ps
`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"

module tb_nic;
reg clk, reset;
reg [1:0]addr;		// from processor -- reg to read
reg [63:0]d_in;		// reg packet from processor to inject to router
wire [63:0]d_out; // content of reg data to be sent to processor
reg nicEn;			// Enable signal to NIC, if '0', d_out = 0
reg nicWrEn; 			// if '1' along with nicEn, write to out_ch_buff
wire  net_so;			// valid packet to send to router ready
reg net_ro;			// router ready to accept paket from NIC
wire  [63:0]net_do;	// wire packet data from NIC to router
reg net_polarity;		// polarity indication
reg net_si;			// indicates router wants to send data to in_ch_buff
wire net_ri;			//indicates if in_ch_buff is empty
reg [63:0]net_di;
parameter halfclk = 2;

nic p2r(clk, reset,addr,d_in,d_out,nicEn,nicWrEn, net_so,net_ro,net_do,net_polarity, net_si,net_ri,net_di);


initial
	$sdf_annotate("../sdf/nic.sdf",p2r,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");


initial clk = 1;
always #halfclk clk = ~clk;

initial 
begin

	reset = 1;
	addr = 2'b00;
	d_in = 64'h123456789ABCDEF;
	nicEn = 1;
	nicWrEn = 0;
	net_ro=0;
	net_polarity = 1;
	net_si = 0;
	net_di = 64'hFEDCBA9876543210;
#(3*halfclk) reset = 0;
#(2*halfclk)	nicWrEn=1;
#(2*halfclk) addr = 2'b01;
#(8*halfclk) net_ro=1;
	d_in = 64'h1111111111111111;
#(8*halfclk)	net_polarity = 0;
	nicWrEn=0;
#(16*halfclk) net_si = 1;
#(8*halfclk) addr = 2'b10;
@(negedge clk);
	net_di=64'h1010101010101010;
#100 $finish;
end 
endmodule
