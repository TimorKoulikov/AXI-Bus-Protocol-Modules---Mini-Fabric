-sverilog
+libext+.v 
-y $SYNOPSYS_SYN_ROOT/dw/sim_ver/ 
// ./src/resources/axi_datatypes.sv
// ./src/resources/axi_if.sv
// ./src/resources/fabric_datatypes.sv

// test bench
/*arbiter engine test*/
src/test/arbiter_rr_test.sv // is only a Waveform
src/test/axi_buffer_test.sv
/*leacky_bucket_test  -   do we need it?*/ 
src/test/patcher_ax_test.sv
/*patcher_w test*/
src/test/router_control_test.sv
