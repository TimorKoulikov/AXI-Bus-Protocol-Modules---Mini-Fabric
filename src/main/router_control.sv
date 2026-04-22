/*------------------------------------------------------------------------------
 * File          : router_control.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 26, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module router_control #(
	parameter NUM_OF_CHANNEL=3,
	parameter token_width = 31
)
(
	input aclk,
	input aresetn,
	
	// interface with arbiter_engine
	input [NUM_OF_CHANNEL -1 : 0] start_transaction,
	output logic [NUM_OF_CHANNEL -1 : 0] end_transaction,
	input [NUM_OF_CHANNEL -1 : 0][token_width -1 :0]  token_allocation,
	input [1:0] mode,
	
	// interface with rob
	output logic [NUM_OF_CHANNEL -1 : 0] pop,
	input logic [NUM_OF_CHANNEL -1 : 0][token_width -1 :0] token_for_transaction,
	input logic [NUM_OF_CHANNEL -1 : 0] ready_for_transaction,
	input [NUM_OF_CHANNEL -1 : 0] full,
	input [NUM_OF_CHANNEL -1 : 0] empty
);
//-----logic-----
logic [NUM_OF_CHANNEL - 1:0][token_width -1 : 0] curr_num_tokens;
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
		token_counter  #(.token_width(token_width))
		u_token_counter 
		(
			.aclk(aclk),
			.aresetn(aresetn),
			.data_load(token_allocation[i]),
			.load(insert_tokens[i]),
			.data_unload(token_for_transaction[i]),
			.unload(pop[i]),
			.count(curr_num_tokens[i]),
			.mode(mode)
			
		);
		
		//BW contorl		
		always_comb begin
			pop[i] = 1'b0;
			insert_tokens[i]=1'b0;
			end_transaction[i]=1'b0;	
			stop_transaction[i]=1'b0;
			case(curr_state)
				IDLE: begin
					end_transaction[i] = 1'b1;
				end
				TRANSACTION_ADD_TOKENS: begin
					insert_tokens[i]=1'b1;
				end
				
				TRANSACTION_POP_TOKENS: begin	
					if( curr_num_tokens[i] < token_for_transaction[i]) begin
						stop_transaction[i]=1'b1;
					end else if(ready_for_transaction[i]) begin
						pop[i]=1'b1;
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

endmodule