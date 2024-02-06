module avg_ram #(parameter RAM_WIDTH = 16, ADDR_WIDTH = 8) (
    output wire signed [RAM_WIDTH    -1 : 0]   dout,
    input  wire signed [RAM_WIDTH    -1 : 0]   din,
    input  wire        [ADDR_WIDTH-1    : 0]   mem_read_addr,
    input  wire                                wre,
    input  wire                                clk,
    input  wire                                rst
);

wire [ADDR_WIDTH-1 :0] mem_addr, mem_write_addr;


ram #(.RAM_WIDTH(RAM_WIDTH), .RAM_DEPTH(240), .ADDR_WIDTH(ADDR_WIDTH)) U1_ram (

    .dout   (dout),
    .din    (din),
    .addr   (mem_addr),
    .wre    (wre),
    .clk    (clk),
    .rst    (rst)

);

mux #(.ADDR_WIDTH(ADDR_WIDTH)) U3_mux (
    .a(mem_write_addr),
    .b(mem_read_addr),
    .sel(wre),
    .out(mem_addr)
);

counter #(.ADDR_WIDTH(ADDR_WIDTH), .FINAL_COUNT('d239)) U2_counter (
    .counter_r(mem_write_addr),
    .count(wre),
    .clk(clk),
    .rst(rst)
);


endmodule