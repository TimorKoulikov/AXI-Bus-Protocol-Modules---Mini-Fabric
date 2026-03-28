/*------------------------------------------------------------------------------
 * File          : arbiter_engine.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 28, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module arbiter_engine #(
parameter NUM_OF_MASTERS=4
)
(
input aclk,
input aresetn,
input  [NUM_OF_MASTERS -1 : 0] is_urgent,
input [NUM_OF_MASTERS -1 : 0 ] end_transaction,
output [NUM_OF_MASTERS -1 : 0] grant
);

localparam grand_index_width = $clog2(NUM_OF_MASTERS);

logic init_rr;
logic enable_regular;
logic enable_urgent;
logic [grand_index_width -1 : 0 ] grant_index_regular;
logic [grand_index_width -1 : 0 ] grant_index_urgent;
//logic [NUM_OF_MASTERS-1:0] enable_regular_bus;
typedef enum logic [1:0] {
	INIT,
	REGULAR,
	URGENT
} state_t;

state_t curr_state;
state_t next_state;

//assign enable_regular_bus ={NUM_OF_MASTERS{enable_regular}};

DW_arb_rr #(.n(NUM_OF_MASTERS),
	.output_mode(1),
	.index_mode(0))
	regular_rr ( .clk(aclk),
	.rst_n(aresetn),
	.init_n(init_rr),
	.enable('1),
	.request({NUM_OF_MASTERS{enable_regular}}),
	.mask('0),
	.granted(granted_inst),
	.grant(grant),
	.grant_index(grant_index_regular)
	);

DW_arb_rr #(.n(NUM_OF_MASTERS),
	.output_mode(0),
	.index_mode(2))
	urgent_rr ( .clk(aclk),
	.rst_n(aresetn),
	.init_n(init_rr),
	.enable(enable_urgent),
	.request('1),
	.mask('0),
	.granted(granted_inst),
	.grant(grant1),
	.grant_index(grant_index_urgent) );


//FSM
always_ff @(posedge aclk or negedge aresetn) begin
	if(!aresetn) begin
		curr_state<= INIT;
	end else begin
		curr_state<= next_state;
	end		
end

always_comb begin
	next_state = curr_state;
	init_rr=1'b1;
	enable_regular=1'b0;
	enable_urgent=1'b0;
	case(curr_state)
		
		INIT: begin
			init_rr=1'b0;
			next_state = REGULAR;
		end
		REGULAR : begin
			if(NUM_OF_MASTERS'(1) << grant_index_regular == end_transaction)//TODO: fix this must
				enable_regular=1'b1;
			if(is_urgent !='0) begin
				next_state=URGENT;
			end
		end
					
		URGENT : begin
			if(NUM_OF_MASTERS'(1) << grant_index_urgent == end_transaction)
				enable_urgent=1'b1;
			if(is_urgent =='0) begin
				next_state=REGULAR;
			end
		end
	endcase
end



endmodule