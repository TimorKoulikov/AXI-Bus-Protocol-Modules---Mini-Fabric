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

localparam token_width = 31;
//-----inputs-----
logic aclk;
logic aresetn;
logic [NUM_OF_CHANNEL -1 : 0] start_transaction;
logic [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_allocation;
logic [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_for_transaction;
logic [NUM_OF_CHANNEL -1 : 0] ready_for_transaction;

//----- inputs from ROB
logic [NUM_OF_CHANNEL -1 : 0] empty;
logic [NUM_OF_CHANNEL -1 : 0] full;
logic [1:0] mode;
//-----output-----
logic [NUM_OF_CHANNEL -1 : 0] end_transaction;
logic [NUM_OF_CHANNEL -1 : 0] pop;

router_control #(.NUM_OF_CHANNEL(NUM_OF_CHANNEL)) router_control_uut
(
	.aclk(aclk),
	.aresetn(aresetn),
	.start_transaction(start_transaction),
	.end_transaction(end_transaction),
	.token_allocation(token_allocation),
	.pop(pop),
	.full(full),
	.empty(empty),
	.token_for_transaction(token_for_transaction),
	.ready_for_transaction(ready_for_transaction),
	.mode(mode)
	);




//-----testbanch -----
int i = $urandom_range(NUM_OF_CHANNEL - 1, 0);
int tokens;
int old_tokens;
initial
begin
		$fsdbDumpvars(0, router_control_test);
		$display("init rounter_control_test");
		aclk=1'b0;
		aresetn=1'b0;
		start_transaction='0;
		token_allocation='0;
		empty='0;
		full='0;
		mode=2'b0;
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
		$display("test_2: adding token");
			start_transaction[i]=1'b1;
			tokens = $random();
			token_allocation[i] = tokens;
		#20
				assert( router_control_uut.curr_num_tokens[i] == token_allocation[i]) begin
					$display("test_2: PASS");
				end else begin
					$display("test_2: FAIL");
				end
			//--------------------------------------------------
			
			$display("test_3: twice remove tokens");
		#20;
			token_for_transaction[i] = tokens / 3;
			$display("token_for_transaction =%d",token_for_transaction[i]);
			#10;
			ready_for_transaction[i]=1'b1;
			#10;
			assert(router_control_uut.curr_num_tokens[i] == tokens - token_for_transaction[i]) begin
				$display("test_3: PASS [1/2]");
			end else begin
				$display("test_3: FAIL [1/2]");
			end
			
			#10;			
			assert(router_control_uut.curr_num_tokens[i] == tokens - token_for_transaction[i] -token_for_transaction[i]) begin
				$display("test_3: PASS [2/2]");
			end else begin
				$display("test_3: FAIL [2/2]");
			end
			//---------------------------
			$display("test_4: testing mode=LEAKY");
			mode=2'b01;
			while(end_transaction[i] == 1'b0) begin
			#10;
				if(end_transaction[i] == 1'b1 )
					break;
			end
			old_tokens = router_control_uut.curr_num_tokens[i];
			ready_for_transaction[i]=1'b0;
			start_transaction[i]=1'b1;
			tokens = $random();
			token_allocation[i] = tokens;
			#20;
				assert( router_control_uut.curr_num_tokens[i] == old_tokens + tokens) begin
					$display("test_4: PASS");
				end else begin
					$display("test_4: FAIL. result = %d expected %d",router_control_uut.curr_num_tokens[i],old_tokens + tokens);
				end

		$finish;
end

always #5 aclk=~aclk;
endmodule