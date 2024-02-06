module LFSR #(parameter LFSR_WIDTH     = 5'd31 ,
                        XOR_POS        = 31'b0000_0000_0000_0000_0000_0000_0001_001) (
    output  wire            OUT,
    input   wire    [0:30]  SEED,
    input   wire            SEED_Ready_Pulse,    //LFSR start shifting
    input   wire            goldseq_done,                // Output from GoldSeqGen ; to stop shifting LFSR after generating the gold sequence to save power
    input   wire            gen,
    input   wire            clk,
    input   wire            rst
);

reg  [LFSR_WIDTH-1 :0]  LFSR;
wire                    feedback;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        LFSR <= 'd0;
    end
    else if (SEED_Ready_Pulse) begin
        LFSR <= SEED;
    end
    else if (!goldseq_done && (gen)) begin
        LFSR <= LFSR>>1;
        LFSR[LFSR_WIDTH -1] <= feedback;
    end
    
end




assign feedback = ^ ( XOR_POS & LFSR );
assign OUT      = LFSR[0];
    
endmodule