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
