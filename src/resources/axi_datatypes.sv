package axi_datatypes;

typedef enum {AW,AR,W,R,B} axiChannelTypes;

localparam AW_BUS_WIDTH=32;
localparam AR_BUS_WIDTH=32;
localparam W_BUS_WIDTH=32;
localparam R_BUS_WIDTH=32;
localparam B_BUS_WIDTH=32;

localparam ADDR_WIDTH=32;

struct {
	logic valid;
	logic [3:0] qos;
	logic [ADDR_WIDTH - 1 : 0] awaddr;
	logic [AW_BUS_WIDTH-1 : 0] data;
} aw_bus;

struct {
	logic valid;
	logic [3:0] qos;
	logic [ADDR_WIDTH - 1:0] araddr;

} ar_bus;



endpackage
