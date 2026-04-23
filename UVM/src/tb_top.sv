


//------------------------------------------------------------------------------
// Module: tb_top
//------------------------------------------------------------------------------
// Purpose:
//   Simulation top for the AXI-only UVM environment.
//   Responsibilities:
//     1) Generate AXI clock and reset
//     2) Instantiate TWO axi_if objects:
//          - axi_mst_if  : stimulus side → connected to DUT's AXI slave port
//          - axi_slv_if  : response side → connected to DUT's AXI master port
//     3) Instantiate the DUT and connect interfaces to its ports
//     4) Publish both virtual interfaces into uvm_config_db
//     5) Start the UVM test
//
// Adapting for your DUT:
//   A) Replace the DUT instantiation with your module name and port mapping.
//   B) Connect axi_mst_if signals to DUT slave-side ports (AWVALID/ARVALID etc. driven by TB).
//   C) Connect axi_slv_if signals to DUT master-side ports (AWVALID/ARVALID etc. driven by DUT).
//   D) Adjust clock period and reset duration as needed.
//------------------------------------------------------------------------------

module tb_top;
	import uvm_pkg::*;
	import axi_tb_pkg::*;
    localparam time AXI_CLK_DELAY = 5ns;

    logic ACLK;
    logic ARESETn;

	// TODO : maybe always #5 aclk=~aclk; . do after UVM works
	// -------------------------------------------------------------------------
	// Clock and reset
	// -------------------------------------------------------------------------
	initial begin
	     ACLK    = 0;
	     forever #AXI_CLK_DELAY ACLK = ~ACLK;
	end
	
	// TODO : consider maybe to remove
	initial begin
		ARESETn = 0;
    	#50ns;
    	ARESETn = 1;
	end
	
	 // -------------------------------------------------------------------------
	 // AXI interfaces
	 //   axi_mst_if : TB (agent) drives master signals → DUT's AXI slave port
	 //   axi_slv_if : DUT drives master signals → AXI slave BFM
	 // -------------------------------------------------------------------------
	 axi_if axi_mst_if (
	      .ACLK    (ACLK),
	      .ARESETn (ARESETn)
	 );
	
	 axi_if axi_slv_if (
	      .ACLK    (ACLK),
	      .ARESETn (ARESETn)
	 );
	
	 // TODO : import my block. do it after finished
	 // -------------------------------------------------------------------------
	 // DUT instance
	 // -------------------------------------------------------------------------
	 // Replace <your_dut> with your module name and connect the ports:
	 //   - axi_mst_if signals → DUT's AXI slave input ports
	 //   - axi_slv_if signals → DUT's AXI master output ports
	 //
	 // Example skeleton (uncomment and fill in):
	 // <your_dut> #() dut (
	 //      .ACLK          (ACLK),
	 //      .ARESETn       (ARESETn),
	 //
	 //      // --- DUT AXI slave port (TB drives) ---
	 //      .S_AWADDR      (axi_mst_if.AWADDR),
	 //      .S_AWVALID     (axi_mst_if.AWVALID),
	 //      .S_AWREADY     (axi_mst_if.AWREADY),
	 //      .S_WDATA       (axi_mst_if.WDATA),
	 //      .S_WSTRB       (axi_mst_if.WSTRB),
	 //      .S_WLAST       (axi_mst_if.WLAST),
	 //      .S_WVALID      (axi_mst_if.WVALID),
	 //      .S_WREADY      (axi_mst_if.WREADY),
	 //      .S_BRESP       (axi_mst_if.BRESP),
	 //      .S_BVALID      (axi_mst_if.BVALID),
	 //      .S_BREADY      (axi_mst_if.BREADY),
	 //      .S_ARADDR      (axi_mst_if.ARADDR),
	 //      .S_ARVALID     (axi_mst_if.ARVALID),
	 //      .S_ARREADY     (axi_mst_if.ARREADY),
	 //      .S_RDATA       (axi_mst_if.RDATA),
	 //      .S_RRESP       (axi_mst_if.RRESP),
	 //      .S_RVALID      (axi_mst_if.RVALID),
	 //      .S_RLAST       (axi_mst_if.RLAST),
	 //      .S_RREADY      (axi_mst_if.RREADY),
	 //
	 //      // --- DUT AXI master port (BFM responds) ---
	 //      .M_AWADDR      (axi_slv_if.AWADDR),
	 //      .M_AWVALID     (axi_slv_if.AWVALID),
	 //      .M_AWREADY     (axi_slv_if.AWREADY),
	 //      .M_WDATA       (axi_slv_if.WDATA),
	 //      .M_WSTRB       (axi_slv_if.WSTRB),
	 //      .M_WLAST       (axi_slv_if.WLAST),
	 //      .M_WVALID      (axi_slv_if.WVALID),
	 //      .M_WREADY      (axi_slv_if.WREADY),
	 //      .M_BRESP       (axi_slv_if.BRESP),
	 //      .M_BVALID      (axi_slv_if.BVALID),
	 //      .M_BREADY      (axi_slv_if.BREADY),
	 //      .M_ARADDR      (axi_slv_if.ARADDR),
	 //      .M_ARVALID     (axi_slv_if.ARVALID),
	 //      .M_ARREADY     (axi_slv_if.ARREADY),
	 //      .M_RDATA       (axi_slv_if.RDATA),
	 //      .M_RRESP       (axi_slv_if.RRESP),
	 //      .M_RVALID      (axi_slv_if.RVALID),
	 //      .M_RLAST       (axi_slv_if.RLAST),
	 //      .M_RREADY      (axi_slv_if.RREADY)
	 // );
	
	 // -------------------------------------------------------------------------
	 // Waveform dumping (FSDB — Verdi/Novas)
	 // -------------------------------------------------------------------------
	 initial begin
	      $display("### FSDB DUMP at time %0t", $time);
	      $fsdbDumpfile("waves.fsdb");
	      $fsdbDumpvars(0, tb_top, "+all");
	      $fsdbDumpMDA();
	 end
	
	 // -------------------------------------------------------------------------
	 // UVM entry point
	 // -------------------------------------------------------------------------
	 initial begin
	      // Publish the two AXI virtual interfaces.
	      // Keys must match what axi_env expects.
	      uvm_config_db#(virtual axi_if)::set(null, "*", "axi_mst_vif", axi_mst_if);
	      uvm_config_db#(virtual axi_if)::set(null, "*", "axi_slv_vif", axi_slv_if);
	
	      run_test("axi_test");
	 end

endmodule
