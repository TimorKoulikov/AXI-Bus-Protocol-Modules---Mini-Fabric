/*------------------------------------------------------------------------------
 * File          : patcher_w_test.sv
 * Project       : AXI Mini Fabric
 * Description   : Testbench for the W-channel patcher and AW-to-W dependency queue
 *------------------------------------------------------------------------------*/

module patcher_w_test;

//----- imports -----
import axi_datatypes::*;
import fabric_datatypes::*;

//----- parameters -----
parameter master_id = 0;
parameter NUM_OF_SLAVES = 3;
parameter QUEUE_DEPTH = 16;

//----- signals -----
logic aclk;
logic aresetn;

// W Channel input (Facing upstream Master)
w_bus data_in;
logic ready_out;

// W Channel Output (Facing downstream ROB)
w_bus data_out;
logic ready_in;
patch_t patch_out;

// AW-to-W Queue synchronization ports
patch_t patch_in;
logic   patch_valid;

//----- DUT Instantiation -----
patcher_w #(
	.master_id(master_id), 
	.NUM_OF_SLAVES(NUM_OF_SLAVES), 
	.QUEUE_DEPTH(QUEUE_DEPTH)
) dut_patcher_w (
	.aclk       (aclk),
	.aresetn    (aresetn),
	.data_in    (data_in),
	.ready_in   (ready_in),
	.patch_in   (patch_in),
	.patch_valid(patch_valid),
	.data_out   (data_out),
	.ready_out  (ready_out),
	.patch_out  (patch_out)
);

//----- Testbench Logic -----
RAND_AXI #(.BUS_TYPE(w_bus)) rand_axi = new();

initial 
begin
	$fsdbDumpvars(0, patcher_w_test);
	$display("init test patcher_w");
	
	// Initialize
	aclk = 1'b0;
	aresetn = 1'b0; // active low reset
	data_in = '0;
	ready_in = 1'b0; // ROB not ready 
	patch_in = '0;
	patch_valid = 1'b0;
	
	#15 aresetn = 1'b1;
	#10;
	
	//======================================
	$display("test_1: Queue Empty Backpressure");
	// If there is no routing tag in the queue, patcher_w MUST not accept W data
	data_in = rand_axi.get_random();
	data_in.valid = 1'b1;
	#10;
	assert(ready_out == 1'b0) begin
		$display("test_1: PASS (ready_out correctly blocked when tag-queue is empty)");
	end else begin
		$error("test_1: FAIL");
	end 
	
	//======================================
	$display("test_2: Push Tag to Queue (AW-W Handshake Simulation)");
	// Simulate patcher_aw sending a routing tag for Slave 2
	patch_in.slave_id = 2;
	patch_in.master_id = master_id;
	patch_in.urgent = 1'b1;
	patch_in.stream = 1'b0;
	patch_valid = 1'b1;
	ready_in = 1'b1; // ROB is ready 
	
	#10; 
	// drop valid after one clock cycle
	patch_valid = 1'b0; 
	
	// wait one more clock cycle for the ready_out flip-flop to update
	#10;
	
	// now when queue has data, ready_out should go high
	assert(ready_out == 1'b1) begin
		$display("test_2: PASS (Queue accepted tag; unblocked W channel)");
	end else begin
		$error("test_2: FAIL");
	end
	
	//======================================
	$display("test_3: Data Beat 1 (wlast = 0)");
	data_in = rand_axi.get_random();
	data_in.valid = 1'b1;
	data_in.wlast = 1'b0; // not the last
	ready_in = 1'b1;      // downstream (ROB) is ready
	#10;
	
	assert(data_out.wdata == data_in.wdata && patch_out.slave_id == 2 && patch_out.urgent == 1'b1) begin
		$display("test_3: PASS (Data transferred, tag correctly appended)");
	end else begin
		$error("test_3: FAIL");
	end
	
	//======================================
	$display("test_4: Data Beat 2 (wlast = 1) -> Queue Pop");
	data_in = rand_axi.get_random();
	data_in.valid = 1'b1;
	data_in.wlast = 1'b1; // Final beat of the burst
	#10;
	
	assert(data_out.wdata == data_in.wdata && patch_out.slave_id == 2 && patch_out.urgent == 1'b1) begin
		$display("test_4: PASS (Final data beat transferred with exact same tag)");
	end else begin
		$error("test_4: FAIL");
	end
	
	//======================================
	$display("test_5: Verify Queue successfully Popped");
	// Clear data inputs
	data_in.valid = 1'b0;
	#10;
	
	// Because the last beat popped the tag queue, it should now be empty.
	// Consequently, the module should instantly raise backpressure (ready_out = 0)
	assert(ready_out == 1'b0) begin
		$display("test_5: PASS (Queue properly popped on wlast, backpressure restored)");
	end else begin
		$error("test_5: FAIL (Tag queue did not pop on wlast)");
	end
	
	$finish;
end

always #5 aclk = ~aclk;

endmodule