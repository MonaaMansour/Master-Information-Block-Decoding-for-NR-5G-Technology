module ch_avg #(parameter INPUT_WIDTH = 16, OUTPUT_WIDTH = 16) (
    output  wire signed [OUTPUT_WIDTH  -1 : 0] i_ch_avged,
    output  wire signed [OUTPUT_WIDTH  -1 : 0] q_ch_avged,
    output  wire                               out_vld,
    input   wire signed [INPUT_WIDTH   -1 : 0] i_ram_dout,
    input   wire signed [INPUT_WIDTH   -1 : 0] q_ram_dout,
    input   wire                               sp_in_vld,
    input   wire        [1                : 0] parallel_mode,
    input   wire                               clk,
    input   wire                               rst

);


            wire [INPUT_WIDTH -1 : 0] real1;
            wire [INPUT_WIDTH -1 : 0] real2;
            wire [INPUT_WIDTH -1 : 0] real3;
            wire [INPUT_WIDTH -1 : 0] imag1;
            wire [INPUT_WIDTH -1 : 0] imag2;
            wire [INPUT_WIDTH -1 : 0] imag3;
            wire [1              : 0] parallel_mode_delayed;

SerialToParallel #(.PARALLEL_NUM(3) , .SERIAL_WIDTH(INPUT_WIDTH*2)) U0_STP (

    .parallel_reg({real1,imag1,real2,imag2,real3,imag3}),
    .out_valid_reg(vld),
    .serial({i_ram_dout,q_ram_dout}),
    .in_valid(sp_in_vld),
    .parallel_mode(parallel_mode),
    .clk(clk),
    .rst(rst)
);

avg #(.INPUT_WIDTH(INPUT_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH)) U0_avg (
    .i_avged_r(i_ch_avged),
    .q_avged_r(q_ch_avged),
    .out_vld(out_vld),
    .i_inputs({real1,real2,real3}),
    .q_inputs({imag1,imag2,imag3}),
    .in_vld(vld),
    .parallel_mode(parallel_mode_delayed),
    .clk(clk),
    .rst(rst)
);

flip_flop u2_flip_flop (
    .reg_out(parallel_mode_delayed[0]),
    .reg_in (parallel_mode[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u3_flip_flop (
    .reg_out(parallel_mode_delayed[1]),
    .reg_in (parallel_mode[1]) ,
    .clk    (clk),
    .rst    (rst)
);




endmodule