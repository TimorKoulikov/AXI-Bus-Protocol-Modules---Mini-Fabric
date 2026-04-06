module arbiter_2inpt_lowprior(
	input  logic clk,
	input  logic rstn,
	input  logic req0,
	input  logic req1,
	output logic grant0,
	output logic grant1
);

always_ff @(posedge clk or negedge rstn) begin
	if(!rstn) begin
		grant0 <= 0;
		grant1 <= 0;
	end else begin 
		// PREVENT STICKY MEMORY (Default assignments)
		grant0 <= 0; 
		grant1 <= 0;
	end

	//------ logics ------
	/*  give the grant by lowest id priority, so if both req0 and req1 are high 
		grant0 will be high and grant1 will be low */

	if(req0) begin
		grant0 <= 1;
	end else if(req1) begin
		grant1 <= 1;
	end
end

endmodule