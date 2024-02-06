module scrambler #(parameter EQUALIZER_WORD_LENGTH = 8,
                            Mpn = 864, Type = 1) (
    output  reg   signed  [EQUALIZER_WORD_LENGTH-1 :0] scrambled_data,
    output  reg                                        out_valid,
    input   wire  signed  [EQUALIZER_WORD_LENGTH-1 :0] equalized_i,
    input   wire  signed  [EQUALIZER_WORD_LENGTH-1 :0] equalized_q,
    input   wire                                       equalizer_out_valid,
    input   wire                                       equalizer_out_valid_level,
    input   wire                                       gold_seq_gen,
    input   wire          [1:0]                        issb,
    input   wire          [9:0]                        ncellid,          
    input   wire                                       n_hf,
    input   wire                                       ncellid_Ready_Pulse,    // PULSE
    input   wire                                       clk,
    input   wire                                       rst
);    
wire goldseq_done_intern, out_valid_intern;
reg  gold_seq_gen_level;
reg  signed [EQUALIZER_WORD_LENGTH-1 :0]     scrambled_data_nx;
reg                                          out_valid_nx;
reg  signed [EQUALIZER_WORD_LENGTH-1 :0]    equalized;
wire                                         c;
//reg equalizer_out_valid_level,equalizer_out_valid_level_r;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        gold_seq_gen_level <= 'd0;
    end
    else if (gold_seq_gen)
    begin
        gold_seq_gen_level <= 1;
    end else if (goldseq_done_intern) begin
        gold_seq_gen_level <= 'd0;
    end
      
end

GoldSeqGen #(.Mpn(Mpn), .Type(Type)) u1_gold_sequence (                        //TYPE = 1 (SCRAMBLER) , TYPE = 0 (DMRS)
    .C(c),
    .out_valid(out_valid_intern),                
    .goldseq_done(goldseq_done_intern),
    .issb(issb),
    .ncellid(ncellid),          
    .n_hf(n_hf),
    .gen_flag(gold_seq_gen_level),
    .ncellid_Ready_Pulse(ncellid_Ready_Pulse),    // PULSE
    .clk(clk),
    .rst(rst)
);

//mux to switch between i and q data
always @(*) begin
    if (equalizer_out_valid) begin
        equalized     = equalized_i;
    end else begin
        equalized     = equalized_q;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        scrambled_data   <= 'd0 ;
        out_valid        <= 'd0 ;
    end else begin
        scrambled_data   <= scrambled_data_nx ;
        out_valid        <= out_valid_nx;
    end
end

always @(*) begin
    scrambled_data_nx = scrambled_data;
    out_valid_nx        = out_valid;
    if (equalizer_out_valid_level) begin 
       scrambled_data_nx = equalized * $signed(2'd1 - {c,1'b0} )  ; 
       out_valid_nx      = 'd1;
    end else begin
       out_valid_nx        = 'd0;
    end
end
//

endmodule


//add wave -position insertpoint sim:/scrambler/*
//force -freeze sim:/scrambler/equalized_i 'b10100011 0
//force -freeze sim:/scrambler/equalized_q 'b00100011 0
//force -freeze sim:/scrambler/equalizer_out_valid 1 60000000
//force -freeze sim:/scrambler/equalizer_out_valid 'd0 60000100
//force -freeze sim:/scrambler/issb 'd5 0
//force -freeze sim:/scrambler/ncellid 'd433 0
//force -freeze sim:/scrambler/n_hf 'd0 0
//force -freeze sim:/scrambler/ncellid_Ready_Pulse 'd1 200
//force -freeze sim:/scrambler/ncellid_Ready_Pulse 'd0 300
//force -freeze sim:/scrambler/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/scrambler/rst 'd1 0
//force -freeze sim:/scrambler/rst 'd0 10
//force -freeze sim:/scrambler/rst 'd1 20

