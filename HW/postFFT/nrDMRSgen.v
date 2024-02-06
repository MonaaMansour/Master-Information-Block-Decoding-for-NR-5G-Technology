module nrDMRSgen #(parameter FP = 16) (
    output  wire  signed   [FP/2-1:0]  dmrs_i,
    output  wire  signed   [FP/2-1:0]  dmrs_q,
    output  wire                       out_valid,
    output  reg                        dmrs_done,
    input   wire           [1:0]       issb,
    input   wire           [9:0]       ncellid,          
    input   wire                       n_hf,
    input   wire                       ncellid_Ready_Pulse, // PULSE
    input   wire                       clk,
    input   wire                       rst
);


wire  c;
wire [1:0]   internal0;
wire         internal1;
reg          internal2,internal3;

GoldSeqGen #(.Mpn('d288) , .Type('d0)) U0_GoldSeqGen (
    .issb(issb),
    .ncellid(ncellid),
    .n_hf(n_hf),
    .ncellid_Ready_Pulse(ncellid_Ready_Pulse),
    .goldseq_done(internal1),
    .out_valid(in_valid),
    .gen_flag(1'b0),
    .C(c),
    .clk(clk),
    .rst(rst)
);

SerialToParallel_1 #(.P_WIDTH('d2)) U0_SerialToParallel (
    .serial(c),
    .in_valid(in_valid),
    .parallel_reg(internal0),
    .out_valid_reg(out_valid_reg),
    .clk(clk),
    .rst(rst)
);

QPSK #(.FP(FP)) U0_QPSK(
    .qpsk_i(dmrs_i),
    .qpsk_q(dmrs_q),
    .out_valid(out_valid),
    .in(internal0),
    .in_valid(out_valid_reg),
    .clk(clk),
    .rst(rst)
);
    
    //delay 3 clock cycles
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dmrs_done   <= 'd0;
            internal2   <= 'd0;
            internal3   <= 'd0;
        end
        else begin
            dmrs_done   <= internal3;
            internal3   <= internal2;
            internal2   <= internal1;
        end
    end

endmodule