//------------------------------------------------------------------------------
// AXI Base Test (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Common base class for all tests in this AXI-only environment.
//   Responsibilities:
//     - Global UVM verbosity configuration
//     - Global simulation timeout
//     - Builds the environment
//     - Runs a default idle/sanity pass (no stimulus) so derived tests
//       can focus only on selecting their sequence.
//------------------------------------------------------------------------------

class axi_base_test extends uvm_test;
	
    `uvm_component_utils(axi_base_test)

    axi_env env;

    function new(string name = "axi_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Project-wide verbosity configuration.
        axi_tb_pkg::axi_configure_verbosity();

        // Simulation watchdog — prevents hanging regressions.
        uvm_top.set_timeout(10ms, 1);

        env = axi_env::type_id::create("env", this);

        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
		
		for( int i=0; i < `NUM_OF_SLAVES ; i++) begin
			`uvm_info("AXI_BASE_TEST",
				$sformatf("AXI sequencer: %s",env.axi_ag.axi_seqr[i].get_full_name()),
				apb2axi_verbosity)

		  // Defensive check: verify driver is connected to the sequencer.
		  if (env.axi_ag.axi_drv[i].seq_item_port != null)
			  `uvm_info("AXI_BASE_TEST", "Driver seq_item_port is valid.", apb2axi_verbosity)
		  else
			  `uvm_error("AXI_BASE_TEST", "Driver seq_item_port is NULL — check agent wiring!")
	
		  // Base test raises/drops an empty objection so derived tests run their own sequences.
		  phase.raise_objection(this);
		  `uvm_info("AXI_BASE_TEST", "Base test run_phase (no default sequence).", apb2axi_verbosity)
		  phase.drop_objection(this);
		end
        

    endtask

endclass
