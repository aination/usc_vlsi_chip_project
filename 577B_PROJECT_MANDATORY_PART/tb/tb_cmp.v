`timescale 1ns/10ps
//`include "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.v"
// clock cycle, using 250MHz.
`define CYCLE_TIME 32

// Memory Files
`include "./include/dmem.v"
`include "./include/imem.v"

module tb_cmp;
	reg clk, reset;
	
	wire	[0:31]	node0_inst_in;
	wire	[0:63]	node0_d_in;
	wire	[0:31]	node0_pc_out;
	wire	[0:63]	node0_d_out;
	wire	[0:31]	node0_addr_out;
	wire			node0_memWrEn;
	wire			node0_memEn;
	wire	[0:1]	node0_addr_nic;
	wire	[0:63]	node0_din_nic;
	wire	[0:63]	node0_dout_nic;
	wire			node0_nicEn;
	wire			node0_nicWrEn;
	
	wire	[0:31]	node1_inst_in;
	wire	[0:63]	node1_d_in;
	wire	[0:31]	node1_pc_out;
	wire	[0:63]	node1_d_out;
	wire	[0:31]	node1_addr_out;
	wire			node1_memEn;
	wire			node1_memWrEn;
	wire	[0:1]	node1_addr_nic;
	wire	[0:63]	node1_din_nic;
	wire	[0:63]	node1_dout_nic;
	wire			node1_nicEn;
	wire			node1_nicWrEn;
	
	wire	[0:31]	node2_inst_in;
	wire	[0:63]	node2_d_in;
	wire	[0:31]	node2_pc_out;
	wire	[0:63]	node2_d_out;
	wire	[0:31]	node2_addr_out;
	wire			node2_memEn;
	wire			node2_memWrEn;
	wire	[0:1]	node2_addr_nic;
	wire	[0:63]	node2_din_nic;
	wire	[0:63]	node2_dout_nic;
	wire			node2_nicEn;
	wire			node2_nicWrEn;
	
	wire	[0:31]	node3_inst_in;
	wire	[0:63]	node3_d_in;
	wire	[0:31]	node3_pc_out;
	wire	[0:63]	node3_d_out;
	wire	[0:31]	node3_addr_out;
	wire			node3_memEn;
	wire			node3_memWrEn;
	wire	[0:1]	node3_addr_nic;
	wire	[0:63]	node3_din_nic;
	wire	[0:63]	node3_dout_nic;
	wire			node3_nicEn;
	wire			node3_nicWrEn;
	
	integer CycleNum;            // Counter to count number of cycles for program exec.	
	
	integer i;
	integer dmem0_dump_file, dmem1_dump_file, dmem2_dump_file, dmem3_dump_file;
	integer file_handle_gather; 
	
	// Data Memory Instances
	dmem DM0 (
		.clk      (clk),					// System Clock
		.memEn    (node0_memEn),			// Memory Enable
		.memWrEn  (node0_memWrEn),			// Memory Write Enable
		.memAddr  (node0_addr_out[23:31]),	// Memory Address (9-bit)
		.dataIn   (node0_d_out),			// Memory WRITE Data  (input to data-memory)
		.dataOut  (node0_d_in)				// Memory READ Data (output from data-memory)
	);
	dmem DM1 (
		.clk      (clk),										
		.memEn    (node1_memEn),			
		.memWrEn  (node1_memWrEn),			
		.memAddr  (node1_addr_out[23:31]),	
		.dataIn   (node1_d_out),			
		.dataOut  (node1_d_in)				
	);
	dmem DM2 (
		.clk      (clk),										
		.memEn    (node2_memEn),			
		.memWrEn  (node2_memWrEn),			
		.memAddr  (node2_addr_out[23:31]),	
		.dataIn   (node2_d_out),			
		.dataOut  (node2_d_in)				
	);
	dmem DM3 (
		.clk      (clk),										
		.memEn    (node3_memEn),			
		.memWrEn  (node3_memWrEn),			
		.memAddr  (node3_addr_out[23:31]),	
		.dataIn   (node3_d_out),			
		.dataOut  (node3_d_in)				
	);
	
	// Instruction Memory Instances
	imem IM0 (
		.memAddr (node0_pc_out[21:29]),  // Memory Read Address (9-bit)
		.dataOut (node0_inst_in)	     // Memory READ Output data
	);
	imem IM1 (
		.memAddr (node1_pc_out[21:29]),  // Memory Read Address (9-bit)
		.dataOut (node1_inst_in)	     // Memory READ Output data
	);
	imem IM2 (
		.memAddr (node2_pc_out[21:29]),  // Memory Read Address (9-bit)
		.dataOut (node2_inst_in)	     // Memory READ Output data
	);
	imem IM3 (
		.memAddr (node3_pc_out[21:29]),  // Memory Read Address (9-bit)
		.dataOut (node3_inst_in)	     // Memory READ Output data
	);

cmp DUT(clk, reset, 
		node0_inst_in, node0_d_in, node0_pc_out, node0_d_out, node0_addr_out, node0_memEn, node0_memWrEn, node0_addr_nic, node0_din_nic, node0_dout_nic, node0_nicEn, node0_nicWrEn, 
		node1_inst_in, node1_d_in, node1_pc_out, node1_d_out, node1_addr_out, node1_memEn, node1_memWrEn, node1_addr_nic, node1_din_nic, node1_dout_nic, node1_nicEn, node1_nicWrEn, 
		node2_inst_in, node2_d_in, node2_pc_out, node2_d_out, node2_addr_out, node2_memEn, node2_memWrEn, node2_addr_nic, node2_din_nic, node2_dout_nic, node2_nicEn, node2_nicWrEn, 
		node3_inst_in, node3_d_in, node3_pc_out, node3_d_out, node3_addr_out, node3_memEn, node3_memWrEn, node3_addr_nic, node3_din_nic, node3_dout_nic, node3_nicEn, node3_nicWrEn);

//	initial
//	begin
//     $sdf_annotate("../sdf/gold_cmp.sdf",DUT,,,"TYPICAL","1.0:1.0:1.0","FROM_MTM");
//    end
		
		
		// Clock Generation
	always #(`CYCLE_TIME /2) clk <= ~clk;

	// Cycle Counter
	always @(posedge clk) begin
		if(reset) 
			CycleNum <= 'd0;
		else 
			CycleNum <= CycleNum + 'd1;
	end
	
	initial begin
		$readmemh("imem0.fill", IM0.MEM);    // Loading Instruction Memory
		$readmemh("imem1.fill", IM1.MEM);    // Loading Instruction Memory
		$readmemh("imem2.fill", IM2.MEM);    // Loading Instruction Memory
		$readmemh("imem3.fill", IM3.MEM);    // Loading Instruction Memory
		
		$readmemh("dmem0.fill", DM0.MEM);    // Loading Data Memory
		$readmemh("dmem1.fill", DM1.MEM);    // Loading Data Memory
		$readmemh("dmem2.fill", DM2.MEM);    // Loading Data Memory
		$readmemh("dmem3.fill", DM3.MEM);    // Loading Data Memory
		clk <= 0;                          // Initialize Clock
		CycleNum <= 0;                     // Initialize				
		reset <= 1'b1;                     // Reset active
		repeat (10) @(negedge clk);         // Wait for CPU
		reset <= 1'b0;                     // Reset inactivated
		
		// How to check LAST INSTRUCTION
		// We would have a last Instruction NOP  => 32'h00000000
		//wait((((node0_inst_in == 32'h00000000)&(node1_inst_in == 32'h00000000)&(node2_inst_in == 32'h00000000)&(node3_inst_in == 32'h00000000))==1)||(CycleNum == 5000));
		wait((node0_inst_in == 32'h00000000)&&(node1_inst_in == 32'h00000000)&&(node2_inst_in == 32'h00000000)&&(node3_inst_in == 32'h00000000)||(CycleNum == 5000));
		//800;
		//how many cycles program took
		$display ("The Program Completed in %d cycles", CycleNum);
		// Let us now flush the pipeline
		repeat(10) @(negedge clk);
		// Open file to copy contents of data-memory
		dmem0_dump_file = $fopen("dmem0.dump");
		dmem1_dump_file = $fopen("dmem1.dump");
		dmem2_dump_file = $fopen("dmem2.dump");
		dmem3_dump_file = $fopen("dmem3.dump");
		// Dump all locations of data-memory to output file
		for (i=0; i<512;i=i+1) begin
			$fdisplay(dmem0_dump_file, "Memory Location #%3d: %h" , i, DM0.MEM[i]);
			$fdisplay(dmem1_dump_file, "Memory Location #%3d: %h" , i, DM1.MEM[i]);
			$fdisplay(dmem2_dump_file, "Memory Location #%3d: %h" , i, DM2.MEM[i]);
			$fdisplay(dmem3_dump_file, "Memory Location #%3d: %h" , i, DM3.MEM[i]);
		end
		$fclose(dmem0_dump_file);
		$fclose(dmem1_dump_file);
		$fclose(dmem2_dump_file);
		$fclose(dmem3_dump_file);
		$finish;
		
	end	
		 
	initial 
	begin
    	file_handle_gather = $fopen("gather.log"); 
		begin
			$fmonitor(file_handle_gather,   "At time = %d", $time,
											"\nPROC_0 outgoing packet - %h, PROC_0 incoming packet - %h", DUT.node0_din_nic, DUT.node0_dout_nic, 
											"\nPROC_1 outgoing packet - %h, PROC_1 incoming packet - %h", DUT.node1_din_nic, DUT.node1_dout_nic, 
											"\nPROC_2 outgoing packet - %h, PROC_2 incoming packet - %h", DUT.node2_din_nic, DUT.node2_dout_nic, 
											"\nPROC_3 outgoing packet - %h, PROC_3 incoming packet - %h\n", DUT.node3_din_nic, DUT.node3_dout_nic);
				
			$fmonitor(file_handle_gather, "\n At time %d ns, NIC 0: nicEn = %b, nicEnWr = %b, nicAddr = %h, nic_din = %h, nic_dout = %h", $time, DUT.node0_nicEn, DUT.node0_nicWrEn, DUT.node0_addr_nic, DUT.node0_din_nic, DUT.node0_dout_nic);
			$fmonitor(file_handle_gather, "\n At time %d ns, NIC 1: nicEn = %b, nicEnWr = %b, nicAddr = %h, nic_din = %h, nic_dout = %h", $time, DUT.node1_nicEn, DUT.node1_nicWrEn, DUT.node1_addr_nic, DUT.node1_din_nic, DUT.node1_dout_nic);
			$fmonitor(file_handle_gather, "\n At time %d ns, NIC 2: nicEn = %b, nicEnWr = %b, nicAddr = %h, nic_din = %h, nic_dout = %h", $time, DUT.node2_nicEn, DUT.node2_nicWrEn, DUT.node2_addr_nic, DUT.node2_din_nic, DUT.node2_dout_nic);
			$fmonitor(file_handle_gather, "\n At time %d ns, NIC 3: nicEn = %b, nicEnWr = %b, nicAddr = %h, nic_din = %h, nic_dout = %h", $time, DUT.node3_nicEn, DUT.node3_nicWrEn, DUT.node3_addr_nic, DUT.node3_din_nic, DUT.node3_dout_nic);
				
		end
	end
	
	
endmodule
