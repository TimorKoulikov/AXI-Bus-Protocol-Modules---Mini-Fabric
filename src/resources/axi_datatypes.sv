package axi_datatypes;

typedef enum {AW,AR,W,R,B} axiChannelTypes;

localparam ADDR_WIDTH = 32;  
localparam ID_WIDTH = 4;              // ID of the transaction
localparam DATA_WIDTH = 32;
localparam STRB_WIDTH = DATA_WIDTH/8;

localparam AW_BUS_SIZE = 25 + ID_WIDTH + ADDR_WIDTH; // 25 is the sum of all unconfigurable bits (valid, ready, arlen, etc)
localparam W_BUS_SIZE  = 3  + DATA_WIDTH + STRB_WIDTH;
localparam B_BUS_SIZE  = 4  + ID_WIDTH;
localparam AR_BUS_SIZE = 25 + ID_WIDTH + ADDR_WIDTH; // 25 is the sum of all unconfigurable bits (valid, ready, arlen, etc)
localparam R_BUS_SIZE  = 5  + ID_WIDTH + DATA_WIDTH;

localparam MAX_LEN = 1024;

typedef struct packed{
	logic 			         valid;
	logic 					 ready;
	logic [ID_WIDTH-1:0]     id;
	logic [ADDR_WIDTH-1:0]   addr;
	logic [7:0]              arlen;
	logic [2:0]              arsize;
	logic [1:0]              arburst;
	logic                    arlock;
	logic [3:0]              arcache;
	logic [2:0]              arprot;
	logic [1:0]              qos;
} ar_bus;

typedef struct packed{
	logic 			         valid;
	logic 					 ready;
	logic [ID_WIDTH-1:0]     id;     
	logic [DATA_WIDTH-1:0]   rdata;
	logic [1:0]              rresp;
	logic                    rlast;
} r_bus;

typedef struct packed {
	logic 			         valid;
	logic 					 ready;
	logic [ID_WIDTH-1:0]     id;
	logic [ADDR_WIDTH-1:0]   addr;
	logic [7:0]              awlen;
	logic [2:0]              awsize;
	logic [1:0]              awburst;
	logic                    awlock;
	logic [3:0]              awcache;
	logic [2:0]              awprot;
	logic [1:0]              qos;
} aw_bus;

typedef struct packed{
	logic 			         valid;
	logic 					 ready;
	logic [DATA_WIDTH-1:0]   wdata;
	logic [STRB_WIDTH-1:0]   wstrb;
	logic                    wlast;
} w_bus;

typedef struct packed {
	logic                    valid;
	logic                    ready;
	logic [ID_WIDTH-1:0]     id;
	logic [1:0]              bresp; // for slave --> master, to show by the end the status (00==okay)
} b_bus;



/*
 * @params t - is enum axiChannelTypes
 * @returns the width of the channel
 */
function int get_bus_size(input axiChannelTypes t);
	int width; // Local variable to hold the result
	
	case (t)
		AW: width = AW_BUS_SIZE;
		AR: width = AR_BUS_SIZE;
		W:  width = W_BUS_SIZE;
		R:  width = R_BUS_SIZE;
		B:  width = B_BUS_SIZE;
		default: begin
			width = 0;
			$display("Error: Unknown AXI Channel Type");
		end
	endcase
	
	return width; // Return the calculated width
endfunction


//defining a new type (BUS_TYPE) which is an inner parameter
//default: BUS_TYPE = aw_bus 
class RAND_AXI #(type BUS_TYPE = aw_bus); 
	rand BUS_TYPE random_axi_data;        // [remove_basof] rand: declare the random_axi_data is random type
	
	// defining constraint that after randomization its valid bit will always 0
	constraint c_axi_data {random_axi_data.valid == 1'b0;}   
	
	function BUS_TYPE get_random();
		this.randomize();                 // 
		return this.random_axi_data;
	endfunction
endclass

//typedef for needy 
typedef enum logic [1:0]
{
	NO_LEAK,
	LEAK,
	EXSTRA_BW,
	LEAK_EXSTRA_BW
	
} mode_token_allocation;

endpackage
