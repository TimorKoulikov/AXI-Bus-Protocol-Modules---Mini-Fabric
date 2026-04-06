
// flags
-sverilog
+incdir+$SYNOPSYS_SYN_ROOT/dw/sim_ver/
+libext+.v 
// packages
//flag only for euclide. no need for vcs
-y $SYNOPSYS_SYN_ROOT/dw/sim_ver/ 
./src/resources/axi_datatypes.sv
./src/resources/fabric_datatypes.sv

//rtl source code
//./src/main/leaky_bucket.sv 
src/main/axi_buffer.sv
src/main/patcher_ax.sv
src/main/patcher_w.sv	// unimplemented
src/main/rob.sv			// unimplemented 
src/main/router_control.sv
src/main/arbiter_rr.sv
src/main/router_ms.sv
src/main/arbiter_engine.sv

// test bench
src/test/axi_buffer_test.sv
src/test/patcher_ax_test.sv
src/test/router_control_test.sv
// arbiter_rr test is only Waveform
./src/test/arbiter_rr_test.sv




//Alex: I will delete it when finish learning SV
drafts/arbiter_2inpt_lowprior.sv
drafts/arbiter_2inpt_lowprior_tb.sv