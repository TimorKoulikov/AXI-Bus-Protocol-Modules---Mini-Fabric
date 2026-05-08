// packages
//flag only for euclide. no need for vcs
-y $SYNOPSYS_SYN_ROOT/dw/sim_ver/ 
./src/resources/axi_datatypes.sv
./src/resources/axi_if.sv
./src/resources/fabric_datatypes.sv

//rtl source code
//./src/main/leaky_bucket.sv 
src/main/axi_buffer.sv
src/main/patcher_ax.sv
src/main/patcher_w.sv	// unimplemented
src/main/rob.sv			// unimplemented 
src/main/token_counter.sv
src/main/router_control.sv
src/main/arbiter_rr.sv
//src/main/router_ms.sv
src/main/arbiter_engine.sv
src/top_block.sv
