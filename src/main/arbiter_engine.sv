/*------------------------------------------------------------------------------
 * File          : arbiter_engine.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 4, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module arbiter_engine #(
	parameter NUM_OF_MASTERS = 4,
	localparam NUM_OF_CHANNEL = 5
) 
(
	input aclk,
	input aresetn,
	// interface for arbitration (arbiter__rr )
	input [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] is_urgent,
	input [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] end_transaction,
	output [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] grant,
	
	//interface for token_allocation
	output [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0][31:0] num_of_tokens
);


genvar i;
genvar j;
generate 
		
		
		for(i=0;i< NUM_OF_CHANNEL; i++) begin: get_block_rr
		//generating aribter_rr for each channel
			arbiter_rr #(.NUM_OF_MASTERS(NUM_OF_MASTERS))
				arbiter_rr_inst (
					.aclk(aclk),
					.aresetn(aresetn),
					.is_urgent(is_urgent[i]),
					.end_transaction(end_transaction[i]),
					.grant(grant[i])
				);
		end
		
		//generation token allocation for each channel
			for(i=0;i< NUM_OF_MASTERS;i++) begin: gen_block_token_allocation_per_master
				for(j=0;j<NUM_OF_CHANNEL;j++) begin: gen_block_token_allocation_per_channel
					assign num_of_tokens[j][i]= 31'd1024;
				end
			end
		
		
		
endgenerate




endmodule