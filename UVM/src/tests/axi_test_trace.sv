//------------------------------------------------------------------------------
// AXI Trace File Test (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Reads trace.txt (or a file specified by +TRACE_FILE=<path>), parses each
//   line, and dispatches AXI transactions to the appropriate master sequencer.
//
// Trace format (one transaction per line):
//   delay  master  write  address   urgent  stream  len
//   0      0       1      00001000  0       0       0
//   0      1       1      00002000  1       0       3
//
// Use 'X' or 'x' for write/address/urgent/stream/len to randomize that field.
// Data is ALWAYS randomized  it is not a trace column.
//
// Lines starting with '#' are comments and are skipped.
//------------------------------------------------------------------------------

class axi_test_trace extends axi_base_test;
    `uvm_component_utils(axi_test_trace)

    function new(string name = "axi_test_trace", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Helper: split a string by whitespace into tokens
    function int tokenize(string line, output string tokens[7]);
        int idx = 0;
        int i = 0;
        int line_len = line.len();
        string tok;

        while (i < line_len && idx < 7) begin
            // Skip whitespace
            while (i < line_len && (line[i] == " " || line[i] == "\t")) i++;
            if (i >= line_len) break;

            // Collect token
            tok = "";
            while (i < line_len && line[i] != " " && line[i] != "\t" && line[i] != "\n" && line[i] != "\r") begin
                tok = {tok, line[i]};
                i++;
            end
            if (tok.len() > 0) begin
                tokens[idx] = tok;
                idx++;
            end
        end
        return idx;
    endfunction

    // Helper: check if a token is 'X' or 'x' (meaning randomize)
    function bit is_random_token(string tok);
        return (tok.tolower() == "x");
    endfunction

    // Helper: convert hex string to address-width value
    function logic [`AXI_ADDR_WIDTH -1 : 0] hex_to_addr(string tok);
        logic [`AXI_ADDR_WIDTH -1 : 0] val;
        void'($sscanf(tok, "%h", val));
        return val;
    endfunction

    task run_phase(uvm_phase phase);
        int    fd;
        string line;
        string tokens[7];
        int    num_tokens;
        string filename = "trace.txt";

        int          delay;
        int          master;
        int          is_write;
        logic [`AXI_ADDR_WIDTH -1 : 0] addr;
        int          urgent;
        int          stream_flag;
        int          len;
        bit          rw, ra, ru, rs, rl;  // randomize flags

        phase.raise_objection(this);

        // Allow overriding filename from command line
        void'($value$plusargs("TRACE_FILE=%s", filename));

        fd = $fopen(filename, "r");
        if (fd == 0) `uvm_fatal("AXI_TEST_TRACE", $sformatf("Cannot open %s", filename))

        `uvm_info("AXI_TEST_TRACE", $sformatf("Parsing trace file: %s", filename), UVM_NONE)

        while (!$feof(fd)) begin
            void'($fgets(line, fd));

            // Skip empty lines and comments
            if (line.len() == 0) continue;
            if (line[0] == "#")   continue;

            num_tokens = tokenize(line, tokens);
            if (num_tokens < 7)   continue;

            // Delay and master are always required (not randomizable)
            void'($sscanf(tokens[0], "%d", delay));
            void'($sscanf(tokens[1], "%d", master));

            // Write field
            rw = is_random_token(tokens[2]);
            if (!rw) void'($sscanf(tokens[2], "%d", is_write));

            // Address field
            ra = is_random_token(tokens[3]);
            if (!ra) addr = hex_to_addr(tokens[3]);

            // Urgent field
            ru = is_random_token(tokens[4]);
            if (!ru) void'($sscanf(tokens[4], "%d", urgent));

            // Stream field
            rs = is_random_token(tokens[5]);
            if (!rs) void'($sscanf(tokens[5], "%d", stream_flag));
            
            // Len field
            rl = is_random_token(tokens[6]);
            if (!rl) void'($sscanf(tokens[6], "%d", len));

            `uvm_info("AXI_TEST_TRACE", $sformatf(
                "Parsed: delay=%0d master=%0d write=%s addr=%s urgent=%s stream=%s len=%s (data=RAND)",
                delay, master,
                rw ? "RAND" : $sformatf("%0d", is_write),
                ra ? "RAND" : $sformatf("0x%08h", addr),
                ru ? "RAND" : $sformatf("%0d", urgent),
                rs ? "RAND" : $sformatf("%0d", stream_flag),
                rl ? "RAND" : $sformatf("%0d", len)
            ), UVM_LOW)

            // Wait for the specified delay before dispatching
            if (delay > 0) begin
                #(delay * 1ns);
            end

            // Dispatch transaction in the background
            fork
                automatic int          m   = master;
                automatic int          w   = is_write;
                automatic logic [`AXI_ADDR_WIDTH -1 : 0] a = addr;
                automatic int          u   = urgent;
                automatic int          s   = stream_flag;
                automatic int          l   = len;
                automatic bit          fw  = rw;
                automatic bit          fa  = ra;
                automatic bit          fu  = ru;
                automatic bit          fs  = rs;
                automatic bit          fl  = rl;

                begin
                    axi_single_item_seq seq = axi_single_item_seq::type_id::create("seq");
                    seq.is_write    = w;
                    seq.req_addr    = a;
                    seq.req_urgent  = u;
                    seq.req_stream  = s;
                    seq.req_len     = l;
                    seq.rand_write  = fw;
                    seq.rand_addr   = fa;
                    seq.rand_urgent = fu;
                    seq.rand_stream = fs;
                    seq.rand_len    = fl;
                    // data is always randomized  no field to set

                    if (m >= 0 && m < `NUM_OF_MASTERS) begin
                        seq.start(env.axi_ag[m].axi_seqr);
                    end else begin
                        `uvm_error("AXI_TEST_TRACE", $sformatf("Invalid master_id %0d", m))
                    end
                end
            join_none
        end

        // Wait for all forked transactions to complete
        wait fork;
        $fclose(fd);

        `uvm_info("AXI_TEST_TRACE", "Trace sequence finished", UVM_NONE)

        phase.drop_objection(this);
    endtask
endclass
