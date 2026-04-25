


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
	localparam NUM_OF_MASTERS = 4;
	localparam NUM_OF_SLAVES = 3;
	
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
	
	 // Declare arrays of interfaces based on your parameters
	 axi_if axi_mst_if [NUM_OF_MASTERS] (.ACLK(ACLK), .ARESETn(ARESETn));
	 axi_if axi_slv_if [NUM_OF_SLAVES]  (.ACLK(ACLK), .ARESETn(ARESETn));
	
	 // TODO : import my block. do it after finished
	 // -------------------------------------------------------------------------
	 // DUT instance
	 // -------------------------------------------------------------------------
	 //Replace <your_dut> with your module name and connect the ports:
	 //   - axi_mst_if signals → DUT's AXI slave input ports
	 //   - axi_slv_if signals → DUT's AXI master output ports
	 
	  top_block #(.NUM_OF_MASTERS(NUM_OF_MASTERS),.NUM_OF_SLAVES(NUM_OF_SLAVES))
	  dut (
	       .aclk(ACLK),
		   .aresetn(ARESETn),
		   .slaves(axi_slv_if),
		   .masters(axi_mst_if)
	  );
	
	 // -------------------------------------------------------------------------
	 // Waveform dumping (FSDB — Verdi/Novas)
	 // -------------------------------------------------------------------------
	 initial begin
	      $display("### FSDB DUMP at time %0t", $time);
	      $fsdbDumpfile("waves.fsdb");
	      $fsdbDumpvars(0, tb_top, "+all");
	      $fsdbDumpMDA();
	 end
	
	
	 genvar i;
	 generate 
		 
		 for (i = 0; i < NUM_OF_SLAVES; i++) begin
			 initial begin
				 uvm_config_db#(virtual axi_if)::set(
					 null, 
					 "*", 
					 $sformatf("axi_slv_vif_%0d", i), 
					 axi_slv_if[i]
				  );
			 end
		 end
		 
		 for (i = 0; i < NUM_OF_MASTERS; i++) begin : mst_vif_setup
			 initial begin
				 uvm_config_db#(virtual axi_if)::set(
					 null, 
					 "*", 
					 $sformatf("axi_mst_vif_%0d", i), 
					 axi_mst_if[i]
				 );
			 end
		 end
	 endgenerate 
	   
	 // -------------------------------------------------------------------------
	 // UVM entry point
	 // -------------------------------------------------------------------------
	 initial begin
	      // Publish the two AXI virtual interfaces.
	      // Keys must match what axi_env expects.
		  // Loop through Slave interfaces
	 run_test("axi_test");
	end
endmodule
