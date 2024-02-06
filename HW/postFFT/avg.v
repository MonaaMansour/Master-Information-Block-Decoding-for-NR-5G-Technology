module avg #(parameter INPUT_WIDTH = 16, OUTPUT_WIDTH = 16) (
    output reg  signed [OUTPUT_WIDTH  -1 : 0]    i_avged_r,
    output reg  signed [OUTPUT_WIDTH  -1 : 0]    q_avged_r,
    output reg                                   out_vld,
    input  wire signed [INPUT_WIDTH*3 -1 : 0]    i_inputs , // 3 inputs concatenated
    input  wire signed [INPUT_WIDTH*3 -1 : 0]    q_inputs ,
    input  wire        [1                : 0]    parallel_mode,
    input  wire                                  in_vld,
    input  wire                                  clk,
    input  wire                                  rst
);
reg  signed [INPUT_WIDTH+2  -1 : 0]    i_temp1;
reg  signed [INPUT_WIDTH+2  -1 : 0]    q_temp1;
reg  signed [INPUT_WIDTH+2+8-1 : 0]    i_avged;
reg  signed [INPUT_WIDTH+2+8-1 : 0]    q_avged;
wire signed [INPUT_WIDTH    -1 : 0]    i_avged_rs;
wire signed [INPUT_WIDTH    -1 : 0]    q_avged_rs;


localparam signed const_factor = 8'b01010101; // 1/3 = 0.3333 , const_factor = 0.332


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        i_avged_r <= 'd0;
        q_avged_r <= 'd0;
    end
    else begin
        out_vld   <= in_vld;
        i_avged_r <= i_avged_rs;
        q_avged_r <= q_avged_rs;
    end 
end


always @(*) begin
    i_avged     = 'd0; 
    q_avged     = 'd0; 
    i_temp1     = 'd0; 
    q_temp1     = 'd0; 

    if (in_vld) begin

        if (!parallel_mode[0]) begin
            i_temp1 = $signed(i_inputs [INPUT_WIDTH*3 -1 : 2*INPUT_WIDTH]) + $signed(i_inputs [INPUT_WIDTH*2 -1 : INPUT_WIDTH]);
            q_temp1 = $signed(q_inputs [INPUT_WIDTH*3 -1 : 2*INPUT_WIDTH]) + $signed(q_inputs [INPUT_WIDTH*2 -1 : INPUT_WIDTH]);

            i_avged = {i_temp1 >>> 1 ,i_temp1[0] , 7'b0000000};
            q_avged = {q_temp1 >>> 1 ,q_temp1[0] , 7'b0000000};
        end
        else begin
            i_temp1 = $signed(i_inputs [INPUT_WIDTH*3 -1 : 2*INPUT_WIDTH]) + $signed(i_inputs [INPUT_WIDTH*2 -1 : INPUT_WIDTH]) + $signed(i_inputs [INPUT_WIDTH -1 : 0]);
            q_temp1 = $signed(q_inputs [INPUT_WIDTH*3 -1 : 2*INPUT_WIDTH]) + $signed(q_inputs [INPUT_WIDTH*2 -1 : INPUT_WIDTH]) + $signed(q_inputs [INPUT_WIDTH -1 : 0]);

            i_avged = const_factor * i_temp1;
            q_avged = const_factor * q_temp1;
        end
    end
end


RoundSaturate #(
    .IN_WORD_LENGTH    (INPUT_WIDTH+8+2),  .IN_INT_LENGTH  (2), .IN_FLOAT_LENGTH  (INPUT_WIDTH -1+8),
    .OUT_WORD_LENGTH   (OUTPUT_WIDTH ),  .OUT_INT_LENGTH (0), .OUT_FLOAT_LENGTH (OUTPUT_WIDTH-1) 
    ) U1_RS (
        .i_in               (i_avged),
        .q_in               (q_avged),
        .i_round_saturated  (i_avged_rs),
        .q_round_saturated  (q_avged_rs)
    );

endmodule

//add wave -position insertpoint  \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/i_avged_r \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/q_avged_r \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/out_vld \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/i_inputs \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/q_inputs \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/parallel_mode \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/in_vld \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/clk \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/rst \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/i_temp1 \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/q_temp1 \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/i_avged \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/q_avged \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/i_avged_rs \
//sim:/est_top_tb/DUT/u0_ch_avg/U0_avg/q_avged_rs