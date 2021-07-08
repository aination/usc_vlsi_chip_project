`timescale 1ns/1ps
`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"

module tb_alu;
//reg clk;
reg [0:63] oprA;
reg [0:63] oprB;
reg [0:4] shift_amount;
reg [0:5] op;
reg [0:1] ww;
wire [0:63] result;
//wire [0:63] mult32_result;
integer aluo;
alu alutest
(
//.clk(clk),
.oprA(oprA),
.oprB(oprB),
.shift_amount(shift_amount),
.op(op),
.ww(ww),
.result(result)
//.mult32_result(mult32_result)
);

initial
	$sdf_annotate("../sdf/alu.sdf",alutest,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");


initial 
	begin
	aluo=$fopen("alu.out");
	//$fdisplay(alphao, "CLK, RST, EN, D, Q");
	$fmonitor(aluo, "oprA= %d, oprB= %d, shift_amount= %b, op= %b, ww=%b, result=%d", oprA, oprB, shift_amount, op, ww, result);
	$display("oprA, oprB, shift_amount, op, ww, result"); 
	$monitor("%b %b %b %b %b %b",oprA, oprB, shift_amount, op, ww, result); //mult32_result);
	//clk=1;    
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000000; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000001; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000010; ww=2'b00; shift_amount=5'b00111;
	#4;      
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000011; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000100; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000101; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000110; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000111; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001000; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001001; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001010; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001011; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001100; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001101; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001110; ww=2'b00; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001111; ww=2'b00; shift_amount=5'b00111;
	#4;

	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000000; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000001; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000010; ww=2'b01; shift_amount=5'b00111;
	#4;      
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000011; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000100; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000101; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000110; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000111; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001000; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001001; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001010; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001011; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001100; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001101; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001110; ww=2'b01; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001111; ww=2'b01; shift_amount=5'b00111;
	#4;

	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000000; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000001; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000010; ww=2'b10; shift_amount=5'b00111;
	#4;      
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000011; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000100; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000101; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000110; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000111; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001000; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001001; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001010; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001011; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001100; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001101; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001110; ww=2'b10; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001111; ww=2'b10; shift_amount=5'b00111;
	#4;

	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000000; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000001; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000010; ww=2'b11; shift_amount=5'b00111;
	#4;      
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000011; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000100; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000101; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000110; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b000111; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001000; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001001; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001010; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001011; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001100; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001101; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001110; ww=2'b11; shift_amount=5'b00111;
	#4;
	oprA= 64'h0000000000000067; oprB= 64'h0000000000000054; op=6'b001111; ww=2'b11; shift_amount=5'b00111;
	#4;

	$fclose(aluo);
	$finish;
	end
endmodule
