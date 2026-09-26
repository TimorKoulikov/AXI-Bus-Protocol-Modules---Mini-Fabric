/*------------------------------------------------------------------------------
top block of router_sl
*------------------------------------------------------------------------------*/

module router_sl #(

	parameter slave_id       = 0,
	parameter NUM_OF_MASTERS = 4,
	parameter token_width    = 30

)
(
	aclk,               //axi clk
	aresetn,            //axi resetn
	
	// B channel
	b_data_channel,     //axi b data channel from slave
	b_ready_out,        //axi bready signal to slave
	b_ready_in,         //bready signal from arbiter_ms
	b_data_out,         //b data channel to arbiter_ms
	
	// R channel
	r_data_channel,     //axi r data channel from slave
	r_ready_out,        //axi rready signal to slave
	r_ready_in,         //rready signal from arbiter_ms
	r_data_out,         //r data channel to arbiter_ms
	
	// configuration
	cfg,                //cfg to patcher
	cfg_en,             //cfg enable signal
	
	// from/to arbiter_engine & router_control
	start_transaction,
	end_transaction,
	token_allocation,
	bw,
	is_urgent
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;
input b_bus b_data_channel;
input r_bus r_data_channel;
input [NUM_OF_MASTERS - 1 : 0] b_ready_in;
input [NUM_OF_MASTERS - 1 : 0] r_ready_in;
input cfg_t cfg;
input cfg_en;
input [1:0] start_transaction;
input [1:0][token_width - 1 : 0] token_allocation;

//-----outputs-----
output b_ready_out;
output r_ready_out;
output b_bus [NUM_OF_MASTERS - 1 : 0] b_data_out;
output r_bus [NUM_OF_MASTERS - 1 : 0] r_data_out;
output [1:0] end_transaction;
output [1:0] is_urgent;
output [1:0][token_width - 1 : 0] bw;


//router_control
router_control #(.NUM_OF_CHANNEL(2)) u_router_control (
	.aclk             (aclk             ),
	.aresetn          (aresetn          ),
	.start_transaction(start_transaction),
	.end_transaction  (end_transaction  ),
	.token_allocation (token_allocation ),
	.bw               (bw               ),
	.push             (push             ),
	.pop              (pop              ),
	.is_urgent_in     (is_urgent_in     ),
	.full             (full             ),
	.empty            (empty            ),
	.is_stream        (is_stream        ),
	.is_urgent_out    (is_urgent_out    )
);

//----- B -----

//ROB

//InputB -> ROB -> outputB


//----- R -----

//ROB

//InpurR -> ROB -> outputR

endmodule