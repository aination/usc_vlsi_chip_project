####################################################################################
#
# EE-577b - Fall 2016
# LAB#2 part 1
# DesignCompiler synthesis script for a FSM
#
# use this script as a template for synthesis
#
####################################################################################

# Setting variables for synthesis
set design_name cmp;
set clk_period 10.6;
set posedge 0.0;
set negedge [expr $clk_period * 0.5];

# Reading source verilog file.
# Copy your verilog file into ./src/ before synthesis.
#read_verilog ./design/gold_router.v;
#read_verilog ./design/gold_ring.v ;
#read_verilog ./design/nic.v;
#read_verilog ./design/alu.v;
#read_verilog ./design/cpu.v;
read_verilog ./design/gold_cmp.v;

# Setting $design_name as current working design.
# Use this command before setting any constraints.
current_design $design_name ;

# If you have multiple instances of the same module,
# use this so that DesignCompiler optimize each instance separately
uniquify ;

# Linking your design into the cells in standard cell libraries.
# This command checks whether your design can be compiled
# with the target libraries specified in the .synopsys_dc.setup file.
link ;

# Setting timing constraints for sequential logic.
# => clock period, input delay, output delay

# (1) Setting clock period.
create_clock -name "CLK" -period $clk_period -waveform [list $posedge $negedge] [get_ports CLK];

# (2) Setting additional constraints for clock signal,
# so that clock network should be ideal network without any buffers.
set_dont_touch_network CLK ;
set_ideal_network CLK ;

# (3) Setting input path delays on input ports(except clock) relative to a clock edge .
# Input signals will arrive after this delay.
set_input_delay 1.0 -max -clock CLK [remove_from_collection [all_inputs] [get_ports "CLK"]] ;

# (4) Setting output path delays on output ports relative to a clock edge.
# output signals should be generated before this delay.
set_output_delay 1.0 -clock CLK [all_outputs] ;

set_max_area 0
# "check_design" checks the internal representation of the
# current design for consistency and issues error and
# warning messages as appropriate.
check_design > reports/$design_name.check_design ;

# Performing synthesis and optimization on the current_design.
#compile -map_effort high -incremental_mapping;
#compile -map_effort high -area_effort high;
compile -map_effort high;

# For better synthesis result, use "compile_ultra" command.
# compile_ultra is doing automatic ungrouping during optimization,
# therefore sometimes it's hard to figure out the critical path 
# from the synthesized netlist.

# Writing the synthesis result into Synopsys dcc format
# You can read the saved ddc file into DesignCompiler later using
# write -format ddc -hierarchy -out db/$design_name.ddc ;

# Generating timing and are report of the synthezied design.
report_timing > reports/$design_name.timing ;
report_area > reports/$design_name.area ;

# Writing synthesized gate-level verilog netlist.
# This verilog netlist will be used for post-synthesis gate-level simulation.
change_names -rules verilog -hierarchy ;
write -format verilog -hierarchy -out netlist/$design_name.syn.v ;

# Writing Standard Delay Format (SDF) back-annotation file.
# This delay information can be used for post-synthesis simulation.
write_sdf sdf/$design_name.sdf;
write_sdc sdc/$design_name.sdc;
