/*------------------------------------------------------------------------------
top block of arbiter_ms
*------------------------------------------------------------------------------*/

module arbiter_ms #(
	parameter int master_id     = 0,
	parameter int NUM_OF_SLAVES = 3,
	parameter int QUEUE_DEPTH   = 16,
	parameter int CYCLES_S_TO_U = 3
)
(
	input  logic                                aclk,         // axi clk
	input  logic                                aresetn,      // axi resetn

	// B channel
	input  b_bus   [NUM_OF_SLAVES - 1 : 0]      b_data_in,    // b data channel from slave_router
	input  logic     						    b_ready_in,   // axi bready signal from master
	input  patch_t [NUM_OF_SLAVES - 1 : 0]      b_patch_in,   // patched metadata from slave_router
	output b_bus                                b_data_out,   // axi b data channel to master
	output logic   [NUM_OF_SLAVES - 1 : 0]      b_ready_out,  // bready signal to slave_router

	// R channel
	input  r_bus   [NUM_OF_SLAVES - 1 : 0]      r_data_in,    // r data channel from slave_router
	input  logic         						r_ready_in,   // axi rready signal from master
	input  patch_t [NUM_OF_SLAVES - 1 : 0]      r_patch_in,   // patched metadata from slave_router
	output r_bus                                r_data_out,   // axi r data channel to master
	output logic   [NUM_OF_SLAVES - 1 : 0]      r_ready_out,  // rready signal to slave_router

	// from arbiter engine
	input  logic   [1:0][NUM_OF_SLAVES - 1 : 0] grant         // grant signal from arbiter_engine
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;


//-----logic-----
b_bus b_data_in_sel; // the muxed logic from router_sl
r_bus r_data_in_sel; // the muxed logic from router_sl

patch_t b_patch_in_sel;
patch_t r_patch_in_sel;


//----- B -----
//MUX
assign b_data_in_sel = b_data_in[grant[0]];
assign b_patch_in_sel = b_patch_in[grant[0]];

//ROB
rob #(.BUS_TYPE(b_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_b_rob (
	.aclk       (aclk       		),
	.aresetn    (aresetn      		),
	.data_in    (b_data_in_sel    	),
	.patch_in   (b_patch_in_sel   	),
	.push_enable(b_ready_in			),
	.ready_out  (b_ready_out  		),
	.data_out   (b_data_out   		),
	//.patch_out  (b_rob_patch_out  	),
	.pop_enable ('1		        	),
	.ready_in(b_ready_in			)
);

//output
//assign b_data_out.id = {id,b_rob_patch_out.slave_id,b_rob_patch_out.master_id};

//----- R -----
//MUX

assign r_data_in_sel = r_data_in[grant[1]];
assign r_patch_in_sel = r_patch_in[grant[1]];
//ROB
rob #(.BUS_TYPE(r_bus), .QUEUE_DEPTH(QUEUE_DEPTH), .CYCLES_S_TO_U(CYCLES_S_TO_U)) u_r_rob (
	.aclk       (aclk       		),
	.aresetn    (aresetn      		),
	.data_in    (r_data_in_sel    	),
	.patch_in   (r_patch_in_sel   		),
	.push_enable(r_ready_in			),
	.ready_out  (r_ready_out  		),
	.data_out   (r_data_out   		),
	//.patch_out  (r_rob_patch_out 	),
	.pop_enable ('1        			),
	.ready_in(r_ready_in)
);
//output
//assign r_data_out.id = {id,r_rob_patch_out.slave_id,r_rob_patch_out.master_id};


endmodule