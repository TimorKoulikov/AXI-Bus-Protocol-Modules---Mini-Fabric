//------------------------------------------------------------------------------
// AXI Agent (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Standard UVM agent wrapping the AXI-side BFM: Driver + Monitor + Sequencer.
//   In the APB2AXI project, this is typically the “AXI slave model / responder”
//   that reacts to AXI traffic issued by the DUT (the bridge).
//
// Key reuse idea:
//   This agent is *protocol container + wiring*, not “behavior”.
//   The actual AXI behavior (e.g., memory model, response policy, delays, out-of-order)
//   should live inside `axi_driver` (and optionally helper components), so the agent
//   itself stays generic.
//
// How to integrate into a different project:
//   1) Bind your AXI interface handle from the top/env:
//        uvm_config_db#(virtual axi_if)::set(null, "uvm_test_top.env.axi_ag", "axi_vif", <your_axi_vif>);
//      - If your interface type or key differs, update `axi_if` and "axi_vif"
//        consistently across env/top/agent/driver/monitor.
//   2) Swap the AXI implementation:
//      - If you need AXI4 vs AXI3, or a simplified AXI-lite, keep the same agent
//        structure but replace `axi_driver/axi_monitor/axi_sequencer` and/or `axi_if`.
//   3) Passive-only usage (common in SOC benches):
//      - If you only want monitoring, add `is_active` gating to avoid creating/connecting
//        the driver+sequencer when passive.
//
// Notes:
//   - This agent currently assumes ACTIVE mode (always connects sequencer->driver).
//------------------------------------------------------------------------------

class axi_agent extends uvm_agent;

     `uvm_component_utils(axi_agent)

     axi_driver                         axi_drv;
     axi_monitor                        axi_mon;
     axi_sequencer                      axi_seqr;

     // Virtual interface for the AXI bus BFM.
     // Must be provided by the TB via uvm_config_db under key "axi_vif".
     virtual axi_if                     vif;

     function new(string name = "axi_agent", uvm_component parent=null);
          super.new(name, parent);
     endfunction

     function void build_phase(uvm_phase phase);

          super.build_phase(phase);

          // Critical binding point:
          // Keeps the agent hierarchy-independent. If this fails, the env/top didn’t set axi_vif.
          if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif))
               `uvm_fatal("AXI_AGENT", "No virtual interface bound to axi_agent")

          // Create sub-components (behavior is in driver/monitor, not here).
          axi_drv                        = axi_driver     ::type_id::create("axi_drv", this);
          axi_mon                        = axi_monitor    ::type_id::create("axi_mon", this);
          axi_seqr                       = axi_sequencer  ::type_id::create("axi_seqr", this);

          // Pass VIF down so sub-components don’t depend on hierarchical paths.
          uvm_config_db#(virtual axi_if)::set(this, "axi_drv", "axi_vif", vif);
          uvm_config_db#(virtual axi_if)::set(this, "axi_mon", "axi_vif", vif);

     endfunction

     function void connect_phase(uvm_phase phase);

          super.connect_phase(phase);

          // Allows sequences to control the AXI driver (e.g., responder policy, delays).
          // If you later support passive-only mode, guard this behind is_active==UVM_ACTIVE.
          axi_drv.seq_item_port.connect(axi_seqr.seq_item_export);

     endfunction

endclass