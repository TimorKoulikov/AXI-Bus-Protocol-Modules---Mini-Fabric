/*------------------------------------------------------------------------------
 * File          : top_block_test.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Sep 30, 2026
 * Description   : Sanity check testing a basic AW->W->B transaction flow.
 *------------------------------------------------------------------------------*/

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

module top_block_test #() ();

	//----- parameters -----
	parameter NUM_OF_MASTERS = 3;
	parameter NUM_OF_SLAVES  = 4;
	parameter token_width    = 30;

	//----- signals -----
	logic aclk;
	logic aresetn;
	cfg_t cfg;
	logic cfg_en;

	//----- interfaces -----
	axi_if masters_if[NUM_OF_MASTERS](aclk, aresetn);
	axi_if slaves_if[NUM_OF_SLAVES](aclk, aresetn);

	//----- DUT instantiation -----
	top_block #(
		.NUM_OF_MASTERS(NUM_OF_MASTERS),
		.NUM_OF_SLAVES (NUM_OF_SLAVES),
		.token_width   (token_width)
	) dut (
		.aclk   (aclk),
		.aresetn(aresetn),
		.cfg    (cfg),
		.cfg_en (cfg_en),
		.slaves (slaves_if),
		.masters(masters_if)
	);

	//----- Clock Generation -----
	initial begin
		aclk = 0;
		forever #5 aclk = ~aclk;
	end
	
	generate
		for (genvar i = 0; i < NUM_OF_MASTERS; i++) begin
			initial begin
				masters_if[i].AWVALID = 0;
				masters_if[i].WVALID  = 0;
				masters_if[i].BREADY  = 0;
				masters_if[i].ARVALID = 0;
				masters_if[i].RREADY  = 0;
			end
		end
	endgenerate
	
	generate
		for(genvar i = 0; i < NUM_OF_SLAVES; i++) begin
			initial begin
				slaves_if[i].AWREADY  = 0;
				slaves_if[i].WREADY   = 0;
				slaves_if[i].BVALID   = 0;
				slaves_if[i].ARREADY  = 0;
				slaves_if[i].RVALID   = 0;
			end
		end
	endgenerate
	
	//----- Test Sequence -----
	initial begin
		$fsdbDumpvars(0, top_block_test);
		$fsdbDumpMDA(0, top_block_test);
		$display("--- Starting top_block Sanity Test ---");

		// 1. Initialize Default Values
		aresetn = 0;
		cfg_en  = 0;
		cfg     = '0;

		

		// 2. Apply Reset
		#20;
		aresetn = 1;
		#20;

		// 3. Configure Address Map
		// Map Slave 0 to 0x0000_0000 - 0x0000_0FFF
		// Map Slave 1 to 0x0000_1000 - 0x0000_1FFF
		// Map Slave 2 to 0x0000_2000 - 0x0000_2FFF
		// Map Slave 3 to 0x0000_3000 - 0x0000_3FFF
		cfg[0].low_addr = 32'h0000_0000; cfg[0].high_addr = 32'h0000_0FFF;
		cfg[1].low_addr = 32'h0000_1000; cfg[1].high_addr = 32'h0000_1FFF;
		cfg[2].low_addr = 32'h0000_2000; cfg[2].high_addr = 32'h0000_2FFF;
		cfg[3].low_addr = 32'h0000_3000; cfg[3].high_addr = 32'h0000_3FFF;
		
		@(posedge aclk);
		cfg_en = 1;
		@(posedge aclk);
		cfg_en = 0;
		#20;

		$display("Time: %0t | Config loaded. Starting Write Transaction from Master 0 to Slave 1...", $time);

		// 4. Fork Master Driver and Slave Responder
		fork
			// ----------------------------------------------------
			// MASTER 0 THREAD: Drive AW and W, Wait for B
			// ----------------------------------------------------
			begin
				// AW Channel
				@(posedge aclk);
				masters_if[0].AWADDR  <= 32'h0000_1100; // Address routing to Slave 1
				masters_if[0].AWID    <= 4'd5;          // Transaction ID
				masters_if[0].AWLEN   <= 0;
				masters_if[0].AWQOS   <= 2'b11;         // Urgent QoS
				masters_if[0].AWVALID <= 1;
				
				wait(masters_if[0].AWREADY);
				@(posedge aclk);
				masters_if[0].AWVALID <= 0;
				$display("Time: %0t | Master 0: AW Handshake completed.", $time);

				// W Channel
				masters_if[0].WDATA  <= 32'hDEADBEEF;
				masters_if[0].WSTRB  <= 4'hF;
				masters_if[0].WLAST  <= 1;
				masters_if[0].WVALID <= 1;
				masters_if[0].WID <=	4'd5;

				wait(masters_if[0].WREADY);
				@(posedge aclk);
				masters_if[0].WVALID <= 0;
				masters_if[0].WLAST  <= 0;
				$display("Time: %0t | Master 0: W Handshake completed.", $time);

				// B Channel
				masters_if[0].BREADY <= 1;
				wait(masters_if[0].BVALID);
				@(posedge aclk);
				assert(masters_if[0].BRESP == 2'b00) else $error("Master 0: BRESP mismatch!");
				assert(masters_if[0].BID == 4'd5) else $error("Master 0: BID mismatch!");
				masters_if[0].BREADY <= 0;
				$display("Time: %0t | Master 0: B Handshake completed. Transaction DONE.", $time);
			end

			// ----------------------------------------------------
			// SLAVE 1 THREAD: Wait for AW and W, Drive B
			// ----------------------------------------------------
			begin
				logic [3:0] captured_id;

				// AW Channel
				slaves_if[1].AWREADY <= 1;
				wait(slaves_if[1].AWVALID);
				@(posedge aclk);
				captured_id = slaves_if[1].AWID;
				assert(slaves_if[1].AWADDR == 32'h0000_1100) else $error("Slave 1: AWADDR mismatch!");
				slaves_if[1].AWREADY <= 0;
				$display("Time: %0t | Slave 1: AW Handshake completed. (Received AWADDR: %h)", $time, slaves_if[1].AWADDR);

				// W Channel
				slaves_if[1].WREADY <= 1;
				wait(slaves_if[1].WVALID);
				@(posedge aclk);
				assert(slaves_if[1].WDATA == 32'hDEADBEEF) else $error("Slave 1: WDATA mismatch!");
				slaves_if[1].WREADY <= 0;
				$display("Time: %0t | Slave 1: W Handshake completed. (Received WDATA: %h)", $time, slaves_if[1].WDATA);

				// Processing delay before responding
				#30;

				// B Channel (Response)
				@(posedge aclk);
				slaves_if[1].BID    <= captured_id;
				slaves_if[1].BRESP  <= 2'b00; // OKAY
				slaves_if[1].BVALID <= 1;

				wait(slaves_if[1].BREADY);
				@(posedge aclk);
				slaves_if[1].BVALID <= 0;
				$display("Time: %0t | Slave 1: B Handshake completed.", $time);
			end
		join

		$display("--- Sanity Check PASSED! ---");
		$finish;
	end

endmodule