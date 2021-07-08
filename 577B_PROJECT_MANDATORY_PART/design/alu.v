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