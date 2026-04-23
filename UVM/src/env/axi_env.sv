//------------------------------------------------------------------------------
// AXI Environment (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Top-level UVM environment for an AXI-only DUT that exposes both an
//   AXI slave port (stimulus input) and an AXI master port (memory output).
//
//   Components:
//     - axi_ag   : AXI master agent — drives transactions into the DUT slave port
//     - axi_bfm  : AXI slave BFM   — responds to the DUT master port
//     - sb       : Scoreboard       — checks functional correctness
//
// Two separate virtual interfaces are required:
//   "axi_mst_vif"  →  connected to the DUT's AXI slave port  (agent drives)
//   "axi_slv_vif"  →  connected to the DUT's AXI master port (BFM responds)
//
// Both keys must be set in tb_top before run_test().
//------------------------------------------------------------------------------

class axi_env extends uvm_env;
	
	
     `uvm_component_utils(axi_env);
	 

     // Optional FIFO: decouples AXI monitor from additional consumers (debug, coverage).
     uvm_tlm_analysis_fifo #(axi_seq_item) axi_mon_fifo;

     // Core verification components
     axi_agent           axi_ag;
     axi3_slave_bfm      axi_bfm;
     axi_scoreboard      sb;

     // Virtual interfaces owned by the environment
     virtual axi_if      axi_mst_vif;   // stimulus side  → DUT slave port
     virtual axi_if      axi_slv_vif;   // response side  → DUT master port

     function new(string name = "axi_env", uvm_component parent = null);
          super.new(name, parent);
     endfunction

     function void build_phase(uvm_phase phase);
          super.build_phase(phase);

          axi_mon_fifo = new("axi_mon_fifo", this);

          // ------------------------------------------------------------------
          // Fetch both virtual interfaces
          // ------------------------------------------------------------------
          if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_mst_vif", axi_mst_vif))
               `uvm_fatal("ENV", "No axi_mst_vif found in config_db — set it in tb_top")
          if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_slv_vif", axi_slv_vif))
               `uvm_fatal("ENV", "No axi_slv_vif found in config_db — set it in tb_top")

          // Force AXI agent to ACTIVE mode (drives stimulus).
          uvm_config_db#(uvm_active_passive_enum)::set(this, "axi_ag", "is_active", UVM_ACTIVE);

          // ------------------------------------------------------------------
          // Component creation
          // ------------------------------------------------------------------
          axi_ag  = axi_agent       ::type_id::create("axi_ag",  this);
          axi_bfm = axi3_slave_bfm  ::type_id::create("axi_bfm", this);
          sb      = axi_scoreboard  ::type_id::create("sb",      this);

          // ------------------------------------------------------------------
          // Propagate interfaces downward
          // ------------------------------------------------------------------
          // Agent and its sub-components use "axi_mst_vif" (stimulus side).
          uvm_config_db#(virtual axi_if)::set(this, "axi_ag",  "axi_vif", axi_mst_vif);

          // BFM responds on the DUT master port, so it gets the slave-side interface.
          uvm_config_db#(virtual axi_if)::set(this, "axi_bfm", "axi_vif", axi_slv_vif);

          // Expose BFM handle globally so sequences can call backdoor functions.
          uvm_config_db#(axi3_slave_bfm)::set(uvm_root::get(), "*", "axi_bfm_h", axi_bfm);

          `uvm_info("ENV", "AXI Environment built successfully.", apb2axi_verbosity);

     endfunction

     function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);

          // AXI monitor (stimulus side) → scoreboard and optional debug FIFO.
          axi_ag.axi_mon.ap.connect(sb.axi_export);
          axi_ag.axi_mon.ap.connect(axi_mon_fifo.analysis_export);

          `uvm_info("ENV", "Scoreboard connections established.", apb2axi_verbosity)

     endfunction

endclass
