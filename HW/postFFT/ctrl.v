module ctrl (
    output reg  dmrs_gen_start,
    output reg  ch_avg_start,
    output wire [1:0] symbol_num,
    output reg  symbol_num_vld,
    input  wire ncellid_ready_pulse,
    input  wire mmse_done,
    input  wire dmrs_gen_done,
    input  wire avg_done,
    input  wire clk,
    input  wire rst
);


reg [1:0] current_state;
reg [1:0] next_state;
reg [1:0] counter,counter_r;
reg       symbol_num_vld_nx;

localparam  IDLE            = 2'b00, 
            DMRS_GEN        = 2'b01,
            PROCESS         = 2'b11,
            AVG             = 2'b10;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state <= IDLE;
        counter_r     <= 'd0;
        symbol_num_vld <= 'd0;
    end
    else begin
        current_state <= next_state;
        counter_r     <= counter;
        symbol_num_vld <= symbol_num_vld_nx;
    end
end

always @(*) begin
    //counter = counter_r;
    case (current_state)
        IDLE    :   begin
                        if (ncellid_ready_pulse) begin
                            next_state = DMRS_GEN;
                        end
                        else begin
                            next_state = IDLE;
                        end 
        end 

        DMRS_GEN   :   begin
                        if (dmrs_gen_done) begin
                            next_state = PROCESS;
                        end
                        else begin
                            next_state = DMRS_GEN;
                        end 
        end

        PROCESS   :   begin
                        if (mmse_done) begin
                            if (counter_r == 3) begin
                                next_state = AVG;
                            end
                            else begin
                                next_state = PROCESS;
                            end
                        end
                        else begin
                            next_state = PROCESS;
                        end 
        end


        AVG   :   begin
                        if (avg_done) begin
                            next_state = IDLE;
                            
                        end
                        else next_state = AVG;
        end

        default :   next_state = IDLE;
    endcase
end

always @(*) begin
    counter = counter_r;
    symbol_num_vld_nx = symbol_num_vld;
    case (current_state)
        IDLE   :    begin
                    dmrs_gen_start      = 1'b0;
                    ch_avg_start        = 1'b0;
                    symbol_num_vld_nx      = 1'b0;
                    if (ncellid_ready_pulse) begin
                        dmrs_gen_start  = 1'b1;
                    end
        end
        DMRS_GEN  :    begin  
                    dmrs_gen_start      = 1'b0;
                    ch_avg_start        = 1'b0;
                    symbol_num_vld_nx      = 1'b0;
                    if (dmrs_gen_done) begin
                        symbol_num_vld_nx      = 1'b1;
                    end
        end

        PROCESS  :    begin  
                    dmrs_gen_start      = 1'b0;
                    ch_avg_start        = 1'b0;
                    symbol_num_vld_nx   = 1'b0;
                    if (mmse_done) begin      
                        if (counter_r == 3) begin
                            ch_avg_start    = 1'b1;
                            counter         ='d0;
                        end
                        else begin
                        counter         = counter_r +'d1;
                        symbol_num_vld_nx      = 1'b1;
                        end
                    end
        end

        AVG  :    begin  
                    dmrs_gen_start      = 1'b0;
                    ch_avg_start        = 1'b1;
                    symbol_num_vld_nx   = 1'b0;
                    if (avg_done) begin
                        ch_avg_start    = 1'b0;
                    end
        end

        default:    begin
                    dmrs_gen_start      = 1'b0;
                    ch_avg_start        = 1'b0;
                    symbol_num_vld_nx   = 1'b0;
        end
    endcase
end

assign symbol_num = counter_r ;

endmodule