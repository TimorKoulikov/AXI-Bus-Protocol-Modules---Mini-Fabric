//------------------------------------------------------------------------------
// AXI Read Sequence
//------------------------------------------------------------------------------
// Purpose:
//   Generates a series of AXI read transactions directly on the AXI master
//   sequencer (env.axi_ag.axi_seqr).
//
// Usage:
//   axi_read_seq rd_seq = axi_read_seq::type_id::create("rd_seq");
//   rd_seq.m_env = env;       // optional: enables memory-model comparison
//   rd_seq.start(env.axi_ag.axi_seqr);
//
// How to extend:
//   - Override NUM_TRANSACTIONS for stress testing.
//   - Compare req.data against addr2idx() / MEM[] for functional checking.
//   - Add address constraints for targeted region testing.
//------------------------------------------------------------------------------

class axi_read_seq extends uvm_sequence;

     `uvm_object_utils(axi_read_seq)

     // Optional back-pointer to the environment (used for memory-model comparison).
     axi_env m_env;

     // Number of read transactions to generate.
     int unsigned NUM_TRANSACTIONS = 4;

     function new(string name = "axi_read_seq");
          super.new(name);
     endfunction

     task body();

          axi_seq_item req;

          for (int i = 0; i < NUM_TRANSACTIONS; i++) begin

               req = axi_seq_item::type_id::create($sformatf("rd_item_%0d", i));

               start_item(req);

               // Randomize with the same address range as the write sequence so that
               // a write-then-read test can verify data integrity.
               if (!req.randomize() with {
                    write == 0;
                    addr  inside {[`AXI_ADDR_WIDTH'h0000_1000 : `AXI_ADDR_WIDTH'h0000_1FF0]};
                    addr  % 8 == 0;          // 64-bit aligned
                    len   == 0;              // single-beat for now
                    size  == 3'b011;         // 8 bytes (matches DATA_WIDTH=64)
                    burst == 2'b01;          // INCR
               })
                    `uvm_fatal("AXI_READ_SEQ", "Randomization failed")

               finish_item(req);

               `uvm_info("AXI_READ_SEQ",
                    $sformatf("Read %0d: addr=0x%08h data=0x%016h resp=%0d",
                              i, req.addr, req.data, req.resp),
                    apb2axi_verbosity)

          end

     endtask

endclass
