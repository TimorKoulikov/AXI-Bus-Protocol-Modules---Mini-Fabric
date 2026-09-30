/*------------------------------------------------------------------------------
 * File          : arbiter_engine.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 4, 2026
 * Description   : Central arbitration and token allocation engine
 *------------------------------------------------------------------------------*/

module arbiter_engine #(
	parameter NUM_OF_MASTERS     = 4,
	parameter NUM_OF_SLAVES      = 3,
	parameter NUM_OF_CHANNEL     = 3, // For router_ms (AW, AR, W)
	parameter NUM_OF_SLV_CHANNEL = 2, // For router_sl (B, R)
	parameter TOKEN_WIDTH        = 30 
) 
(
	input aclk,
	input aresetn,
	
	// ==========================================================
	// interface for arbitration (router_ms)
	// ==========================================================
	input  [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] is_urgent,
	input  [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] end_transaction,
	output [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] grant,
	
	// interface for token_allocation (router_ms)
	input  [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0][1:0] needy_level,
	output [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0][1:0] mode,
	output [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0][TOKEN_WIDTH -1 : 0] num_of_tokens,

	// ==========================================================
	// interface for arbitration (router_sl)
	// ==========================================================
	input  [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0] sl_is_urgent,
	input  [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0] sl_end_transaction,
	output [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0] sl_grant,

	// interface for token_allocation (router_sl)
	input  [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0][1:0] sl_needy_level,
	output [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0][1:0] sl_mode,
	output [NUM_OF_SLV_CHANNEL -1 :0][NUM_OF_SLAVES -1 : 0][TOKEN_WIDTH -1 : 0] sl_num_of_tokens
);

// ----- imports -----
import axi_datatypes::*;

genvar i, j;
generate 
	
	// =========================================================================
	// Master Side (router_ms) Channels (AW, AR, W)
	// =========================================================================
	for(i = 0; i < NUM_OF_CHANNEL; i++) begin: get_block_rr_ms
		// generating aribter_rr for each master channel
		arbiter_rr #(.NUM_OF_MASTERS(NUM_OF_MASTERS))
			arbiter_rr_ms_inst (
				.aclk           (aclk              ),
				.aresetn        (aresetn           ),
				.is_urgent      (is_urgent[i]      ),
				.end_transaction(end_transaction[i]),
				.grant          (grant[i]          )
			);
	end
	
	// generation token allocation for each master channel
	for(i = 0; i < NUM_OF_MASTERS; i++) begin: gen_ms_token_alloc_master
		for(j = 0; j < NUM_OF_CHANNEL; j++) begin: gen_ms_token_alloc_channel
			assign mode[j][i] = needy_level[j][i];
			assign num_of_tokens[j][i] = (needy_level[j][i] >= EXSTRA_BW) ? TOKEN_WIDTH'(2048) : TOKEN_WIDTH'(1024);
		end
	end

	// =========================================================================
	// Slave Side (router_sl) Channels (B, R)
	// =========================================================================
	for(i = 0; i < NUM_OF_SLV_CHANNEL; i++) begin: get_block_rr_sl
		// generating aribter_rr for each slave channel
		// Note: We use NUM_OF_SLAVES as the parameter since there are NUM_OF_SLAVES competitors
		arbiter_rr #(.NUM_OF_MASTERS(NUM_OF_SLAVES))
			arbiter_rr_sl_inst (
				.aclk           (aclk                 ),
				.aresetn        (aresetn              ),
				.is_urgent      (sl_is_urgent[i]      ),
				.end_transaction(sl_end_transaction[i]),
				.grant          (sl_grant[i]          )
			);
	end
	
	// generation token allocation for each slave channel
	for(i = 0; i < NUM_OF_SLAVES; i++) begin: gen_sl_token_alloc_slave
		for(j = 0; j < NUM_OF_SLV_CHANNEL; j++) begin: gen_sl_token_alloc_channel
			assign sl_mode[j][i] = sl_needy_level[j][i];
			assign sl_num_of_tokens[j][i] = (sl_needy_level[j][i] >= EXSTRA_BW) ? TOKEN_WIDTH'(2048) : TOKEN_WIDTH'(1024);
		end
	end
	
endgenerate

endmodule