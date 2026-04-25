//------------------------------------------------------------------------------
// AXI Test (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Sequence dispatcher test. Selects and runs a specific AXI sequence based
//   on a simulation plusarg.
//
// How to run:
//   ./simv +UVM_TESTNAME=axi_test +AXI_SEQ=WRITE
//   ./simv +UVM_TESTNAME=axi_test +AXI_SEQ=READ
//   ./simv +UVM_TESTNAME=axi_test          (defaults to READ)
//
// How to add a new sequence:
//   1) Declare a handle below (e.g., my_seq_h)
//   2) Add an else-if branch with create + start
//------------------------------------------------------------------------------

class axi_test extends axi_base_test;
    `uvm_component_utils(axi_test)

    function new(string name = "axi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);

        string           seq_sel;
        axi_read_seq     rd_seq;
        axi_write_seq    wr_seq;

        // --------------- ADD NEW SEQUENCE HANDLES HERE ---------------
        // <SEQUENCE_CLASS> <handle_name>;

        phase.raise_objection(this);

        if (!$value$plusargs("AXI_SEQ=%s", seq_sel)) seq_sel = "READ";

        `uvm_info("AXI_TEST", $sformatf("Starting test, seq_sel=%s", seq_sel), UVM_NONE)
		// TODO : add for loop. for know lazy just want to check all work
        if (seq_sel.tolower() == "read") begin
            `uvm_info("AXI_TEST", "Running [READ] sequence", UVM_NONE)
            rd_seq        = axi_read_seq::type_id::create("rd_seq");
            rd_seq.m_env  = env;
            rd_seq.start(env.axi_ag.axi_seqr[0]);
        end
        else if (seq_sel.tolower() == "write") begin
            `uvm_info("AXI_TEST", "Running [WRITE] sequence", UVM_NONE)
            wr_seq        = axi_write_seq::type_id::create("wr_seq");
            wr_seq.m_env  = env;
            wr_seq.start(env.axi_ag.axi_seqr[0]);
        end

        // --------------- TEMPLATE FOR NEW SEQUENCES ---------------
        // else if (seq_sel.tolower() == "<name>") begin
        //     `uvm_info("AXI_TEST", "Running [<NAME>] sequence", UVM_NONE)
        //     <handle_name>        = <SEQUENCE_CLASS>::type_id::create("<name>_seq");
        //     <handle_name>.m_env  = env;
        //     <handle_name>.start(env.axi_ag.axi_seqr);
        // end

        `uvm_info("AXI_TEST", $sformatf("%s sequence finished", seq_sel), UVM_NONE)

        phase.drop_objection(this);

    endtask

endclass
