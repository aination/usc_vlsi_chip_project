`timescale 1ns/10ps
`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"
module tb_crc5;
reg clk,rst;
reg [63:0] data_in;
wire[4:0] crc_out;
integer crco5;
integer i;
crc5 crc5test
(
.clk(clk),
.rst(rst),
.data_in(data_in),
.crc_out(crc_out)
);
always #2 clk=~clk;
initial 
	begin
	$sdf_annotate("../sdf/crc5.sdf",crc5test,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");
	crco5=$fopen("crc5.out");
	$fmonitor(crco5, "at time %g ns, rst= %b, data_in= %h, crc_out= %b,", $time, rst,data_in,crc_out);
	$monitor("%b %b %h %b", clk,rst,data_in,crc_out);
	clk=0;
	rst=1;data_in=64'h0123456789ABCDEF;
	#6;
	rst=0;
	#4;
	data_in = 64'hFEDCBA9876543210;
	#4;
	for(i=0;i<5;i=i+1)
	begin
		data_in[31:0] = $random;
		data_in[63:32] = $random;
		#4;
	end
	$fclose(crco5);
	$finish;
	end
endmodule

