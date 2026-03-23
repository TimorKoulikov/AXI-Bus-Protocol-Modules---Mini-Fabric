//testbench for axi_buffer
module axi_buffer_test_test;


//-----imports-----
import axi_datatypes::*;

//----parameters-----
parameter type BUS_TYPE = aw_bus;

//-----Initiazation-----
logic aclk,aresetn;
logic ready_in,ready_out;
BUS_TYPE data_in;
BUS_TYPE data_out;
BUS_TYPE data_old;
axi_buffer #(BUS_TYPE) axi_buffer_uut(
						.aclk(aclk),
						.aresetn(aresetn),
						.data_in(data_in),
						.data_out(data_out),
						.ready_in(ready_in),
						.ready_out(ready_out));




//-----testbanch-----
Rand_AXI#(BUS_TYPE) random = new();

initial
begin
	$display("init test reciver_test");
	aclk = 1'b0;
	aresetn=1'b1;
	ready_in=1'b1;
	data_in={0};
	#10
	$display("test_1: check data pass when valid is high");
	data_in=random.get_random();
	data_in.valid=1'b1;	
	#10
	assert(data_in==data_out) begin
		$display("test_1: PASS");
	end else begin
		$error("test_1: FAIL");
	end
	$display("test_2: check data dont pass when valid is low");
	data_old=data_in;
	data_in=random.get_random();
	#10
	assert(data_in!=data_out && data_out == data_old) begin
		$display("test_2: PASS");
	end else begin
		$error("test_2: FAIL");
	end
	$display("teset_3: check if ready_in is low so ready_out is low");
	ready_in=1'b0;
	#10
	assert(ready_out==1'b0) begin
		$display("test_3: PASS");
	end else begin
		$error("test_3: FAIL");
	end
	$finish;
end

always #10 aclk = ~aclk;


endmodule