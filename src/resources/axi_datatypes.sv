package axi_datatypes;

typedef enum {AW,AR,W,R,B} axiChannelTypes;

// TODO: maybe i should remove it
localparam AW_BUS_WIDTH=32;
localparam AR_BUS_WIDTH=32;
localparam W_BUS_WIDTH=32;
localparam R_BUS_WIDTH=32;
localparam B_BUS_WIDTH=32;

localparam ADDR_WIDTH=32;
localparam ID_WIDTH=4;
localparam DATA_WIDTH=32;
localparam STRB_WIDTH=DATA_WIDTH/8;

localparam AW_BUS_SIZE = 27 + ID_WIDTH + ADDR_WIDTH + AW_BUS_WIDTH;
localparam W_BUS_SIZE  = 3  + DATA_WIDTH + STRB_WIDTH;
localparam B_BUS_SIZE  = 4  + ID_WIDTH;
localparam AR_BUS_SIZE = 27 + ID_WIDTH + ADDR_WIDTH;
localparam R_BUS_SIZE  = 5  + ID_WIDTH + DATA_WIDTH;

localparam MAX_LEN=1024;

typedef struct packed {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     awid;
	logic [ADDR_WIDTH-1:0]   addr;
	logic [7:0]              awlen;
	logic [2:0]              awsize;
	logic [1:0]              awburst;
	logic                    awlock;
	logic [3:0]              awcache;
	logic [2:0]              awprot;
	logic [1:0]              qos;
	logic [AW_BUS_WIDTH-1:0] data;
} aw_bus;

typedef struct packed{
	logic valid;
	logic ready;
	logic [DATA_WIDTH-1:0]   wdata;
	logic [STRB_WIDTH-1:0]   wstrb;
	logic                    wlast;
} w_bus;

typedef struct packed {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     bid;
	logic [1:0]              bresp;
} b_bus;

typedef struct packed{
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     arid;
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
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     rid;
	logic [DATA_WIDTH-1:0]   rdata;
	logic [1:0]              rresp;
	logic                    rlast;
} r_bus;


function int get_bus_width(input axiChannelTypes t);
	int width; // Local variable to hold the result
	
	case (t)
		AW: width = AW_BUS_WIDTH;
		AR: width = AR_BUS_WIDTH;
		W:  width = W_BUS_WIDTH;
		R:  width = R_BUS_WIDTH;
		B:  width = B_BUS_WIDTH;
		default: begin
			width = 0;
			$display("Error: Unknown AXI Channel Type");
		end
	endcase
	
	return width; // Return the calculated width
endfunction


class RAND_AXI #(type BUS_TYPE = aw_bus);
	rand BUS_TYPE random_axi_data;
	
	constraint c_axi_data {random_axi_data.valid==1'b0;}
	
	function BUS_TYPE get_random();
		this.randomize();
		return this.random_axi_data;
	endfunction
endclass


endpackage
