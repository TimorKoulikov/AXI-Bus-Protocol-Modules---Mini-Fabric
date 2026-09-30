/*------------------------------------------------------------------------------
 * File          : needy_test.sv
 * Project       : Fabric
 * Description   : Directed Pass/Fail testbench for needy module
 *------------------------------------------------------------------------------*/

module needy_test ();

	//----- parameters -----
	parameter NUM_OF_CHANNEL = 3;
	parameter token_width = 31;
	parameter [token_width - 1 : 0] TOKEN_LOW_THRESHOLD = 8;

	//----- inputs -----
	logic [NUM_OF_CHANNEL - 1 : 0][token_width - 1 : 0] token_allocation;
	logic [NUM_OF_CHANNEL - 1 : 0] full;
	logic [NUM_OF_CHANNEL - 1 : 0] empty;

	//----- outputs -----
	logic [NUM_OF_CHANNEL - 1 : 0][1:0] needy;

	//----- DUT instantiation -----
	needy #(
		.NUM_OF_CHANNEL(NUM_OF_CHANNEL),
		.token_width(token_width),
		.TOKEN_LOW_THRESHOLD(TOKEN_LOW_THRESHOLD)
	) needy_uut (
		.token_allocation(token_allocation),
		.full            (full),
		.empty           (empty),
		.needy_level           (needy)
	);

	//----- testbench -----
	int i = $urandom_range(NUM_OF_CHANNEL - 1, 0);

	initial begin
		$fsdbDumpvars(0, needy_test);
		$display("init needy_test (testing channel %0d)", i);

		// Initialize inputs
		token_allocation = '0;
		full             = '0;
		empty            = '1;
		#10;

		//======================================================================
		// test_1: Normal state -> NO_LEAK (2'b00)
		// token_allocation >= TOKEN_LOW_THRESHOLD and full == 0
		//======================================================================
		$display("test_1: check NO_LEAK (2'b00) when tokens >= threshold and not full");
		token_allocation[i] = TOKEN_LOW_THRESHOLD + $urandom_range(100, 0);
		full[i]             = 1'b0;
		empty[i]            = 1'b0;
		#10;
		assert (needy[i] == 2'b00) begin
			$display("test_1: PASS");
		end else begin
			$error("test_1: FAIL - needy[%0d]=%b, expected=2'b00", i, needy[i]);
		end

		//======================================================================
		// test_2: Low tokens only -> LEAK (2'b01)
		// token_allocation < TOKEN_LOW_THRESHOLD and full == 0
		//======================================================================
		$display("test_2: check LEAK (2'b01) when tokens < threshold and not full");
		token_allocation[i] = $urandom_range(TOKEN_LOW_THRESHOLD - 1, 0);
		full[i]             = 1'b0;
		#10;
		assert (needy[i] == 2'b01) begin
			$display("test_2: PASS");
		end else begin
			$error("test_2: FAIL - needy[%0d]=%b, expected=2'b01", i, needy[i]);
		end

		//======================================================================
		// test_3: ROB full only -> EXSTRA_BW (2'b10)
		// token_allocation >= TOKEN_LOW_THRESHOLD and full == 1
		//======================================================================
		$display("test_3: check EXSTRA_BW (2'b10) when tokens >= threshold and ROB is full");
		token_allocation[i] = TOKEN_LOW_THRESHOLD; // exact boundary check
		full[i]             = 1'b1;
		#10;
		assert (needy[i] == 2'b10) begin
			$display("test_3: PASS");
		end else begin
			$error("test_3: FAIL - needy[%0d]=%b, expected=2'b10", i, needy[i]);
		end

		//======================================================================
		// test_4: Low tokens AND ROB full -> LEAK_EXSTRA_BW (2'b11)
		// token_allocation < TOKEN_LOW_THRESHOLD and full == 1
		//======================================================================
		$display("test_4: check LEAK_EXSTRA_BW (2'b11) when tokens < threshold and ROB is full");
		token_allocation[i] = TOKEN_LOW_THRESHOLD - 1;
		full[i]             = 1'b1;
		#10;
		assert (needy[i] == 2'b11) begin
			$display("test_4: PASS");
		end else begin
			$error("test_4: FAIL - needy[%0d]=%b, expected=2'b11", i, needy[i]);
		end

		//======================================================================
		// test_5: Multi-channel independence check
		//======================================================================
		$display("test_5: check all channels simultaneously with different states");
		token_allocation[0] = TOKEN_LOW_THRESHOLD + 5; full[0] = 1'b0; // Expect 2'b00
		token_allocation[1] = TOKEN_LOW_THRESHOLD - 2; full[1] = 1'b0; // Expect 2'b01
		token_allocation[2] = TOKEN_LOW_THRESHOLD - 1; full[2] = 1'b1; // Expect 2'b11
		#10;
		assert (needy[0] == 2'b00 && needy[1] == 2'b01 && needy[2] == 2'b11) begin
			$display("test_5: PASS");
		end else begin
			$error("test_5: FAIL - needy={%b, %b, %b}", needy[2], needy[1], needy[0]);
		end

		$finish;
	end

endmodule