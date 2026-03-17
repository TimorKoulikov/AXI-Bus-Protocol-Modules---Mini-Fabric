package axi_datatypes;

typedef enum {AW,AR,W,R,B} axiChannelTypes;

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

struct {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     awid;
	logic [ADDR_WIDTH-1:0]   awaddr;
	logic [7:0]              awlen;
	logic [2:0]              awsize;
	logic [1:0]              awburst;
	logic                    awlock;
	logic [3:0]              awcache;
	logic [2:0]              awprot;
	logic [3:0]              awqos;
	logic [AW_BUS_WIDTH-1:0] data;
} aw_bus;

struct {
	logic valid;
	logic ready;
	logic [DATA_WIDTH-1:0]   wdata;
	logic [STRB_WIDTH-1:0]   wstrb;
	logic                    wlast;
} w_bus;

struct {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     bid;
	logic [1:0]              bresp;
} b_bus;

struct {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     arid;
	logic [ADDR_WIDTH-1:0]   araddr;
	logic [7:0]              arlen;
	logic [2:0]              arsize;
	logic [1:0]              arburst;
	logic                    arlock;
	logic [3:0]              arcache;
	logic [2:0]              arprot;
	logic [3:0]              arqos;
} ar_bus;

struct {
	logic valid;
	logic ready;
	logic [ID_WIDTH-1:0]     rid;
	logic [DATA_WIDTH-1:0]   rdata;
	logic [1:0]              rresp;
	logic                    rlast;
} r_bus;



endpackage
