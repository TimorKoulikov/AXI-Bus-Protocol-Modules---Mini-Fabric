/*------------------------------------------------------------------------------
top block of router_sl
*------------------------------------------------------------------------------*/

module router_sl #(
	parameter slave_id       = 0,
	parameter NUM_OF_MASTERS = 4,
	parameter token_width    = 31,
	parameter [token_width -1 : 0] TOKEN_LOW_THRESHOLD = 8,
	parameter QUEUE_DEPTH    = 16,
	parameter CYCLES_S_TO_U  = 3,
	
	localparam NUM_OF_CHANNEL = 2
)
(
	aclk,               //axi clk
	aresetn,            //axi resetn
	
	// B channel
	b_data_channel,     //axi b data channel from slave
	b_ready_out,        //axi bready signal to slave
	b_data_out,         //b data channel to arbiter_ms
	b_ready_in,         //bready signal from arbiter_ms
	
	// R channel
	r_data_channel,     //axi r data channel from slave
	r_ready_out,        //axi rready signal to slave
	r_data_out,         //r data channel to arbiter_ms
	r_ready_in,         //rready signal from arbiter_ms
	
	// configuration
	cfg,                //cfg to patcher
	cfg_en,             //cfg enable signal
	
	// from/to arbiter_engine & router_control
	start_transaction,
	end_transaction,
	token_allocation,
	num_tokens,
	is_urgent,
	needy_level,
	mode
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;

input b_bus b_data_channel;
input r_bus r_data_channel;

input [NUM_OF_MASTERS - 1 : 0] b_ready_in;
input [NUM_OF_MASTERS - 1 : 0] r_ready_in;

input cfg_t cfg;
input cfg_en;
input [1:0] start_transaction;
input [1:0][token_width - 1 : 0] token_allocation;
input [1:0][2:0] mode;

//-----outputs-----
output logic b_ready_out;
output logic r_ready_out;

output b_bus [NUM_OF_MASTERS - 1 : 0] b_data_out;
output r_bus [NUM_OF_MASTERS - 1 : 0] r_data_out;

output [1:0] end_transaction;
output [1:0] is_urgent;
output [1:0][token_width - 1 : 0] num_tokens;
output logic [1:0][1:0] needy_level; 

//-----logic-----
// router <-> ROB wires
wire [NUM_OF_CHANNEL -1 : 0] full; 						
wire [NUM_OF_CHANNEL -1 : 0] empty; 					
wire [NUM_OF_CHANNEL -1 : 0] pop;
logic [NUM_OF_CHANNEL -1 : 0] token_enable;
logic [NUM_OF_CHANNEL -1 : 0][token_width -1 : 0] token_for_transaction;

// patcher -> ROB wires
wire b_bus   b_patcher_data_out;
wire r_bus   r_patcher_data_out;
wire patch_t b_patcher_patch_out;
wire patch_t r_patcher_patch_out;

// ROB -> output wires
wire         b_rob_ready_out;
wire b_bus   b_rob_data_out;
wire patch_t b_rob_patch_out;

wire         r_rob_ready_out;
wire r_bus   r_rob_data_out;
wire patch_t r_rob_patch_out;

//router_control
router_control #(
	.NUM_OF_CHANNEL(NUM_OF_CHANNEL),
	.token_width   (token_width   )
) u_router_control (
	.aclk                 (aclk                 ),
	.aresetn              (aresetn              ),
	.start_transaction    (start_transaction    ),
	.end_transaction      (end_transaction      ),
	.token_allocation     (token_allocation     ),
	.num_tokens           (num_tokens           ),
	.pop                  (pop                  ),
	.token_for_transaction(token_for_transaction),
	.token_enable         (token_enable         ),
	.full                 (full                 ),
	.empty                (empty                ),
	.mode                 (mode                 )
);

// needy
needy #(
	.NUM_OF_CHANNEL     (NUM_OF_CHANNEL     ), 
	.token_width        (token_width        ), 
	.TOKEN_LOW_THRESHOLD(TOKEN_LOW_THRESHOLD)
) u_needy (
	.token_allocation(token_allocation),
	.full            (full            ),
	.empty           (empty           ),
	.needy_level     (needy_level     )
);

//----- B ------
// input -> patcher
patcher_ax #(
	.BUS_TYPE     (b_bus         ),
	.master_id    (slave_id      ),
	.NUM_OF_SLAVES(NUM_OF_MASTERS)
) patcher_b (
	.aclk     (aclk               ),
	.aresetn  (aresetn            ),
	.data_in  (b_data_channel     ),
	.ready_out(b_ready_out        ),
	.data_out (b_patcher_data_out ),
	.ready_in (b_rob_ready_out    ),
	.patch_out(b_patcher_patch_out),
	.cfg      (cfg                ),
	.cfg_en   (cfg_en             )
);

// patcher -> rob
rob #(
	.BUS_TYPE     (b_bus        ),
	.QUEUE_DEPTH  (QUEUE_DEPTH  ),
	.CYCLES_S_TO_U(CYCLES_S_TO_U)
) u_b_rob (
	.aclk       (aclk               ),
	.arstn      (aresetn            ),
	.data_in    (b_patcher_data_out ),
	.patch_in   (b_patcher_patch_out),
	.push_enable(1'b1               ), 
	.ready_out  (b_rob_ready_out    ), 
	.data_out   (b_rob_data_out     ), 
	.patch_out  (b_rob_patch_out    ),
	.pop        (pop[0]             ),
	.empty_out  (empty[0]           ),
	.full_out   (full[0]            ),
	.got_urgent (is_urgent[0]       )
);

// Dispatcher: rob -> mux -> output
always_comb begin
	b_data_out = '0;
	token_enable[0] = 1'b0;
	token_for_transaction[0] = 1; // B channel payload is always 1 token
	
	if (!empty[0]) begin
		b_data_out[b_rob_patch_out.slave_id] = b_rob_data_out;
		token_enable[0] = b_ready_in[b_rob_patch_out.slave_id];
	end
end

//----- R -----
// input -> patcher
patcher_ax #(
	.BUS_TYPE     (r_bus         ),
	.master_id    (slave_id      ),
	.NUM_OF_SLAVES(NUM_OF_MASTERS)
) patcher_r (
	.aclk     (aclk               ),
	.aresetn  (aresetn            ),
	.data_in  (r_data_channel     ),
	.ready_out(r_ready_out        ),
	.data_out (r_patcher_data_out ),
	.ready_in (r_rob_ready_out    ),
	.patch_out(r_patcher_patch_out),
	.cfg      (cfg                ),
	.cfg_en   (cfg_en             )
);

// patcher -> rob
rob #(
	.BUS_TYPE     (r_bus        ),
	.QUEUE_DEPTH  (QUEUE_DEPTH  ),
	.CYCLES_S_TO_U(CYCLES_S_TO_U)
) u_r_rob (
	.aclk       (aclk               ),
	.arstn      (aresetn            ),
	.data_in    (r_patcher_data_out ),
	.patch_in   (r_patcher_patch_out),
	.push_enable(1'b1               ), 
	.ready_out  (r_rob_ready_out    ), 
	.data_out   (r_rob_data_out     ), 
	.patch_out  (r_rob_patch_out    ),
	.pop        (pop[1]             ),
	.empty_out  (empty[1]           ),
	.full_out   (full[1]            ),
	.got_urgent (is_urgent[1]       )
);

// Dispatcher: rob -> mux -> output
always_comb begin
	r_data_out = '0;
	token_enable[1] = 1'b0;
	token_for_transaction[1] = 1; // Set to burst length cost if tracking beats
	
	if (!empty[1]) begin
		r_data_out[r_rob_patch_out.slave_id] = r_rob_data_out;
		token_enable[1] = r_ready_in[r_rob_patch_out.slave_id];
	end
end

endmodule