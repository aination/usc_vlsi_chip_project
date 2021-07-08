`timescale 1ns/10ps
//`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"     
module tb_gold_ring;

	reg clk, reset;
	wire node0_polarity, node1_polarity, node2_polarity, node3_polarity;
	wire node0_pesi, node1_pesi, node2_pesi, node3_pesi;
	wire node0_peri, node1_peri, node2_peri, node3_peri;
	wire node0_peso, node1_peso, node2_peso, node3_peso;
	wire node0_pero, node1_pero, node2_pero, node3_pero;
	wire [63:0] node0_pedi, node1_pedi, node2_pedi, node3_pedi;
	wire [63:0] node0_pedo, node1_pedo, node2_pedo, node3_pedo;
	wire [3:0] received;
	parameter clk_p = 4;   //clock period setting to 4 ns
	parameter EVEN= 1'b0;
	parameter ODD = 1'b1;
	parameter CW  = 1'b0;
	parameter CCW = 1'b1;
	integer start_time [3:0] , end_time [3:0];
	integer loop;

	integer test_class;
	reg [1:0] id0 = 2'h0;
	reg [1:0] id1 = 2'h1;
	reg [1:0] id2 = 2'h2;
	reg [1:0] id3 = 2'h3;
	// we are building 4 processing element handler to handle the send and receive operation [pe_handler]
    // node 0 and node 1 always inject packets into the even channels
	//node 2 and node 3 always inject packets into the odd channels

	
	gold_ring	DUT (.clk(clk), .reset(reset), .node0_pesi(node0_pesi), .node0_peri(node0_peri), .node0_pedi(node0_pedi), 
								.node0_peso(node0_peso), .node0_pero(node0_pero), .node0_pedo(node0_pedo), 
								.node1_pesi(node1_pesi), .node1_peri(node1_peri), .node1_pedi(node1_pedi), .node1_peso(node1_peso), .node1_pero(node1_pero), .node1_pedo(node1_pedo), 
								.node2_pesi(node2_pesi), .node2_peri(node2_peri), .node2_pedi(node2_pedi), .node2_peso(node2_peso), .node2_pero(node2_pero), .node2_pedo(node2_pedo), 
								.node3_pesi(node3_pesi), .node3_peri(node3_peri), .node3_pedi(node3_pedi), .node3_peso(node3_peso), .node3_pero(node3_pero), .node3_pedo(node3_pedo), 
								.node0_polarity(node0_polarity), .node1_polarity(node1_polarity), .node2_polarity(node2_polarity), .node3_polarity(node3_polarity));
	
	//---------------------------------------------------------------------// for post syn simulation 
	//initial
    // begin
    //  $sdf_annotate("../sdf/gold_ring.sdf",DUT,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");
    // end
    //---------------------------------------------------------------------
								

	
	pe_handler PEH0 (.clk(clk), .reset(reset), .polarity(node0_polarity), 
						.pesi(node0_pesi), .peri(node0_peri), .pedi(node0_pedi), 
						.peso(node0_peso), .pero(node0_pero), .pedo(node0_pedo), .id(id0), .recv_done(received[0]));
						
	pe_handler PEH1 (.clk(clk), .reset(reset), .polarity(node1_polarity), 
						.pesi(node1_pesi), .peri(node1_peri), .pedi(node1_pedi), 
						.peso(node1_peso), .pero(node1_pero), .pedo(node1_pedo), .id(id1), .recv_done(received[1]));
						
	pe_handler PEH2 (.clk(clk), .reset(reset), .polarity(node2_polarity), 
						.pesi(node2_pesi), .peri(node2_peri), .pedi(node2_pedi), 
						.peso(node2_peso), .pero(node2_pero), .pedo(node2_pedo), .id(id2), .recv_done(received[2]));
						
	pe_handler PEH3 (.clk(clk), .reset(reset), .polarity(node3_polarity), 
						.pesi(node3_pesi), .peri(node3_peri), .pedi(node3_pedi), 
						.peso(node3_peso), .pero(node3_pero), .pedo(node3_pedo), .id(id3), .recv_done(received[3]));
	
	integer file_io_handle;

	

	initial
	begin	
		clk = 1'b0;
		forever #(clk_p/2) clk = !clk;
	end

	initial
	begin	
		reset = 1'b1;
		#(2*clk_p)	reset = !reset;
	end		
				
				
	initial 
	begin
    	file_io_handle = $fopen("reports/start_end_time.out"); 
		PEH0.pesi = 0;                                         // reset all signals
		PEH0.pedi = 0;
		PEH0.pero = 0;
		PEH1.pesi = 0;
		PEH1.pedi = 0;
		PEH1.pero = 0;
		PEH2.pesi = 0;
		PEH2.pedi = 0;
		PEH2.pero = 0;
		PEH3.pesi = 0;
		PEH3.pedi = 0;
		PEH3.pero = 0;
		test_class = 0;
		
		//----------------------------------------------------------------
		// 1 - gather test bench cases 
		//----------------------------------------------------------------
		repeat (3) @(posedge clk);
		test_class = 1;
		
		// gather - phase 0
		// node 1,2,3 -> node 0
		start_time[0] = $time;
		fork
			PEH0.receive;
			PEH1.send(CCW, 1, 0);   //direction,hopcount,destination
			PEH2.send(CW, 2, 0);	//direction,hopcount,destination
			PEH3.send(CW, 1, 0);	//direction,hopcount,destination
		join
		
		// gather - phase 1
		// node 0,2,3 -> node 1 
		wait(received[0]);          //wait until node 0 receives the data  
		end_time[0] = $time-1;
		start_time[1] = $time;
		fork                        //here we are trying to simulate the multi processor activity using fork join; 
		                            //the processing elements are simultaneously injecting data into the 3 routers 
									//while the 4th node is configured to receive the packet  
			PEH1.receive;
			PEH0.send(CW, 1, 1);    //direction,hopcount,destination
			PEH2.send(CCW, 1, 1);	//direction,hopcount,destination
			PEH3.send(CW, 2, 1);	//direction,hopcount,destination
		join
		
		// gather - phase 2
		// node 0,1,3 -> node 2
		wait(received[1]);          //wait until node 1 receives the data
		end_time[1] = $time-1;
		start_time[2] = $time;
		fork
			PEH2.receive;
			PEH0.send(CW, 2, 2);     //direction,hopcount,destination
			PEH1.send(CW, 1, 2);     //direction,hopcount,destination
			PEH3.send(CCW, 1, 2);    //direction,hopcount,destination
		join
		
		// gather - phase 3
		// node 0,1,2 -> node 3
		wait(received[2]);         //wait until node 2 receives the data
		end_time[2] = $time-1;
		start_time[3] = $time;
		fork
			PEH3.receive;
			PEH0.send(CCW, 1, 3);
			PEH1.send(CW, 2, 3);
			PEH2.send(CW, 1, 3);
		join
		
		wait(received[3]);         //wait until node 3 receives the data
		end_time[3] = $time-1;
		
		
		for (loop = 0; loop < 4; loop = loop + 1)
		begin
			$fdisplay(file_io_handle, "\nPhase=%0d,\tStart Time=%g", loop, start_time[loop]);   //START TIME  -  END TIME  dump into "start_end_time.out"
			$fdisplay(file_io_handle, "Phase=%0d,\tCompletion Time=%g\n", loop, end_time[loop]);
		end 
		
		repeat(2) @(posedge clk);
		$finish;
	end
				
endmodule	

// module processing element handler acts as a dummy NIC to simulate Nic to router kind of interface 

module pe_handler (clk, reset, polarity, pesi, peri, pedi, peso, pero, pedo, id, recv_done);
	input clk, reset, polarity,id,peri, peso, pedo;
	output pesi, pero, pedi, recv_done;
	wire [63:0] pedo;
	wire [1:0] id;
	reg pesi, pero;
	reg [63:0] pedi;
	reg recv_done;
	parameter EVEN= 1'b0;
	parameter ODD = 1'b1;
	parameter CW  = 1'b0;
	parameter CCW = 1'b1;
	// file IO 
	integer file_handle;
	initial 
	begin
		@(posedge clk)
		case (id)
			0: file_handle = $fopen("reports/gather_phase0.out");        //dump each of the gather phase into reports/gather_phasex text files x-0,1,2,3
			1: file_handle = $fopen("reports/gather_phase1.out"); 
			2: file_handle = $fopen("reports/gather_phase2.out"); 
			3: file_handle = $fopen("reports/gather_phase3.out"); 
			default: file_handle = $fopen("reports/gather_phase0.out"); 
		endcase

	end
	
	initial
	begin
		recv_done = 0;
		pesi = 0;
		pedi = 0;
		pero = 0;
	end 
				
	//----------------------------------------------------------------
	// Tasks/functions
	//----------------------------------------------------------------
	
	task send;
		input dir;
		input [7:0] hopcnt;
		input [1:0] destination;
		reg polar;
	begin
		case (id)        // determine polarity to send on
			0: polar = EVEN;
			1: polar = EVEN;
			2: polar = ODD;
			3: polar = ODD;
			default: polar = EVEN;
		endcase 
		
		// set signals
		#1;
		wait((polarity == !polar) && peri);
		@(negedge clk); #1; // Next posedge will be polar
		pesi = 1;
		pedi = form_packet(polar, dir, hopcnt, destination);
		
		// reset signals on next clock
		@(negedge clk); #1;		
		pesi =  0;
		pedi = 0;
	end 
	endtask
	
	
	// to form data packet
	function [63:0] form_packet;
		input vc;
		input dir;
		input [7:0] hopcnt;
		input [1:0] dest;
	begin
		form_packet = {vc, dir, 6'h00, hopcnt, 14'h0, id, 30'h0, dest};
	end
	endfunction
	

	task receive;
		reg [63:0] incoming_packet;
		integer packet_count;
	begin
		// init 
		packet_count = 1;
		recv_done = 0;
		
		// set signals
		pero = 1;
		
		while (packet_count < 4)        //while recieves 3 full packets 
		begin
			@(posedge clk); 
			#1;    
			if(peso) begin            // detecting an incoming packet
				incoming_packet = pedo;			
				$fdisplay(file_handle, "Phase=%d, Time=%g,\tDestination=%0d, Source=%0d, Packet=0x%h", id, $time-1, incoming_packet[31:0], incoming_packet[47:32], incoming_packet);
				packet_count = packet_count + 1;
			end
		end 
		
		recv_done = 1;
		$fclose(file_handle);
	end 
	endtask
endmodule