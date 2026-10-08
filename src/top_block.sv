/*------------------------------------------------------------------------------
 * File          : top_block.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 24, 2026
 * Description   : Top-level interconnect wrapper
 *------------------------------------------------------------------------------*/

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

module top_block #(
	parameter NUM_OF_MASTERS = 3,
	parameter NUM_OF_SLAVES  = 4,
	parameter TOKEN_WIDTH    = 32
)
(
	input aclk,                             //axi clk
	input aresetn,                          //axi resetn
	input cfg_t cfg,
	input cfg_en,
	axi_if.master_if masters[NUM_OF_MASTERS], // Fabric acts as master to external slaves
	axi_if.slave_if  slaves[NUM_OF_SLAVES]// Fabric acts as slave to external masters
);

//----- Crossbar interconnect buses -----
// Forward path: router_ms [m][s] -> arbiter_sl [s][m]
aw_bus  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] aw_master_to_slave;
ar_bus  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] ar_master_to_slave;
w_bus   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] w_master_to_slave;

patch_t [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] aw_patch_master_to_slave;
patch_t [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] ar_patch_master_to_slave;
patch_t [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] w_patch_master_to_slave;

aw_bus  [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] aw_slave_from_master;
ar_bus  [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] ar_slave_from_master;
w_bus   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] w_slave_from_master;

patch_t [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] aw_patch_slave_from_master;
patch_t [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] ar_patch_slave_from_master;
patch_t [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] w_patch_slave_from_master;

logic   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] aw_ready_sl_to_ms;
logic   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] ar_ready_sl_to_ms;
logic   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] w_ready_sl_to_ms;

logic   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] aw_ready_ms_to_sl;
logic   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] ar_ready_ms_to_sl;
logic   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] w_ready_ms_to_sl;

// Return path: router_sl [s][m] -> arbiter_ms [m][s]
b_bus   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] b_slave_to_master_raw;
r_bus   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] r_slave_to_master_raw;

patch_t [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] b_patch_slave_to_master_raw;
patch_t [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] r_patch_slave_to_master_raw;

b_bus   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] b_slave_to_master;
r_bus   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] r_slave_to_master;

patch_t [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] b_patch_slave_to_master;
patch_t [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] r_patch_slave_to_master;

logic   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] b_ready_ms_to_sl;
logic   [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES  - 1 : 0] r_ready_ms_to_sl;

logic   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] b_ready_sl_from_ms;
logic   [NUM_OF_SLAVES  - 1 : 0][NUM_OF_MASTERS - 1 : 0] r_ready_sl_from_ms;

// Transpose [master][slave] <-> [slave][master] matrix
always_comb begin
	for (int m = 0; m < NUM_OF_MASTERS; m++) begin
		for (int s = 0; s < NUM_OF_SLAVES; s++) begin
			// Forward Data: Master -> Slave
			aw_slave_from_master[s][m]       = aw_master_to_slave[m][s];
			ar_slave_from_master[s][m]       = ar_master_to_slave[m][s];
			w_slave_from_master[s][m]        = w_master_to_slave[m][s];

			// Forward Patch: Master -> Slave
			aw_patch_slave_from_master[s][m] = aw_patch_master_to_slave[m][s];
			ar_patch_slave_from_master[s][m] = ar_patch_master_to_slave[m][s];
			w_patch_slave_from_master[s][m]  = w_patch_master_to_slave[m][s];

			// Return Data: Slave -> Master
			b_slave_to_master[m][s]          = b_slave_to_master_raw[s][m];
			r_slave_to_master[m][s]          = r_slave_to_master_raw[s][m];

			// Return Patch: Slave -> Master
			b_patch_slave_to_master[m][s]    = b_patch_slave_to_master_raw[s][m];
			r_patch_slave_to_master[m][s]    = r_patch_slave_to_master_raw[s][m];

			// Forward Ready (Slave->Master)
			aw_ready_ms_to_sl[m][s]          = aw_ready_sl_to_ms[s][m];
			ar_ready_ms_to_sl[m][s]          = ar_ready_sl_to_ms[s][m];
			w_ready_ms_to_sl[m][s]           = w_ready_sl_to_ms[s][m];

			// Return Ready (Master->Slave)
			b_ready_sl_from_ms[s][m]         = b_ready_ms_to_sl[m][s];
			r_ready_sl_from_ms[s][m]         = r_ready_ms_to_sl[m][s];
		end
	end
end

//----- Interconnect logic between arbiter_engine and master/slave -----
// Master Side Channels (AW, AR, W - 3 Channels)
logic [2:0][NUM_OF_MASTERS - 1 : 0]                      ms_is_urgent_eng;
logic [2:0][NUM_OF_MASTERS - 1 : 0]                      ms_end_transaction_eng;
logic [2:0][NUM_OF_MASTERS - 1 : 0]                      ms_grant_eng;
logic [2:0][NUM_OF_MASTERS - 1 : 0][TOKEN_WIDTH - 1 : 0] ms_num_of_tokens_eng;
logic [2:0][NUM_OF_MASTERS - 1 : 0][1:0]                 ms_needy_level_eng;
logic [2:0][NUM_OF_MASTERS - 1 : 0][1:0]                 ms_mode_eng;

// Slave Side Channels (B, R - 2 Channels)
logic [1:0][NUM_OF_SLAVES - 1 : 0]                       sl_is_urgent_eng;
logic [1:0][NUM_OF_SLAVES - 1 : 0]                       sl_end_transaction_eng;
logic [1:0][NUM_OF_SLAVES - 1 : 0]                       sl_grant_eng;
logic [1:0][NUM_OF_SLAVES - 1 : 0][TOKEN_WIDTH - 1 : 0]  sl_num_of_tokens_eng;
logic [1:0][NUM_OF_SLAVES - 1 : 0][1:0]                  sl_needy_level_eng;
logic [1:0][NUM_OF_SLAVES - 1 : 0][1:0]                  sl_mode_eng;


//----- Arbiter Engine -----
arbiter_engine #(
	.NUM_OF_MASTERS    (NUM_OF_MASTERS),
	.NUM_OF_SLAVES     (NUM_OF_SLAVES),
	.NUM_OF_CHANNEL    (3), // AR, AW, W
	.NUM_OF_SLV_CHANNEL(2), // R, B
	.TOKEN_WIDTH       (TOKEN_WIDTH)
) u_arbiter_engine (
	.aclk               (aclk                  ),
	.aresetn            (aresetn               ),
	// Master side (AW, AR, W)
	.ms_is_urgent          (ms_is_urgent_eng      ),
	.ms_end_transaction    (ms_end_transaction_eng),
	.ms_grant              (ms_grant_eng          ),
	.ms_needy_level        (ms_needy_level_eng    ),
	.ms_mode               (ms_mode_eng           ),
	.ms_num_of_tokens      (ms_num_of_tokens_eng  ),
	// Slave side (B, R)
	.sl_is_urgent       (sl_is_urgent_eng      ),
	.sl_end_transaction (sl_end_transaction_eng),
	.sl_grant           (sl_grant_eng          ),
	.sl_needy_level     (sl_needy_level_eng    ),
	.sl_mode            (sl_mode_eng           ),
	.sl_num_of_tokens   (sl_num_of_tokens_eng  )
);

//----- Master Side -----

genvar i;
generate
	for (i = 0; i < NUM_OF_MASTERS; i++) begin : gen_master

		// Local channel vectors for Master[i]
		logic [2:0]                      ms_is_urgent;
		logic [2:0]                      ms_end_transaction;
		logic [2:0]                      ms_start_transaction;
		logic [2:0][TOKEN_WIDTH - 1 : 0] ms_token_allocation;
		logic [2:0][TOKEN_WIDTH - 1 : 0] ms_curr_tokens;
		logic [2:0][1:0]                 ms_needy_level;
		logic [2:0][2:0]                 ms_mode; // 3-bit mode input on router

		aw_bus m_aw;
		ar_bus m_ar;
		w_bus  m_w;
		b_bus  m_b;
		r_bus  m_r;

		// 1. Pack AW channel (Interface -> Struct)
		assign m_aw.id      = masters[i].AWID;
		assign m_aw.addr    = masters[i].AWADDR;
		assign m_aw.len     = masters[i].AWLEN;
		assign m_aw.awsize  = masters[i].AWSIZE;
		assign m_aw.awburst = masters[i].AWBURST;
		assign m_aw.awlock  = masters[i].AWLOCK;
		assign m_aw.awcache = masters[i].AWCACHE;
		assign m_aw.awprot  = masters[i].AWPROT;
		assign m_aw.qos     = masters[i].AWQOS;
		assign m_aw.valid   = masters[i].AWVALID;

		// 2. Pack AR channel (Interface -> Struct)
		assign m_ar.id      = masters[i].ARID;
		assign m_ar.addr    = masters[i].ARADDR;
		assign m_ar.len     = masters[i].ARLEN;
		assign m_ar.arsize  = masters[i].ARSIZE;
		assign m_ar.arburst = masters[i].ARBURST;
		assign m_ar.arlock  = masters[i].ARLOCK;
		assign m_ar.arcache = masters[i].ARCACHE;
		assign m_ar.arprot  = masters[i].ARPROT;
		assign m_ar.qos     = masters[i].ARQOS;
		assign m_ar.valid   = masters[i].ARVALID;

		// 3. Pack W channel (Interface -> Struct)
		assign m_w.wdata    = masters[i].WDATA;
		assign m_w.wstrb    = masters[i].WSTRB;
		assign m_w.wlast    = masters[i].WLAST;
		assign m_w.valid    = masters[i].WVALID;
		assign m_w.id		= masters[i].WID;

		// 4. Unpack B & R channels (Struct -> Interface from arbiter_ms)
		assign masters[i].BID    = m_b.id;
		assign masters[i].BRESP  = m_b.bresp;
		assign masters[i].BVALID = m_b.valid;

		assign masters[i].RID    = m_r.id;
		assign masters[i].RDATA  = m_r.rdata;
		assign masters[i].RRESP  = m_r.rresp;
		assign masters[i].RLAST  = m_r.rlast;
		assign masters[i].RVALID = m_r.valid;

		router_ms #(
			.master_id    (i            ),
			.NUM_OF_SLAVES(NUM_OF_SLAVES),
			.TOKEN_WIDTH  (TOKEN_WIDTH  )
		) u_router_ms (
			.aclk             (aclk                       ),
			.aresetn          (aresetn                    ),
			.aw_data_channel  (m_aw                       ),
			.aw_ready_out     (masters[i].AWREADY         ),
			.aw_data_out      (aw_master_to_slave[i]      ),
			.aw_patch_out     (aw_patch_master_to_slave[i]), // New Patch Forward
			.aw_ready_in      (aw_ready_ms_to_sl[i]       ),
			.ar_data_channel  (m_ar                       ),
			.ar_ready_out     (masters[i].ARREADY         ),
			.ar_data_out      (ar_master_to_slave[i]      ),
			.ar_patch_out     (ar_patch_master_to_slave[i]), // New Patch Forward
			.ar_ready_in      (ar_ready_ms_to_sl[i]       ),
			.w_data_channel   (m_w                        ),
			.w_ready_out      (masters[i].WREADY          ),
			.w_data_out       (w_master_to_slave[i]       ),
			.w_patch_out      (w_patch_master_to_slave[i] ), // New Patch Forward
			.w_ready_in       (w_ready_ms_to_sl[i]        ),
			.cfg              (cfg                        ),
			.cfg_en           (cfg_en                     ),
			.start_transaction(ms_start_transaction       ),
			.end_transaction  (ms_end_transaction         ),
			.token_allocation (ms_token_allocation        ),
			.num_tokens       (ms_curr_tokens             ),
			.mode             (ms_mode                    ),
			.is_urgent        (ms_is_urgent               ),
			.needy_level      (ms_needy_level             )
		);

		arbiter_ms #(
			.master_id    (i            ),
			.NUM_OF_SLAVES(NUM_OF_SLAVES)
		) u_arbiter_ms (
			.aclk       (aclk                       ),
			.aresetn    (aresetn                    ),
			.b_data_in  (b_slave_to_master[i]       ),
			.b_ready_in (masters[i].BREADY          ),
			.b_patch_in (b_patch_slave_to_master[i] ), // New Patch Return
			.b_ready_out(b_ready_ms_to_sl[i]        ),
			.b_data_out (m_b                        ),
			.r_data_in  (r_slave_to_master[i]       ),
			.r_ready_in (masters[i].RREADY          ),
			.r_patch_in (r_patch_slave_to_master[i] ), // New Patch Return
			.r_ready_out(r_ready_ms_to_sl[i]        ),
			.r_data_out (m_r                        ),
			.grant      (sl_grant_eng               )
		);

		// Transpose between [channel][master] and [master][channel]
		always_comb begin
			for (int c = 0; c < 3; c++) begin
				// Outputs from Master -> Inputs to Arbiter Engine
				ms_is_urgent_eng[c][i]       = ms_is_urgent[c];
				ms_end_transaction_eng[c][i] = ms_end_transaction[c];
				ms_needy_level_eng[c][i]     = ms_needy_level[c];

				// Outputs from Arbiter Engine -> Inputs to Master
				ms_start_transaction[c]      = ms_grant_eng[c][i];
				ms_token_allocation[c]       = ms_num_of_tokens_eng[c][i];
				ms_mode[c]                   = {1'b0, ms_mode_eng[c][i]}; // Zero-extend 2-bit to 3-bit mode
			end
		end

	end //end for
endgenerate

//----- Slave Side -----
genvar j;
generate
	for (j = 0; j < NUM_OF_SLAVES; j++) begin : gen_slave

		logic [1:0]                      sl_start_transaction;
		logic [1:0]                      sl_end_transaction;
		logic [1:0]                      sl_is_urgent;
		logic [1:0][TOKEN_WIDTH - 1 : 0] sl_token_allocation;
		logic [1:0][TOKEN_WIDTH - 1 : 0] sl_curr_tokens;
		logic [1:0][1:0]                 sl_needy_level;
		logic [1:0][2:0]                 sl_mode;

		aw_bus s_aw;
		ar_bus s_ar;
		w_bus  s_w;
		b_bus  s_b;
		r_bus  s_r;

		// 1. Unpack AW channel (Struct from arbiter_sl -> Slave Interface)
		assign slaves[j].AWID    = s_aw.id;
		assign slaves[j].AWADDR  = s_aw.addr;
		assign slaves[j].AWLEN   = s_aw.len;
		assign slaves[j].AWSIZE  = s_aw.awsize;
		assign slaves[j].AWBURST = s_aw.awburst;
		assign slaves[j].AWLOCK  = s_aw.awlock;
		assign slaves[j].AWCACHE = s_aw.awcache;
		assign slaves[j].AWPROT  = s_aw.awprot;
		assign slaves[j].AWQOS   = s_aw.qos;
		assign slaves[j].AWVALID = s_aw.valid;

		// 2. Unpack AR channel (Struct from arbiter_sl -> Slave Interface)
		assign slaves[j].ARID    = s_ar.id;
		assign slaves[j].ARADDR  = s_ar.addr;
		assign slaves[j].ARLEN   = s_ar.len;
		assign slaves[j].ARSIZE  = s_ar.arsize;
		assign slaves[j].ARBURST = s_ar.arburst;
		assign slaves[j].ARLOCK  = s_ar.arlock;
		assign slaves[j].ARCACHE = s_ar.arcache;
		assign slaves[j].ARPROT  = s_ar.arprot;
		assign slaves[j].ARQOS   = s_ar.qos;
		assign slaves[j].ARVALID = s_ar.valid;

		// 3. Unpack W channel (Struct from arbiter_sl -> Slave Interface)
		assign slaves[j].WDATA   = s_w.wdata;
		assign slaves[j].WSTRB   = s_w.wstrb;
		assign slaves[j].WLAST   = s_w.wlast;
		assign slaves[j].WVALID  = s_w.valid;
        assign slaves[j].WID     = s_w.id;

		// 4. Pack B & R channels (Slave Interface -> Struct into router_sl)
		assign s_b.id    = slaves[j].BID;
		assign s_b.bresp = slaves[j].BRESP;
		assign s_b.valid = slaves[j].BVALID;

		assign s_r.id    = slaves[j].RID;
		assign s_r.rdata = slaves[j].RDATA;
		assign s_r.rresp = slaves[j].RRESP;
		assign s_r.rlast = slaves[j].RLAST;
		assign s_r.valid = slaves[j].RVALID;

		router_sl #(
			.slave_id      (j             ),
			.NUM_OF_MASTERS(NUM_OF_MASTERS),
			.TOKEN_WIDTH   (TOKEN_WIDTH   )
		) u_router_sl (
			.aclk             (aclk                          ),
			.aresetn          (aresetn                       ),
			.b_data_channel   (s_b                           ),
			.b_ready_out      (slaves[j].BREADY              ),
			.b_ready_in       (b_ready_sl_from_ms[j]         ),
			.b_data_out       (b_slave_to_master_raw[j]      ),
			.b_patch_out      (b_patch_slave_to_master_raw[j]), // New Patch Return
			.r_data_channel   (s_r                           ),
			.r_ready_out      (slaves[j].RREADY              ),
			.r_ready_in       (r_ready_sl_from_ms[j]         ),
			.r_data_out       (r_slave_to_master_raw[j]      ),
			.r_patch_out      (r_patch_slave_to_master_raw[j]), // New Patch Return
			.cfg              (cfg                           ),
			.cfg_en           (cfg_en                        ),
			.start_transaction(sl_start_transaction          ),
			.end_transaction  (sl_end_transaction            ),
			.token_allocation (sl_token_allocation           ),
			.num_tokens       (sl_curr_tokens                ),
			.is_urgent        (sl_is_urgent                  ),
			.needy_level      (sl_needy_level                ),
			.mode             (sl_mode                       )
		);

		arbiter_sl #(
			.slave_id      (j             ),
			.NUM_OF_MASTERS(NUM_OF_MASTERS)
		) u_arbiter_sl (
			.aclk        (aclk                           ),
			.aresetn     (aresetn                        ),
			.aw_data_in  (aw_slave_from_master[j]        ),
			.aw_patch_in (aw_patch_slave_from_master[j]  ), // New Patch Forward
			.aw_ready_in (slaves[j].AWREADY              ),
			.aw_ready_out(aw_ready_sl_to_ms[j]           ),
			.aw_data_out (s_aw                           ),
			.ar_data_in  (ar_slave_from_master[j]        ),
			.ar_patch_in (ar_patch_slave_from_master[j]  ), // New Patch Forward
			.ar_ready_in (slaves[j].ARREADY              ),
			.ar_ready_out(ar_ready_sl_to_ms[j]           ),
			.ar_data_out (s_ar                           ),
			.w_data_in   (w_slave_from_master[j]         ),
			.w_patch_in  (w_patch_slave_from_master[j]   ), // New Patch Forward
			.w_ready_in  (slaves[j].WREADY               ),
			.w_ready_out (w_ready_sl_to_ms[j]            ),
			.w_data_out  (s_w                            ),
			.grant       (ms_grant_eng                   ) 
		);

		always_comb begin
			for (int c = 0; c < 2; c++) begin
				// Outputs from Slave -> Inputs to Arbiter Engine
				sl_is_urgent_eng[c][j]       = sl_is_urgent[c];
				sl_end_transaction_eng[c][j] = sl_end_transaction[c];
				sl_needy_level_eng[c][j]     = sl_needy_level[c];

				// Outputs from Arbiter Engine -> Inputs to Slave
				sl_start_transaction[c]      = sl_grant_eng[c][j];
				sl_token_allocation[c]       = sl_num_of_tokens_eng[c][j];
				sl_mode[c]                   = {1'b0, sl_mode_eng[c][j]}; // Zero-extend 2-bit to 3-bit mode
			end
		end

	end
endgenerate

endmodule