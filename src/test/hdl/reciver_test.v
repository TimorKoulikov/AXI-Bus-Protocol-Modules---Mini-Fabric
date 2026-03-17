module reciver_test;

class Rand;
	rand logic [31:0] random_data;
	
	constraint c_data {random_data[0] == 0;}
endclass

Rand randobj = new();

import axi_datatypes::*;

logic aclk,aresetn,valid_out;
logic [31:0] data_in;
logic [31:0] data_out;

reciver #(aw_bus) rc(
						.aclk(aclk),
						.aresetn(aresetn),
						.data_in(data_in),
						.data_out(data_out),
						.valid_out(valid_out));


logic [31:0] data_old;
initial
begin
	$display("init test reciver_test");
	aclk = 1'b0; data_in=31'b0;
	aresetn=1'b1;
	#10
	$display("test_1: check data pass when valid is high");
	randobj.randomize();
	data_in=randobj.random_data;
	data_in[0]=1'b1;
	data_old=data_in;
	#10
	assert(data_in==data_out) begin
		$display("test_1: PASS");
	end else begin
		$error("test_1: FAIL");
	end
	#10
	$display("test_2: check data dont pass when valid is low");
	
	randobj.randomize();
	data_in=randobj.random_data;
	#10
	assert(data_in!=data_out && data_out == data_old) begin
		$display("test_2: PASS");
	end else begin
		$error("test_2: FAIL");
	end
	#30
	$finish;
end

always #10 aclk = ~aclk;


endmodule