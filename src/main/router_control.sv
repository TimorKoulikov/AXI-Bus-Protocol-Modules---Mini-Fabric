/*------------------------------------------------------------------------------
 * File          : router_control.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 26, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module router_control (
aclk,
aresetn,
start_transaction,
end_transaction,
token_allocation,
bw,
push,
pop,
is_urgent,
full,
empty,
is_stream
);

//-----parameter-----
parameter NUM_OF_CHANNEL=3;

localparam token_width = 30;
//-----inputs-----
input aclk;
input aresetn;
input [NUM_OF_CHANNEL -1 : 0] start_transaction;
input [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_allocation;

//----- inputs from ROB
input [NUM_OF_CHANNEL -1 : 0] push;
input [NUM_OF_CHANNEL -1 : 0] pop;
input [NUM_OF_CHANNEL -1 : 0] empty;
input [NUM_OF_CHANNEL -1 : 0] full;
input [NUM_OF_CHANNEL -1 : 0] is_urgent;
input [NUM_OF_CHANNEL -1 : 0] is_stream;

//-----output-----
output [NUM_OF_CHANNEL -1 : 0] end_transaction;
output [NUM_OF_CHANNEL -1 : 0] bw;

//-----logic-----
wire [token_width - 1 ] curr_num_of_tokens;
wire [token_width - 1 ] new_num_of_tokens;
wire leak;
wire tercent;

DW01_add #(token_width)
token_adder (.A(num_of_tokens), .B(token_allocation[0]),.SUM(new_num_of_tokens));

leaky_bucket #(.MAX_TOKEN(100)) 
		counter_token(
			.aclk(aclk),
			.aresetn(aresetn),
			.data(new_num_of_tokens),
			.count(curr_num_of_tokens),
			.loadn(~start_transaction[0]),
			.tercent(tercent),
			.leak(leak)
);


endmodule