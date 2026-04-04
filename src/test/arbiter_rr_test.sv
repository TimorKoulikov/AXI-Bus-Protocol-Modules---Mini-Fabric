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

arbiter_rr #(
	.NUM_OF_MASTERS(NUM_OF_MASTERS)
) arbiter_rr_dut (
	.aclk(aclk),
	.aresetn(aresetn),
	.is_urgent(is_urgent),
	.end_transaction(end_transaction),
	.grant(grant)
);

// --------------------------------------------------------
// TASK 1: The Regular Round-Robin Shift
// --------------------------------------------------------
task do_regular_shift();
	// Wait for a clean clock edge instead of using arbitrary #100 delays
	@(posedge aclk); 
	
	if (end_transaction == '0 || end_transaction[NUM_OF_MASTERS-1] == 1'b1) begin
		end_transaction <= 1;
	end else begin
		end_transaction <= end_transaction << 1;
	end
endtask

// --------------------------------------------------------
// TASK 2: The Urgent Sequence
// --------------------------------------------------------
task do_urgent_sequence();
	$display("Time: %0t | ---> STARTING URGENT INJECTION: 101", $time);
	
	// Assert urgent mode
	is_urgent <= 3'b101; 
	
	// Drive the exact sequence, waiting 1 clock cycle between each change
	end_transaction <= 3'b000;
	#100;
	$display("Time: %0t| end_transaction: %b | grant: %b", $time,end_transaction, grant);
	end_transaction <= 3'b100;
	#100;
	$display("Time: %0t| end_transaction: %b | grant: %b", $time,end_transaction, grant);
	end_transaction <= 3'b001;
	#100;
	$display("Time: %0t| end_transaction: %b | grant: %b", $time,end_transaction, grant);
	end_transaction <= 3'b100;
	#100;
	$display("Time: %0t| end_transaction: %b | grant: %b", $time,end_transaction, grant);
	end_transaction <= 3'b001;
	#100;
	$display("Time: %0t| end_transaction: %b | grant: %b", $time,end_transaction, grant);
	// Clean up
	is_urgent <= '0;
	end_transaction <= 3'b000; 
	$display("Time: %0t | ---> URGENT SEQUENCE COMPLETE", $time);
endtask

int interrupt_point = $urandom_range(5, 12); 
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

			// Run the main simulation loop
			for( int i=0 ; i< 20; i++) begin
				
				#100;
				
				// If we hit the random interrupt point, pause the regular 
				// shifts and execute the urgent task instead.
				if (i == interrupt_point) begin
					do_urgent_sequence();
				end
				
				// Execute 1 regular shift
				do_regular_shift();
				
				$display("Time: %0t | Iteration: %0d | end_transaction: %b | grant: %b", $time, i, end_transaction, grant);
			end
			
			$display("Time: %0t | Test complete.", $time);
		
		
		$finish;
	end


always #5 aclk=~aclk;
endmodule