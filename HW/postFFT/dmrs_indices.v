module dmrs_indices (
    output  wire    [9:0]                    current_index,
    output  wire                             out_valid,
    input   wire    [9:0]                    ncellid,          
    input   wire                             symbol_number_valid, // PULSE
    input   wire    [1:0]                    symbol_number, // 4 values 
    input   wire                             clk,
    input   wire                             rst
);

reg [7:0] counter , counter_r ;
reg out_valid_nx,out_valid_r;
reg [1:0] offset;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter_r     <= 'd0 ;
        out_valid_r   <= 'd0 ;
    end else begin
        counter_r     <= counter ;
        out_valid_r   <= out_valid_nx;
    end
end

always @(*) begin
    counter          = counter_r ;
    out_valid_nx     = out_valid_r;
    if (symbol_number_valid) begin
        if (symbol_number != 'd2) begin
            counter      = ncellid[1:0] + 'd8;
            out_valid_nx = 1'b1 ;
        end else begin
            counter = counter_r + 'd148 ;
            out_valid_nx = 1'b1 ;
        end
    end else begin
        if ( (counter_r < 'd244) && (counter_r >= 'd8)) begin
            if  (symbol_number == 'd1 || symbol_number == 'd2 ) begin
                if ( (counter_r <= 'd51)  ||  (counter_r >= 'd196) ) begin
                    counter = counter_r + 3'd4 ;
                end else begin
                    out_valid_nx = 1'b0 ;
                end
                
            end else begin
                counter = counter_r + 3'd4 ;
            end
        end else begin
            counter = 'd0 ;
            out_valid_nx = 1'b0 ;
        end
    end


    case (symbol_number)
       'b00 : offset = 'd0;
       'b01 : offset = 'd1;
       'b10 : offset = 'd1;
       'b11 : offset = 'd2;
        default: offset = 'd0;
    endcase

end




assign current_index = out_valid_r? counter_r + offset*256 : 'd0 ;
assign out_valid     = out_valid_r;


endmodule


//force -freeze sim:/dmrs_indices/ncellid 'd11 100
//force -freeze sim:/dmrs_indices/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/dmrs_indices/rst 1 0
//force -freeze sim:/dmrs_indices/rst 0 10
//force -freeze sim:/dmrs_indices/rst 1 20
//force -freeze sim:/dmrs_indices/symbol_number_valid 0 0
//force -freeze sim:/dmrs_indices/symbol_number 'd2 200
//force -freeze sim:/dmrs_indices/symbol_number_valid 1 200
//force -freeze sim:/dmrs_indices/symbol_number_valid 0 300
