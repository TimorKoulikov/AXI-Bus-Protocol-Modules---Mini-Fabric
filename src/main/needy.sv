/*------------------------------------------------------------------------------
 * File          : needy.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Jul 10, 2026
 * Description   : per-channel needy score (0-7) used by the arbiter -
 *                  grows with rob fullness and shrinks with token_allocation
 *------------------------------------------------------------------------------*/

module needy #(
	parameter NUM_OF_CHANNEL = 3,
	parameter token_width = 31,
	parameter [token_width -1 : 0] TOKEN_LOW_THRESHOLD = 8
)
(
	// interface with router_control
	input [NUM_OF_CHANNEL -1 : 0][token_width -1 : 0] token_allocation,

	// interface with rob
	input [NUM_OF_CHANNEL -1 : 0] full,
	input [NUM_OF_CHANNEL -1 : 0] half_full,
	input [NUM_OF_CHANNEL -1 : 0] empty,

	output logic [NUM_OF_CHANNEL -1 : 0][2:0] needy
);
//-----logic-----
logic [1:0] rob_level;

always_comb begin
	for (int i = 0; i < NUM_OF_CHANNEL; i++) begin
		if (full[i])
			rob_level = 2'd3;
		else if (half_full[i])
			rob_level = 2'd2;
		else if (empty[i])
			rob_level = 2'd0;
		else
			rob_level = 2'd1;

		needy[i] = {rob_level, token_allocation[i] < TOKEN_LOW_THRESHOLD};
	end
end

endmodule
