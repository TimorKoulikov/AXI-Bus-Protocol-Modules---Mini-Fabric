// packages
//flag only for euclide. no need for vcs
-y $SYNOPSYS_SYN_ROOT/dw/sim_ver/ 
./src/resources/axi_datatypes.sv
./src/resources/fabric_datatypes.sv

//rtl source code
//./src/main/leaky_bucket.sv 
main/axi_buffer.sv
main/patcher_ax.sv
main/patcher_w.sv	// unimplemented
main/rob.sv			// unimplemented 
main/token_counter.sv
main/router_control.sv
main/arbiter_rr.sv
//src/main/router_ms.sv
main/arbiter_engine.sv


// test bench
//src/test/axi_buffer_test.sv
//src/test/patcher_ax_test.sv
src/test/router_control_test.sv
// arbiter_rr test is only Waveform
./src/test/arbiter_rr_test.sv