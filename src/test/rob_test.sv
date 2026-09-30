/*-----------------------------------------------------------------------------------------
 * Module: rob_test
 * Description: 
 * 		TB for the parameterized ROB
 * 		Validates FIFO mechanics, backpressure, urgent id-promotion, and stream aging.
 *-----------------------------------------------------------------------------------------*/

import axi_datatypes::*;
import fabric_datatypes::*;

module rob_test();

//----- Parameters -----
localparam QUEUE_DEPTH = MAX_OUTSTANDING;
localparam CYCLES_S_TO_U = 3;
localparam TOKEN_WIDTH = 4;

//----- Signals -----
logic    aclk;
logic    aresetn;

// Ingress
aw_bus   data_in;
patch_t  patch_in;
logic    push_enable;
logic    ready_out;

// Egress
aw_bus   data_out;
patch_t  patch_out;
logic    pop_enable;
logic    ready_in;

// Token Tracking
logic    token_enable;
logic [TOKEN_WIDTH-1:0] tokens_used;

// Status
logic    is_empty_out;
logic    is_full_out;
logic    got_urgent;

//----- DUT Instantiation -----
rob #(
    .BUS_TYPE(aw_bus),
    .QUEUE_DEPTH(QUEUE_DEPTH),
    .CYCLES_S_TO_U(CYCLES_S_TO_U),
    .TOKEN_WIDTH(TOKEN_WIDTH)
) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .data_in(data_in),
    .patch_in(patch_in),
    .push_enable(push_enable),
    .ready_out(ready_out),
    .data_out(data_out),
    .patch_out(patch_out),
    .pop_enable(pop_enable),
    .ready_in(ready_in),
    .token_enable(token_enable),
    .tokens_used(tokens_used),
    .is_empty_out(is_empty_out),
    .is_full_out(is_full_out),
    .got_urgent(got_urgent)
);

//----- clock  -----
initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk; // 10ns period
end

//----- helper tasks -----

// reset the dut to a known clean state
task reset_dut();
    begin
        aresetn = 1'b0;
        push_enable = 1'b0;
        pop_enable = 1'b0;
        ready_in = 1'b0;
        data_in = '0;
        patch_in = '0;
        // wait for 2 cycles of aclk to ensure reset propagates to all ffs
        @(posedge aclk);
        @(posedge aclk);
        // de-assert reset and wait 1 cycle to wake up the rob
        aresetn = 1'b1;
        @(posedge aclk);
    end
endtask

// to simulate the upstream (master or patcher) pushing a transaction into the rob
task push_tx(input logic [ID_WIDTH-1:0] id, input logic urgent, 
             input logic stream, input logic [LEN_WIDTH-1:0] len);
    begin
        data_in.valid = 1'b1;
        data_in.id    = id;
        patch_in.urgent = urgent;
        patch_in.stream = stream;
        patch_in.len    = len;
        push_enable   = 1'b1;
        
        // wait for handshake (when ready_out is asserted to 1)
        do begin
            @(posedge aclk);
        end while (!ready_out);
        
        // de-assert after push
        #1; 
        data_in.valid = 1'b0;
        push_enable   = 1'b0;
    end
endtask

// to simulate the downstream 
task pop_tx(output logic [ID_WIDTH-1:0] popped_id);
    begin
        pop_enable = 1'b1;
        ready_in   = 1'b1;
        
        // wait for non-empty to ensure successful pop
        do begin
            @(posedge aclk);
        end while (is_empty_out);
        
        // Capture the data that was popped
        popped_id = data_out.id;
        
        // De-assert after pop
        #1;
        pop_enable = 1'b0;
        ready_in   = 1'b0;
    end
endtask


//----- Testbench Logic -----
logic [ID_WIDTH-1:0] out_id;

initial begin
    reset_dut();

    // ---------------------------------------------------------
    $display("Tests 1,2,3: Basic Push & Pop Handshake");
    push_tx(.id(1), .urgent(0), .stream(0), .len(2));
    if (!is_empty_out) $display("test_1: PASS (ROB is not empty after push)");
    else $error("test_1: FAIL (ROB is empty after push)");
    
    pop_tx(out_id);
    if (out_id == 1) $display("test_2: PASS (popped correct ID (1))");
    else $error("test_2: FAIL (Expected ID 1, got %0d)", out_id);
    
    if (is_empty_out) $display("test_3: PASS (ROB is empty after pop)");
    else $error("test_3: FAIL (ROB not empty after pop)");

    //======================================

    $display("\nTest 4: Full-Queue Backpressure");
    for (int i = 0; i < QUEUE_DEPTH; i++) begin
        push_tx(.id(i[ID_WIDTH-1:0]), .urgent(0), .stream(0), .len(1));
    end
    #1;
    if (is_full_out && !ready_out) $display("test_4: PASS (queue is full, ready_out is properly gated)");
    else $error("test_4: FAIL (queue full backpressure failed)");
    
    // Drain others
    for (int i = 0; i < QUEUE_DEPTH; i++) begin
        pop_tx(out_id);
    end

    //======================================

    $display("\nTest 5: Tie-Breaker Verification");
    // Push two identical priority transactions, verify oldest pops first
    push_tx(.id(8), .urgent(0), .stream(0), .len(1)); // Oldest
    push_tx(.id(9), .urgent(0), .stream(0), .len(1)); // Youngest
    pop_tx(out_id);
    if (out_id == 8) $display("test_5: PASS (oldest normal transaction popped first)");
    else $error("test_5: FAIL (tie-breaker failed, got %0d)", out_id);
    pop_tx(out_id); // Drain remaining

    //======================================

    $display("\nTests 6,7: Urgent Intra-Queue ID Promotion");
    push_tx(.id(3), .urgent(0), .stream(0), .len(1)); // 1st in norm
    push_tx(.id(4), .urgent(0), .stream(0), .len(1)); // 2nd in norm
    push_tx(.id(5), .urgent(0), .stream(0), .len(1)); // 3rd in norm
    push_tx(.id(5), .urgent(1), .stream(0), .len(1)); // Urgent ID=5
    #1;
    if (got_urgent) $display("test_6: PASS (got_urgent asserted dynamically)");
    else $error("test_6: FAIL (got_urgent did not assert)");
    
    pop_tx(out_id);
    if (out_id == 5) $display("test_7: PASS (first id=5 transaction popped first due to inherited urgency)");
    else $error("test_7: FAIL (id Promotion failed, popped %0d)", out_id);
    
    // Drain remaining
    pop_tx(out_id); pop_tx(out_id); pop_tx(out_id);

    //======================================

    $display("\nTests 8,9: Stream Aging (CYCLES_S_TO_U)");
    // Push 7 normal transactions
    for (int i = 1; i <= 7; i++) begin
        push_tx(.id(i[ID_WIDTH-1:0]), .urgent(0), .stream(0), .len(1));
    end
    
    // Push the stream transaction (ID = 8)
    push_tx(.id(8), .urgent(0), .stream(1), .len(1));
    
    // Wait for aging threshold to pass
    for (int i = 0; i < CYCLES_S_TO_U + 2; i++) begin
        @(posedge aclk);
    end
    #1;
    
    if (got_urgent) $display("test_8: PASS (stream transaction id=8 aged into an urgent transaction)");
    else $error("test_8: FAIL (stream transaction did not promote to urgent.)");
    
    pop_tx(out_id);
    if (out_id == 8) $display("test_9: PASS (stream transaction id=8 bypassed normal traffic and popped)");
    else $error("test_9: FAIL (stream transaction did not pop first, got %0d)", out_id);
    
    // Drain remaining 7 transactions
    for (int i = 0; i < 7; i++) begin
        pop_tx(out_id);
        
    end

    //======================================

    $display("\nTest 10: Token Tracking Output");
    push_tx(.id(10), .urgent(0), .stream(0), .len(5)); // Push with len=5
    pop_tx(out_id); // This task waits for posedge aclk where pop happens
    
    // Check token_enable and tokens_used on the exact cycle of the pop
    if (token_enable && tokens_used == 5) 
        $display("test_10: PASS (tokens_used correctly outputted %0d with token_enable asserted.", tokens_used);
    else 
        $error("test_10: FAIL (token output incorrect. enable=%b, used=%0d", token_enable, tokens_used);

    $finish;
end

endmodule