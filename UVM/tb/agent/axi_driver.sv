//------------------------------------------------------------------------------
// AXI Driver (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Drives AXI transactions described by `axi_seq_item` onto `axi_if`.
//
// IMPORTANT CONTEXT (why this driver exists / what “direction” it is):
//   In many APB2AXI projects the DUT is the *AXI master* (it issues AW/AR/W),
//   so the testbench typically models an *AXI slave* that RESPONDS on R/B.
//   However, THIS driver actively drives AW/AR/W (master behavior).
//
//   That means one of these is true in your environment:
//     A) The TB uses this driver as an AXI *master* to stimulate an AXI *slave* DUT, OR
//     B) The naming is “AXI driver” but the DUT side is wired differently than usual.
//
//   For future reuse, be explicit in your project README/env:
//     - If DUT is AXI master: you usually want a *slave BFM* (drive READY/VALID on R/B,
//       sample AW/AR/W), not a master driver like this.
//     - If DUT is AXI slave: this is fine as a master driver.
//
// How to adapt for other projects:
//   1) AXI feature support:
//      - This implementation is a **minimal single-beat** flow:
//          • WLAST is always 1, WSTRB='1, one data beat only
//          • Reads capture only the first R beat (no RLAST handling)
//      - If you need bursts, you must:
//          • loop over beats for WDATA/WVALID/WLAST, obey WREADY each beat
//          • loop over RVALID beats until RLAST, capturing data/resp per beat
//   2) Reset / initialization:
//      - This code assumes signals are already in a sane default state.
//        In a generic reusable BFM, you typically drive all outputs to 0 on reset
//        and keep them stable when idle.
//   3) Handshake correctness:
//      - Using `wait(AWREADY)` after a clock edge works, but a more robust style is
//        “while(!(AWVALID && AWREADY)) @(posedge ACLK)” to avoid racey ready changes.
//      - Same idea applies to W and AR.
//   4) Timing / backpressure / random delays:
//      - In real systems you may want to insert random stalls or obey sequence knobs.
//        That belongs here (driver) so sequences stay high-level.
//------------------------------------------------------------------------------

class axi_driver extends uvm_driver #(axi_seq_item); // RSP defaults to REQ

     `uvm_component_utils(axi_driver)

     // Virtual interface to the AXI bus.
     // Must be set via uvm_config_db key "axi_vif".
     virtual axi_if vif;

     function new(string name = "axi_drv", uvm_component parent=null);
          super.new(name, parent);
     endfunction

     function void build_phase(uvm_phase phase);
          super.build_phase(phase);

          // Critical binding point:
          // If this fails, env/top did not set "axi_vif" for this component.
          if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif))
               `uvm_fatal("AXI_DRIVER", "No virtual interface bound to axi_driver")

     endfunction

     task run_phase(uvm_phase phase);

          axi_seq_item req;

          // Main stimulus loop: get one transaction, drive it, complete it.
          // Any concurrency (multiple outstanding, reordering, etc.) is NOT handled here.
          forever begin
               seq_item_port.get_next_item(req);
               if (req.write) begin
                    drive_write(req);
               end
               else begin
                    drive_read(req);
               end
               seq_item_port.item_done();
          end

     endtask

     task drive_write(axi_seq_item req);
          // -------------------------------------------------------------------
          // Minimal AXI write transaction:
          //   1) AW address phase (single descriptor)
          //   2) W data phase (single beat, WLAST=1)
          //   3) B response phase (capture BRESP)
          //
          // If your project needs true bursts:
          //   - expand the data phase into a beat loop and generate WLAST correctly
          //   - potentially support multiple outstanding writes (IDs, interleaving)
          // -------------------------------------------------------------------

          // --- Address phase ---
          vif.AWADDR          <= req.addr;
          vif.AWVALID         <= 1;
          vif.AWLEN           <= req.len;
          vif.AWBURST         <= req.burst;
          vif.AWSIZE          <= req.size;
          vif.AWID            <= req.id;

          // Wait for a clock edge while out of reset, then for handshake.
          @(posedge vif.ACLK iff vif.ARESETn);
          wait (vif.AWREADY);
          vif.AWVALID         <= 0;

          // --- Data phase ---
          // NOTE: This drives exactly one beat.
          // If AWLEN>0 (burst), this is not sufficient and must be extended.
          vif.WDATA           <= req.data;
          vif.WSTRB           <= '1;   // “all bytes valid” assumption
          vif.WLAST           <= 1;
          vif.WVALID          <= 1;

          @(posedge vif.ACLK iff vif.ARESETn);
          wait (vif.WREADY);
          vif.WVALID          <= 0;
          vif.WLAST           <= 0;

          // --- Response phase ---
          vif.BREADY          <= 1;
          wait (vif.BVALID);
          req.resp            = vif.BRESP; // capture observed response
          vif.BREADY          <= 0;

          `uvm_info("AXI_DRIVER", $sformatf("WRITE: addr=0x%08h data=0x%08h resp=%0d", req.addr, req.data, req.resp), apb2axi_verbosity)
     endtask

     task drive_read(axi_seq_item req);
          // -------------------------------------------------------------------
          // Minimal AXI read transaction:
          //   1) AR address phase
          //   2) R data phase (captures only the first beat)
          //
          // If your project needs bursts:
          //   - keep RREADY asserted and loop until RLAST
          //   - capture all beats (array/queue) or stream to a collector
          // -------------------------------------------------------------------

          // --- Address phase ---
          vif.ARADDR          <= req.addr;
          vif.ARVALID         <= 1;
          vif.ARLEN           <= req.len;
          vif.ARBURST         <= req.burst;
          vif.ARSIZE          <= req.size;
          vif.ARID            <= req.id;

          @(posedge vif.ACLK iff vif.ARESETn);
          wait (vif.ARREADY);
          vif.ARVALID         <= 0;

          // --- Data phase ---
          // NOTE: This assumes a single R beat.
          // If ARLEN>0, you must loop until RLAST.
          vif.RREADY          <= 1;
          wait (vif.RVALID);
          req.data            = vif.RDATA;
          req.resp            = vif.RRESP;
          vif.RREADY          <= 0;

          `uvm_info("AXI_DRIVER", $sformatf("READ:  addr=0x%08h data=0x%08h resp=%0d", req.addr, req.data, req.resp), apb2axi_verbosity)
     endtask

endclass