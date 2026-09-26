/*------------------------------------------------------------------------------
 * File          : top_block.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

module top_block #(
	parameter NUM_OF_MASTERS = 3,
	parameter NUM_OF_SLAVES = 4,
	parameter token_width = 30
)
(
	input aclk,				//axi clk
	input aresetn,			//axi resetn
	input cfg_t cfg,				
	input cfg_en,
	axi_if.slave_if			slaves[NUM_OF_SLAVES],
	axi_if.master_if		masters[NUM_OF_MASTERS]
);

// parameters
localparam NUM_OF_CHANNEL = 5;

//interconnect logic between slaves to master
aw_bus [NUM_OF_MASTERS -1 : 0][NUM_OF_SLAVES -1 : 0]  aw_master_to_slave;
ar_bus [NUM_OF_MASTERS -1 : 0][NUM_OF_SLAVES -1 : 0]  ar_master_to_slave;
w_bus  [NUM_OF_MASTERS -1 : 0][NUM_OF_SLAVES -1 : 0]  w_master_to_slave;
r_bus  [NUM_OF_MASTERS -1 : 0][NUM_OF_SLAVES -1 : 0]  r_master_to_slave;
b_bus  [NUM_OF_MASTERS -1 : 0][NUM_OF_SLAVES -1 : 0]  b_master_to_slave;

logic  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES - 1 : 0] aw_ready_ms_to_slave;
logic  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES - 1 : 0] ar_ready_ms_to_slave;
logic  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES - 1 : 0] w_ready_ms_to_slave;
logic  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES - 1 : 0] b_ready_ms_to_slave;
logic  [NUM_OF_MASTERS - 1 : 0][NUM_OF_SLAVES - 1 : 0] r_ready_ms_to_slave;

//interconnect logic between arbiter_engine to master/slave
logic [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] 		is_urgent;
logic [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0]			end_transaction;
logic [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0] 		grant;
logic [NUM_OF_CHANNEL -1 :0][NUM_OF_MASTERS -1 : 0][token_width -1 : 0]	num_of_tokens;



// Arbiter engine
arbiter_engine #(.NUM_OF_MASTERS(NUM_OF_MASTERS), .NUM_OF_CHANNEL(NUM_OF_CHANNEL)) u_arbiter_engine (
	.aclk           (aclk           ),
	.aresetn        (aresetn        ),
	.is_urgent      (is_urgent      ),
	.end_transaction(end_transaction),
	.grant          (grant          ),
	.num_of_tokens  (num_of_tokens  )
);
// Master side
genvar i;
generate
	for( i=0;i <NUM_OF_MASTERS ; i++) begin: gen_master
		
		//index swap between aribter_engine signals and router/arbiter _ms units.
		// logic for aribter_engine.is_urgent 
		logic [NUM_OF_CHANNEL - 1 : 0] ms_is_urgent;
		logic [NUM_OF_CHANNEL - 1 : 0] ms_end_transaction;
		logic [NUM_OF_CHANNEL -1 :0][token_width -1 : 0]	ms_num_of_tokens;
		logic [NUM_OF_CHANNEL -1 :0] ms_grant;

		// Local 1D data buses for Master[i]
		aw_bus [NUM_OF_SLAVES - 1 : 0] aw_ms_data;
		ar_bus [NUM_OF_SLAVES - 1 : 0] ar_ms_data;
		w_bus  [NUM_OF_SLAVES - 1 : 0] w_ms_data;
		b_bus  [NUM_OF_SLAVES - 1 : 0] b_ms_data;
		r_bus  [NUM_OF_SLAVES - 1 : 0] r_ms_data;

		// Local 1D ready wires for Master[i]
		logic  aw_ms_ready;
		logic  ar_ms_ready;
		logic  w_ms_ready;
		logic [NUM_OF_SLAVES - 1 : 0] b_ms_ready;
		logic [NUM_OF_SLAVES - 1 : 0] r_ms_ready;

		// Local struct wires for Master[i]
		aw_bus m_aw;
		ar_bus m_ar;
		w_bus  m_w;
		b_bus  m_b;
		r_bus  m_r;
		
		// 1. Pack AW channel (Interface -> Struct)
		assign m_aw.id    = masters[i].AWID;
		assign m_aw.addr    = masters[i].AWADDR;
		assign m_aw.awlen   = masters[i].AWLEN;
		assign m_aw.awsize  = masters[i].AWSIZE;
		assign m_aw.awburst = masters[i].AWBURST;
		assign m_aw.awlock  = masters[i].AWLOCK;
		assign m_aw.awcache = masters[i].AWCACHE;
		assign m_aw.awprot  = masters[i].AWPROT;
		assign m_aw.qos     = masters[i].AWQOS;
		assign m_aw.valid   = masters[i].AWVALID;

		// 2. Pack AR channel (Interface -> Struct)
		assign m_ar.id    = masters[i].ARID;
		assign m_ar.addr    = masters[i].ARADDR;
		assign m_ar.arlen   = masters[i].ARLEN;
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

		// 4. Unpack B & R channels (Struct -> Interface from arbiter_ms)
		assign masters[i].BID    = m_b.id;
		assign masters[i].BRESP  = m_b.bresp;
		assign masters[i].BVALID = m_b.valid;

		assign masters[i].RID    = m_r.id;
		assign masters[i].RDATA  = m_r.rdata;
		assign masters[i].RRESP  = m_r.rresp;
		assign masters[i].RLAST  = m_r.rlast;
		assign masters[i].RVALID = m_r.valid;
		
		router_ms #(.master_id(i), .NUM_OF_SLAVES(NUM_OF_SLAVES), .token_width(token_width)) u_router_ms (
			.aclk             (aclk              ),
			.aresetn          (aresetn           ),
			.aw_data_channel  (m_aw              ),
			.aw_ready_out     (masters[i].AWREADY),
			.aw_data_out      (aw_ms_data        ),
			.aw_ready_in	  (aw_ms_ready       ),
			.ar_data_channel  (m_ar              ),
			.ar_ready_out     (masters[i].ARREADY),
			.ar_data_out      (ar_ms_data        ),
			.ar_ready_in	  (ar_ms_ready       ),
			.w_data_channel   (m_w               ),
			.w_ready_out      (masters[i].WREADY ),
			.w_data_out       (w_ms_data         ),
			.w_ready_in	  	  (w_ms_ready     	 ),
			.cfg              (cfg               ),
			.cfg_en           (cfg_en            ),
			.start_transaction(ms_grant[2:0]     ),
			.end_transaction  (ms_end_transaction),
			.token_allocation (ms_num_of_tokens  ),
			.is_urgent        (ms_is_urgent      )
		);
		
		arbiter_ms #(.master_id(i), .NUM_OF_SLAVES(NUM_OF_SLAVES)) u_arbiter_ms (
			.aclk       (aclk             ),
			.aresetn    (aresetn          ),
			.b_data_in  (b_ms_data        ),
			.b_ready_in (masters[i].BREADY),
			.b_ready_out(b_ms_ready       ),
			.b_data_out (m_b              ),
			.r_data_in  (r_ms_data        ),
			.r_ready_in (masters[i].RREADY),
			.r_ready_out(r_ms_ready       ),
			.r_data_out (m_r              ),
			.grant      (ms_grant[1:0]    )
			// might add is_urgent
		);
		
		always_comb begin
			for (int c = 0; c < NUM_OF_CHANNEL; c++) begin
				is_urgent[c][i] = ms_is_urgent[c];
				end_transaction[c][i] = ms_end_transaction[c];
				ms_grant[c] = grant[c][i];
				ms_num_of_tokens[c] = num_of_tokens[c][i];
			end

			for (int s = 0; s < NUM_OF_SLAVES; s++) begin
				// AW, AR, W data: Master -> Slave
				aw_master_to_slave[i][s] = aw_ms_data[s];
				ar_master_to_slave[i][s] = ar_ms_data[s];
				w_master_to_slave[i][s]  = w_ms_data[s];

				// B, R data: Slave -> Master
				b_ms_data[s] = b_master_to_slave[i][s];
				r_ms_data[s] = r_master_to_slave[i][s];

				// AW, AR, W ready: Slave -> Master
				aw_ms_ready = aw_ready_ms_to_slave[i][s];
				ar_ms_ready = ar_ready_ms_to_slave[i][s];
				w_ms_ready  = w_ready_ms_to_slave[i][s];

				// B, R ready: Master -> Slave
				b_ready_ms_to_slave[i][s] = b_ms_ready[s];
				r_ready_ms_to_slave[i][s] = r_ms_ready[s];
			end
		end
		
	end
endgenerate

// Slave side
genvar j;
generate
	for (j = 0; j < NUM_OF_SLAVES; j++) begin : gen_slave

		// Local control wires for Slave[j]
		logic [1:0]                      sl_start_transaction;
		logic [1:0]                      sl_end_transaction;
		logic [1:0]                      sl_is_urgent;
		logic [1:0][token_width - 1 : 0] sl_token_allocation;
		logic [1:0][token_width - 1 : 0] sl_bw;
		logic [2:0]                      sl_grant;

		// Local 1D data buses for Slave[j]
		aw_bus [NUM_OF_MASTERS - 1 : 0] aw_sl_data;
		ar_bus [NUM_OF_MASTERS - 1 : 0] ar_sl_data;
		w_bus  [NUM_OF_MASTERS - 1 : 0] w_sl_data;
		b_bus  [NUM_OF_MASTERS - 1 : 0] b_sl_data;
		r_bus  [NUM_OF_MASTERS - 1 : 0] r_sl_data;

		// Local 1D ready wires for Slave[j]
		logic [NUM_OF_MASTERS - 1 : 0] aw_sl_ready;
		logic [NUM_OF_MASTERS - 1 : 0] ar_sl_ready;
		logic [NUM_OF_MASTERS - 1 : 0] w_sl_ready;
		logic  b_sl_ready;
		logic  r_sl_ready;

		// Local struct wires for Slave[j]
		aw_bus s_aw;
		ar_bus s_ar;
		w_bus  s_w;
		b_bus  s_b;
		r_bus  s_r;

		// 1. Unpack AW channel (Struct from arbiter_sl -> Slave Interface)
		assign slaves[j].AWID    = s_aw.id;
		assign slaves[j].AWADDR  = s_aw.addr;
		assign slaves[j].AWLEN   = s_aw.awlen;
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
		assign slaves[j].ARLEN   = s_ar.arlen;
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

		// 4. Pack B & R channels (Slave Interface -> Struct into router_sl)
		assign s_b.bid   = slaves[j].BID;
		assign s_b.bresp = slaves[j].BRESP;
		assign s_b.valid = slaves[j].BVALID;

		assign s_r.rid   = slaves[j].RID;
		assign s_r.rdata = slaves[j].RDATA;
		assign s_r.rresp = slaves[j].RRESP;
		assign s_r.rlast = slaves[j].RLAST;
		assign s_r.valid = slaves[j].RVALID;

		router_sl #(
			.slave_id      (j             ),
			.NUM_OF_MASTERS(NUM_OF_MASTERS),
			.token_width   (token_width   )
		) u_router_sl (
			.aclk             (aclk                 ),
			.aresetn          (aresetn              ),
			.b_data_channel   (s_b                  ),
			.b_ready_out      (slaves[j].BREADY     ),
			.b_ready_in       (b_sl_ready           ),
			.b_data_out       (b_sl_data            ),
			.r_data_channel   (s_r                  ),
			.r_ready_out      (slaves[j].RREADY     ),
			.r_ready_in       (r_sl_ready           ),
			.r_data_out       (r_sl_data            ),
			.cfg              (cfg                  ),
			.cfg_en           (cfg_en               ),
			.start_transaction(sl_start_transaction ),
			.end_transaction  (sl_end_transaction   ),
			.token_allocation (sl_token_allocation  ),
			.bw               (sl_bw                ),
			.is_urgent        (sl_is_urgent         )
		);

		arbiter_sl #(
			.slave_id      (j             ),
			.NUM_OF_MASTERS(NUM_OF_MASTERS)
		) u_arbiter_sl (
			.aclk        (aclk             ),
			.aresetn     (aresetn          ),
			.aw_data_in  (aw_sl_data       ),
			.aw_ready_in (slaves[j].AWREADY),
			.aw_ready_out(aw_sl_ready      ),
			.aw_data_out (s_aw             ),
			.ar_data_in  (ar_sl_data       ),
			.ar_ready_in (slaves[j].ARREADY),
			.ar_ready_out(ar_sl_ready      ),
			.ar_data_out (s_ar             ),
			.w_data_in   (w_sl_data        ),
			.w_ready_in  (slaves[j].WREADY ),
			.w_ready_out (w_sl_ready       ),
			.w_data_out  (s_w              ),
			.grant       (sl_grant         )
		);

		always_comb begin
			for (int m = 0; m < NUM_OF_MASTERS; m++) begin
				// AW, AR, W data: Master -> Slave
				aw_sl_data[m] = aw_master_to_slave[m][j];
				ar_sl_data[m] = ar_master_to_slave[m][j];
				w_sl_data[m]  = w_master_to_slave[m][j];

				// B, R data: Slave -> Master
				b_master_to_slave[m][j] = b_sl_data[m];
				r_master_to_slave[m][j] = r_sl_data[m];

				// AW, AR, W ready: Slave -> Master
				aw_ready_ms_to_slave[m][j] = aw_sl_ready[m];
				ar_ready_ms_to_slave[m][j] = ar_sl_ready[m];
				w_ready_ms_to_slave[m][j]  = w_sl_ready[m];

				// B, R ready: Master -> Slave
				b_sl_ready = b_ready_ms_to_slave[m][j];
				r_sl_ready = r_ready_ms_to_slave[m][j];
			end
		end

	end
endgenerate


endmodule