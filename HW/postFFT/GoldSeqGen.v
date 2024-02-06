module GoldSeqGen #(parameter   Mpn  = 'd288, 
                                Type = 'd0) (                        //TYPE = 1 (SCRAMBLER) , TYPE = 0 (DMRS)
    output  reg                              C,
    output  reg                              out_valid,        // Output is ready , SerialToParallel start working. when = 0 goldseq finished        
    output  wire                             goldseq_done,
    input   wire    [1:0]                    issb,
    input   wire    [9:0]                    ncellid,          
    input   wire                             n_hf,
    input   wire                             ncellid_Ready_Pulse,    // PULSE
    input   wire                             gen_flag,
    input   wire                             clk,
    input   wire                             rst
);
localparam  Nc  = 'd1600;



wire X1;
wire X2;
wire XOR;
wire Count;
wire gen;



wire [30:0]  X1_init;
reg  [30:0]  X2_init;
wire [2 :0]  issb_bar;
reg  [12:0]  counter;
reg         ncellid_Ready_Level;       // When ncellid_Ready_Pulse has a pulse , ncellid_Read_Level always 1 (Edge Detection)
reg          SEED_Ready_Pulse;
          



//Calculata SEED of LFSR2 When Ncellid is ready (One time)
generate
    if (Type == 'd0) begin
        always @(*) begin
            X2_init  = {(issb_bar + 'd1),11'd0} * (ncellid[9:2] + 'd1) + {(issb_bar + 'd1),6'd0} + ncellid[1:0];
        end
    end
    else begin
        always @(*) begin
            X2_init = ncellid;
        end
    end
endgenerate

//Enable XORing at time n+1600 
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        C <= 'd0;
    end
    else if (gen) begin
        C<=XOR;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 'd0;
    end
    else if (goldseq_done)
    begin
        counter <= 'd0;
    end else if (Count  || (gen && Type =='d1))begin
        counter <= counter + 'd1;
    end
end

// SEED is ready after ncellid is ready by one clock cycle 
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        SEED_Ready_Pulse <= 0;
        out_valid <=0;
    end
    else begin
        SEED_Ready_Pulse <= ncellid_Ready_Pulse;
        out_valid <= gen;
    end
end


//FLAGS
assign X1_init      = 31'b0000_0000_0000_0000_0000_0000_0000_001;
assign XOR          = X1^X2;
assign gen          = ((counter > Nc ) && Count && Type =='d0) || (gen_flag && Type == 'd1);
assign Count        = ( (counter <= (Nc+Mpn) && Type == 'd0) || (counter <= (Nc+Mpn*(issb)) && Type == 'd1) ) && ncellid_Ready_Level;
assign issb_bar     = issb + {n_hf,2'b00};
assign goldseq_done = (!Count && ncellid_Ready_Level && Type=='d0) || ( (counter == Nc+Mpn*(issb+1)+1) && Type =='d1 );

////////////////////////////////INSTANTIATION/////////////////////////////////////
//EdgeDetection U0_EdgeDetection (
//    .Level_signal(ncellid_Ready_Level),
//    .Pulse_signal(ncellid_Ready_Pulse),
//    .clk(clk),
//    .rst(rst)
//);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ncellid_Ready_Level <= 'd0;
    end
    else if (ncellid_Ready_Pulse)
    begin
        ncellid_Ready_Level <= 1;
    end else if (goldseq_done) begin
        ncellid_Ready_Level <= 'd0;
    end
      
end

LFSR X1_LFSR (
    .OUT(X1),
    .SEED(X1_init),
    .SEED_Ready_Pulse(SEED_Ready_Pulse),
    .goldseq_done(goldseq_done),
    .gen(Count || gen),
    .clk(clk),
    .rst(rst)
);

LFSR #(.XOR_POS(31'b0000_0000_0000_0000_0000_0000_0001_111)) X2_LFSR  (

    .OUT(X2),
    .SEED(X2_init),
    .SEED_Ready_Pulse(SEED_Ready_Pulse),
    .goldseq_done(goldseq_done),
    .gen(Count || gen),
    .clk(clk),
    .rst(rst)
);



endmodule