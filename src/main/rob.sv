/*-----------------------------------------------------------------------------------------
 * Module: rob
 * Description: 
 *   Parameterized Reorder Buffer (ROB) utilizing an Age Counter array.
 *   - Universal BUS_TYPE parameter supports aw_bus, w_bus, ar_bus, r_bus, b_bus.
 *   - Push-in Logic: Handshakes via data_in.valid and ready_out. Gated by 'push_enable'.
 *   - Pop-out Logic: Handshakes via pop_enable and ready_in (downstream backpressure).
 *   - Intra-Queue Promotion: Pushing an urgent transaction instantly promotes older 
 *                            transactions with the same ID to maintain AXI FIFO ordering.
 *   - Stream Aging: Stream transactions naturally promote to urgent after CYCLES_S_TO_U.
 *   - Token Tracking: Outputs token_enable and tokens_used synchronously on a successful pop.
 *-----------------------------------------------------------------------------------------*/

//----- imports -----
import axi_datatypes::*;
import fabric_datatypes::*;

module rob #(
    parameter type BUS_TYPE = aw_bus,
    parameter QUEUE_DEPTH = MAX_OUTSTANDING, // for w_bus we have to define MAX_LEN*MAX_OUTSTANDING,
    parameter CYCLES_S_TO_U = 3,
    parameter TOKEN_WIDTH = 4
)(
    input  logic    aclk,
    input  logic    arstn,
    // --- Ingress (push) ---
    input  BUS_TYPE data_in,
    input  patch_t  patch_in,
    input  logic    push_enable, // Enable signal (from arbiter_control). If 1'b0, ROB refuses to accept new data.
    output logic    ready_out,   // Handshake signal sent upstream (e.g. to patcher or Master)

    // --- Egress (pop) ---
    output BUS_TYPE data_out,
    output patch_t  patch_out,
    input  logic    pop_enable,  // Enable signal (from router_control). If 1'b0, ROB refuses to pop-out data.
    input  logic    ready_in,    // Handshake signal from downstream (dispatcher or another rob)

    // --- Token Tracking (to Router Control) ---
    output logic    token_enable,
    output logic [TOKEN_WIDTH-1:0] tokens_used,  // Number of tokens used by the popped transaction

    // --- Status Flags (to Control Modules) ---
    output logic    is_empty_out,
    output logic    is_full_out,
    output logic    got_urgent
);

//----- Internal Array Sizing -----
localparam AGE_WIDTH = $clog2(QUEUE_DEPTH);
localparam TIMER_WIDTH = $clog2(CYCLES_S_TO_U + 1);

//----- The Register File Array -----
logic                   slot_valid [0:QUEUE_DEPTH-1];    
logic [AGE_WIDTH-1:0]   slot_age   [0:QUEUE_DEPTH-1];  // array of counters tracking how long every transaction has been in the ROB
logic [TIMER_WIDTH-1:0] slot_timer [0:QUEUE_DEPTH-1];  // array of counters tracking how long a stream transaction has been in the ROB
BUS_TYPE                slot_data  [0:QUEUE_DEPTH-1];  
patch_t                 slot_patch [0:QUEUE_DEPTH-1];

//----- Urgent Status & Push Handshake Logic -----
int     empty_idx;
logic   has_empty;   // indicates at least one empty slot exists
logic   do_push;
logic   do_pop;     

always_comb begin
    empty_idx  = 0;
    has_empty  = 1'b0;

    is_empty_out  = 1'b1;
    got_urgent = 1'b0;
    
    // scan array for first available empty slot and urgents status 
    for (int i = 0; i < QUEUE_DEPTH; i++) begin
        if (!has_empty && !slot_valid[i]) begin
            has_empty = 1'b1;
            empty_idx = i;
        end
        
        if (slot_valid[i]) begin
            is_empty_out = 1'b0;
            if (slot_patch[i].urgent) begin
                got_urgent = 1'b1; // caught at least one --> told to router_control
            end
        end
    end
    
    is_full_out = !has_empty; // if at least one empty slot exists, we are not full
    
    // ROB is ready to get data if both: it has space && the {arb,router}_control enables it
    ready_out = has_empty && push_enable;
    do_push = data_in.valid && ready_out;

    // successful pop occurs when the controller asks to pop and we actually have data
    do_pop = pop_enable && ready_in && !is_empty_out;
end


//----- Pop Logic (Find Oldest Winner) -----
logic [AGE_WIDTH-1:0] max_urg_age;
logic [AGE_WIDTH-1:0] max_norm_age;
int best_urg_idx;
int best_norm_idx;

logic found_urg;
logic found_norm;
int winner_idx;

always_comb begin
    max_urg_age   = '0;
    max_norm_age  = '0;
    best_urg_idx  =  0;
    best_norm_idx =  0;
    found_urg     =  1'b0;
    found_norm    =  1'b0;
    
    // scan all slots simultaneously
    for (int i = 0; i < QUEUE_DEPTH; i++) begin
        if (slot_valid[i]) begin
            if (slot_patch[i].urgent) begin
                if (!found_urg || slot_age[i] >= max_urg_age) begin
                    max_urg_age  = slot_age[i];
                    best_urg_idx = i;
                    found_urg    = 1'b1;
                end
            end 
            else begin // the slot is not urgent --> regular
                if (!found_norm || slot_age[i] >= max_norm_age) begin
                    max_norm_age  = slot_age[i];
                    best_norm_idx = i;
                    found_norm    = 1'b1;
                end
            end
        end
    end
    
    // prioritize urgent oldest upon regular oldest
    if (found_urg) begin
        winner_idx = best_urg_idx;
    end 
    else begin
        winner_idx = best_norm_idx;
    end
    
    // connect to output ports
    data_out  = slot_data[winner_idx];
    patch_out = slot_patch[winner_idx];
end


//----- Unified Array Updater (Registers) -----
always_ff @(posedge aclk or negedge arstn) begin
    if (!arstn) begin
        token_enable <= 1'b0;
        tokens_used  <= '0;
        for (int i = 0; i < QUEUE_DEPTH; i++) begin
            slot_valid[i] <= 1'b0;
            slot_age[i]   <= '0;
            slot_timer[i] <= '0;
        end
    end 
    else begin
        // token tracking - sync output on successful pop
        if (do_pop) begin
            token_enable <= 1'b1;
            tokens_used  <= slot_patch[winner_idx].len;
        end else begin
            token_enable <= 1'b0;
            tokens_used  <= '0;
        end

        // Push action - write new data into the empty slot
        if (do_push) begin
            slot_valid[empty_idx] <= 1'b1;
            slot_data[empty_idx]  <= data_in;
            slot_patch[empty_idx] <= patch_in;
            slot_age[empty_idx]   <= '0;
            slot_timer[empty_idx] <= '0;
        end

        // Scan all slots to pop, age, or promote to urgent
        for (int i = 0; i < QUEUE_DEPTH; i++) begin
            if (slot_valid[i]) begin
                if (do_pop && (winner_idx == i)) begin
                    // this slot is the winner to pop --> we invalidate it
                    slot_valid[i] <= 1'b0;
                end 
                else begin // others slots are staying in the ROB --> update
                    // 1) age incr
                    if (do_push && (i != empty_idx)) begin
                        slot_age[i] <= slot_age[i] + 1'b1;
                    end
                    
                    // 2) intra-queue id-traversal
                    // if the new push is urgent --> we promote all older transactions with the same ID to urgent
                    if (do_push && patch_in.urgent) begin
                        if (slot_data[i].id == data_in.id) begin 
                            slot_patch[i].urgent <= 1'b1;
                        end
                    end
                    
                    // 3) stream aging to urgent
                    if (slot_patch[i].stream && !slot_patch[i].urgent) begin
                        if (slot_timer[i] >= CYCLES_S_TO_U) begin
                            slot_patch[i].urgent <= 1'b1;
                        end else begin
                            slot_timer[i] <= slot_timer[i] + 1'b1;
                        end
                    end 
                end // end else (slot is staying)
            end // end if (valid)  
        end // end for loop
    end
end

endmodule