module addr_gen (
    output reg [9:0] addr_r,
    output reg       out_vld_r,
    output reg       addr_done_r,
    output reg [1:0] parallel_mode_r,
    input wire       in_vld,
    input wire       clk,
    input wire       rst
);

reg  [9:0] addr;
reg  [9:0] counter_240 , counter_240_r;
reg  [9:0] temp;
reg  [1:0] counter_3   , counter_3_r;
reg  [1:0] counter_stop, counter_stop_r; // this counter to stop the averaging 1 cycle to write the value back in memory
reg        out_vld;
reg        addr_done;
wire [1:0] parallel_mode;
wire [1:0] parallel_mode_delayed;
wire [1:0] parallel_mode_temp;
wire [1:0] parallel_mode_temp2;
wire [1:0] counter_stop_delayed;
wire [1:0] counter_stop_delayed_2;
wire [1:0] counter_stop_delayed_3;
wire       forbidden_region;


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        addr_r                  <= 'd1023;
        out_vld_r               <= 'd0;
        counter_240_r           <= 'd0;
        counter_3_r             <= 'd0;
        counter_stop_r          <= 'd0;
        parallel_mode_r         <= 'd3;
        addr_done_r             <= 'd0;
        counter_stop_r          <= 'd0;

    end
    else begin
        addr_r          <= addr;
        counter_240_r   <= counter_240;
        counter_3_r     <= counter_3;
        counter_stop_r  <= counter_stop_delayed_3;
        out_vld_r       <= out_vld;
        addr_done_r     <= addr_done;
        parallel_mode_r <= parallel_mode_delayed;
    end
end


always @(*) begin
    counter_240   = counter_240_r;
    counter_3     = counter_3_r;
    counter_stop  = counter_stop_delayed;
    addr          = addr_r;
    out_vld       = 'd0;
    addr_done     = 'd0;

    if (counter_240_r[6]) begin
        temp = counter_240_r + 'd96;
    end
    else begin
        temp = counter_240_r + 'd240;
    end

    if (in_vld) begin
        if (counter_stop_r == parallel_mode_r -1 && parallel_mode_r=='d3) begin
            counter_stop = 'd2;
        end
        else if (counter_stop_delayed == parallel_mode_r+1 && parallel_mode_r=='d2)
        begin
            counter_stop = 'd0;
        end
        else begin
            counter_stop = counter_stop_delayed + 'd1;
        end

        if ( (counter_stop_r != parallel_mode_r && (counter_240_r < 'd48) && parallel_mode_r=='d3) || (counter_stop_delayed != 'd0 && (counter_240_r > 'd191) && parallel_mode_temp2=='d3) || ((counter_stop_delayed != 'd0 && counter_stop_delayed != 'd2) && parallel_mode_temp2=='d2) )begin
            if (forbidden_region) begin
                counter_3   = counter_3_r + 'd2;
            end
            else begin
                counter_3   = counter_3_r + 'd1;
            end 

            if (counter_3_r   == 'd3) begin
                counter_3   = 'd1;
            end

            if (counter_3_r   == 'd3 && counter_240_r != 'd240) begin
                counter_240 = counter_240_r + 'd1;
            end



            case (counter_3_r)
                2'b00: begin
                    addr = 10'b1111111111;
                    out_vld = 'd0;
                end
                2'b01: begin
                    addr = counter_240_r;
                    out_vld = 'd1;
                end
                2'b10: begin
                    addr = temp;
                    out_vld = 'd1;
                end 
                2'b11: begin
                    addr = counter_240_r + 'd336; 
                    out_vld = 'd1;
                end
            endcase
        end
        if (counter_240_r == 'd240 ) begin
                out_vld      = 1'b0;
                addr_done    = 1'b1;
                counter_3    = 'd0;
                counter_240  = 'd0;
                counter_stop = 'd0;
                addr         = 'd1023;
            end
    end
    else begin
      
    end
    
end

assign forbidden_region = (counter_240_r > 47 && counter_240_r < 192);
assign parallel_mode    = (counter_240_r > 47 && counter_240_r < 192) ? 'd2 : 'd3;


flip_flop u0_flip_flop (
    .reg_out(parallel_mode_delayed[0]),
    .reg_in (parallel_mode[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u1_flip_flop (
    .reg_out(parallel_mode_delayed[1]),
    .reg_in (parallel_mode[1]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u2_flip_flop (
    .reg_out(counter_stop_delayed[0]),
    .reg_in (counter_stop[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u3_flip_flop (
    .reg_out(counter_stop_delayed[1]),
    .reg_in (counter_stop[1]) ,
    .clk    (clk),
    .rst    (rst)
);



flip_flop u4_flip_flop (
    .reg_out(counter_stop_delayed_2[0]),
    .reg_in (counter_stop_delayed[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u5_flip_flop (
    .reg_out(counter_stop_delayed_2[1]),
    .reg_in (counter_stop_delayed[1]) ,
    .clk    (clk),
    .rst    (rst)
);


flip_flop u6_flip_flop (
    .reg_out(counter_stop_delayed_3[0]),
    .reg_in (counter_stop_delayed_2[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u7_flip_flop (
    .reg_out(counter_stop_delayed_3[1]),
    .reg_in (counter_stop_delayed_2[1]) ,
    .clk    (clk),
    .rst    (rst)
);



flip_flop u8_flip_flop (
    .reg_out(parallel_mode_temp[0]),
    .reg_in (parallel_mode_r[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u9_flip_flop (
    .reg_out(parallel_mode_temp[1]),
    .reg_in (parallel_mode_r[1]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u10_flip_flop (
    .reg_out(parallel_mode_temp2[0]),
    .reg_in (parallel_mode_temp[0]) ,
    .clk    (clk),
    .rst    (rst)
);

flip_flop u11_flip_flop (
    .reg_out(parallel_mode_temp2[1]),
    .reg_in (parallel_mode_temp[1]) ,
    .clk    (clk),
    .rst    (rst)
);

endmodule