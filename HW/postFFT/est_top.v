module est_top #(parameter   FP=16, 
DMRS_RX_WORD_LENGTH     = 12,   DMRS_RX_INT_LENGTH    = 0,  DMRS_RX_FLOAT_LENGTH    = 11,
DMRS_TX_WORD_LENGTH     = FP/2, DMRS_TX_INT_LENGTH    = 0,  DMRS_TX_FLOAT_LENGTH    = FP/2-1,
RAM_WIDTH               = 16,   ADDR_WIDTH            = 10, INPUT_WIDTH             = 8, OUTPUT_WIDTH    = 8, // ch_avg input & output
MMSE_WORD_LENGTH        = 8,    MMSE_INT_LENGTH        = 0, MMSE_FLOAT_LENGTH       = 7, MULTIPLIERS_NUM = 12,
CH_EST_LSE_WORD_LENGTH  = 8,    CH_EST_LSE_INT_LENGTH  = 0, CH_EST_LSE_FLOAT_LENGTH = 7) 
( 


    output wire        [9                    :0]     current_index,
    output wire                                      dmrs_indices_out_valid,
    output wire signed [OUTPUT_WIDTH  -1     :0]     i_ch_avg_out,
    output wire signed [OUTPUT_WIDTH  -1     :0]     q_ch_avg_out,
    output wire                                      ch_avg_done,
    output wire        [10                   :0]     coeff_addr,
    input  wire        [MMSE_WORD_LENGTH*12-1:0]     rhp_inv_rpp,
    input  wire        [ADDR_WIDTH-1         :0]     eq_read_addr,
    input  wire                                      eq_read_enable,
	input  wire                                      clk, 
    input  wire                                      rst, 
    input  wire        [1                    :0]     issb,
    input  wire        [9                    :0]     ncellid,          
    input  wire                                      n_hf,
    input  wire signed [DMRS_RX_WORD_LENGTH-1:0]     rx_i,
    input  wire signed [DMRS_RX_WORD_LENGTH-1:0]     rx_q,
    input  wire                                      ncellid_Ready_Pulse // PULSE

); 
    
wire signed   [FP/2-1                  :0]  dmrs_i, dmrs_q ;
wire signed   [FP/2-1                  :0]  bf_out_i;
wire signed   [FP/2-1                  :0]  bf_out_q;
wire signed   [CH_EST_LSE_WORD_LENGTH-1:0]  ch_est_lse_i_r;
wire signed   [CH_EST_LSE_WORD_LENGTH-1:0]  ch_est_lse_q_r;
wire          [1                       :0]  symbol_number ;
wire signed   [MMSE_WORD_LENGTH-1      :0]  mmse_rs_i;
wire signed   [MMSE_WORD_LENGTH-1      :0]  mmse_rs_q;
wire signed   [MMSE_WORD_LENGTH*2-1    :0]  mmse_out ;
wire signed   [MMSE_WORD_LENGTH*2-1    :0]  mmse_ram_out ;
wire signed   [MMSE_WORD_LENGTH-1      :0]  i_ram_dout;
wire signed   [MMSE_WORD_LENGTH-1      :0]  q_ram_dout;
wire          [1                       :0]  parallel_mode;
wire signed   [OUTPUT_WIDTH  -1        :0]  i_ch_avged;
wire signed   [OUTPUT_WIDTH  -1        :0]  q_ch_avged;
wire signed   [MMSE_WORD_LENGTH*2-1    :0]  ch_avg_out ;
wire signed   [MMSE_WORD_LENGTH*2-1    :0]  eq_ram_dout ;
wire                                        avg_done_delayed;
wire                                        out_valid_pop;


assign mmse_out   = {mmse_rs_i,mmse_rs_q} ;
assign i_ram_dout = mmse_ram_out[MMSE_WORD_LENGTH*2-1 :MMSE_WORD_LENGTH];
assign q_ram_dout = mmse_ram_out[MMSE_WORD_LENGTH-1   :0];
assign ch_avg_out = {i_ch_avged, q_ch_avged};
assign i_ch_avg_out = eq_ram_dout[MMSE_WORD_LENGTH*2-1 :MMSE_WORD_LENGTH];
assign q_ch_avg_out = eq_ram_dout[MMSE_WORD_LENGTH-1   :0];
assign dmrs_indices_out_valid = out_valid_pop;

nrDMRSgen #(.FP(FP)) u0_dmrsgen  (
    .dmrs_i             (dmrs_i),
    .dmrs_q             (dmrs_q),
    .out_valid          (out_valid_push),
    .dmrs_done          (dmrs_done),
    .issb               (issb),
    .ncellid            (ncellid),          
    .n_hf               (n_hf),
    .ncellid_Ready_Pulse(dmrs_gen_start_intern), // PULSE
    .clk                (clk),
    .rst                (rst)
);

Buffer  #(.FP(FP)) u0_buffer 
(   .bf_out_i           (bf_out_i), 
    .bf_out_q           (bf_out_q),  
	.clk                (clk), 
    .rst                (rst), 
    .pop                (out_valid_pop), 
    .push               (out_valid_push), 
    .bf_in_i            (dmrs_i),
    .bf_in_q            (dmrs_q)
    );

 dmrs_indices u0_dmrs_indices (
    .current_index      (current_index),
    .out_valid          (out_valid_pop),
    .ncellid            (ncellid),          
    .symbol_number_valid(symbol_num_vld_intern), // PULSE
    .symbol_number      (symbol_number),
    .clk                (clk),
    .rst                (rst)
);

lse  #( .CH_EST_LSE_WORD_LENGTH (CH_EST_LSE_WORD_LENGTH),  
        .CH_EST_LSE_INT_LENGTH  (CH_EST_LSE_INT_LENGTH), 
        .CH_EST_LSE_FLOAT_LENGTH(CH_EST_LSE_FLOAT_LENGTH),        // S0.7   
        .DMRS_TX_WORD_LENGTH    (DMRS_TX_WORD_LENGTH),  
        .DMRS_TX_INT_LENGTH     (DMRS_TX_INT_LENGTH) , 
        .DMRS_TX_FLOAT_LENGTH   (DMRS_TX_FLOAT_LENGTH),        // S0.4
        .DMRS_RX_WORD_LENGTH    (DMRS_RX_WORD_LENGTH), 
        .DMRS_RX_INT_LENGTH     (DMRS_RX_INT_LENGTH), 
        .DMRS_RX_FLOAT_LENGTH   (DMRS_RX_FLOAT_LENGTH)) u0_ch_est_lse (
    .ch_est_lse_i_r             (ch_est_lse_i_r),
    .ch_est_lse_q_r             (ch_est_lse_q_r),
    .out_valid                  (out_valid_lse),
    .rx_i                       (rx_i),
    .rx_q                       (rx_q),
    .tx_i                       (bf_out_i),
    .tx_q                       (bf_out_q),
    .in_valid                   (out_valid_delayed),
    .clk                        (clk),
    .rst                        (rst)
);

flip_flop u0_flip_flop (
    .reg_out    (out_valid_delayed),
    .reg_in     (out_valid_pop) ,
    .clk        (clk),
    .rst        (rst)
);

mmse #(.MMSE_WORD_LENGTH        (MMSE_WORD_LENGTH),
       .MMSE_INT_LENGTH         (MMSE_INT_LENGTH),       
       .MMSE_FLOAT_LENGTH       (MMSE_FLOAT_LENGTH),         // S0.15 
       .CH_EST_LSE_WORD_LENGTH  (CH_EST_LSE_WORD_LENGTH),  
       .CH_EST_LSE_INT_LENGTH   (CH_EST_LSE_INT_LENGTH), 
       .CH_EST_LSE_FLOAT_LENGTH (CH_EST_LSE_FLOAT_LENGTH),
        .MULTIPLIERS_NUM        (MULTIPLIERS_NUM)) u0_mmse (
    .mmse_rs_i      (mmse_rs_i),
    .mmse_rs_q      (mmse_rs_q),
    .out_valid_r    (out_valid_mmse),
    .symbol_done_r  (symbol_done),
    .coeff_addr     (coeff_addr),
    .h_tilde_i      (ch_est_lse_i_r),
    .h_tilde_q      (ch_est_lse_q_r),
    .in_valid       (out_valid_lse), //level
    .symbol_num     (symbol_number),
    .rhp_inv_rpp    (rhp_inv_rpp),
    .clk            (clk),
    .rst            (rst)
);


ctrl u0_ctrl (
    .dmrs_gen_start     (dmrs_gen_start_intern),
    .ch_avg_start       (ch_avg_start),
    .symbol_num         (symbol_number),
    .symbol_num_vld     (symbol_num_vld_intern),
    .ncellid_ready_pulse(ncellid_Ready_Pulse),
    .mmse_done          (symbol_done),
    .dmrs_gen_done      (dmrs_done),
    .avg_done           (avg_done_delayed),
    .clk                (clk),
    .rst                (rst)
);

mmse_ram #(.RAM_WIDTH(RAM_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u0_mmse_ram (
    .avg_ram_dout   (mmse_ram_out),
    .eq_ram_dout    (eq_ram_dout),
    .sp_in_vld      (sp_in_vld),
    .addr_done_r    (avg_done),
    .parallel_mode  (parallel_mode),
    .mmse_din       (mmse_out),
    .avg_din        (ch_avg_out),
    .ch_avg_start   (ch_avg_start),
    .mmse_wre       (out_valid_mmse),
    .avg_out_valid  (out_vld),
    .eq_read_addr   (eq_read_addr),
    .eq_read_enable (eq_read_enable),
    .clk            (clk),
    .rst            (rst)
);

ch_avg #(.INPUT_WIDTH(INPUT_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH)) u0_ch_avg (
    .i_ch_avged     (i_ch_avged),
    .q_ch_avged     (q_ch_avged),
    .out_vld        (out_vld),
    .i_ram_dout     (i_ram_dout),
    .q_ram_dout     (q_ram_dout),
    .sp_in_vld      (sp_in_vld_delayed),
    .parallel_mode  (parallel_mode),
    .clk            (clk),
    .rst            (rst)
    );

flip_flop u1_flip_flop (
    .reg_out(sp_in_vld_delayed),
    .reg_in (sp_in_vld) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u6_flip_flop (
    .reg_out(avg_done_delayed),
    .reg_in (avg_done) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u7_flip_flop (
    .reg_out(ch_avg_done),
    .reg_in (avg_done_delayed) ,
    .clk    (clk),
    .rst    (rst)
);



endmodule

//add wave -position insertpoint  \
//sim:/est_top/current_index \
//sim:/est_top/i_ch_avged \
//sim:/est_top/q_ch_avged \
//sim:/est_top/out_vld \
//sim:/est_top/clk \
//sim:/est_top/rst \
//sim:/est_top/issb \
//sim:/est_top/ncellid \
//sim:/est_top/n_hf \
//sim:/est_top/rx_i \
//sim:/est_top/rx_q \
//sim:/est_top/ncellid_Ready_Pulse
//force -freeze sim:/est_top/n_hf 0 0
//force -freeze sim:/est_top/ncellid 'd0 0
//force -freeze sim:/est_top/issb 0 0
//force -freeze sim:/est_top/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/est_top/rst 1 0
//force -freeze sim:/est_top/rst 0 5
//force -freeze sim:/est_top/rst 1 10
//force -freeze sim:/est_top/rx_i 12'b001011000000 0
//force -freeze sim:/est_top/rx_q 12'b000101100000 0
//force -freeze sim:/est_top/ncellid_Ready_Pulse 1 270