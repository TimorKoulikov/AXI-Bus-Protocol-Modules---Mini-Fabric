/*------------------------------------------------------------------------------
 * top block of arbiter_sl
 *------------------------------------------------------------------------------*/

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

module arbiter_sl #(
	parameter int slave_id       = 0,
	parameter int NUM_OF_MASTERS = 4,
	parameter int QUEUE_DEPTH    = 16,
	parameter int CYCLES_S_TO_U  = 3
)
(
	input  logic                                aclk,         // axi clk
	input  logic                                aresetn,      // axi resetn

	// AW channel
	input  aw_bus  [NUM_OF_MASTERS - 1 : 0]     aw_data_in,   // aw data channel from router_ms
	input  patch_t [NUM_OF_MASTERS - 1 : 0]     aw_patch_in,  // aw patch from router_ms
	input  logic                                aw_ready_in,  // 1-bit awready signal from physical slave
	output logic   [NUM_OF_MASTERS - 1 : 0]     aw_ready_out, // awready array back to router_ms
	output aw_bus                               aw_data_out,  // axi aw data channel to physical slave

	// AR channel
	input  ar_bus  [NUM_OF_MASTERS - 1 : 0]     ar_data_in,   // ar data channel from router_ms
	input  patch_t [NUM_OF_MASTERS - 1 : 0]     ar_patch_in,  // ar patch from router_ms
	input  logic                                ar_ready_in,  // 1-bit arready signal from physical slave
	output logic   [NUM_OF_MASTERS - 1 : 0]     ar_ready_out, // arready array back to router_ms
	output ar_bus                               ar_data_out,  // axi ar data channel to physical slave

	// W channel
	input  w_bus   [NUM_OF_MASTERS - 1 : 0]     w_data_in,    // w data channel from router_ms
	input  patch_t [NUM_OF_MASTERS - 1 : 0]     w_patch_in,   // w patch from router_ms
	input  logic                                w_ready_in,   // 1-bit wready signal from physical slave
	output logic   [NUM_OF_MASTERS - 1 : 0]     w_ready_out,  // wready array back to router_ms
	output w_bus                                w_data_out,   // axi w data channel to physical slave

	// from arbiter engine
	input  logic   [2:0][NUM_OF_MASTERS - 1 : 0] grant        // one-hot grant signal from arbiter_engine
);

//-----logic-----
aw_bus  aw_data_in_sel;
patch_t aw_patch_in_sel;
logic   aw_rob_ready;

ar_bus  ar_data_in_sel;
patch_t ar_patch_in_sel;
logic   ar_rob_ready;

w_bus   w_data_in_sel;
patch_t w_patch_in_sel;
logic   w_rob_ready;


//==============================================================================
//----- AW Channel -----
//==============================================================================
// MUX: Translate one-hot grant to array index
always_comb begin
	aw_data_in_sel  = '0;
	aw_patch_in_sel = '0;
	aw_ready_out    = '0;
	
	for (int m = 0; m < NUM_OF_MASTERS; m++) begin
		if (grant[0][m]) begin
			aw_data_in_sel  = aw_data_in[m];
			aw_patch_in_sel = aw_patch_in[m];
			aw_ready_out[m] = aw_rob_ready;
		end
	end
end

// ROB
rob #(
	.BUS_TYPE     (aw_bus       ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U)
) u_aw_rob (
	.aclk         (aclk                               ),
	.aresetn      (aresetn                            ),
	.data_in      (aw_data_in_sel                     ),
	.patch_in     (aw_patch_in_sel                    ), 
	.push_enable  (|grant[0]                          ), // Push if any master is granted
	.ready_out    (aw_rob_ready                       ),
	.data_out     (aw_data_out                        ),
	.pop_enable   ('1								  )
);


//==============================================================================
//----- AR Channel -----
//==============================================================================
// MUX: Translate one-hot grant to array index
always_comb begin
	ar_data_in_sel  = '0;
	ar_patch_in_sel = '0;
	ar_ready_out    = '0;
	
	for (int m = 0; m < NUM_OF_MASTERS; m++) begin
		if (grant[1][m]) begin
			ar_data_in_sel  = ar_data_in[m];
			ar_patch_in_sel = ar_patch_in[m];
			ar_ready_out[m] = ar_rob_ready;
		end
	end
end

// ROB
rob #(
	.BUS_TYPE     (ar_bus       ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U)
) u_ar_rob (
	.aclk         (aclk                               ),
	.aresetn      (aresetn                            ),
	.data_in      (ar_data_in_sel                     ),
	.patch_in     (ar_patch_in_sel                    ),
	.push_enable  (|grant[1]                          ), 
	.ready_out    (ar_rob_ready                       ),
	.data_out     (ar_data_out                        ),
	.pop_enable          ('1  )
);


//==============================================================================
//----- W Channel -----
//==============================================================================
// MUX: Translate one-hot grant to array index
always_comb begin
	w_data_in_sel  = '0;
	w_patch_in_sel = '0;
	w_ready_out    = '0;
	
	for (int m = 0; m < NUM_OF_MASTERS; m++) begin
		if (grant[2][m]) begin
			w_data_in_sel  = w_data_in[m];
			w_patch_in_sel = w_patch_in[m];
			w_ready_out[m] = w_rob_ready;
		end
	end
end

// ROB
rob #(
	.BUS_TYPE     (w_bus        ), 
	.QUEUE_DEPTH  (QUEUE_DEPTH  ), 
	.CYCLES_S_TO_U(CYCLES_S_TO_U)
) u_w_rob (
	.aclk         (aclk                               ),
	.aresetn      (aresetn                            ),
	.data_in      (w_data_in_sel                      ),
	.patch_in     (w_patch_in_sel                     ),
	.push_enable  (|grant[2]                          ), 
	.ready_out    (w_rob_ready                        ),
	.data_out     (w_data_out                         ),
	.pop_enable   ('1		  						  )
);

endmodule