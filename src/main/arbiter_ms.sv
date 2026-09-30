/*------------------------------------------------------------------------------
top block of arbiter_ms
*------------------------------------------------------------------------------*/

module arbiter_ms #(

	parameter master_id     = 0,
	parameter NUM_OF_SLAVES = 3,
	parameter QUEUE_DEPTH = 16,
	parameter CYCLES_S_TO_U = 3

)
(
aclk,               //axi clk
aresetn,            //axi resetn

// B channel
b_data_in,          //b data channel from slave_router
b_ready_in,         //axi bready signal from master
b_data_out,         //axi b data channel to master
b_ready_out,        //bready signal to slave_router


// R channel
r_data_in,          //r data channel from slave_router
r_ready_in,         //axi rready signal from master
r_ready_out,        //rready signal to slave_router
r_data_out,         //axi r data channel to master

// from arbiter engine
grant               //grant signal from arbiter_engine
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;
input b_bus [NUM_OF_SLAVES - 1 : 0] b_data_in;
input r_bus [NUM_OF_SLAVES - 1 : 0] r_data_in;
input [NUM_OF_SLAVES - 1 : 0] b_ready_in;
input [NUM_OF_SLAVES - 1 : 0] r_ready_in;
input [1:0][NUM_OF_SLAVES -1 : 0] grant;

//-----outputs-----
output logic b_ready_out;
output logic r_ready_out;
output b_bus b_data_out;
output r_bus r_data_out;

//-----logic-----
b_bus b_data_in_sel; // the muxed logic from router_sl
logic b_ready_in_sel; // the muxed ready signal from router_sl
r_bus r_data_in_sel; // the muxed logic from router_sl
logic r_ready_in_sel; // the muxed ready signal from router_sl


//----- B -----
//MUX
assign b_data_in_sel = b_data_in[grant[0]];
assign b_ready_in_sel = b_ready_in[grant[0]];

//ROB
rob #(.BUS_TYPE(b_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_b_rob (
	.aclk       (aclk          ),
	.aresetn    (aresetn       ),
	.data_in    (b_data_in_sel ),
	//.patch_in   (patch_in      ),
	.push_enable(b_ready_in_sel),
	.ready_out  (b_ready_out   ),
	.data_out   (b_data_out    ),
	//.patch_out  (patch_out     ),
	.pop_enable  (pop_enable   )
);
//----- R -----
//MUX

assign r_data_in_sel = r_data_in[grant[1]];
assign r_ready_in_sel = r_ready_in[grant[1]];

//ROB
rob #(.BUS_TYPE(r_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_r_rob (
	.aclk       (aclk          ),
	.aresetn    (aresetn       ),
	.data_in    (r_data_in_sel ),
	//.patch_in   (patch_in      ),
	.push_enable(r_ready_in_sel),
	.ready_out  (r_ready_out   ),
	.data_out   (r_data_out    ),
	//.patch_out  (patch_out     ),
	.pop_enable  (pop_enable   )
);

endmodule