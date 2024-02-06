module SerialToParallel #(parameter PARALLEL_NUM = 3, SERIAL_WIDTH = 16*2) (
    output  reg           [PARALLEL_NUM*SERIAL_WIDTH -1 : 0]    parallel_reg, // concatenate serial inputs
    output  reg                                                 out_valid_reg,
    input   wire  signed  [SERIAL_WIDTH              -1 : 0]    serial,
    input   wire                                                in_valid,
    input   wire          [1                            : 0]    parallel_mode,
    input   wire                                                clk,
    input   wire                                                rst
);

localparam COUNTER_WIDTH = $clog2(PARALLEL_NUM+1);



reg         [COUNTER_WIDTH             -1 : 0]   counter_reg;
reg         [COUNTER_WIDTH             -1 : 0]   counter;
reg signed  [PARALLEL_NUM*SERIAL_WIDTH -1 : 0]   parallel;
reg                                              out_valid;

always @(posedge clk or negedge rst)
  begin

      if (!rst) begin
          parallel_reg  <= 'd0;
          counter_reg   <= 'd0;
          out_valid_reg <= 'd0;
      end
      else begin
          parallel_reg  <= parallel;
          counter_reg   <= counter;
          out_valid_reg <= out_valid;   
      end

  end
  
always @(*) begin

    parallel  = parallel_reg;
    counter   = counter_reg;
    out_valid = 1'b0;
    if (in_valid) begin
        parallel                                                              = parallel >> (SERIAL_WIDTH);
        parallel[SERIAL_WIDTH*PARALLEL_NUM-1 : SERIAL_WIDTH*(PARALLEL_NUM-1)] = serial;
        counter                                                               = counter_reg + 1'd1;
        out_valid                                                             = (counter_reg == parallel_mode -1);
        if (counter_reg == parallel_mode -1 ) begin
            counter = 'd0;
        end
    end

end

endmodule

