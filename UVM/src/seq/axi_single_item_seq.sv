//------------------------------------------------------------------------------
// Single Item AXI Sequence
//------------------------------------------------------------------------------
// Supports per-field randomization: if a rand_* flag is set, that field
// is left unconstrained (fully randomized).
//------------------------------------------------------------------------------
class axi_single_item_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_single_item_seq)
    
    // Variables configured by the caller
    bit        is_write;
    bit [31:0] req_addr;
    bit [63:0] req_data;
    bit        req_urgent;
    bit        req_stream;
    
    // Randomization control  when set, the corresponding field is randomized
    bit rand_write  = 0;
    bit rand_addr   = 0;
    bit rand_data   = 0;
    bit rand_urgent = 0;
    bit rand_stream = 0;
    
    function new(string name = "axi_single_item_seq");
        super.new(name);
    endfunction

    task body();
        axi_seq_item req = axi_seq_item::type_id::create("req");
        
        start_item(req);
        
        if (!req.randomize() with {
            if (!local::rand_write)     write  == local::is_write;
            if (!local::rand_addr)      addr   == local::req_addr;
            if (!local::rand_data)      data   == local::req_data;
            if (!local::rand_urgent)    urgent == local::req_urgent;
            if (!local::rand_stream)    stream == local::req_stream;
            len   == 0;      // 1 beat
            burst == 2'b01;  // INCR
            size  == 3'b011; // 8 bytes (64-bit)
        }) `uvm_fatal("SEQ", "Randomization failed")
        
        finish_item(req);
        `uvm_info("AXI_SINGLE_SEQ",
        $sformatf("Executed %s at 0x%08h (data: 0x%016h, urgent=%0b, stream=%0b, qos=%0b)", 
                (req.write ? "WRITE" : "READ"), req.addr, req.data,
                req.urgent, req.stream, req.qos),
        UVM_LOW)
    endtask
endclass
