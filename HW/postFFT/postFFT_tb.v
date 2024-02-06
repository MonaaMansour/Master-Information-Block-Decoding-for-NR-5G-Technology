`timescale 1ns/1ps
module postFFT_tb #(parameter       DMRS_RX_WORD_LENGTH_tb     = 12,//
                                    DMRS_RX_INT_LENGTH_tb      = 0,
                                    DMRS_RX_FLOAT_LENGTH_tb    = 11,
                                    DMRS_TX_WORD_LENGTH_tb     = 8,
                                    DMRS_TX_INT_LENGTH_tb      = 0,
                                    DMRS_TX_FLOAT_LENGTH_tb    = 7,
                                    RAM_WIDTH_tb               = 8*2,
                                    ADDR_WIDTH_tb              = 10,
                                    INPUT_WIDTH_tb             = 8,
                                    OUTPUT_WIDTH_tb            = 8,
                                    MMSE_WORD_LENGTH_tb        = 8,//
                                    MMSE_INT_LENGTH_tb         = 0,
                                    MMSE_FLOAT_LENGTH_tb       = 7,
                                    MULTIPLIERS_NUM_tb         = 12,
                                    CH_EST_LSE_WORD_LENGTH_tb  = 8,
                                    CH_EST_LSE_INT_LENGTH_tb   = 0,
                                    CH_EST_LSE_FLOAT_LENGTH_tb = 7,
                                    FP_tb                      = 8*2, //FP depend on the width of 1/root(2)
                                    PBCH_RX_WORD_LENGTH_tb     = 12,
                                    PBCH_RX_INT_LENGTH_tb      = 0,
                                    PBCH_RX_FLOAT_LENGTH       = 11,
                                    EQUALIZ_WORD_LENGTH_tb     = 8,
                                    EQUALIZ_INT_LENGTH_tb      = 0,
                                    EQUALIZ_FLOAT_LENGTH_tb    = 7,
                                    LLR_WIDTH_tb               = 8 )(); 

    wire       [9                        :0] fft_mem_addr_tb;
    wire       [LLR_WIDTH_tb          -1 :0] llrs_tb;
    wire       [6                     -1 :0] llr_mem_w_addr_tb;
    wire       [2                     -1 :0] mem_llr_slct_tb;
    wire                                     llr_mem_1_w_enable_tb;
    wire                                     llr_mem_2_w_enable_tb;
    wire                                     llr_done_tb;
    wire       [10                       :0] coeff_addr_tb;
    reg        [MMSE_WORD_LENGTH_tb *12-1:0] rhp_inv_rpp_tb;
    reg                                      clk_tb; 
    reg                                      rst_tb;
    reg        [1                        :0] issb_tb;
    reg        [9                        :0] ncellid_tb;          
    reg                                      n_hf_tb;
    reg signed [DMRS_RX_WORD_LENGTH_tb-1 :0] fft_mem_data_i_tb;
    reg signed [DMRS_RX_WORD_LENGTH_tb-1 :0] fft_mem_data_q_tb;
    reg                                      est_strt_tb ;
    
    
    


/////local param//////
    localparam  clk_period = 16.2156;

/////instantiation//////
postFFT #(      .RX_WORD_LENGTH             (DMRS_RX_WORD_LENGTH_tb    ),
                .MMSE_WORD_LENGTH           (MMSE_WORD_LENGTH_tb       ),
                .LLR_WIDTH                  (LLR_WIDTH_tb              )) DUT (

    .fft_mem_addr           (fft_mem_addr_tb),
    .llrs                   (llrs_tb),
    .llr_mem_w_addr         (llr_mem_w_addr_tb),
    .mem_llr_slct           (mem_llr_slct_tb),
    .llr_mem_1_w_enable     (llr_mem_1_w_enable_tb),
    .llr_mem_2_w_enable     (llr_mem_2_w_enable_tb),
    .llr_done               (llr_done_tb), ////
    .coeff_addr             (coeff_addr_tb),
    .rhp_inv_rpp            (rhp_inv_rpp_tb),
    .fft_mem_data_i         (fft_mem_data_i_tb),
    .fft_mem_data_q         (fft_mem_data_q_tb),
    .est_strt               (est_strt_tb),
    .issb                   (issb_tb),
    .ncellid                (ncellid_tb),
    .n_hf                   (n_hf_tb),
    .clk                    (clk_tb),
    .rst                    (rst_tb)
);



/////clock generation///////
always #(clk_period/2) clk_tb=~clk_tb;

/////initial block////////
integer INPUTS,LSE,MMSE,AVG,EQ,SCRMBL,LLR,COEFF1,COEFF2,RAM_FFT,PBCHrx,k_lse,k_mmse,k_avg,k_eq,k_scrmbl,k_llr1,k_llr2,Passed,Failed,increment,Latency,trials,Total;


reg [OUTPUT_WIDTH_tb           -1:0] AVG_test_i ;
reg [OUTPUT_WIDTH_tb           -1:0] AVG_test_q ;
reg [MMSE_WORD_LENGTH_tb       -1:0] MMSE_test_i ;
reg [MMSE_WORD_LENGTH_tb       -1:0] MMSE_test_q ;
reg [CH_EST_LSE_WORD_LENGTH_tb -1:0] LSE_test_i;
reg [CH_EST_LSE_WORD_LENGTH_tb -1:0] LSE_test_q;
reg [DMRS_TX_WORD_LENGTH_tb    -1:0] tx_i_tb;
reg [DMRS_TX_WORD_LENGTH_tb    -1:0] tx_q_tb;
reg [EQUALIZ_WORD_LENGTH_tb    -1:0] EQ_test_i;
reg [EQUALIZ_WORD_LENGTH_tb    -1:0] EQ_test_q;
reg [EQUALIZ_WORD_LENGTH_tb    -1:0] SCRMBL_test;
reg [PBCH_RX_WORD_LENGTH_tb    -1:0] PBCHrx_test_i;
reg [PBCH_RX_WORD_LENGTH_tb    -1:0] PBCHrx_test_q;
reg [LLR_WIDTH_tb              -1:0] LLR_test1;
reg [LLR_WIDTH_tb              -1:0] LLR_test2;
reg [LLR_WIDTH_tb              -1:0] LLR_test3;
reg [LLR_WIDTH_tb              -1:0] LLR_test4;

reg [8*4-1   :0] llr_1_ram [64-1  :0]; 
reg [8*4-1   :0] llr_2_ram [64-1  :0]; 

reg [12*2-1  :0] fft_ram   [256*3-1:0];

reg signed  [MMSE_WORD_LENGTH_tb*6  -1:0]           offline_coeff1  [0:1247];
reg signed  [MMSE_WORD_LENGTH_tb*6  -1:0]           offline_coeff2  [0:1247];
integer i,j,k;
initial begin
    INPUTS = $fopen("TOP_INPUTS.txt", "rb");
    if(INPUTS == 0) $error("Could not open INPUTS file");
    LSE = $fopen("TOP_LSE.txt", "rb");
    if(LSE == 0) $error("Could not open LSE file");
    MMSE = $fopen("TOP_MMSE.txt", "rb");
    if(MMSE == 0) $error("Could not open MMSE file");
    AVG = $fopen("TOP_AVG.txt", "rb");
    if(AVG == 0) $error("Could not open AVG file");
    EQ = $fopen("TOP_EQ.txt", "rb");
    if(EQ == 0) $error("Could not open  file");
    SCRMBL = $fopen("TOP_SCRMBL.txt", "rb");
    if(SCRMBL == 0) $error("Could not open SCRMBL file");
    LLR = $fopen("TOP_RATEMATCH.txt", "rb");
    if(LLR == 0) $error("Could not open LLR file");
    RAM_FFT = $fopen("FFT_RAM.txt", "rb");
    if(RAM_FFT == 0) $error("Could not open FFT_RAM file");
    COEFF1 = $fopen("COEFF1.txt", "rb");
    if(COEFF1 == 0) $error("Could not open COEFF file");
    COEFF2 = $fopen("COEFF2.txt", "rb");
    if(COEFF2 == 0) $error("Could not open COEFF file");
    
    for (j = 0; j<1248 ;j=j+1 ) begin
        $fscanf(COEFF1,"%b",offline_coeff1[j]);
        $fscanf(COEFF2,"%b",offline_coeff2[j]);
    end
    
    
    

end


initial begin
    clk_tb      = 'd0;
    trials      =   0;
    Total       =   0;
    est_strt_tb =   0;
    do_reset(clk_period);
    //$dumpfile("est_top_tb.vcd");
	//$dumpvars(1,est_top_tb);  
    
    while (1) begin
        k_lse       =   0;
        k_mmse      =   0;
        k_avg       =   0;
        k_eq        =   0;
        k_scrmbl    =   0;
        k_llr1      =   0;
        k_llr2      =   0;
        increment   =   0;
        Latency     =   0;
        Passed      =   0;
        Failed      =   0;
        // Read Inputs //
        $fscanf(INPUTS,"%d",ncellid_tb);
        $fscanf(INPUTS,"%d",issb_tb);
        $fscanf(INPUTS,"%d",n_hf_tb);
        for (k = 0; k<768 ;k=k+1 ) begin
            $fscanf(RAM_FFT,"%b",fft_ram[k]);
        end 
        if(!$feof(INPUTS)) begin
            // GENERATE A PULSE TO START THE ESTIMATION //
            @(posedge clk_tb) 
            #(0.1*clk_period)  
            est_strt_tb = 1;
            #(clk_period)      
             est_strt_tb = 0;
            // WAIT FOT THE ESTIMATION TO FINISH //
            wait (llr_done_tb);
            #(4*clk_period)
            $display ("Trial number %d",trials+1);
            // Display Latency //
            $display ("Latency = %d ",Latency+1);
            // Check for any errors //
            if (Failed == 0) begin
              $display ("******* 0 Errors, All Symbols Passed******");
            end
            else begin
              $display ("******* %d Errors occured******",Failed);
              Total=Total+1;
            end
            trials=trials + 1;
            
            #(1*clk_period);
        end 
        else begin
            $display ("Number of trials tested =",trials);

            if (Total==0) begin
                $display ("All trials PASSED");
            end
            else begin
                $display("Number of PASSED trials =",trials-Total);
                $display("Number of FAILED trials =",Total);
            end
                $finish;
            end
    end

end



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// TX_DMRS_GEN ///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_tb) begin
    {fft_mem_data_i_tb,fft_mem_data_q_tb} = fft_ram[fft_mem_addr_tb];
    //#(0.1*clk_period)
    if(DUT.u0_est_top.u0_ch_est_lse.in_valid) begin
    $fscanf(LSE,"%b",tx_i_tb);
    $fscanf(LSE,"%b",tx_q_tb);
    //$fscanf(LSE,"%b",fft_mem_data_i_tb);
    //$fscanf(LSE,"%b",fft_mem_data_q_tb);
    


    if (tx_i_tb == DUT.u0_est_top.u0_ch_est_lse.tx_i && tx_q_tb == DUT.u0_est_top.u0_ch_est_lse.tx_q) begin
                $display(" DMRS_GEN test case %d PASSED",k_lse+1);
                Passed = Passed +1;
            end
    else begin
                $display(" DMRS_GEN test case %d FAILED!!!!!!!!!!",k_lse+1);
                Failed = Failed +1;
    end
    end
end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// LSE ///////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_tb) begin
    wait(DUT.u0_est_top.u0_ch_est_lse.out_valid);

    if(fft_mem_addr_tb != 'd8 ) begin
        
        $fscanf(LSE,"%b",LSE_test_i);
        $fscanf(LSE,"%b",LSE_test_q);
        k_lse=k_lse+1;

        #(0.1*clk_period)
        if (LSE_test_i == DUT.u0_est_top.u0_ch_est_lse.ch_est_lse_i_r && LSE_test_q == DUT.u0_est_top.u0_ch_est_lse.ch_est_lse_q_r) begin
            $display(" LSE test case %d PASSED",k_lse);
            Passed = Passed +1;
        end
        else begin
            $display(" LSE test case %d FAILED!!!!!!!!!!",k_lse);
            $display(" Expected_i %b , Found_i %b ",LSE_test_i , DUT.u0_est_top.u0_ch_est_lse.ch_est_lse_i_r);
            $display(" Expected_q %b , Found_q %b ",LSE_test_q , DUT.u0_est_top.u0_ch_est_lse.ch_est_lse_q_r);
            Failed = Failed +1;
        end
        if (k_lse == 60 || k_lse == 72 || k_lse == 84 || k_lse == 144) begin
          #(clk_period);
        end
    end
    end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// MMSE //////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge DUT.u0_est_top.u0_mmse.symbol_done_r) begin
    #clk_period
    if (DUT.u0_est_top.u0_ctrl.symbol_num == 'd0) begin
        #(0.1*clk_period)
        for (k_mmse = 0; k_mmse < 240 ; k_mmse = k_mmse+1 ) begin
            $fscanf(MMSE,"%b",MMSE_test_i);
            $fscanf(MMSE,"%b",MMSE_test_q);

            if ({MMSE_test_i,MMSE_test_q} == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse]) begin
                $display(" MMSE 1st symbol, test case %d PASSED",k_mmse+1);
                Passed = Passed +1;
            end
            else begin
                $display(" MMSE 1st symbol, test case %d FAILED!!!!!!!!!!",k_mmse+1);
                $display(" Expected_i %b , Found_i %b ",MMSE_test_i , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][2*INPUT_WIDTH_tb-1:INPUT_WIDTH_tb]);
                $display(" Expected_q %b , Found_q %b ",MMSE_test_q , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][INPUT_WIDTH_tb-1:0]);
                Failed = Failed +1;
            end
        end
    end
    else if (DUT.u0_est_top.u0_ctrl.symbol_num == 'd1) begin
         #(0.1*clk_period)
        for (k_mmse = 240; k_mmse < 288 ; k_mmse = k_mmse+1 ) begin
            $fscanf(MMSE,"%b",MMSE_test_i);
            $fscanf(MMSE,"%b",MMSE_test_q);

            if ({MMSE_test_i,MMSE_test_q} == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse]) begin
                $display(" MMSE 2nd symbol 1st part, test case %d PASSED",k_mmse+1);
                Passed = Passed +1;
            end
            else begin
                $display(" MMSE 2nd symbol 1st part, test case %d FAILED!!!!!!!!!!",k_mmse+1);
                $display(" Expected_i %b , Found_i %b ",MMSE_test_i , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][2*INPUT_WIDTH_tb-1:INPUT_WIDTH_tb]);
                $display(" Expected_q %b , Found_q %b ",MMSE_test_q , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][INPUT_WIDTH_tb-1:0]);
                Failed = Failed +1;
            end
        end
        
    end
    else if (DUT.u0_est_top.u0_ctrl.symbol_num == 'd2) begin
         #(0.1*clk_period)
        for (k_mmse = 288; k_mmse < 336 ; k_mmse = k_mmse+1 ) begin
            $fscanf(MMSE,"%b",MMSE_test_i);
            $fscanf(MMSE,"%b",MMSE_test_q);
    
            if ({MMSE_test_i,MMSE_test_q} == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse]) begin
                $display(" MMSE 2nd symbol 2nd part, test case %d PASSED",k_mmse+1);
                Passed = Passed +1;
            end
            else begin
                $display(" MMSE 2nd symbol 2nd part, test case %d FAILED!!!!!!!!!!",k_mmse+1);
                $display(" Expected_i %b , Found_i %b ",MMSE_test_i , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][2*INPUT_WIDTH_tb-1:INPUT_WIDTH_tb]);
                $display(" Expected_q %b , Found_q %b ",MMSE_test_q , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][INPUT_WIDTH_tb-1:0]);
                Failed = Failed +1;
            end
        end
        
    end
//////////////////////////////////////////////////SYMBOL-3///////////////////////////////////////////////////////////////////////////
    else if (DUT.u0_est_top.u0_ctrl.symbol_num == 'd3) begin
         #(0.1*clk_period)
        for (k_mmse = 336; k_mmse < 576 ; k_mmse = k_mmse+1 ) begin
            $fscanf(MMSE,"%b",MMSE_test_i);
            $fscanf(MMSE,"%b",MMSE_test_q);
    
            if ({MMSE_test_i,MMSE_test_q} == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse]) begin
                $display(" MMSE 3rd symbol, test case %d PASSED",k_mmse+1);
                Passed = Passed +1;
            end
            else begin
                $display(" MMSE 3rd symbol, test case %d FAILED!!!!!!!!!!",k_mmse+1);
                $display(" Expected_i %b , Found_i %b ",MMSE_test_i , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][2*INPUT_WIDTH_tb-1:INPUT_WIDTH_tb]);
                $display(" Expected_q %b , Found_q %b ",MMSE_test_q , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_mmse][INPUT_WIDTH_tb-1:0]);
                Failed = Failed +1;
            end
        end
    end
    

end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// AVG ///////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_tb) begin
    //#(0.1*clk_period);
    if(DUT.u0_est_top.u0_mmse_ram.U0_addr_gen.addr_done_r) begin
        #(3*clk_period)
        for(k_avg=576;k_avg<576+240;k_avg=k_avg+1) begin
            $fscanf(AVG,"%b",AVG_test_i);
            $fscanf(AVG,"%b",AVG_test_q);

            //k_avg=k_avg+1;

            #(0.0001*clk_period);
            if (AVG_test_i == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_avg][RAM_WIDTH_tb   -1 :RAM_WIDTH_tb/2] && AVG_test_q == DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_avg][RAM_WIDTH_tb/2 -1 :0]) begin
                $display(" AVG test case %d PASSED",k_avg-575);
                Passed = Passed +1;
            end
            else begin
                $display(" AVG test case %d FAILED!!!!!!!!!!",k_avg-575);
                $display(" Expected_i %b , Found_i %b ",AVG_test_i , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_avg][RAM_WIDTH_tb   -1 :RAM_WIDTH_tb/2]);
                $display(" Expected_q %b , Found_q %b ",AVG_test_q , DUT.u0_est_top.u0_mmse_ram.U0_ram.RAM[k_avg][RAM_WIDTH_tb/2 -1 :0]);
                Failed = Failed +1;
            end
        end
    end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// EQ ////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_tb) begin
    #(0.1*clk_period);
    wait (DUT.u0_equalizer.in_valid)
    //$fscanf(EQ,"%b",fft_mem_data_i_tb);
    //$fscanf(EQ,"%b",fft_mem_data_q_tb);
    {fft_mem_data_i_tb,fft_mem_data_q_tb} = fft_ram[fft_mem_addr_tb];

    wait(DUT.u0_equalizer.out_valid)

        $fscanf(EQ,"%b",EQ_test_i);
        $fscanf(EQ,"%b",EQ_test_q);
        k_eq=k_eq+1;
        #(0.0001*clk_period);
        if (EQ_test_i == DUT.u0_equalizer.equalized_i_r && EQ_test_q == DUT.u0_equalizer.equalized_q_r) begin
            $display(" EQ test case %d PASSED",k_eq);
            Passed = Passed +1;
        end
        else begin
            $display(" EQ test case %d FAILED!!!!!!!!!!",k_eq);
            $display(" Expected_i %b , Found_i %b ",EQ_test_i , DUT.u0_equalizer.equalized_i_r);
            $display(" Expected_q %b , Found_q %b ",EQ_test_q , DUT.u0_equalizer.equalized_q_r);
            Failed = Failed +1;
        end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// SCRAMBLER ////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_tb) begin
    #(0.1*clk_period);
    wait(DUT.u0_scrambler.out_valid)
        $fscanf(SCRMBL,"%b",SCRMBL_test);
        k_scrmbl=k_scrmbl+1;
        
        if (SCRMBL_test == DUT.u0_scrambler.scrambled_data) begin
            $display(" SCRMBL test case %d PASSED",k_scrmbl);
            Passed = Passed +1;
        end
        else begin
            $display(" SCRMBL test case %d FAILED!!!!!!!!!!",k_scrmbl);
            $display(" Expected_i %b , Found_i %b ",SCRMBL_test , DUT.u0_scrambler.scrambled_data);
            Failed = Failed +1;
        end
end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// LLR ///////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
integer k_llr3,k_llr4;
always @(posedge clk_tb) begin
    wait(llr_done_tb) 
    k_llr3 = 0;
    k_llr4 = 0;
        #(2*clk_period)
        for(k_llr1=0;k_llr1<128;k_llr1=k_llr1+1) begin
                $fscanf(LLR,"%b",LLR_test1);
                $fscanf(LLR,"%b",LLR_test2);
                $fscanf(LLR,"%b",LLR_test3);
                $fscanf(LLR,"%b",LLR_test4);
            if (k_llr1 <64) begin
                if ({LLR_test1,LLR_test2,LLR_test3,LLR_test4} == llr_1_ram[k_llr1]) begin
                    $display(" LLR test case %d PASSED",k_llr1+1);
                    Passed = Passed +1;
                end
                else begin
                    $display(" LLR test case %d FAILED!!!!!!!!!!1111",k_llr1+1);
                    $display(" Expected_i %b , Found_i %b ",{LLR_test1,LLR_test2,LLR_test3,LLR_test4} , llr_1_ram[k_llr1]);
                    Failed = Failed +1;
                end

            end
            else begin
                if ({LLR_test1,LLR_test2,LLR_test3,LLR_test4} == llr_2_ram[k_llr1-64]) begin
                    $display(" LLR test case %d PASSED",k_llr1+1);
                    Passed = Passed +1;
                end
                else begin
                    $display(" LLR test case %d FAILED!!!!!!!!!!2222",k_llr1+1);
                    $display(" Expected_i %b , Found_i %b ",{LLR_test1,LLR_test2,LLR_test3,LLR_test4} , llr_2_ram[k_llr1-64]);
                    Failed = Failed +1;
                end
            end
        end
end




always @(posedge clk_tb) begin
    if (DUT.u0_est_top.u0_ch_est_lse.in_valid) increment = 1;
    if (DUT.u0_scrambler.out_valid)            increment = 0;
    if (increment)                  Latency = Latency +1;
end

task do_reset;
input clk_period;
begin
    rst_tb = 1;

    #(0.1*clk_period)
    rst_tb = 0;

    #(0.1*clk_period)
    rst_tb = 1;
end
endtask


always @(*) begin
    if (DUT.u0_est_top.u0_mmse.start_process_r) begin
        #clk_period
        rhp_inv_rpp_tb = {offline_coeff1[coeff_addr_tb],offline_coeff2[coeff_addr_tb]};
    end
    
end 
always @(posedge clk_tb) begin
    if(llr_mem_1_w_enable_tb) begin
        if (mem_llr_slct_tb == 0) begin
            llr_1_ram[llr_mem_w_addr_tb][(3-0)*8 + 7 : (3-0)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end
        else if (mem_llr_slct_tb == 1) begin
            llr_1_ram[llr_mem_w_addr_tb][(3-1)*8 + 7 : (3-1)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end 
        else if (mem_llr_slct_tb == 2) begin
            llr_1_ram[llr_mem_w_addr_tb][(3-2)*8 + 7 : (3-2)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end
        else if (mem_llr_slct_tb == 3) begin
            llr_1_ram[llr_mem_w_addr_tb][(3-3)*8 + 7 : (3-3)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end

    end
    if(llr_mem_2_w_enable_tb) begin
        if (mem_llr_slct_tb == 0) begin
            llr_2_ram[llr_mem_w_addr_tb][(3-0)*8 + 7 : (3-0)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end
        else if (mem_llr_slct_tb == 1) begin
            llr_2_ram[llr_mem_w_addr_tb][(3-1)*8 + 7 : (3-1)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end 
        else if (mem_llr_slct_tb == 2) begin
            llr_2_ram[llr_mem_w_addr_tb][(3-2)*8 + 7 : (3-2)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end
        else if (mem_llr_slct_tb == 3) begin
            llr_2_ram[llr_mem_w_addr_tb][(3-3)*8 + 7 : (3-3)*8] = llrs_tb; //31:24, 23:16, 15:8, 7:0
        end
    end
    
end


endmodule

//add wave -position insertpoint  \
//sim:/est_top_tb/DUT/u0_ch_avg/i_ch_avged \
//sim:/est_top_tb/DUT/u0_ch_avg/q_ch_avged \
//sim:/est_top_tb/DUT/u0_ch_avg/out_vld \
//sim:/est_top_tb/DUT/u0_ch_avg/i_ram_dout \
//sim:/est_top_tb/DUT/u0_ch_avg/q_ram_dout \
//sim:/est_top_tb/DUT/u0_ch_avg/sp_in_vld \
//sim:/est_top_tb/DUT/u0_ch_avg/clk \
//sim:/est_top_tb/DUT/u0_ctrl/avg_done \
//sim:/est_top_tb/AVG_test_i \
//sim:/est_top_tb/AVG_test_i