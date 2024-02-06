module postFFT #(parameter  LLR_WIDTH          = 8 ,
                            RX_WORD_LENGTH     = 12,    
                            RX_INT_LENGTH      = 0 ,  
                            RX_FLOAT_LENGTH    = 11, 
                            MMSE_WORD_LENGTH   = 8  ) 
( 
    output  wire        [10                 -1 :0]     fft_mem_addr,        // reading address for fft ram to access rx data
    output  wire        [LLR_WIDTH          -1 :0]     llrs,                // channel llrs stored in the ram
    output  wire        [6                  -1 :0]     llr_mem_w_addr,      // address for writing channel llrs in llr ram
    output  wire        [2                  -1 :0]     mem_llr_slct,        // select which llr in the word
    output  wire                                       llr_mem_1_w_enable,  // high while writing (for the first mem)
    output  wire                                       llr_mem_2_w_enable,  // high while writing (for the second mem)
    output  wire                                       llr_done,            //all channel llrs stored in the ram - PULSE
    output  wire        [11                 -1 :0]     coeff_addr,          // address to access mmse coeff.

    input   wire        [MMSE_WORD_LENGTH*12-1 :0]     rhp_inv_rpp,         // coeff data
    input   wire signed [RX_WORD_LENGTH-1      :0]     fft_mem_data_i,
    input   wire signed [RX_WORD_LENGTH-1      :0]     fft_mem_data_q,
    input   wire        [2                  -1 :0]     issb,
    input   wire        [10                 -1 :0]     ncellid,          
    input   wire                                       n_hf,
    input   wire                                       est_strt, // PULSE
    input   wire                                       clk, 
    input   wire                                       rst
); 

localparam  CH_WORD_LENGTH        = 8 ,
            EQUALIZER_WORD_LENGTH = 8 ,
            ADDR_WIDTH            = 10;

            wire        [ADDR_WIDTH-1            :0] mem_read_addr_intrn;
            wire signed [CH_WORD_LENGTH-1        :0] ch_avg_i_intern, ch_avg_q_intern;
            wire signed [EQUALIZER_WORD_LENGTH-1 :0] equalized_i_intern, equalized_q_intern;
            wire                                     scrambler_out_valid;
            wire                                     dmrs_indices_out_valid;
            wire        [10                    -1:0] pbch_indices_fft, dmrs_indices_fft;
            wire        [2                     -1:0] issb_r;
            wire        [10                    -1:0] ncellid_r;  
            wire                                     n_hf_r;
            wire        [RX_WORD_LENGTH-1        :0] dmrs_rx_i;
            wire        [RX_WORD_LENGTH-1        :0] dmrs_rx_q;
            wire        [RX_WORD_LENGTH-1        :0] pbch_rx_i;
            wire        [RX_WORD_LENGTH-1        :0] pbch_rx_q;

est_top #(
.DMRS_RX_WORD_LENGTH    (RX_WORD_LENGTH),           .DMRS_RX_INT_LENGTH     (RX_INT_LENGTH),        .DMRS_RX_FLOAT_LENGTH       (RX_FLOAT_LENGTH),
.DMRS_TX_WORD_LENGTH    (8),                        .DMRS_TX_INT_LENGTH     (0),                    .DMRS_TX_FLOAT_LENGTH       (7),            .FP(8*2),
.RAM_WIDTH              (16),                       .ADDR_WIDTH             (ADDR_WIDTH),           .INPUT_WIDTH                (8),            .OUTPUT_WIDTH(8),
.MMSE_WORD_LENGTH       (MMSE_WORD_LENGTH),         .MMSE_INT_LENGTH        (0),                    .MMSE_FLOAT_LENGTH          (MMSE_WORD_LENGTH-1),                  .MULTIPLIERS_NUM(12),
.CH_EST_LSE_WORD_LENGTH (8),                        .CH_EST_LSE_INT_LENGTH  (0),                    .CH_EST_LSE_FLOAT_LENGTH    (7)) u0_est_top
(
     .current_index         (dmrs_indices_fft),
     .dmrs_indices_out_valid(dmrs_indices_out_valid),
     .i_ch_avg_out          (ch_avg_i_intern),
     .q_ch_avg_out          (ch_avg_q_intern),
     .ch_avg_done           (ch_avg_done),
     .coeff_addr            (coeff_addr),
     .rhp_inv_rpp           (rhp_inv_rpp),
     .eq_read_addr          (mem_read_addr_intrn),
     .eq_read_enable        (pbch_out_valid),
     .clk                   (clk), 
     .rst                   (rst), 
     .issb                  (issb_r),
     .ncellid               (ncellid_r),          
     .n_hf                  (n_hf_r),
     .rx_i                  (dmrs_rx_i),
     .rx_q                  (dmrs_rx_q),
     .ncellid_Ready_Pulse   (ncellid_ready_pulse) // PULSE
);

pbch_indices u0_pbch_indices (
    .current_index_fft      (pbch_indices_fft),
    .current_index_ch_avg   (mem_read_addr_intrn),
    .out_valid              (pbch_out_valid),
    .ncellid                (ncellid),          
    .symbol_number_valid    (symbol_number_valid), // PULSE
    .pbch_indices_valid     (pbch_indices_valid),
    .clk                    (clk),
    .rst                    (rst)
);

flip_flop u10_flip_flop (
    .reg_out    (pbch_out_valid_delayed),
    .reg_in     (pbch_out_valid) ,
    .clk        (clk),
    .rst        (rst)
);

equalizer #(.EQUALIZER_WORD_LENGTH(EQUALIZER_WORD_LENGTH),  .EQUALIZER_INT_LENGTH (0),                .EQUALIZER_FLOAT_LENGTH (EQUALIZER_WORD_LENGTH-1),        // S0.7   
            .CH_WORD_LENGTH       (CH_WORD_LENGTH),         .CH_INT_LENGTH        (0),                .CH_FLOAT_LENGTH      (CH_WORD_LENGTH-1),        // S
            .PBCH_RX_WORD_LENGTH  (RX_WORD_LENGTH),         .PBCH_RX_INT_LENGTH   (RX_INT_LENGTH),    .PBCH_RX_FLOAT_LENGTH (RX_FLOAT_LENGTH) ) u0_equalizer (    // S0.14

    .equalized_i_r          (equalized_i_intern),
    .equalized_q_r          (equalized_q_intern),
    .out_valid              (equalizer_out_valid),
    .out_valid_level        (equalizer_out_valid_level),
    .equalization_done_r    (equalization_done),
    .rx_i                   (pbch_rx_i),
    .rx_q                   (pbch_rx_q),
    .ch_i                   (ch_avg_i_intern),
    .ch_q                   (ch_avg_q_intern),
    .in_valid               (pbch_out_valid_delayed),
    .clk                    (clk),
    .rst                    (rst)
);

top_ctrl u0_top_ctrl(
    .ncellid_ready_pulse    (ncellid_ready_pulse),
    .issb_r                 (issb_r),
    .ncellid_r              (ncellid_r),
    .n_hf_r                 (n_hf_r),
    .symbol_num_vld         (symbol_number_valid),
    .est_strt               (est_strt),
    .ch_avg_done            (ch_avg_done),
    .pbch_indices_valid     (pbch_indices_valid),
    .equalization_done      (equalization_done),
    .issb                   (issb),
    .ncellid                (ncellid),
    .n_hf                   (n_hf),
    .clk                    (clk),
    .rst                    (rst)
);

scrambler #(.EQUALIZER_WORD_LENGTH(8),
            .Mpn('d864), .Type('b1)) u0_scrambler (
    .scrambled_data             (llrs),
    .out_valid                  (scrambler_out_valid),
    .equalized_i                (equalized_i_intern),
    .equalized_q                (equalized_q_intern),
    .equalizer_out_valid        (equalizer_out_valid),
    .equalizer_out_valid_level  (equalizer_out_valid_level),
    .gold_seq_gen               (pbch_out_valid),
    .issb                       (issb_r),
    .ncellid                    (ncellid_r),          
    .n_hf                       (n_hf_r),
    .ncellid_Ready_Pulse        (ncellid_ready_pulse),    // PULSE
    .clk                        (clk),
    .rst                        (rst)
);    

RateMatch u0_RateMatch (
    .mem_write_addr_r   (llr_mem_w_addr),
    .mem_llr_slct_r     (mem_llr_slct),
    .llr_done_r         (llr_done),
    .mem_1_w_enable_r   (llr_mem_1_w_enable),
    .mem_2_w_enable_r   (llr_mem_2_w_enable),
    .in_vld             (equalizer_out_valid_level),
    .clk                (clk),
    .rst                (rst)
);



mux #(.ADDR_WIDTH(10)) u30_mux(
    .out(fft_mem_addr),
    .a  (dmrs_indices_fft),
    .b  (pbch_indices_fft),
    .sel(dmrs_indices_out_valid)
);

flip_flop u8_flip_flop (
    .reg_out(dmrs_indices_out_valid_r),
    .reg_in (dmrs_indices_out_valid) ,
    .clk    (clk),
    .rst    (rst)
);

demux #(.ADDR_WIDTH(RX_WORD_LENGTH)) u1_demux(
    .in     (fft_mem_data_i),
    .out1   (dmrs_rx_i),
    .out2   (pbch_rx_i),
    .sel    (dmrs_indices_out_valid_r)
);

demux #(.ADDR_WIDTH(RX_WORD_LENGTH)) u2_demux(
    .in     (fft_mem_data_q),
    .out1   (dmrs_rx_q),
    .out2   (pbch_rx_q),
    .sel    (dmrs_indices_out_valid_r)
);


endmodule


//force -freeze sim:/est_equalize_top/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/est_equalize_top/rst 1 0
//force -freeze sim:/est_equalize_top/rst 0 10
//force -freeze sim:/est_equalize_top/rst 1 20
//force -freeze sim:/est_equalize_top/issb 'd3 0
//force -freeze sim:/est_equalize_top/ncellid 'd143 0
//force -freeze sim:/est_equalize_top/n_hf 0 0
//force -freeze sim:/est_equalize_top/dmrs_rx_i 'b101000110011 0
//force -freeze sim:/est_equalize_top/dmrs_rx_q 'b001000110011 0
//force -freeze sim:/est_equalize_top/pbch_rx_i 'b101000110011 0
//force -freeze sim:/est_equalize_top/pbch_rx_q 'b001000110011 0
//force -freeze sim:/est_equalize_top/est_strt 1 300

//&& ^DUT.data !== 'X && ^exp_data !== 'X