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
//          • Write: loop on WVALID/WREADY until WLAST
//          • Read : loop on RVALID/RREADY until RLAST
//      - Store data in an array/queue inside axi_seq_item.
//   2) Out-of-order / multiple outstanding IDs:
//      - This structure already supports it logically (per-ID forked handlers),
//        but real designs may require an explicit ID→transaction map.
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

     function new(string name = "axi_mon", uvm_component parent=null);
          super.new(name, parent);
          ap                                = new("ap", this);
     endfunction

     function void build_phase(uvm_phase phase);

          super.build_phase(phase);

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
                    axi_seq_item tr     = axi_seq_item::type_id::create("axi_wr_tr", this);
                    tr.write            = 1;
                    tr.addr             = vif.AWADDR;
                    tr.id               = vif.AWID;
                    tr.len              = vif.AWLEN;
                    tr.size             = vif.AWSIZE;
                    tr.burst            = vif.AWBURST;

                    `uvm_info(
                         "AXI_MONITOR",
                         $sformatf(
                              "AW handshake: id=%0d addr=0x%0h len=%0d size=%0d burst=%0d",
                              tr.id, tr.addr, tr.len, tr.size, tr.burst
                         ),
                         apb2axi_verbosity
                    )

                    // Spawn a per-transaction handler.
                    // Using 'automatic' ensures each fork has its own transaction object.
                    fork
                         automatic axi_seq_item wr_tr = tr;
                         begin
                              handle_write_transaction(wr_tr);
                         end
                    join_none
               end

               // -------------------------------------------------------------
               // Detect READ address handshake (AR channel)
               // -------------------------------------------------------------
               else if (vif.ARVALID && vif.ARREADY) begin
                    axi_seq_item tr     = axi_seq_item::type_id::create("axi_rd_tr", this);
                    tr.write            = 0;
                    tr.addr             = vif.ARADDR;
                    tr.id               = vif.ARID;
                    tr.len              = vif.ARLEN;
                    tr.size             = vif.ARSIZE;
                    tr.burst            = vif.ARBURST;

                    `uvm_info(
                         "AXI_MONITOR",
                         $sformatf(
                              "AR handshake: id=%0d addr=0x%0h len=%0d size=%0d burst=%0d",
                              tr.id, tr.addr, tr.len, tr.size, tr.burst
                         ),
                         apb2axi_verbosity
                    )

                    // Spawn handler for read data/response.
                    fork
                         automatic axi_seq_item rd_tr = tr;
                         begin
                              handle_read_transaction(rd_tr);
                         end
                    join_none
               end
          end
     endtask

     // =========================================================
     // Private helpers
     // =========================================================

     // ---------------------------------------------------------
     // Write transaction handler
     // ---------------------------------------------------------
     // Current assumption:
     //   - Single-beat write (AWLEN == 0)
     //   - One W beat followed by one B response
     //
     // Extension points:
     //   - Loop on W beats until WLAST
     //   - Track partial writes, byte strobes, or interleaving
     // ---------------------------------------------------------
     task automatic handle_write_transaction(axi_seq_item tr);

          // Wait for first (and currently only) W data beat
          @(posedge vif.ACLK);
          wait (vif.WVALID && vif.WREADY);
          tr.data = vif.WDATA;

          `uvm_info(
               "AXI_MONITOR",
               $sformatf(
                    "WRITE data beat: id=%0d data=0x%0h last=%0b",
                    tr.id, tr.data, vif.WLAST
               ),
               apb2axi_verbosity
          )

          // FIXME (future):
          //   - If AWLEN > 0, loop until WLAST == 1
          //   - Accumulate multiple beats

          // Wait for write response
          wait (vif.BVALID && vif.BREADY);
          tr.resp = vif.BRESP;

          `uvm_info(
               "AXI_MONITOR",
               $sformatf("WRITE resp: id=%0d resp=%0d", tr.id, tr.resp),
               apb2axi_verbosity
          )

          // Transaction is now complete and can be published.
          ap.write(tr);

     endtask : handle_write_transaction

     // ---------------------------------------------------------
     // Read transaction handler
     // ---------------------------------------------------------
     // Current assumption:
     //   - Single-beat read (ARLEN == 0)
     //
     // Extension points:
     //   - Loop on R beats until RLAST
     //   - Collect multiple data beats
     // ---------------------------------------------------------
     task automatic handle_read_transaction(axi_seq_item tr);

          // Wait for first (and currently only) R data beat
          @(posedge vif.ACLK);
          wait (vif.RVALID && vif.RREADY);
          tr.data = vif.RDATA;
          tr.resp = vif.RRESP;

          `uvm_info(
               "AXI_MONITOR",
               $sformatf(
                    "READ data beat: id=%0d data=0x%0h resp=%0d last=%0b",
                    tr.id, tr.data, tr.resp, vif.RLAST
               ),
               apb2axi_verbosity
          )

          // FIXME (future):
          //   - Enforce RLAST==1 for single-beat reads
          //   - Or loop until RLAST for burst reads

          // Publish completed read transaction.
          ap.write(tr);

     endtask : handle_read_transaction

endclass