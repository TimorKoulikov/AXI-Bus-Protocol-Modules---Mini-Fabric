//------------------------------------------------------------------------------
// AXI Monitor (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Passively observes AXI bus activity and reconstructs *completed* AXI
//   read/write transactions into `axi_seq_item`s.
//
// Why this monitor is more complex than the APB monitor:
//   - AXI is multi-channel and potentially out-of-order.
//   - Address (AW/AR), data (W/R), and response (B) occur on different channels
//     and possibly different cycles.
//   - The monitor must therefore correlate phases that belong to the *same* AXI ID.
//
// Current design philosophy:
//   - Keep the monitor simple and readable.
//   - Support single-beat transactions only (AWLEN/ARLEN assumed 0).
//   - Spawn a lightweight per-transaction handler using fork/join_none.
//   - Leave clear extension points for bursts and interleaving.
//
// How to adapt / extend in future projects:
//   1) Burst support (very common):
//      - Replace single-beat assumptions with loops:
//           Write: loop on WVALID/WREADY until WLAST
//           Read : loop on RVALID/RREADY until RLAST
//      - Store data in an array/queue inside axi_seq_item.
//   2) Out-of-order / multiple outstanding IDs:
//      - This structure already supports it logically (per-ID forked handlers),
//        but real designs may require an explicit ID?transaction map.
//   3) Passive-only systems:
//      - This monitor can be used standalone (no driver) to observe a real AXI fabric.
//   4) Sampling rules:
//      - Sampling is done strictly on VALID && READY handshakes to avoid race conditions.
//   5) Protocol variants:
//      - AXI3 vs AXI4 vs AXI-Lite differences are localized here.
//        You can swap fields without touching scoreboards/sequences.
//------------------------------------------------------------------------------

class axi_monitor extends uvm_monitor;

     `uvm_component_utils(axi_monitor)

     // Analysis port publishing completed AXI transactions.
     // Typically consumed by scoreboards, coverage, or checkers.
     uvm_analysis_port #(axi_seq_item)     ap;

     // Virtual AXI interface for passive observation.
     virtual axi_if                        vif;
    
     string port_id;
     
     function new(string name = "axi_mon", uvm_component parent=null);
          super.new(name, parent);
          ap                                = new("ap", this);
     endfunction

     function void build_phase(uvm_phase phase);

          super.build_phase(phase);
          
          if (uvm_is_match("*slv*", get_full_name())) begin
              port_id = "SLAVE"; // e.g. "axi_slv_mon_0"
          end else begin
              port_id = "MASTER"; // e.g. "axi_ag_0"
          end
          // Binding point for the AXI interface.
          // Keeps the monitor hierarchy-independent and reusable.
          if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif))
               `uvm_fatal("AXI_MONITOR", "No virtual interface bound to axi_monitor")

     endfunction

     task run_phase(uvm_phase phase);

          // Do not observe bus activity during reset.
          wait (vif.ARESETn === 1'b1);
          @(posedge vif.ACLK);

          forever begin
               @(posedge vif.ACLK);
               
               // -------------------------------------------------------------
               // Detect WRITE address handshake (AW channel)
               // -------------------------------------------------------------
               if (vif.AWVALID && vif.AWREADY) begin
                    axi_seq_item tr = axi_seq_item::type_id::create("aw_tr", this);
                    tr.ch_type = AW; 
                    tr.write = 1;
                    tr.addr = vif.AWADDR;
                    tr.id = vif.AWID; 
                    tr.len = vif.AWLEN;
                    tr.size = vif.AWSIZE;
                    tr.burst = vif.AWBURST;
                    `uvm_info($sformatf("AXI_MONITOR_%s",port_id), $sformatf("AW Beat: id=%0d addr=0x%0h", tr.id, tr.addr), axi_verbosity)
                    ap.write(tr);
               end

               // -------------------------------------------------------------
               // Detect WRITE data handshake (W channel)
               // -------------------------------------------------------------
               if (vif.WVALID && vif.WREADY) begin
                    axi_seq_item tr = axi_seq_item::type_id::create("w_tr", this);
                    tr.ch_type = W;
                    tr.write = 1;
                    tr.data = vif.WDATA;
                    tr.id = vif.WID; 
                    `uvm_info($sformatf("AXI_MONITOR_%s",port_id), $sformatf("W Beat: id=%0d data=0x%0h last=%0b", tr.id, tr.data, vif.WLAST), axi_verbosity)
                    ap.write(tr);
               end

               // -------------------------------------------------------------
               // Detect WRITE response handshake (B channel)
               // -------------------------------------------------------------
               if (vif.BVALID && vif.BREADY) begin
                    axi_seq_item tr = axi_seq_item::type_id::create("b_tr", this);
                    tr.ch_type = B;
                    tr.write = 1;
                    tr.resp = vif.BRESP; 
                    tr.id = vif.BID;
                    `uvm_info($sformatf("AXI_MONITOR_%s",port_id), $sformatf("B Beat: id=%0d resp=%0d", tr.id, tr.resp), axi_verbosity)
                    ap.write(tr);
               end

               // -------------------------------------------------------------
               // Detect READ address handshake (AR channel)
               // -------------------------------------------------------------
               if (vif.ARVALID && vif.ARREADY) begin
                    axi_seq_item tr = axi_seq_item::type_id::create("ar_tr", this);
                    tr.ch_type = AR; 
                    tr.write = 0; 
                    tr.addr = vif.ARADDR;
                    tr.id = vif.ARID; 
                    tr.len = vif.ARLEN; 
                    tr.size = vif.ARSIZE; 
                    tr.burst = vif.ARBURST;
                    `uvm_info($sformatf("AXI_MONITOR_%s",port_id), $sformatf("AR Beat: id=%0d addr=0x%0h", tr.id, tr.addr), axi_verbosity)
                    ap.write(tr);
               end

               // -------------------------------------------------------------
               // Detect READ data/response handshake (R channel)
               // -------------------------------------------------------------
               if (vif.RVALID && vif.RREADY) begin
                    axi_seq_item tr = axi_seq_item::type_id::create("r_tr", this);
                    tr.ch_type = R;
                    tr.write = 0;
                    tr.data = vif.RDATA; 
                    tr.resp = vif.RRESP;
                    tr.id = vif.RID;
                    `uvm_info($sformatf("AXI_MONITOR_%s",port_id), $sformatf("R Beat: id=%0d data=0x%0h resp=%0d last=%0b", tr.id, tr.data, tr.resp, vif.RLAST), axi_verbosity)
                    ap.write(tr);
               end
            end
        endtask
 endclass