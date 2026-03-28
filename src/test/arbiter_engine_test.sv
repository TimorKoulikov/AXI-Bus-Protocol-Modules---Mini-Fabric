/*------------------------------------------------------------------------------
test_banch or arbiter_engine.
no binary verification. common i dont have time for this. just open wavelog
 *------------------------------------------------------------------------------*/

module arbiter_engine_test ();

//----parameters-----
parameter NUM_OF_MASTERS = 3;

//-----initaliztion-----
logic aclk;
logic aresetn;
logic [NUM_OF_MASTERS - 1 : 0] is_urgent;
logic [NUM_OF_MASTERS - 1 : 0] end_transaction;
logic [NUM_OF_MASTERS - 1 : 0] grant;

arbiter_engine #(
	.NUM_OF_MASTERS(NUM_OF_MASTERS)
) arbiter_engine_uut (
	.aclk(aclk),
	.aresetn(aresetn),
	.is_urgent(is_urgent),
	.end_transaction(end_transaction),
	.grant(grant)
);

initial
	begin
		$fsdbDumpvars(0, arbiter_engine_test);
		$display("init test arbiter_engine");
		aclk=1'b0;
		aresetn=1'b1;
		is_urgent='0;
		end_transaction='0;
		#10;
		aresetn=1'b0;
		#10;
		aresetn=1'b1;
		#10;
		$display("start transactions");
		
		for( int i=0 ; i< 15; i++) begin
			#50;	
			if (end_transaction == '0 || end_transaction[NUM_OF_MASTERS-1] == 1'b1) begin
				end_transaction = 1;
			end else begin
				end_transaction = end_transaction << 1;
			end
			
			$display("Time: %0t | Iteration: %0d | end_transaction: %b | grant: %b", $time, i, end_transaction,grant);
		end
		
		
		$finish;
	end


always #5 aclk=~aclk;
endmodule