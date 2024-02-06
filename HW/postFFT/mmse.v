module mmse #(parameter MMSE_WORD_LENGTH = 8,       MMSE_INT_LENGTH = 0,       MMSE_FLOAT_LENGTH = 7,         // S0.8 
                        CH_EST_LSE_WORD_LENGTH = 8, CH_EST_LSE_INT_LENGTH = 0, CH_EST_LSE_FLOAT_LENGTH = 7,   // S0.8  
                        MULTIPLIERS_NUM = 12)       
    (
    output  wire signed   [MMSE_WORD_LENGTH-1       :0]     mmse_rs_i,
    output  wire signed   [MMSE_WORD_LENGTH-1       :0]     mmse_rs_q,
    output  reg                                             out_valid_r,
    output  reg                                             symbol_done_r,
    output  wire          [10                       :0]     coeff_addr,
    input   wire signed   [CH_EST_LSE_WORD_LENGTH-1 :0]     h_tilde_i,
    input   wire signed   [CH_EST_LSE_WORD_LENGTH-1 :0]     h_tilde_q,
    input   wire                                            in_valid, //level
    input   wire          [1                        :0]     symbol_num,
    input   wire signed   [MMSE_WORD_LENGTH *12 -1  :0]     rhp_inv_rpp,
    input   wire                                            clk,
    input   wire                                            rst
);
    

//reg signed  [MMSE_WORD_LENGTH-1           :0]           rhp_inv_rpp1  [0:239][0:59] ;
//reg signed  [MMSE_WORD_LENGTH-1           :0]           rhp_inv_rpp2  [0:47 ][0:11] ;
reg signed  [CH_EST_LSE_WORD_LENGTH-1     :0]           h_tilde_r_i   [0:59 ]       ;
reg signed  [CH_EST_LSE_WORD_LENGTH-1     :0]           h_tilde_r_q   [0:59 ]       ;
reg         [6                     -1     :0]           index_r, index ;
reg         [3                     -1     :0]           counter_5_r, counter_5 ;
reg         [11                    -1     :0]           counter_1200, counter_1200_r;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]           accumulator_i;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]           accumulator_q;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]           mmse_i;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]           mmse_q;



//reg                                                     in_valid_r;
//wire                                                    in_valid_ne;
reg                                                     start_process; // Input has been stored, start multiplication
reg                                                     start_process_r;
reg                                                     start_process_r_r;
reg                                                     out_valid;
reg                                                     symbol_done;
reg                                                     early_symbol_done;

always @(posedge clk, negedge rst) begin
    if (!rst) begin
        index_r                 <= 'd0;
        counter_5_r             <= 'd0;
        counter_1200_r          <= 'd0;
        mmse_i                  <= 'd0;
        mmse_q                  <= 'd0;
        out_valid_r             <= 'd0;
        start_process_r         <= 'd0;
        start_process_r_r       <= 'd0;
        early_symbol_done       <= 'd0;
        symbol_done_r           <= 'd0;
        
    end 
    else begin
        //if(in_valid) begin
            h_tilde_r_i[index_r]    <= h_tilde_i;
            h_tilde_r_q[index_r]    <= h_tilde_q;
        //end
        index_r                 <= index;
        start_process_r         <= start_process;
        start_process_r_r       <= start_process_r;
        counter_5_r             <= counter_5;
        counter_1200_r          <= counter_1200;
        mmse_i                  <= accumulator_i;
        mmse_q                  <= accumulator_q;
        out_valid_r             <= out_valid;
        early_symbol_done       <= symbol_done;
        symbol_done_r           <= early_symbol_done;
    end
end




always @(*) begin
    index = index_r ;
    if (in_valid) begin
        if (symbol_num == 'd1 || symbol_num == 'd2) begin
            if (index_r<=11) begin
                index = index_r + 1'b1;
            end

        end
        else begin
            if (index_r<=59) begin
                index = index_r + 1'b1;
            end

        end
    end 

    if (symbol_num == 'd1 || symbol_num == 'd2) begin
            //counter_5    = 'd0;
            if (counter_1200_r == 'd47 ) begin
                index = 'd0;
            end
        end
        else begin
            
            if (counter_1200_r == 'd1199 ) begin
                index ='d0;
            end
        end
end

always @(*) begin
    counter_1200 = counter_1200_r;
    counter_5    = counter_5_r;
    out_valid    = 1'b0;
    symbol_done  = 1'b0;

    if (start_process_r) begin
        counter_1200 = counter_1200_r + 'd1;

        if (symbol_num == 'd1 || symbol_num == 'd2) begin
            //counter_5    = 'd0;
            if (counter_1200_r == 'd47 ) begin
                counter_1200 = 'd0;
                symbol_done  = 1'b1;
            end
        end
        else begin
            
            if (counter_1200_r == 'd1199 ) begin
                counter_1200 = 'd0;
                symbol_done  = 1'b1;
            end
        end
    end

    if (start_process_r_r) begin
        if (symbol_num == 'd0 || symbol_num == 'd3) begin
            counter_5    = counter_5_r    + 'd1;
            if (counter_5_r == 'd4) begin
                counter_5 = 'd0;
                out_valid = 1'b1;
            end
        end else begin
          out_valid = 1'b1;
        end

    end
end



//rhp_inv_rpp[1][1:12] * h_tilde_r_i [1:12] + rhp_inv_rpp[1][1:12] * h_tilde_r_q [1:12]


reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       mul_i     [0:11]      ; // S0.15 * S0.15 = S0.30 --RoundSat---> S0.15
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       mul_q     [0:11]      ;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_1_i   [0:5]       ;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_1_q   [0:5]       ;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_2_i   [0:2]       ; 
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_2_q   [0:2]       ;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_3_i   [0:1]       ; 
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_3_q   [0:1]       ;
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_4_i               ; 
reg signed  [CH_EST_LSE_WORD_LENGTH*2-1-1 :0]       add_4_q               ;






integer i;
always @(*) begin
    accumulator_i = mmse_i;
    accumulator_q = mmse_q;

    if (start_process_r_r) begin
    //MULTIPLICATION - STAGE 1//
        mul_i[0] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-0) -1 : MMSE_WORD_LENGTH * (11-0)  ])* h_tilde_r_i[0+12*counter_5_r]; 
        mul_q[0] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-0) -1 : MMSE_WORD_LENGTH * (11-0)  ])* h_tilde_r_q[0+12*counter_5_r];

        mul_i[1] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-1) -1 : MMSE_WORD_LENGTH * (11-1)  ])* h_tilde_r_i[1+12*counter_5_r]; 
        mul_q[1] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-1) -1 : MMSE_WORD_LENGTH * (11-1)  ])* h_tilde_r_q[1+12*counter_5_r];

        mul_i[2] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-2) -1 : MMSE_WORD_LENGTH * (11-2)  ])* h_tilde_r_i[2+12*counter_5_r]; 
        mul_q[2] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-2) -1 : MMSE_WORD_LENGTH * (11-2)  ])* h_tilde_r_q[2+12*counter_5_r];

        mul_i[3] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-3) -1 : MMSE_WORD_LENGTH * (11-3)  ])* h_tilde_r_i[3+12*counter_5_r]; 
        mul_q[3] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-3) -1 : MMSE_WORD_LENGTH * (11-3)  ])* h_tilde_r_q[3+12*counter_5_r];

        mul_i[4] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-4) -1 : MMSE_WORD_LENGTH * (11-4)  ])* h_tilde_r_i[4+12*counter_5_r]; 
        mul_q[4] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-4) -1 : MMSE_WORD_LENGTH * (11-4)  ])* h_tilde_r_q[4+12*counter_5_r];

        mul_i[5] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-5) -1 : MMSE_WORD_LENGTH * (11-5)  ])* h_tilde_r_i[5+12*counter_5_r]; 
        mul_q[5] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-5) -1 : MMSE_WORD_LENGTH * (11-5)  ])* h_tilde_r_q[5+12*counter_5_r];

        mul_i[6] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-6) -1 : MMSE_WORD_LENGTH * (11-6)  ])* h_tilde_r_i[6+12*counter_5_r]; 
        mul_q[6] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-6) -1 : MMSE_WORD_LENGTH * (11-6)  ])* h_tilde_r_q[6+12*counter_5_r];

        mul_i[7] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-7) -1 : MMSE_WORD_LENGTH * (11-7)  ])* h_tilde_r_i[7+12*counter_5_r]; 
        mul_q[7] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-7) -1 : MMSE_WORD_LENGTH * (11-7)  ])* h_tilde_r_q[7+12*counter_5_r];

        mul_i[8] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-8) -1 : MMSE_WORD_LENGTH * (11-8)  ])* h_tilde_r_i[8+12*counter_5_r]; 
        mul_q[8] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-8) -1 : MMSE_WORD_LENGTH * (11-8)  ])* h_tilde_r_q[8+12*counter_5_r];

        mul_i[9] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-9) -1 : MMSE_WORD_LENGTH * (11-9)  ])* h_tilde_r_i[9+12*counter_5_r]; 
        mul_q[9] = $signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-9) -1 : MMSE_WORD_LENGTH * (11-9)  ])* h_tilde_r_q[9+12*counter_5_r]; 

        mul_i[10] =$signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-10) -1: MMSE_WORD_LENGTH * (11-10) ])* h_tilde_r_i[10+12*counter_5_r]; 
        mul_q[10] =$signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-10) -1: MMSE_WORD_LENGTH * (11-10) ])* h_tilde_r_q[10+12*counter_5_r]; 

        mul_i[11] =$signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-11) -1: MMSE_WORD_LENGTH * (11-11) ])* h_tilde_r_i[11+12*counter_5_r];
        mul_q[11] =$signed(rhp_inv_rpp[MMSE_WORD_LENGTH *(12-11) -1: MMSE_WORD_LENGTH * (11-11) ])* h_tilde_r_q[11+12*counter_5_r]; 

    //ADDER TREE//
    //ADDITION STAGE 2//
    for (i = 0; i<6; i=i+1 ) begin                              //add_1[0] = mul[0]  + mul[1] ;
        add_1_i[i] = mul_i[2*i]  + mul_i[2*i+1];                //add_1[1] = mul[2]  + mul[3] ;
        add_1_q[i] = mul_q[2*i]  + mul_q[2*i+1];                //add_1[5] = mul[10] + mul[11];
    end       

    //ADDITION STAGE 3//
    for (i = 0; i<3 ; i=i+1 ) begin
        add_2_i[i] = add_1_i[2*i]  + add_1_i[2*i+1];
        add_2_q[i] = add_1_q[2*i]  + add_1_q[2*i+1];
    end

    //ADDITION STAGE 4//
    add_3_i[0] = add_2_i[0] + add_2_i[1];
    add_3_q[0] = add_2_q[0] + add_2_q[1];
    add_3_i[1] = add_2_i[2];
    add_3_q[1] = add_2_q[2];

    //ADDITION STAGE 5//
    add_4_i    = add_3_i[0] + add_3_i[1];
    add_4_q    = add_3_q[0] + add_3_q[1];

    //ACCUMULATION STAGE//
    if (counter_5_r == 0) begin
        accumulator_i = add_4_i;
        accumulator_q = add_4_q;
    end
    else begin
        accumulator_i = mmse_i + add_4_i;
        accumulator_q = mmse_q + add_4_q;
    end
    

    

    end

    else begin
      //RESETING//
    for (i = 0; i<MULTIPLIERS_NUM ; i=i+1 ) begin
        mul_i[i]   = 'd0;
        mul_q[i]   = 'd0;
    end

    for (i = 0; i<6; i=i+1 ) begin            
        add_1_i[i] = 'd0;                
        add_1_q[i] = 'd0;                
    end       

    
    for (i = 0; i<3 ; i=i+1 ) begin
        add_2_i[i] = 'd0;
        add_2_q[i] = 'd0;
    end

    
    add_3_i[0]  = 'd0;
    add_3_q[0]  = 'd0;
    add_3_i[1]  = 'd0;
    add_3_q[1]  = 'd0;
    add_4_i     = 'd0;
    add_4_q     = 'd0;
    
    end
end



RoundSaturate #(    .IN_WORD_LENGTH     (CH_EST_LSE_WORD_LENGTH*2-1) ,
                    .IN_INT_LENGTH      (CH_EST_LSE_INT_LENGTH),
                    .IN_FLOAT_LENGTH    (CH_EST_LSE_WORD_LENGTH*2-1-1),
                    .OUT_WORD_LENGTH    (CH_EST_LSE_WORD_LENGTH), 
                    .OUT_INT_LENGTH     (CH_EST_LSE_INT_LENGTH), 
                    .OUT_FLOAT_LENGTH   (CH_EST_LSE_FLOAT_LENGTH) ) U0_Round (
    
    .i_in(mmse_i),
    .q_in(mmse_q),
    .i_round_saturated(mmse_rs_i),
    .q_round_saturated(mmse_rs_q)
);


always @(*) begin

    start_process = start_process_r;

  if (symbol_num == 'd1 || symbol_num == 'd2) begin
      if (index_r>11) begin
          start_process = 1'b1;
      end
      if ( coeff_addr == 'd1247 ) begin
          start_process = 1'b0;
      end

  end else begin
      if (index_r>59) begin
          start_process = 1'b1;
      end
      if ( coeff_addr == 'd1199 ) begin
          start_process = 1'b0;
      end      

  end
end

//assign in_valid_ne = in_valid_r & ~(in_valid);
assign coeff_addr  = (symbol_num == 'd1 || symbol_num == 'd2) ? (counter_1200_r + 'd1200) : counter_1200_r ;

endmodule
