/*------------------------------------------------------------------------------
 * top block of router_ms
 *------------------------------------------------------------------------------*/

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

module router_ms #(
	parameter master_id                                    = 0,
	parameter NUM_OF_SLAVES                                = 3,
	parameter TOKEN_WIDTH                                  = 30,
	parameter logic [TOKEN_WIDTH - 1 : 0] TOKEN_LOW_THRESHOLD = 8,
	parameter QUEUE_DEPTH                                  = 16,
	parameter CYCLES_S_TO_U                                = 3,
	
	localparam NUM_OF_CHANNEL                              = 3
)
(
	input  logic                                    aclk,              // axi clk
	input  logic                                    aresetn,           // axi resetn
	
	// AW channel
	input  aw_bus                                   aw_data_channel,   // axi aw data channel
	output logic [NUM_OF_SLAVES - 1 : 0]            aw_ready_out,      // axi awready signal to master
	output aw_bus  [NUM_OF_SLAVES - 1 : 0]          aw_data_out,       // aw data channel to slave_arbiter
	output patch_t [NUM_OF_SLAVES - 1 : 0]          aw_patch_out,      // aw patch to slave_arbiter
	input  logic [NUM_OF_SLAVES - 1 : 0]            aw_ready_in,       // aw ready from slave		
	
	// AR channel
	input  ar_bus                                   ar_data_channel,   // axi ar data channel
	output logic [NUM_OF_SLAVES - 1 : 0]            ar_ready_out,      // axi arready signal to master
	output ar_bus  [NUM_OF_SLAVES - 1 : 0]          ar_data_out,       // ar data channel to slave_arbiter
	output patch_t [NUM_OF_SLAVES - 1 : 0]          ar_patch_out,      // ar patch to slave_arbiter
	input  logic [NUM_OF_SLAVES - 1 : 0]            ar_ready_in,       // ar ready from slave	
	
	// W channel
	input  w_bus                                    w_data_channel,    // axi w data channel
	output logic [NUM_OF_SLAVES - 1 : 0]            w_ready_out,       // axi wready signal to master
	output w_bus   [NUM_OF_SLAVES - 1 : 0]          w_data_out,        // w data channel to slave_arbiter
	output patch_t [NUM_OF_SLAVES - 1 : 0]          w_patch_out,       // w patch to slave_arbiter
	input  logic [NUM_OF_SLAVES - 1 : 0]            w_ready_in,        // w ready from slave	

	// from arbiter_engine
	input  cfg_t                                    cfg,               // cfg to patcher_ax
	input  logic                                    cfg_en,            // cfg enable signal
	input  logic [2:0]                              start_transaction,
	output logic [2:0]                              end_transaction,
	input  logic [2:0][TOKEN_WIDTH - 1 : 0]         token_allocation,
	output logic [2:0][TOKEN_WIDTH - 1 : 0]         num_tokens,
	output logic [2:0]                              is_urgent,
	output logic [2:0][2:0]                         needy_level,       // [num_of_channel][needy_num_of_bits]
	input  logic [2:0][2:0]                         mode
);

//-----logic-----
// router <-> ROB wires
wire  [NUM_OF_CHANNEL - 1 : 0]                      full; 						
wire  [NUM_OF_CHANNEL - 1 : 0]                      empty; 					
wire  [NUM_OF_CHANNEL - 1 : 0]                      pop_enable;
logic [NUM_OF_CHANNEL - 1 : 0]                      token_enable;
logic [NUM_OF_CHANNEL - 1 : 0][TOKEN_WIDTH - 1 : 0] token_for_transaction;

// patcher -> ROB wires
wire aw_bus  aw_patcher_data_out;
wire ar_bus  ar_patcher_data_out;
wire w_bus   w_patcher_data_out;
wire         aw_patcher_ready_out;
wire         ar_patcher_ready_out;
wire         w_patcher_ready_out;
wire patch_t aw_patcher_patch_out;
wire patch_t ar_patcher_patch_out;
wire patch_t w_patcher_patch_out;

// ROB -> output wires
wire         aw_rob_ready_out;
wire aw_bus  aw_rob_data_out;
wire patch_t aw_rob_patch_out_internal;
logic        aw_rob_ready_in;

wire         ar_rob_ready_out;
wire ar_bus  ar_rob_data_out;
wire patch_t ar_rob_patch_out_internal;
logic        ar_rob_ready_in;

wire         w_rob_ready_out;
wire w_bus   w_rob_data_out;
wire patch_t w_rob_patch_out_internal;
logic        w_rob_ready_in;

//router_control
router_control #(
	.NUM_OF_CHANNEL(NUM_OF_CHANNEL),
	.TOKEN_WIDTH   (TOKEN_WIDTH   )
) u_router_control (
	.aclk                 (aclk                 ),
	.aresetn              (aresetn              ),
	.start_transaction    (start_transaction    ),
	.end_transaction      (end_transaction      ),
	.token_allocation     (token_allocation     ),
	.num_tokens           (num_tokens           ),
	.pop_enable           (pop_enable           ),
	.token_for_transaction(token_for_transaction),
	.token_enable         (token_enable         ),
	.full                 (full                 ),
	.empty                (empty                ),
	.mode                 (mode                 )
);

// needy
needy #(
	.NUM_OF_CHANNEL     (NUM_OF_CHANNEL     ), 
	.TOKEN_WIDTH        (TOKEN_WIDTH        ), 
	.TOKEN_LOW_THRESHOLD(TOKEN_LOW_THRESHOLD)
) u_needy (
	.token_allocation(token_allocation),
	.full            (full            ),
	.empty           (empty           ),
	.needy_level     (needy_level     )
);

//==============================================================================
//----- AW Channel -----
//==============================================================================

// input -> patcher
patcher_ax #(.BUS_TYPE(aw_bus), .master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES)) pathcer_aw(
	.aclk     (aclk                ),
	.aresetn  (aresetn             ),
	.data_in  (aw_data_channel     ),
	.ready_out(aw_ready_out        ), 
	.data_out (aw_patcher_data_out ),
	.ready_in (aw_rob_ready_out	   ),
	.patch_out(aw_patcher_patch_out),
	.cfg      (cfg                 ),
	.cfg_en   (cfg_en              )
);

// patcher -> rob
rob #(
	.BUS_TYPE     (aw_bus       ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U),
	.TOKEN_WIDTH  (TOKEN_WIDTH  )
) u_aw_rob (
	.aclk         (aclk                     ),
	.aresetn      (aresetn                  ),
	.data_in      (aw_patcher_data_out      ),
	.patch_in     (aw_patcher_patch_out     ),
	.push_enable  (1'b1                     ), 
	.ready_out    (aw_rob_ready_out         ), 
	.data_out     (aw_rob_data_out          ), 
	.patch_out    (aw_rob_patch_out_internal),
	.pop_enable   (pop_enable[0]            ),
	.ready_in     (aw_rob_ready_in          ),
	.token_enable (token_enable[0]          ),
	.tokens_used  (token_for_transaction[0] ),
	.is_empty_out (empty[0]                 ),
	.is_full_out  (full[0]                  ),
	.got_urgent   (is_urgent[0]             )
);

// rob -> mux -> output
always_comb begin
	aw_data_out     = '0;
	aw_patch_out    = '0;
	//aw_ready_out    = '0; 
	aw_rob_ready_in = 1'b0;
	if (!empty[0]) begin
		aw_data_out[aw_rob_patch_out_internal.slave_id]  = aw_rob_data_out;
		aw_patch_out[aw_rob_patch_out_internal.slave_id] = aw_rob_patch_out_internal;
		aw_rob_ready_in                                  = aw_ready_in[aw_rob_patch_out_internal.slave_id];
	end
end

//==============================================================================
//----- AR Channel -----
//==============================================================================

// input -> patcher
patcher_ax #(.BUS_TYPE(ar_bus), .master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES)) pathcer_ar(
	.aclk     (aclk                ),
	.aresetn  (aresetn             ),
	.data_in  (ar_data_channel     ),
	.ready_out(ar_ready_out        ), 
	.data_out (ar_patcher_data_out ),
	.ready_in (ar_patcher_ready_out),
	.patch_out(ar_patcher_patch_out),
	.cfg      (cfg                 ),
	.cfg_en   (cfg_en              )
);

// patcher -> rob
rob #(
	.BUS_TYPE     (ar_bus       ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U),
	.TOKEN_WIDTH  (TOKEN_WIDTH  )
) u_ar_rob (
	.aclk         (aclk                     ),
	.aresetn      (aresetn                  ),
	.data_in      (ar_patcher_data_out      ),
	.patch_in     (ar_patcher_patch_out     ),
	.push_enable  (1'b1                     ), 
	.ready_out    (ar_rob_ready_out         ), 
	.data_out     (ar_rob_data_out          ), 
	.patch_out    (ar_rob_patch_out_internal),
	.pop_enable   (pop_enable[1]            ),
	.ready_in     (ar_rob_ready_in          ),
	.token_enable (token_enable[1]          ),
	.tokens_used  (token_for_transaction[1] ),
	.is_empty_out (empty[1]                 ),
	.is_full_out  (full[1]                  ),
	.got_urgent   (is_urgent[1]             )
);

// rob -> mux -> output
always_comb begin
	ar_data_out     = '0;
	ar_patch_out    = '0;
	//ar_ready_out    = '0;
	ar_rob_ready_in = 1'b0;
	if (!empty[1]) begin
		ar_data_out[ar_rob_patch_out_internal.slave_id]  = ar_rob_data_out;
		ar_patch_out[ar_rob_patch_out_internal.slave_id] = ar_rob_patch_out_internal;
		ar_rob_ready_in                                  = ar_ready_in[ar_rob_patch_out_internal.slave_id];
	end
end

//==============================================================================
//----- W Channel -----
//==============================================================================

// input -> patcher
patcher_w #(.master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES), .QUEUE_DEPTH(QUEUE_DEPTH)) pathcer_w(
	.aclk       (aclk                       ),
	.aresetn    (aresetn                    ),
	.data_in    (w_data_channel             ),
	.ready_out  (w_ready_out                ), 
	.data_out   (w_patcher_data_out         ),
	.ready_in   (w_rob_ready_out        ),
	.patch_in   (aw_patcher_patch_out       ),
	.patch_valid(aw_patcher_data_out.valid  ),
	.patch_out  (w_patcher_patch_out        )
);

// patcher -> rob
rob #(
	.BUS_TYPE     (w_bus        ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U),
	.TOKEN_WIDTH  (TOKEN_WIDTH  )
) u_w_rob (
	.aclk         (aclk                     ),
	.aresetn      (aresetn                  ),
	.data_in      (w_patcher_data_out       ),
	.patch_in     (w_patcher_patch_out      ),
	.push_enable  (1'b1                     ), 
	.ready_out    (w_rob_ready_out          ), 
	.data_out     (w_rob_data_out           ), 
	.patch_out    (w_rob_patch_out_internal ),
	.pop_enable   (pop_enable[2]            ),
	.ready_in     (w_rob_ready_in           ),
	.token_enable (token_enable[2]          ),
	.tokens_used  (token_for_transaction[2] ),
	.is_empty_out (empty[2]                 ),
	.is_full_out  (full[2]                  ),
	.got_urgent   (is_urgent[2]             )
);

// rob -> mux -> output
always_comb begin
	w_data_out     = '0;
	w_patch_out    = '0;
	//w_ready_out    = '0;
	w_rob_ready_in = 1'b0;
	if (!empty[2]) begin
		w_data_out[w_rob_patch_out_internal.slave_id]  = w_rob_data_out;
		w_patch_out[w_rob_patch_out_internal.slave_id] = w_rob_patch_out_internal;
		w_rob_ready_in                                 = w_ready_in[w_rob_patch_out_internal.slave_id];
	end
end

endmodule