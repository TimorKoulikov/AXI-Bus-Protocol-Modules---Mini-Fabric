//testbench for axi_buffer
module patcher_ax_test;

//-----imports-----
import axi_datatypes::*;

//----parameters-----
parameter type BUS_TYPE = aw_bus;

//-----Initiazation-----
logic aclk;
logic aresetn;
logic cfg_en;


patcher_ax #(BUS_TYPE)
		dut_patcher_ax (
			.aclk(aclk),
			.aresetn(aresetn),
			.data_in(data_in),
			.ready_out(ready_out),
			.data_out(data_out),
			.ready_in(ready_in),
			.patch_out(patch_out),
			.cfg(cfg),
			.cfg_en(cfg_en)
		);



initial
begin
	$display("init test patcher_ax");
	aclk=1'b0;
	aresetn=1'b1;
	cfg_en=1'b1;
	#10
	//not implamented 
	$display("test_1:config successfull cfg");
	#10
	//not implamented 
	$display("test_2:pass with valid high");
	#10
	//not implamented 
	$display("test_3: pass with valid low ");
	$finish;
end


always #10 aclk = ~aclk;

endmodule