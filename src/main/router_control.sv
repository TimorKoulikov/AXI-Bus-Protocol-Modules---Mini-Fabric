/*------------------------------------------------------------------------------
 * File          : router_control.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 26, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module router_control (
aclk,
aresetn,
start_transaction,
end_transaction,
token_allocation,
bw,
push,
pop,
is_urgent_in,
full,
empty,
is_stream,
is_urgent_out
);

//-----parameter-----
parameter NUM_OF_CHANNEL=3;

//parameter IS_MASTER = 1; //if true will create router_control_ms, else create router_control_sl

localparam token_width = 30;
//-----inputs-----
input aclk;
input aresetn;
input [NUM_OF_CHANNEL -1 : 0] start_transaction;
input [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_allocation;

//----- inputs from ROB
input [NUM_OF_CHANNEL -1 : 0] push;
input [NUM_OF_CHANNEL -1 : 0] empty;
input [NUM_OF_CHANNEL -1 : 0] full;
input [NUM_OF_CHANNEL -1 : 0] is_urgent_in;
input [NUM_OF_CHANNEL -1 : 0] is_stream;

//-----output-----
output [NUM_OF_CHANNEL -1 : 0] end_transaction;
output logic [NUM_OF_CHANNEL -1 : 0] pop;
output [NUM_OF_CHANNEL -1 : 0][token_width -1 :0] bw;
output [NUM_OF_CHANNEL -1 : 0] is_urgent_out;

//-----logic-----
wire [NUM_OF_CHANNEL - 1 :0][token_width -1 :0] curr_num_of_tokens;
wire [NUM_OF_CHANNEL - 1 :0][token_width -1 :0] new_num_of_tokens;
logic [NUM_OF_CHANNEL - 1:0] leak_enable;
wire [NUM_OF_CHANNEL - 1 :0] tercnt;
logic [NUM_OF_CHANNEL -1 : 0] stop_transaction;
logic [NUM_OF_CHANNEL - 1 : 0 ] insert_tokens;

typedef enum logic [1:0] {
	IDLE,
	TRANSACTION_ADD_TOKENS,
	TRANSACTION_POP_TOKENS
} state_t;

state_t [NUM_OF_CHANNEL -1 : 0] curr_state; 
state_t [NUM_OF_CHANNEL -1 : 0] next_state;
genvar i;
generate 
	
	for	(i=0;i<NUM_OF_CHANNEL;i++) begin : gen_block	
		
// logic of token managemnt
		// adder : new_num_of_tokens= num_of_tokens + token_allocation
		DW01_add #(token_width)
		token_adder (.A(curr_num_of_tokens[i]), .B(token_allocation[i]),.CI('0),.SUM(new_num_of_tokens[i]));
		
		// leaky_bucket : 
		DW03_updn_ctr #(.width(token_width)) 
				leaky_counter_token(
					.clk(aclk),
					.reset(aresetn),
					.data(new_num_of_tokens[i]),
					.count(curr_num_of_tokens[i]),
					.up_dn(1'b0),				//always count down
					.load(insert_tokens[i]),
					.tercnt(tercnt[i]),
					.cen(leak_enable[i])
		);
		
		
		//BW contorl		
		always_comb begin
			leak_enable[i] = 1'b1;
			pop[i] = 1'b1;
			stop_transaction[i] =1'b0;
			insert_tokens[i]=1'b1;
			case(curr_state)
				IDLE: begin
					leak_enable[i] = 1'b0;
					pop[i] = 1'b0;
				end
				TRANSACTION_ADD_TOKENS: begin
					insert_tokens[i]=1'b0;
				end
				
				TRANSACTION_POP_TOKENS: begin
					leak_enable[i] = 1'b1;
					pop[i] = 1'b1;
					if(tercnt[i]) begin
						stop_transaction[i] = 1'b1;
					end
				end
			endcase
		end
		
		//FSM
		always_ff @(posedge aclk or negedge aresetn) begin
			if(!aresetn) begin
				curr_state[i] <= IDLE;
			end else begin
				curr_state[i] <= next_state[i];
			end		
		end
		
		always_comb begin
			next_state[i] = curr_state[i];
			
			case(curr_state[i])
				
				IDLE: begin
					if(start_transaction[i] ) begin
						next_state[i] = TRANSACTION_ADD_TOKENS ;
					end
				end
				TRANSACTION_ADD_TOKENS : begin
					next_state[i]=TRANSACTION_POP_TOKENS;
					if(stop_transaction[i] || full[i] || empty[i])
						next_state[i] = IDLE;
					
				end
				
				TRANSACTION_POP_TOKENS : begin
					if(stop_transaction[i] || full[i] || empty[i])
						next_state[i] = IDLE;
				end
			endcase
		end
		
		
	end
	
endgenerate

assign is_urgent_out = is_urgent_in;

endmodule