module pbch_indices (
    output  wire    [9:0]                    current_index_fft,
    output  wire    [9:0]                    current_index_ch_avg,
    output  wire                             out_valid,
    input   wire    [9:0]                    ncellid,          
    input   wire                             symbol_number_valid, // PULSE
    input   wire                             pbch_indices_valid,
    input   wire                             clk,
    input   wire                             rst
);

reg [7:0] counter1 , counter1_r ;
reg [1:0] counter2 , counter2_r ;
reg [1:0] symbol_number,symbol_number_r;
reg out_valid_nx, out_valid_r;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter1_r     <= 'd0 ;
        counter2_r     <= 'd0 ;
        out_valid_r    <= 'd0 ;
        symbol_number_r<= 'd0 ;
    end else begin
        counter1_r     <= counter1 ;   
        counter2_r     <= counter2 ;  
        out_valid_r    <= out_valid_nx;
        symbol_number_r<= symbol_number;
    end
end

always @(*) begin
    counter1          = counter1_r ;
    out_valid_nx      = out_valid_r ;
    symbol_number     = symbol_number_r;
    if(pbch_indices_valid)
    begin
        case ( {symbol_number_valid, ncellid[1:0] =='d0} )

        2'b00: begin
            if ( ( counter1_r >='d8 ) && ( counter1_r <= 'd245 + !ncellid[1] ) ) begin
                out_valid_nx='d1;
                if ( (symbol_number_r == 'd1) && ~( (counter1_r <= 'd53 + ^ncellid[1:0])  ||  (counter1_r >= 'd198 + ^ncellid[1:0]) ) ) begin
                    counter1 = counter1_r + 'd145+ ~^ncellid[1:0];
                end else begin
                    if ( counter2_r == ncellid[1:0]-1'b1 ) begin
                        counter1 = counter1_r + 'd2;
                    end else begin
                        counter1 = counter1_r + 'd1;
                    end
                end
            end else begin
                if (counter1_r <'d8 || symbol_number_r == 'd2) begin
                    counter1 = 'd0 ;
                    out_valid_nx='d0;
                end else begin
                  counter1 = 'd8;
                  out_valid_nx='d1;
                  symbol_number=symbol_number_r+'d1;
                end
                
            end
        end

        2'b01: begin
            if ( (counter1_r >='d8) && (counter1_r <='d246) ) begin
                out_valid_nx='d1;
                if ( (symbol_number_r == 'd1) && ~( (counter1_r <= 'd54)  ||  (counter1_r >= 'd199) ) ) begin
                    counter1 = counter1_r + 'd146;
                end else begin
                    if ( counter2_r == 'd2 ) begin
                        counter1 = counter1_r + 'd2;
                    end else begin
                        counter1 = counter1_r + 'd1;
                    end
                end
            end else begin
                if (counter1_r <'d8 || symbol_number_r=='d2) begin
                    counter1 = 'd0 ;
                    out_valid_nx='d0;
                end else begin
                  counter1 = 'd9;
                  out_valid_nx='d1;
                  symbol_number=symbol_number_r+'d1;
                end
            end
        end     

        2'b10: begin
            counter1 = 'd8;
            out_valid_nx = 1'b1;
            symbol_number='d0;
            //counter2 = counter2_r + 'd1;
        end 

        2'b11: begin
            counter1 ='d9;
            out_valid_nx = 1'b1;
            symbol_number='d0;
            //counter2 = counter2_r + 'd1;
        end 

        endcase
    end else begin
      out_valid_nx = 1'b0;
    end
end

always @(*) begin
    counter2 = counter2_r ;
    if(pbch_indices_valid)
    begin
        if ( counter1_r >='d8 && counter1_r <'d246 )begin
            if (counter2_r<=1) begin
                counter2 =counter2_r +1'd1 ;
            end else begin
                counter2 = 'd0 ;
            end   
        end else begin
          counter2 = 'd0 ;
        end
    end
end


assign current_index_fft = (counter1_r == 'd0) ? 'd0 : (counter1_r+symbol_number_r*256) ;
assign current_index_ch_avg = (counter1_r<8 )? counter1_r : counter1_r+'d568;
assign out_valid    = out_valid_r;

    
endmodule



//force -freeze sim:/pbch_indices/symbol_number_valid 0 0
//force -freeze sim:/pbch_indices/symbol_number_valid 1 200
//force -freeze sim:/pbch_indices/symbol_number_valid 0 300
//noforce sim:/pbch_indices/clk
//force -freeze sim:/pbch_indices/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/pbch_indices/rst 1 0
//force -freeze sim:/pbch_indices/rst 0 20
//force -freeze sim:/pbch_indices/rst 1 40
//force -freeze sim:/pbch_indices/ncellid 'd4 0


