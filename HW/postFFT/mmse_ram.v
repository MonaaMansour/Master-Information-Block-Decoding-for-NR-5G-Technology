module mmse_ram #(parameter RAM_WIDTH = 32, ADDR_WIDTH = 10) (
    output wire signed [RAM_WIDTH    -1 : 0]   avg_ram_dout,
    output wire signed [RAM_WIDTH    -1 : 0]   eq_ram_dout,
    output wire                                sp_in_vld,
    output wire                                addr_done_r,
    output wire        [1               : 0]   parallel_mode,
    input  wire        [ADDR_WIDTH-1    : 0]   eq_read_addr,
    input  wire                                eq_read_enable,
    input  wire signed [RAM_WIDTH    -1 : 0]   avg_din,
    input  wire signed [RAM_WIDTH    -1 : 0]   mmse_din,
    input  wire                                ch_avg_start,
    input  wire                                mmse_wre,
    input  wire                                avg_out_valid,
    input  wire                                clk,
    input  wire                                rst
);

wire  [ADDR_WIDTH-1 :0] mem_addr,mmse_write_addr, avg_write_addr, avg_read_addr, avg_eq_addr;
wire  [ADDR_WIDTH-1 :0] avg_addr;
wire  [RAM_WIDTH -1 :0] din_intern, dout;


ram #(.RAM_WIDTH(RAM_WIDTH), .RAM_DEPTH(816), .ADDR_WIDTH(ADDR_WIDTH)) U0_ram (

    .dout   (dout),
    .din    (din_intern),
    .addr   (mem_addr),
    .wre    (wre),
    .clk    (clk),
    .rst    (rst)

);

demux #(.ADDR_WIDTH(RAM_WIDTH)) U0_demux (
    .out1(avg_ram_dout),
    .out2(eq_ram_dout),
    .in(dout),
    .sel(sp_in_vld_delayed)
);

flip_flop u10_flip_flop (
    .reg_out    (sp_in_vld_delayed),
    .reg_in     (sp_in_vld) ,
    .clk        (clk),
    .rst        (rst)
);

mux #(.ADDR_WIDTH(ADDR_WIDTH)) U0_mux (
    .a(mmse_write_addr),
    .b(avg_addr),
    .sel(mmse_wre),
    .out(mem_addr)
);
mux #(.ADDR_WIDTH(ADDR_WIDTH)) U1_mux (
    .a(avg_read_addr),
    .b(avg_eq_addr),  //  // // // // // 
    .sel(sp_in_vld),
    .out(avg_addr)
);

mux #(.ADDR_WIDTH(ADDR_WIDTH)) U9_mux (
    .a(eq_read_addr),
    .b(avg_write_addr),  //  // // // // // 
    .sel(eq_read_enable),
    .out(avg_eq_addr)
);


mux #(.ADDR_WIDTH(1'b1)) U3_mux (
    .a(mmse_wre),
    .b(avg_out_valid), // // // // // //
    .sel(mmse_wre),
    .out(wre)
);

mux #(.ADDR_WIDTH(RAM_WIDTH)) U2_mux (
    .a(mmse_din),
    .b(avg_din),
    .sel(mmse_wre),
    .out(din_intern)
);


counter #(.ADDR_WIDTH(ADDR_WIDTH), .FINAL_COUNT('d575), .INITIAL_COUNT('d0)) U0_counter (
    .counter_r(mmse_write_addr),
    .count(mmse_wre),
    .clk(clk),
    .rst(rst)
);

counter #(.ADDR_WIDTH(ADDR_WIDTH), .FINAL_COUNT('d815), .INITIAL_COUNT('d576)) U1_counter (
    .counter_r(avg_write_addr),
    .count(avg_out_valid),
    .clk(clk),
    .rst(rst)
);


addr_gen U0_addr_gen (
    .addr_r(avg_read_addr),
    .out_vld_r(sp_in_vld),
    .addr_done_r(addr_done_r),
    .parallel_mode_r(parallel_mode),
    .in_vld(ch_avg_start),
    .clk(clk),
    .rst(rst)
);

//flip_flop U1_FF (
//    .reg_in(sel1),
//    .reg_out(sp_in_vld),
//    .clk(clk),
//    .rst(rst)
//);

endmodule

//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_ram/*
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/U0_STP/clk
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/sp_in_vld
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/out_vld
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/U0_STP/in_valid
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/U0_STP/serial
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/U0_STP/out_valid_reg
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_ch_avg/U0_STP/parallel_reg
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_addr_gen/addr_r
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_addr_gen/in_vld
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_addr_gen/out_vld_r
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_ram/RAM
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_addr_gen/parallel_mode_r
//add wave -position insertpoint sim:/est_top_tb/DUT/u0_mmse_ram/U0_addr_gen/counter_stop_r