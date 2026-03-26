/*===============================================================
module is receiving data from a specific channel of axi component.
output - the most recent data from axi component
=================================================================*/
module axi_buffer(
	input  logic    aclk,      // axi global clock signal
	input  logic    aresetn,   // global reset signal. active low
	input  BUS_TYPE data_in,   // AXI channel that comes from axi component
	output logic    ready_out, // valid signal the receiver sends for the data_in
	output BUS_TYPE data_out,  // data of entering valid and new data
	input  logic    ready_in   // ready signal receiver gets for the data_out
);

//----- imports -----
import axi_datatypes::*;

//----- Parameters -----
parameter type BUS_TYPE = aw_bus;
parameter IS_W = 0;

//----- logic ------

always_ff @(posedge aclk or negedge aresetn) begin
	// reset the module
	if(!aresetn) begin
		data_out  <= '0;
		ready_out <= 1'b0;
	end else begin
		// Default assignment for ready_out
		ready_out <= 1'b1;
		
		// Backpressure logic
		if(ready_in == 1'b0) begin
			ready_out <= 1'b0;
		end
		
		// Data latching logic
		if(data_in.valid == 1'b1) begin
			data_out <= data_in;
		end else begin
			data_out.valid <= 1'b0;
		end
	end
end

endmodule