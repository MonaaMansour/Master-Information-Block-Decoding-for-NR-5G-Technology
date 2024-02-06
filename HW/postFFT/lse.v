module lse #(parameter      CH_EST_LSE_WORD_LENGTH = 16,  CH_EST_LSE_INT_LENGTH = 0, CH_EST_LSE_FLOAT_LENGTH = 15,        // S0.7   

                            DMRS_TX_WORD_LENGTH    = 5,  DMRS_TX_INT_LENGTH    = 0, DMRS_TX_FLOAT_LENGTH    = 4,        // S0.4

                            DMRS_RX_WORD_LENGTH    = 12, DMRS_RX_INT_LENGTH    = 0, DMRS_RX_FLOAT_LENGTH    = 11 ) (    // S0.14

    output reg  signed [CH_EST_LSE_WORD_LENGTH-1:0]  ch_est_lse_i_r,
    output reg  signed [CH_EST_LSE_WORD_LENGTH-1:0]  ch_est_lse_q_r,
    output reg                                       out_valid,

    input  wire signed [DMRS_RX_WORD_LENGTH-1:0]     rx_i,
    input  wire signed [DMRS_RX_WORD_LENGTH-1:0]     rx_q,

    input  wire signed [DMRS_TX_WORD_LENGTH-1:0]     tx_i,
    input  wire signed [DMRS_TX_WORD_LENGTH-1:0]     tx_q,

    input  wire                                      in_valid,
    input  wire                                      clk,
    input  wire                                      rst
);

//WE WANT TO APPLY COMPLEX MULTIPLICATION : ch_est_lse_r = (rx_i+j rx_q) * conj(tx_i + j tx_q) 
//
//FIRST METHOD SIMPLIFIES TO : ch_est_lse_r = [(rx_i * tx_i) + (rx_q * tx_q)] + j [(-rx_i * tx_q) + (rx_q * tx_i)]
//               HENCE WE NEED (4 MULTIPLIERS + 3 ADDERS)
//
//SECOND METHOD SIMPLIFIES TO : ch_est_lse_r = [rx_i * (tx_i - tx_q) + tx_q * (rx_i + rx_q)] + j [rx_i * (tx_i - tx_q) + tx_i * (rx_q - rx_i)]
//                HENCE WE NEED (3 MULTIPLIERS + 5 ADDERS)
//
//IN THIS MODULE WE USE THE SECOND APPROACH


//rx_i/q    = SX.Y
//tx_i/q    = SA.B
//out_i/q   = SG.Z

// S(X+A+1).(Y+B) + S(X+A+1).(Y+B) = S(X+A+2).(Y+B)
reg signed [1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 2 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH -1:0] ch_est_lse_i;
reg signed [1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 2 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH -1:0] ch_est_lse_q;



reg signed [DMRS_TX_WORD_LENGTH-1 +1 :0]    temp1; // SA.B + SA.B = S(A+1).(B)   
reg signed [DMRS_RX_WORD_LENGTH-1 +1 :0]    temp2; // SX.Y + SX.Y = S(X+1).(Y)
reg signed [DMRS_RX_WORD_LENGTH-1 +1 :0]    temp3; // SX.Y + SX.Y = S(X+1).(Y)   


// S(A+1).(B)   * SX.Y = S(X+A+1).(Y+B)
reg signed [1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 1 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH -1:0]    temp11;  

// [S(X+1).(Y)] * SA.B = S(X+A+1).(Y+B) 
reg signed [1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 1 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH -1:0]    temp22; 

// S(X+1).(Y)   * SA.B = S(X+A+1).(Y+B)
reg signed [1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 1 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH -1:0]    temp33; 




wire [CH_EST_LSE_WORD_LENGTH-1:0] ch_est_lse_i_round_saturated;
wire [CH_EST_LSE_WORD_LENGTH-1:0] ch_est_lse_q_round_saturated;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ch_est_lse_i_r <= 'd0;
        ch_est_lse_q_r <= 'd0;
        out_valid      <= 'd0;
    end
    else begin
        if(in_valid) begin
        ch_est_lse_i_r <= ch_est_lse_i_round_saturated;
        ch_est_lse_q_r <= ch_est_lse_q_round_saturated;
        end
        out_valid      <= in_valid;

    end
end


always @(*) begin
    //if (in_valid) begin
        temp1 = tx_i - tx_q;
        temp2 = rx_i + rx_q;
        temp3 = rx_q - rx_i;

        temp11 = temp1 * rx_i;
        temp22 = temp2 * tx_q;
        temp33 = temp3 * tx_i;

        ch_est_lse_i = temp11 + temp22;
        ch_est_lse_q = temp11 + temp33;
    //end
    //else begin
    //    temp1 = 'd0;
    //    temp2 = 'd0;
    //    temp3 = 'd0;
    //    temp11 = 'd0;
    //    temp22 = 'd0;
    //    temp33 = 'd0;
    //    ch_est_lse_i = 'd0;
    //    ch_est_lse_q = 'd0;
    //end
    
    
end






RoundSaturate #(    .IN_WORD_LENGTH(1 + DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 2 + DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH) ,
                    .IN_INT_LENGTH(DMRS_RX_INT_LENGTH + DMRS_TX_INT_LENGTH + 2),
                    .IN_FLOAT_LENGTH(DMRS_RX_FLOAT_LENGTH + DMRS_TX_FLOAT_LENGTH),
                    .OUT_WORD_LENGTH(CH_EST_LSE_WORD_LENGTH), 
                    .OUT_INT_LENGTH(CH_EST_LSE_INT_LENGTH), 
                    .OUT_FLOAT_LENGTH(CH_EST_LSE_FLOAT_LENGTH) ) U0_RoundSaturate (
    
    .i_in(ch_est_lse_i),
    .q_in(ch_est_lse_q),
    .i_round_saturated(ch_est_lse_i_round_saturated),
    .q_round_saturated(ch_est_lse_q_round_saturated)

);




endmodule



//SX.Y + SA.B = S( max(X,A)+1 ).( max(Y,B) )
//SX.Y + SX.Y = S(X+1).(Y) ----> S(X).(Y)

//SX.Y * SA.B = S(X+A).(Y+B)
//SX.Y * SX.Y = S(2X).(2Y)





//SX.Y + SA.B = S( max(X,A)+1 ).( max(Y,B) )
//SX.Y + SX.Y = S(X+1).(Y) ----> S(X).(Y)

//SX.Y * SA.B = S(X+A).(Y+B)
//SX.Y * SX.Y = S(2X).(2Y)



