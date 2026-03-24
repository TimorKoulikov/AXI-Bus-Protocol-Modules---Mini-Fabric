
// flags
-sverilog

// packages 
./src/resources/axi_datatypes.sv
./src/resources/fabric_datatypes.sv
//$SNPS_SYN/dw/*

//rtl source code
./src/main/leaky_bucket.sv 
./src/main/axi_buffer.sv
./src/main/patcher_ax.sv
./src/main/patcher_w.sv

// test bench
./src/test/axi_buffer_test.sv
./src/test/patcher_ax_test.sv
./src/test/patcher_w_test.sv
./src/test/leaky_bucket_test.sv