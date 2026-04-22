//------------------------------------------------------------------------------
// AXI Write Sequence
//------------------------------------------------------------------------------
// Purpose:
//   Generates a series of AXI write transactions directly on the AXI master
//   sequencer (env.axi_ag.axi_seqr).
//
// Usage:
//   axi_write_seq wr_seq = axi_write_seq::type_id::create("wr_seq");
//   wr_seq.m_env = env;       // optional: enables backdoor read-back check
//   wr_seq.start(env.axi_ag.axi_seqr);
//
// How to extend:
//   - Override NUM_TRANSACTIONS for stress testing.
//   - Add address constraints in body() for targeted region testing.
//   - Use m_env.axi_bfm.peek_word64() for backdoor verification.
//------------------------------------------------------------------------------

class axi_write_seq extends uvm_sequence #(axi_seq_item);

     `uvm_object_utils(axi_write_seq)

     // Optional back-pointer to the environment (used for backdoor checks).
     axi_env m_env;

     // Number of write transactions to generate.
     int unsigned NUM_TRANSACTIONS = 4;

     function new(string name = "axi_write_seq");
          super.new(name);
     endfunction

     task body();

          axi_seq_item req;

          for (int i = 0; i < NUM_TRANSACTIONS; i++) begin

               req = axi_seq_item::type_id::create($sformatf("wr_item_%0d", i));

               start_item(req);

               // Randomize with a simple address constraint: stay within the memory model range.
               if (!req.randomize() with {
                    write == 1;
                    addr  inside {[`AXI_ADDR_WIDTH'h0000_1000 : `AXI_ADDR_WIDTH'h0000_1FF0]};
                    addr  % 8 == 0;          // 64-bit aligned
                    len   == 0;              // single-beat for now
                    size  == 3'b011;         // 8 bytes (matches DATA_WIDTH=64)
                    burst == 2'b01;          // INCR
               })
                    `uvm_fatal("AXI_WRITE_SEQ", "Randomization failed")

               finish_item(req);

               `uvm_info("AXI_WRITE_SEQ",
                    $sformatf("Write %0d: addr=0x%08h data=0x%016h resp=%0d",
                              i, req.addr, req.data, req.resp),
                    apb2axi_verbosity)

          end

     endtask

endclass
