//testbench for axi_buffer
module patcher_ax_test;

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//----parameters-----
parameter type BUS_TYPE = aw_bus;
parameter NUM_OF_SLAVES=4;
parameter master_id=0;

//-----Initiazation-----
logic aclk;
logic aresetn;
logic cfg_en;
logic [NUM_OF_SLAVES - 1:0][1:0][ADDR_WIDTH - 1:0] cfg;
BUS_TYPE data_in;
BUS_TYPE data_out;
patcher_ax #(.BUS_TYPE(BUS_TYPE), .master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES))
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

//-----testbench-----

// creating objects for random data
RAND_CFG rand_cfg = new();
RAND_AXI#(.BUS_TYPE(BUS_TYPE)) rand_axi = new();
initial
begin
	$display("init test patcher_ax");
	aclk=1'b0;
	aresetn=1'b1;
	cfg_en=1'b0;	
	#10
	//======================================
	$display("test_1:config successfull cfg");
	cfg=rand_cfg.get_random();
	cfg_en=1'b1;
	#10
	cfg_en=1'b0;
	#10
	assert( dut_patcher_ax.cfg_reg == cfg) begin
		$display("test_1: PASS");
	end else begin
		$error("test_1: FAIL");
	end 
	//======================================
	$display("test_2:pass with valid high");
	data_in=rand_axi.get_random();
	data_in.valid=1'b1;
	#10
	assert ( data_in == data_out) begin
		$display("test_2: PASS");
	end else begin
		$error("test_2: FAIL");
	end
	//======================================
	//not implamented 
	$display("test_3: pass with valid low ");
	$finish;
end


always #10 aclk = ~aclk;

endmodule