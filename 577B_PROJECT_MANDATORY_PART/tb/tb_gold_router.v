// Test class 1 - individual tokens on a single channel
// Test class 2 - multiple tokens on different VCs of same channel	
// Test class 3 - sending on three channels (same VC)
// Test class 4 - blocking - fill all input and output buffers

`timescale 1ns/1ps
`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"
module tb_gold_router;
	
	// testbench variables
	reg clk_tb, reset_tb;
	wire polarity_tb;
	 
	reg cwsi_tb, ccwsi_tb, pesi_tb;
	reg [63:0] cwdi_tb, ccwdi_tb, pedi_tb;
	wire cwri_tb, ccwri_tb, peri_tb;
	
	reg cwro_tb, ccwro_tb, pero_tb;
	wire cwso_tb, ccwso_tb, peso_tb;
	wire [63:0] cwdo_tb, ccwdo_tb, pedo_tb;
	parameter clk_p = 8;
	integer test_class = 0;
	parameter EVEN = 0;
	parameter ODD = 1;
	parameter CW = 0;
	parameter CCW = 1;
	parameter PE = 2;
	reg [31:0] payload_data = 0;
	integer file_handle;
	integer testnum = 2;

	gold_router	gold_router_inst0(.clk(clk_tb), .reset(reset_tb), .polarity(polarity_tb),
				.cwso(cwso_tb), .cwro(cwro_tb), .ccwso(ccwso_tb), .ccwro(ccwro_tb),
				.cwsi(cwsi_tb), .cwri(cwri_tb), .ccwsi(ccwsi_tb), .ccwri(ccwri_tb), 
				.peso(peso_tb), .pero(pero_tb), .cwdo(cwdo_tb), .ccwdo(ccwdo_tb), .pedo(pedo_tb),
				.pesi(pesi_tb), .peri(peri_tb), .cwdi(cwdi_tb), .ccwdi(ccwdi_tb), .pedi(pedi_tb));
			
	//---------------------------------------------------------------------
	initial
     begin
      $sdf_annotate("../sdf/gold_router.sdf",gold_router_inst0,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");
     end
    //---------------------------------------------------------------------
								

	// stimulus
	initial
	begin
		clk_tb = 1'b0;
		forever #(clk_p/2) clk_tb = !clk_tb;
	end

	initial
	begin
		reset_tb = 1'b1;
		#(2*clk_p) reset_tb = !reset_tb;
	end
	
    initial
		begin 
			file_handle = $fopen("reports/gold_router.out");
			cwsi_tb = 0;          //initialize
			cwro_tb = 1;
			ccwsi_tb = 0;
			pero_tb = 1;
			pesi_tb = 0;
			pedi_tb = 0;
			cwdi_tb = 0;
			ccwdi_tb = 0;
			ccwro_tb = 1;
			repeat(3) @(posedge clk_tb);
            //1		
				test_class = 1;
				run_test(PE, CW, EVEN, build_packet(EVEN, CW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CW, ODD, build_packet(ODD, CW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CCW, EVEN, build_packet(EVEN, CCW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CCW, ODD, build_packet(ODD, CCW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(CW, CW, EVEN, build_packet(EVEN, CW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(CW, CW, ODD, build_packet(ODD, CW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(CCW, CCW, EVEN, build_packet(EVEN, CCW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(CCW, CCW, ODD, build_packet(ODD, CCW, 4), 0);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CW, EVEN, build_packet(EVEN, CW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CW, ODD, build_packet(ODD, CW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CCW, EVEN, build_packet(EVEN, CCW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(PE, CCW, ODD, build_packet(ODD, CCW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CW, CW, EVEN, build_packet(EVEN, CW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CW, CW, ODD, build_packet(ODD, CW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CCW, CCW, EVEN, build_packet(EVEN, CCW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CCW, CCW, ODD, build_packet(ODD, CCW, 4), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CW, PE, EVEN, build_packet(EVEN, CW, 0), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CW, PE, ODD, build_packet(ODD, CW, 0), 1);
				repeat(3) @(posedge clk_tb);																
				run_test(CCW, PE, EVEN, build_packet(EVEN, CCW, 0), 1);
				repeat(3) @(posedge clk_tb);
				run_test(CCW, PE, ODD, build_packet(ODD, CCW, 0), 1);
				repeat(3) @(posedge clk_tb);
			
			//end of 1
			
			//2 
				test_class = 2;
				run_test_b2b(PE, CW, EVEN, build_packet(EVEN, CW, 4), build_packet(ODD, CW, 4), 0);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(PE, CCW, EVEN, build_packet(EVEN, CCW, 4), build_packet(ODD, CCW, 4), 0);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(PE, CW, EVEN, build_packet(EVEN, CW, 4), build_packet(ODD, CW, 4), 1);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(PE, CCW, EVEN, build_packet(EVEN, CCW, 4), build_packet(ODD, CCW, 4), 1);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(CW, CW, EVEN, build_packet(EVEN, CW, 4), build_packet(ODD, CW, 4), 0);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(CCW, CCW, EVEN, build_packet(EVEN, CCW, 4), build_packet(ODD, CCW, 4), 0);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(CW, PE, EVEN, build_packet(EVEN, CW, 0), build_packet(ODD, CW, 0), 0);
				repeat(5) @(posedge clk_tb);
				run_test_b2b(CCW, PE, EVEN, build_packet(EVEN, CCW, 0), build_packet(ODD, CCW, 0), 0);
				repeat(5) @(posedge clk_tb);
			
			//end of 2
			
			//3
				test_class = 3;
				testnum = testnum + 1;
				cwro_tb = 1;
				ccwro_tb = 1;
				@(posedge clk_tb);
				#1;
				wait((polarity_tb == ODD) && (peri_tb)  &&(cwri_tb) && (ccwri_tb));
				pesi_tb = 1;
				cwsi_tb = 1;
				ccwsi_tb = 1;
				pedi_tb = build_packet(EVEN, CCW, 4);
				cwdi_tb = build_packet(EVEN, CW, 4);
				ccwdi_tb = build_packet(EVEN, CCW, 4);
				@(posedge clk_tb);
				#1;
				cwsi_tb = 0;
				ccwsi_tb = 0;
				pesi_tb = 0;
				cwro_tb = 1;
				ccwro_tb = 1;
				pero_tb = 1;
				repeat(3) @(posedge clk_tb);
			
			
			//end of 3
			
			//4 
				test_class = 4;
				testnum = testnum + 1;
							
				cwro_tb = 0;
				ccwro_tb = 0;
				pero_tb = 0;
				@(posedge clk_tb);
				#1;
				wait((polarity_tb == ODD) );//&& (peri_tb)  &&(cwri_tb) && (ccwri_tb));
				cwsi_tb = 1;
				ccwsi_tb = 1;
				pesi_tb = 1;
				
				cwdi_tb = build_packet(EVEN, CW, 0);
				ccwdi_tb = build_packet(EVEN, CCW, 4);
				pedi_tb = build_packet(EVEN, CW, 4);
				@(posedge clk_tb);
				#1;
				cwdi_tb = build_packet(ODD, CW, 0);
				ccwdi_tb = build_packet(ODD, CCW, 4);
				pedi_tb = build_packet(EVEN, CW, 4);

				@(posedge clk_tb);
				#1;		
				cwdi_tb = build_packet(EVEN, CW, 0);
				ccwdi_tb = build_packet(EVEN, CCW, 4);
				pedi_tb = build_packet(EVEN, CW, 4);
				@(posedge clk_tb);
				#1;
				cwdi_tb = build_packet(ODD, CW, 0);
				ccwdi_tb = build_packet(ODD, CCW, 4);
				pedi_tb = build_packet(EVEN, CW, 4);	
				
				@(posedge clk_tb);
				#1;

				cwsi_tb = 0;
				ccwsi_tb = 0;
				pesi_tb = 0;
				cwro_tb = 1;
				ccwro_tb = 1;
				pero_tb = 1;
				repeat(5) @(posedge clk_tb);
			//end of 4
			$finish;
		end
	always @(negedge clk_tb)
	begin
		$fdisplay(file_handle, "TIME=%g ns", $time);
		$fdisplay(file_handle, "RESET=%b, \tPOLARITY=%b, \tTEST_NUM=%d,\tTEST_CLASS=%d", reset_tb, polarity_tb, testnum, test_class);
		$fdisplay(file_handle, "CWSI=%b, \tCWRI=%b, \tCWDI=%h, \tCWSO=%b, \tCWRO=%b, \tCWDO=%h", cwsi_tb, cwri_tb, cwdi_tb, cwso_tb, cwro_tb, cwdo_tb);
		$fdisplay(file_handle, "CCSI=%b, \tCCRI=%b, \tCCDI=%h, \tCCSO=%b, \tCCRO=%b, \tCCDO=%h", ccwsi_tb, ccwri_tb, ccwdi_tb, ccwso_tb, ccwro_tb, ccwdo_tb);
		$fdisplay(file_handle, "PESI=%b, \tPERI=%b, \tPEDI=%h, \tPESO=%b, \tPERO=%b, \tPEDO=%h\n", pesi_tb, peri_tb, pedi_tb, peso_tb, pero_tb, pedo_tb);
	end
	
	
		// to send a token from one input channel to an output channel
	task run_test;
		input [1:0] inp_channel;
		input [1:0] out_channel;
		input polar;
		input [63:0] packet;
		input is_blocking;
	begin
		testnum = testnum + 1;
		if(!is_blocking)
		begin
			// set output channel ready in 
			case (out_channel)
				CW:
					begin
						cwro_tb = 1;
					end
				CCW:
					begin
						ccwro_tb = 1;
					end
				PE:
					begin
						pero_tb = 1;
					end
			endcase
			
			case (inp_channel)
				CW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (cwri_tb == 1));
						cwsi_tb = 1;
						cwdi_tb = packet;
					end
				CCW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (ccwri_tb == 1));
						ccwsi_tb = 1;
						ccwdi_tb = packet;
					end
				PE:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (peri_tb == 1));
						$display("Time=%g, POLARITY=%b, POLAR=%b", $time, polarity_tb, polar);
						pesi_tb = 1;
						pedi_tb = packet;
					end
			endcase
			
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
		    ccwsi_tb = 0;
			pesi_tb = 0;
			cwro_tb = 1;
			ccwro_tb = 1;
			pero_tb = 1;
		end
		else
		begin
			// reset output channel ready in 
			case (out_channel)
				CW:
					begin
						cwro_tb = 0;
					end
				CCW:
					begin
						ccwro_tb = 0;
					end
				PE:
					begin
						pero_tb = 0;
					end
			endcase
			
			case (inp_channel)
				CW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (cwri_tb == 1));
						cwsi_tb = 1;
						cwdi_tb = packet;
					end
				CCW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (ccwri_tb == 1));
						ccwsi_tb = 1;
						ccwdi_tb = packet;
					end
				PE:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (peri_tb == 1));
						$display("Time=%g, POLARITY=%b, POLAR=%b", $time, polarity_tb, polar);
						pesi_tb = 1;
						pedi_tb = packet;
					end
			endcase
			
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
			ccwsi_tb = 0;
			pesi_tb = 0;
			@(posedge clk_tb);
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
			ccwsi_tb = 0;
			pesi_tb = 0;
			cwro_tb = 1;
			ccwro_tb = 1;
			pero_tb = 1;
		end 
	end 
	endtask 
		
	function [63:0] build_packet;
		input vc;
		input dir;
		input [7:0] hopcnt;
		reg [31:0] data;
	begin
		payload_data = payload_data + 1;
		data = payload_data;
		build_packet = {vc, dir, 6'h00, hopcnt, 16'h00, data};
	end
	endfunction
	
		// to run a test with back-to-back tokens from a single input channel 
	// to a single output channel
	task run_test_b2b;
		input [1:0] inp_channel;
		input [1:0] out_channel;
		input polar;
		input [63:0] packet_one;
		input [63:0] packet_two;
		input is_blocking;
	begin
		testnum = testnum + 1;
		if(!is_blocking)
		begin
			// set output channel ready in 
			case (out_channel)
				CW:
					begin
						cwro_tb = 1;
					end
				CCW:
					begin
						ccwro_tb = 1;
					end
				PE:
					begin
						pero_tb = 1;
					end
			endcase
			
			case (inp_channel)
				CW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (cwri_tb == 1));
						cwsi_tb = 1;
						cwdi_tb = packet_one;
						@(posedge clk_tb);
						#1;
						cwdi_tb = packet_two;
					end
				CCW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (ccwri_tb == 1));
						ccwsi_tb = 1;
						ccwdi_tb = packet_one;
						@(posedge clk_tb);
						#1;
						ccwdi_tb = packet_two;
					end
				PE:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (peri_tb == 1));
						pesi_tb = 1;
						pedi_tb = packet_one;
						@(posedge clk_tb);
						wait( clk_tb && (polarity_tb == polar) && (peri_tb == 1));
						#1;
						pedi_tb = packet_two;
					end
			endcase
			
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
			ccwsi_tb = 0;
			pesi_tb = 0;
			cwro_tb = 1;
			ccwro_tb = 1;
			pero_tb = 1;
		end
		else
		begin
			// reset output channel ready in 
			case (out_channel)
				CW:
					begin
						cwro_tb = 0;
					end
				CCW:
					begin
						ccwro_tb = 0;
					end
				PE:
					begin
						pero_tb = 0;
					end
			endcase
			
			case (inp_channel)
				CW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (cwri_tb == 1));
						cwsi_tb = 1;
						cwdi_tb = packet_one;
						@(posedge clk_tb);
						#1;
						cwdi_tb = packet_two;
					end
				CCW:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (ccwri_tb == 1));
						ccwsi_tb = 1;
						ccwdi_tb = packet_one;
						@(posedge clk_tb);
						#1;
						ccwdi_tb = packet_two;
					end
				PE:
					begin
						@(posedge clk_tb);
						#1;
						wait( clk_tb && (polarity_tb == ~polar) && (peri_tb == 1));
						pesi_tb = 1;
						pedi_tb = packet_one;
						@(posedge clk_tb);
						#1;
						pedi_tb = packet_two;
					end
			endcase
			
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
			ccwsi_tb = 0;
			pesi_tb = 0;
			@(posedge clk_tb);
			@(posedge clk_tb);
			#1;
			cwsi_tb = 0;
			ccwsi_tb = 0;
			pesi_tb = 0;
			cwro_tb = 1;
			ccwro_tb = 1;
			pero_tb = 1;
		end 
	end
	endtask
	
endmodule
	
