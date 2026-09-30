/*------------------------------------------------------------------------------
top block of arbiter_sl
*------------------------------------------------------------------------------*/

module arbiter_sl #(

	parameter slave_id       = 0,
	parameter NUM_OF_MASTERS = 4,
	parameter QUEUE_DEPTH    = 16,
	parameter CYCLES_S_TO_U  = 3

)
(
aclk,               //axi clk
aresetn,            //axi resetn

// AW channel
aw_data_in,         //aw data channel from router_ms
aw_ready_in,        //axi awready signal from slave
aw_patch_in,
aw_ready_out,       //awready signal to router_ms
aw_data_out,        //axi aw data channel to slave

// AR channel
ar_data_in,         //ar data channel from router_ms
ar_ready_in,        //axi arready signal from slave
ar_ready_out,       //arready signal to router_ms
ar_data_out,        //axi ar data channel to slave

// W channel
w_data_in,          //w data channel from router_ms
w_ready_in,         //axi wready signal from slave
w_ready_out,        //wready signal to router_ms
w_data_out,         //axi w data channel to slave

// from arbiter engine
grant               //grant signal from arbiter_engine
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;

input aw_bus [NUM_OF_MASTERS - 1 : 0] aw_data_in;
input ar_bus [NUM_OF_MASTERS - 1 : 0] ar_data_in;
input w_bus  [NUM_OF_MASTERS - 1 : 0] w_data_in;

input patch_t [NUM_OF_MASTERS - 1 : 0] aw_patch_in;

input [NUM_OF_MASTERS - 1 : 0] aw_ready_in;
input [NUM_OF_MASTERS - 1 : 0] ar_ready_in;
input [NUM_OF_MASTERS - 1 : 0] w_ready_in;

input [2:0][NUM_OF_MASTERS - 1 : 0] grant; 

//-----outputs-----
output logic aw_ready_out;
output logic ar_ready_out;
output logic w_ready_out;
output aw_bus aw_data_out;
output ar_bus ar_data_out;
output w_bus  w_data_out;

//-----logic-----
aw_bus aw_data_in_sel;  // the muxed logic from router_ms
logic  aw_ready_in_sel; // the muxed ready signal from router_ms
ar_bus ar_data_in_sel;  // the muxed logic from router_ms
logic  ar_ready_in_sel; // the muxed ready signal from router_ms
w_bus  w_data_in_sel;   // the muxed logic from router_ms
logic  w_ready_in_sel;  // the muxed ready signal from router_ms


//----- AW -----
//MUX
// TODO: grant is by index of bit it is not int value.
assign aw_data_in_sel  = aw_data_in[grant[0]];
assign aw_ready_in_sel = aw_ready_in[grant[0]];

//ROB
rob #(.BUS_TYPE(aw_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_aw_rob (
	.aclk       (aclk           ),
	.arstn      (aresetn        ),
	.data_in    (aw_data_in_sel ),
	//.patch_in   (patch_in       ),
	.push_enable(aw_ready_in_sel),
	.ready_out  (aw_ready_out   ),
	.data_out   (aw_data_out    )
	//.patch_out  (patch_out      ),
);

//----- AR -----
//MUX
assign ar_data_in_sel  = ar_data_in[grant[1]];
assign ar_ready_in_sel = ar_ready_in[grant[1]];

//ROB
rob #(.BUS_TYPE(ar_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_ar_rob (
	.aclk       (aclk           ),
	.arstn      (aresetn        ),
	.data_in    (ar_data_in_sel ),
	//.patch_in   (patch_in       ),
	.push_enable(ar_ready_in_sel),
	.ready_out  (ar_ready_out   ),
	.data_out   (ar_data_out    )
	//.patch_out  (patch_out      ),
);

//----- W -----
//MUX
assign w_data_in_sel  = w_data_in[grant[2]];
assign w_ready_in_sel = w_ready_in[grant[2]];

//ROB
rob #(.BUS_TYPE(w_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_w_rob (
	.aclk       (aclk          ),
	.arstn      (aresetn       ),
	.data_in    (w_data_in_sel ),
	//.patch_in   (patch_in      ),
	.push_enable(w_ready_in_sel),
	.ready_out  (w_ready_out   ),
	.data_out   (w_data_out    )
	//.patch_out  (patch_out     ),
);

endmodule