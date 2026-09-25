/*-----------------------------------------------------------------------------------------
 * module: patcher_w
 * description: 
 *   Appends routing metadata (target_slave, QoS) to incoming W-channel data bursts.
 *   
 *   To support high-throughput routing, data beats are NOT stored or delayed. 
 *   Every data beat is transferred immediately when the slave is ready.
 *
 *   Routing tags are fetched from an internal AW-to-W dependency queue (tag_queue)
 *   The tag at the head of the queue is applied to every beat in the current burst. 
 *   The tag-queue is only popped when the WLAST signal is asserted, completing the transaction 
 *   and exposing the next routing tag for the subsequent burst.
 *-----------------------------------------------------------------------------------------*/

module patcher_w (
	aclk,        // axi global clock signal
	arstn,       // global reset signal, active low
	data_in,     // AXI W bus that comes from axi component
	ready_in,    // ready signal the patcher receives from the downstream ROB (for data_out)
	patch_in,    // Routing tag coming from patcher_aw
	patch_valid, // High when patch_in bus (from patcher_aw) is valid
		
	ready_out,   // ready signal sent to master (ready for data_in)
	data_out,    // outgoing AXI bus payload (including the valid bit) sent downstream to the ROB
	patch_out,   // routing tag(patch_t) sent downstream to the ROB
);

//----- imports -----
import axi_datatypes::*;
import fabric_datatypes::*;


//----- parameters -----
parameter master_id = 0;
parameter NUM_OF_SLAVES = 3;
parameter QUEUE_DEPTH = 16;                	// outstanding size
localparam PTR_WIDTH = $clog2(QUEUE_DEPTH);		   

//----- Input Ports-----
input  logic    aclk;
input  logic    arstn;
input  w_bus    data_in;
input  logic    ready_in;
input  patch_t  patch_in;
input  logic    patch_valid;

//----- Output Ports -----
output w_bus    data_out;
output logic    ready_out;
output patch_t  patch_out;


//----- Internal Queue Logic -----
patch_t tag_queue [0:QUEUE_DEPTH-1]; 
logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;

/* --- count ---
 * tracks the number of write requests that have been accepted on the AW channel, 
   but whose data bursts have not yet finished on the W channel
 * has to store [0,16] range of values --> needs 5 bits */
logic [PTR_WIDTH:0]   count; 
							 
logic pop;
logic empty;
logic full;
logic do_push;
logic do_pop;

always_comb begin
	empty = (count == 0);
	full  = (count == QUEUE_DEPTH);
	
	// The WLAST trigger from the W-Channel
	pop = (data_in.valid && ready_out && data_in.wlast); 

	// explicit queue actions
    do_push = (patch_valid && !full);
    do_pop  = (pop && !empty);
end


//----- AW-to-W dependency queue (synchronous FIFO) -----
always_ff @(posedge aclk or negedge arstn) begin
	if (!arstn) begin
		wr_ptr <= '0;
		rd_ptr <= '0;
		count  <= '0;
	end
	
	else begin
		// 1) Pointer Updates
        if (do_push) begin
            tag_queue[wr_ptr] <= patch_in;
            wr_ptr <= wr_ptr + 1'b1;
        end
        
        if (do_pop) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
		
		// 2) FIFO Counter Updater
        // Note: If (do_push && do_pop) is true, they cancel out and count stays the same.
        if (do_push && !do_pop) begin
            count <= count + 1'b1;
        end 
        else if (!do_push && do_pop) begin
            count <= count - 1'b1;
        end
	end
end

//----- W-Channel Forwarding & Tagging -----
always_ff @(posedge aclk or negedge arstn) begin
	if (!arstn) begin
		data_out  <= '0;
		ready_out <= 1'b0;
		patch_out <= '0;
	end 
	
	else begin
		// We can only accept W data if both are true:
		// 1) we have a matching AW tag (the tag_queue is not empty)
		// 2) the downstream module (ROB) is ready to get data (ready_in==1'b1)
		if (!empty && ready_in == 1'b1) begin
			ready_out <= 1'b1;
		end else begin
			ready_out <= 1'b0;
		end
		
		// Payload & Tag Forwarding
		if (data_in.valid == 1'b1 && !empty) begin
			data_out  <= data_in;
			// Retrieve the target_slave & QoS metadata for this burst from the queue
			patch_out <= tag_queue[rd_ptr];
		end else begin
			data_out.valid <= 1'b0;
		end
	end
end

endmodule