module SerialToParallel_1 #(parameter P_WIDTH = 2) (
    output  reg     [P_WIDTH-1 : 0] parallel_reg,
    output  reg                     out_valid_reg,
    input   wire                    serial,
    input   wire                    in_valid,
    input   wire                    clk,
    input   wire                    rst
);

localparam COUNTER_WIDTH = $clog2(P_WIDTH);



reg     [COUNTER_WIDTH-1 : 0]   Counter_reg;
reg     [COUNTER_WIDTH-1 : 0]   Counter;
reg     [P_WIDTH-1       : 0]   parallel;
wire                            out_valid;

always @(posedge clk or negedge rst)
  begin

      if (!rst) begin
          parallel_reg <= 'd0;
          Counter_reg  <= 'd0;
      end
      else begin
          parallel_reg <= parallel;
          Counter_reg  <= Counter;
      end

  end
  
always @(*) begin

    parallel = parallel_reg;
    Counter  = Counter_reg;
    
    if (in_valid) begin
          parallel[Counter] = serial;
          Counter           = Counter + 1'd1;
    end

end


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        out_valid_reg <= 'd0;
    end
    else begin
        out_valid_reg <= out_valid;
    end
end  

assign out_valid = (Counter_reg == {COUNTER_WIDTH{1'b1}} );

endmodule