//testbench for axi_buffer
module patcher_ax_test;

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//----parameters-----
parameter type BUS_TYPE = ar_bus;
parameter NUM_OF_SLAVES=4;
parameter master_id=0;

//-----Initiazation-----
logic aclk;
logic aresetn;
logic cfg_en;
cfg_t cfg;
patch_t patch_out;
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
BUS_TYPE data_old;
initial
begin
	$fsdbDumpvars(0, patcher_ax_test);
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
	assert ( data_in == data_out &&
			patch_out == {get_slave(cfg,data_in.addr),master_id,is_urgent(data_in.qos),is_stream(data_in.qos)}) begin
		$display("test_2: PASS");
	end else begin
		$error("test_2: FAIL");
	end
	//======================================
	$display("test_3: pass with valid low ");
	data_old=data_in;
	data_in=rand_axi.get_random();
	#10
	assert (data_in != data_out && data_out.valid == 1'b0) begin
		$display("teset_3: PASS");
	end else begin
		$display("test_3: FAIL");
	end
	
	$display("test_4: pass with urgent bit");
	data_in = rand_axi.get_random();
	data_in.valid=1'b1;
	data_in.qos=2'b11;
	#10;
	assert (patch_out == {get_slave(cfg,data_in.addr),master_id,is_urgent(data_in.qos),is_stream(data_in.qos)}) begin
		$display("test_4: PASS");
	end else begin
		$display("test_4: FAIL - patch=%d expected= %d|%d|%d|%d",patch_out,get_slave(cfg,data_in.addr),master_id,is_urgent(data_in.qos),is_stream(data_in.qos));
	end
	$finish;
end


//----- helper functions
function int get_slave(input cfg_t cfg,input [31:0] addr);
	for(int i=0;i<NUM_OF_SLAVES;i=i+1) 
	begin
		if(cfg[i].low_addr<data_in.addr && cfg[i].high_addr>data_in.addr) 
		begin
			return i;
		end
	end
endfunction

function logic is_urgent(input [1:0] qos);
	
	if (qos ==2'b11) begin
		return 1;
	end
	return 0;
endfunction

function logic is_stream(input [1:0] qos);
	if (qos ==2'b10) 
		return 1;
	return 0;
endfunction

always #5 aclk = ~aclk;

endmodule