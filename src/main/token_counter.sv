/*------------------------------------------------------------------------------
 * File          : token_counter.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 4, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module token_counter #(
	parameter token_width=30,
	localparam NUM_OF_MODES = 3
) 
(
	input aclk,
	input aresetn,
	input [token_width -1 : 0 ] data_load,
	input load,
	input [token_width -1 : 0 ] data_unload,
	input unload,
	output logic [token_width -1 : 0 ] count,
	input [NUM_OF_MODES -1 : 0 ] mode
	
);

logic [token_width -1 :0] add_token;
wire [token_width -1 :0] sub_token;
typedef enum logic [1:0]
{
	NO_LEAK,
	LEAK,
	EXSTRA_BW
	
} mode_token_allocation;


DW01_add #(token_width)
token_adder (.A(count), .B(data_load),.CI('0),.SUM(add_token));

DW01_sub #(.width(token_width)) 
token_sub (.A(count),.B(data_unload),.CI('0), .DIFF(sub_token) );

always_ff @(posedge aclk or negedge aresetn) begin
	if(!aresetn) begin
		count <= '0;
	end else begin
	
		case(mode)
			NO_LEAK :  begin
				if(load) 
					count <= data_load;
				if(unload)
					count <= sub_token;
			end
			
			LEAK , EXSTRA_BW: begin
				if(load)
					count <=add_token;
				if(unload)
					count <= sub_token;
			end
		endcase
	end
end


endmodule