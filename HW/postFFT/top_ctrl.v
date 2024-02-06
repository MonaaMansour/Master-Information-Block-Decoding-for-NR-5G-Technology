module top_ctrl (
    output reg                                       ncellid_ready_pulse,
    output reg         [1                    :0]     issb_r,
    output reg         [9                    :0]     ncellid_r,          
    output reg                                       n_hf_r,
    output reg                                       symbol_num_vld,
    output reg                                       pbch_indices_valid,
    input  wire                                      est_strt,
    input  wire                                      ch_avg_done,
    input  wire                                      equalization_done,
    input  wire        [1                    :0]     issb,
    input  wire        [9                    :0]     ncellid,  
    input  wire                                      n_hf,
    input  wire                                      clk,
    input  wire                                      rst
);


reg [1:0] current_state;
reg [1:0] next_state;
reg       symbol_num_vld_nx, pbch_indices_valid_nx, ncellid_ready_pulse_nx;

localparam  IDLE            = 2'b00, 
            ESTIMATION      = 2'b01,
            EQUALIZATION    = 2'b10;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state      <= IDLE;
        symbol_num_vld     <= 'd0;
        pbch_indices_valid <= 'd0;
        issb_r             <= 'd0;
        ncellid_r          <= 'd0;
        n_hf_r             <= 'd0; 
        ncellid_ready_pulse<= 'd0;
    end
    else begin
        current_state      <= next_state;
        symbol_num_vld     <= symbol_num_vld_nx;
        pbch_indices_valid <= pbch_indices_valid_nx;
        ncellid_ready_pulse<= ncellid_ready_pulse_nx;
        if (est_strt) begin
            issb_r         <= issb ;
            ncellid_r      <= ncellid;
            n_hf_r         <= n_hf;
        end
    end
end

always @(*) begin
    //counter = counter_r;
    case (current_state)
        IDLE    :   begin
                        if (est_strt) begin
                            next_state = ESTIMATION;
                        end
                        else begin
                            next_state = IDLE;
                        end 
        end 

        ESTIMATION   :   begin
                        if (ch_avg_done) begin
                            next_state = EQUALIZATION;
                        end
                        else begin
                            next_state = ESTIMATION;
                        end 
        end

        EQUALIZATION   :   begin
                        if (equalization_done) begin
                            next_state = IDLE;
                        end else begin
                            next_state = EQUALIZATION;
                        end 
        end

        default :   next_state = IDLE;
    endcase
end

always @(*) begin
    pbch_indices_valid_nx = pbch_indices_valid;
    ncellid_ready_pulse_nx = ncellid_ready_pulse;
    case (current_state)
        IDLE   :    begin
                    ncellid_ready_pulse_nx    = 1'b0;
                    symbol_num_vld_nx      = 1'b0;
                    pbch_indices_valid_nx  = 1'b0;
                    if (est_strt) begin
                        ncellid_ready_pulse_nx  = 1'b1;
                    end
        end
        ESTIMATION  :    begin  
                    ncellid_ready_pulse_nx    = 1'b0;
                    symbol_num_vld_nx         = 1'b0;
                    pbch_indices_valid_nx     = 1'b0;
                    if (ch_avg_done) begin
                        symbol_num_vld_nx     = 1'b1;
                        pbch_indices_valid_nx = 1'b1;
                    end      
        end

        EQUALIZATION  :    begin  
                    ncellid_ready_pulse_nx = 1'b0;
                    symbol_num_vld_nx      = 1'b0;
                    pbch_indices_valid_nx  = pbch_indices_valid+1'b1;
        end

        default:    begin
                    ncellid_ready_pulse_nx = 1'b0;
                    symbol_num_vld_nx      = 1'b0;
                    pbch_indices_valid_nx  = 1'b0;
        end
    endcase
end


endmodule