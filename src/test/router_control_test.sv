/*------------------------------------------------------------------------------
 * File          : router_control_test.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 27, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module router_control_test ();

//----- parameter
parameter NUM_OF_CHANNEL=3;

localparam token_width = 30;
//-----inputs-----
logic aclk;
logic aresetn;
logic [NUM_OF_CHANNEL -1 : 0] start_transaction;
logic [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_allocation;

//----- inputs from ROB
logic [NUM_OF_CHANNEL -1 : 0] push;
logic [NUM_OF_CHANNEL -1 : 0] empty;
logic [NUM_OF_CHANNEL -1 : 0] full;
logic [NUM_OF_CHANNEL -1 : 0] is_urgent_in;
logic [NUM_OF_CHANNEL -1 : 0] is_stream;

//-----output-----
logic [NUM_OF_CHANNEL -1 : 0] end_transaction;
logic [NUM_OF_CHANNEL -1 : 0] pop;
logic [NUM_OF_CHANNEL -1 : 0] bw;
logic [NUM_OF_CHANNEL -1 : 0] is_urgent_out;

router_control #(.NUM_OF_CHANNEL(NUM_OF_CHANNEL)) router_control_uut
(
	,aclk(aclk),
	.aresetn(aresetn),
	,start_transaction,
	end_transaction,
	token_allocation,
	bw,
	push,
	pop,
	is_urgent_in,
	full,
	empty,
	is_stream,
	is_urgent_out
	);



//-----testbanch
initial
begin
		$display("init rounter_control_test");
		
		$display("test_1: fsm");
		
		$display("test_2: leaky counter - add new token");
		
		$display("test_3: leaky counter - check token leakge");
		
		$display("test_4: full transaction");
		
		$finish;
end

always #5 aclk=~aclk;
endmodule