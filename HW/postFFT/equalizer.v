module equalizer #(parameter    EQUALIZER_WORD_LENGTH = 8,  EQUALIZER_INT_LENGTH = 0, EQUALIZER_FLOAT_LENGTH = 7,        // S0.7   
                                CH_WORD_LENGTH        = 8,  CH_INT_LENGTH        = 0, CH_FLOAT_LENGTH        = 7,        // S0.4
                                PBCH_RX_WORD_LENGTH   = 12, PBCH_RX_INT_LENGTH   = 0, PBCH_RX_FLOAT_LENGTH   = 11 ) (    // S0.14

    output reg  signed [EQUALIZER_WORD_LENGTH-1:0]  equalized_i_r,
    output reg  signed [EQUALIZER_WORD_LENGTH-1:0]  equalized_q_r,
    output reg                                      out_valid,
    output reg                                      out_valid_level,
    output reg                                      equalization_done_r,

    input  wire signed [PBCH_RX_WORD_LENGTH-1:0]    rx_i,
    input  wire signed [PBCH_RX_WORD_LENGTH-1:0]    rx_q,
  
    input  wire signed [CH_WORD_LENGTH-1    :0]     ch_i,
    input  wire signed [CH_WORD_LENGTH-1    :0]     ch_q,
  
    input  wire                                     in_valid,
    input  wire                                     clk,
    input  wire                                     rst
);

//WE WANT TO APPLY COMPLEX MULTIPLICATION : EQUALIZER_r = (rx_i+j rx_q) * conj(ch_i + j ch_q) 
//
//FIRST METHOD SIMPLIFIES TO : EQUALIZER_r = [(rx_i * ch_i) + (rx_q * ch_q)] + j [(-rx_i * ch_q) + (rx_q * ch_i)]
//               HENCE WE NEED (4 MULTIPLIERS + 3 ADDERS)
//
//SECOND METHOD SIMPLIFIES TO : EQUALIZER_r = [rx_i * (ch_i - ch_q) + ch_q * (rx_i + rx_q)] + j [rx_i * (ch_i - ch_q) + ch_i * (rx_q - rx_i)]
//                HENCE WE NEED (3 MULTIPLIERS + 5 ADDERS)
//
//IN THIS MODULE WE USE THE SECOND APPROACH


//rx_i/q    = SX.Y
//ch_i/q    = SA.B
//out_i/q   = SG.Z

// S(X+A+1).(Y+B) + S(X+A+1).(Y+B) = S(X+A+2).(Y+B)
reg signed [1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 2 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH -1:0] equalized_i;
reg signed [1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 2 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH -1:0] equalized_q;



reg signed [CH_WORD_LENGTH     -1 +1 :0]    temp1; // SA.B + SA.B = S(A+1).(B)   
reg signed [PBCH_RX_WORD_LENGTH-1 +1 :0]    temp2; // SX.Y + SX.Y = S(X+1).(Y)
reg signed [PBCH_RX_WORD_LENGTH-1 +1 :0]    temp3; // SX.Y + SX.Y = S(X+1).(Y)   


// S(A+1).(B)   * SX.Y = S(X+A+1).(Y+B)
reg signed [1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 1 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH -1:0]    temp11;  

// [S(X+1).(Y)] * SA.B = S(X+A+1).(Y+B) 
reg signed [1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 1 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH -1:0]    temp22; 

// S(X+1).(Y)   * SA.B = S(X+A+1).(Y+B)
reg signed [1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 1 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH -1:0]    temp33; 




wire [EQUALIZER_WORD_LENGTH-1:0] equalized_i_round_saturated;
wire [EQUALIZER_WORD_LENGTH-1:0] equalized_q_round_saturated;

reg [8:0] pbch_counter,pbch_counter_r;
reg       equalization_done;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        equalized_i_r <= 'd0;
        equalized_q_r <= 'd0;
        out_valid     <= 'd0;
        pbch_counter_r <= 'd0;
        out_valid_level      <='d0;
        equalization_done_r <='d0;
    end
    else begin
        out_valid     <= in_valid;
        equalization_done_r<= equalization_done;
        if (in_valid) begin
            equalized_i_r <= equalized_i_round_saturated;
            equalized_q_r <= equalized_q_round_saturated;
            pbch_counter_r <= pbch_counter;
            out_valid_level <= in_valid;
        end else if (equalization_done_r) begin
            out_valid_level     <= 'd0;
            pbch_counter_r      <= 'd0;
        end
    end
end


always @(*) begin
    //if (in_valid) begin
        equalization_done= 'd0;
        temp1 = ch_i - ch_q;
        temp2 = rx_i + rx_q;
        temp3 = rx_q - rx_i;

        temp11 = temp1 * rx_i;
        temp22 = temp2 * ch_q;
        temp33 = temp3 * ch_i;

        equalized_i = temp11 + temp22;
        equalized_q = temp11 + temp33;
        pbch_counter = pbch_counter_r +'d1;
        if (pbch_counter_r == 'd432 && out_valid) begin
            equalization_done   ='d1 ;
        end
    //end
    //else begin
    //    temp1 = 'd0;
    //    temp2 = 'd0;
    //    temp3 = 'd0;
    //    temp11 = 'd0;
    //    temp22 = 'd0;
    //    temp33 = 'd0;
    //    equalized_i = 'd0;
    //    equalized_q = 'd0;
    //end
    
    
end






RoundSaturate #(    .IN_WORD_LENGTH(1 + PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 2 + PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH) ,
                    .IN_INT_LENGTH(PBCH_RX_INT_LENGTH + CH_INT_LENGTH + 2),
                    .IN_FLOAT_LENGTH(PBCH_RX_FLOAT_LENGTH + CH_FLOAT_LENGTH),
                    .OUT_WORD_LENGTH(EQUALIZER_WORD_LENGTH), 
                    .OUT_INT_LENGTH(EQUALIZER_INT_LENGTH), 
                    .OUT_FLOAT_LENGTH(EQUALIZER_FLOAT_LENGTH) ) U2_RoundSaturate (
    
    .i_in(equalized_i),
    .q_in(equalized_q),
    .i_round_saturated(equalized_i_round_saturated),
    .q_round_saturated(equalized_q_round_saturated)

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



