//------------------------------------------------------------------------------
// AXI Trace File Test (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Reads trace.txt (or a file specified by +TRACE_FILE=<path>), parses each
//   line, and dispatches AXI transactions to the appropriate master sequencer.
//
// Trace format (one transaction per line):
//   delay  master  write  address   data      urgent  stream
//   0      0       1      00001000  ABCD1234  0       0
//   0      1       1      00002000  DEADBEEF  1       0
//
// Use 'X' for any field (write/address/data/urgent/stream) to randomize it:
//   0      0       X      X         X         X       X
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
        int len = line.len();
        string tok;

        while (i < len && idx < 7) begin
            // Skip whitespace
            while (i < len && (line[i] == " " || line[i] == "\t")) i++;
            if (i >= len) break;

            // Collect token
            tok = "";
            while (i < len && line[i] != " " && line[i] != "\t" && line[i] != "\n" && line[i] != "\r") begin
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

    // Helper: convert hex string to 64-bit value
    function logic [63:0] hex_to_val(string tok);
        logic [63:0] val;
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
        logic [31:0] addr;
        logic [63:0] data;
        int          urgent;
        int          stream_flag;
        bit          rw, ra, rd, ru, rs;  // randomize flags

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
            if (!ra) addr = hex_to_val(tokens[3]);

            // Data field
            rd = is_random_token(tokens[4]);
            if (!rd) data = hex_to_val(tokens[4]);

            // Urgent field
            ru = is_random_token(tokens[5]);
            if (!ru) void'($sscanf(tokens[5], "%d", urgent));

            // Stream field
            rs = is_random_token(tokens[6]);
            if (!rs) void'($sscanf(tokens[6], "%d", stream_flag));

            `uvm_info("AXI_TEST_TRACE", $sformatf(
                "Parsed: delay=%0d master=%0d write=%s addr=%s data=%s urgent=%s stream=%s",
                delay, master,
                rw ? "RAND" : $sformatf("%0d", is_write),
                ra ? "RAND" : $sformatf("0x%08h", addr),
                rd ? "RAND" : $sformatf("0x%016h", data),
                ru ? "RAND" : $sformatf("%0d", urgent),
                rs ? "RAND" : $sformatf("%0d", stream_flag)
            ), UVM_LOW)

            // Wait for the specified delay before dispatching
            if (delay > 0) begin
                #(delay * 1ns);
            end

            // Dispatch transaction in the background
            fork
                automatic int          m   = master;
                automatic int          w   = is_write;
                automatic logic [31:0] a   = addr;
                automatic logic [63:0] d   = data;
                automatic int          u   = urgent;
                automatic int          s   = stream_flag;
                automatic bit          fw  = rw;
                automatic bit          fa  = ra;
                automatic bit          fd_flag = rd;
                automatic bit          fu  = ru;
                automatic bit          fs  = rs;

                begin
                    axi_single_item_seq seq = axi_single_item_seq::type_id::create("seq");
                    seq.is_write    = w;
                    seq.req_addr    = a;
                    seq.req_data    = d;
                    seq.req_urgent  = u;
                    seq.req_stream  = s;
                    seq.rand_write  = fw;
                    seq.rand_addr   = fa;
                    seq.rand_data   = fd_flag;
                    seq.rand_urgent = fu;
                    seq.rand_stream = fs;

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
