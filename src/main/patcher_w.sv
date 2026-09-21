/*-----------------------------------------------------------------------------------------
 * module: patcher_w
 * description: 
 *   Appends routing metadata (target_slave, QoS) to incoming W-channel data bursts.
 *   
 *   To support high-throughput routing, data beats are NOT stored or delayed. 
 *   Every data beat is transferred immediately when the slave is ready.
 *
 *   Routing tags are fetched from an internal AW-to-W dependency queue. 
 *   The tag at the head of the queue is applied to every beat in the current burst. 
 *   The tag-queue is only popped when the WLAST signal is asserted, completing the transaction 
 *   and exposing the next routing tag for the subsequent burst.
 *-----------------------------------------------------------------------------------------*/

module patcher_w (
	aclk,        // axi global clock signal
	aresetn,     // global reset signal. active low
	data_in,     // AXI W bus that comes from axi component
	ready_in,    // ready signal the patcher receives from the downstream ROB (for data_out)
	patch_in,    // Routing tag coming from patcher_aw
	patch_valid, // High when patcher_aw successfully captures AW transaction
		
	data_out,    // outgoing AXI bus payload (including the valid bit) sent downstream to the ROB/FIFO
	ready_out,   // ready signal the patcher sends to master (ready for data_in)
	patch_out,   // patched data the patcher added
);

//----- imports -----
import axi_datatypes::*;
import fabric_datatypes::*;


// TODO : think we have to move these to external file
//----- parameters -----
parameter master_id = 0;
parameter NUM_OF_SLAVES = 3;
parameter QUEUE_DEPTH = 16;                	// outstanding size
localparam PTR_WIDTH = $clog2(QUEUE_DEPTH);		   

//----- Input Ports-----
input  logic    aclk;
input  logic    aresetn;
input  w_bus    data_in;
input  logic    ready_in;
input  patch_t  patch_in;
input  logic    patch_valid;

//----- Output Ports -----
output w_bus    data_out;
output logic    ready_out;
output patch_t  patch_out;


//----- Internal Queue Logic -----
patch_t aw_to_w_queue [0:QUEUE_DEPTH-1]; 
logic [PTR_WIDTH-1:0] wr_ptr;
logic [PTR_WIDTH-1:0] rd_ptr;
logic [PTR_WIDTH:0]   count;

logic pop;
logic empty;
logic full;

always_comb begin
	empty = (count == 0);
	full  = (count == QUEUE_DEPTH);
	
	// Pop the queue when the final beat of the W burst is successfully transferred
	pop = (data_in.valid && ready_out && data_in.wlast); 
end


//----- AW-to-W dependency queue (synchronous FIFO) -----
always_ff @(posedge aclk or negedge aresetn) begin
	if (!aresetn) begin
		wr_ptr <= '0;
		rd_ptr <= '0;
		count  <= '0;
	end 
	
	else begin
		// Push logic (Tag arrives from AW channel)
		if (patch_valid && !full) begin
			aw_to_w_queue[wr_ptr] <= patch_in;
			wr_ptr <= wr_ptr + 1'b1;
		end
		
		// Pop logic (W channel burst completes)
		if (pop && !empty) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
		
		// FIFO Counter updater
		if (patch_valid && !full && !(pop && !empty)) begin
			count <= count + 1'b1;
		end else if (!(patch_valid && !full) && (pop && !empty)) begin
			count <= count - 1'b1;
		end
	end
end

//----- W-Channel Forwarding & Tagging -----
always_ff @(posedge aclk or negedge aresetn) begin
	if (!aresetn) begin
		data_out  <= '0;
		ready_out <= 1'b0;
		patch_out <= '0;
	end 
	
	else begin
		// Backpressure: We can only accept W data if we have a matching AW tag (!empty)
		// AND the downstream fabric module is ready (ready_in)
		if (empty || ready_in == 1'b0) begin
			ready_out <= 1'b0;
		end else begin
			ready_out <= 1'b1;
		end
		
		// Payload & Tag Forwarding
		if (data_in.valid == 1'b1 && !empty) begin
			data_out  <= data_in;
			
			// Retrieve the target_slave & QoS metadata for this burst from the queue
			patch_out <= aw_to_w_queue[rd_ptr];
		end else begin
			data_out.valid <= 1'b0;
		end
	end
end

endmodule