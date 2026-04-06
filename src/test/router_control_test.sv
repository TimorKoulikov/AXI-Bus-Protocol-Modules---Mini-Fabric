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
	.aclk(aclk),
	.aresetn(aresetn),
	.start_transaction(start_transaction),
	.end_transaction(end_transaction),
	.token_allocation(token_allocation),
	.bw(bw),
	.push(push),
	.pop(pop),
	.is_urgent_in(is_urgent_in),
	.full(full),
	.empty(empty),
	.is_stream(is_stream),
	.is_urgent_out(is_urgent_out)
	);



//-----testbench
int i=$urandom_range(NUM_OF_CHANNEL - 1, 0);

initial
begin
		$display("init rounter_control_test");
		aclk=1'b0;
		aresetn=1'b1;
		start_transaction='0;
		token_allocation='0;
		push='0;
		empty='0;
		full='0;
		is_urgent_in='0;
		is_stream='0;
		#10
		aresetn=1'b0;
		#10
		aresetn=1'b1;
		//----------------------------------------------------
		$display("test_1: fsm");
		start_transaction[i]=1'b1;
		#10
		assert( router_control_uut.curr_state[i] == router_control_uut.TRANSACTION_ADD_TOKENS) begin
			$display("IDLE->TRANSACTION_ADD_TOKENS PASS");
		end else begin
			$display("IDEL->TRANSACTION_ADD_TOKENS FAIL");
		end
		#10
		assert( router_control_uut.curr_state[i] == router_control_uut.TRANSACTION_POP_TOKENS) begin
			$display("TRANSACTION_ADD_TOKENS->TRANSACTION_POP_TOKENS PASS");
		end else begin
			$display("TRANSACTION_ADD_TOKENS->TRANSACTION_POP_TOKENS FAIL");
		end	
		full[i]=1'b1;
		#10
		full[i]=1'b0;
		assert( router_control_uut.curr_state [i]== router_control_uut.IDLE) begin
			$display("TRANSACTION->IDLE PASS");
		end else begin
			$display("TRANSACTION->IDLE FAIL");
		end
		
			aresetn=1'b0;
		#10
			aresetn=1'b1;
		//----------------------------------------------------------
		$display("test_2: leaky counter - add new token");
			start_transaction[i]=1'b1;
			token_allocation[i]=$random();
		#20
				assert( router_control_uut.curr_num_of_tokens[i] == token_allocation[i]) begin
					$display("test_2: PASS");
				end else begin
					$display("test_3: FAIL %d",router_control_uut.curr_num_of_tokens[i]);
				end
			//--------------------------------------------------
			
			$display("test_3: leaky counter - check token leakge");
		#50
			assert(router_control_uut.curr_num_of_tokens[i] == token_allocation[i] - 30'd5) begin
				$display("test_3: PASS");
			end else begin
				$display("test_3: FAIL, result :%d expected: %d",router_control_uut.curr_num_of_tokens[i],token_allocation[i] - 5	);
			end
		$finish;
end

always #5 aclk=~aclk;
endmodule