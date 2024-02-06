module counter #(parameter ADDR_WIDTH = 16, FINAL_COUNT= 'd575, INITIAL_COUNT = 'd0) (
    output reg  [ADDR_WIDTH -1 :0] counter_r,
    input  wire                    count,
    input  wire                    clk,
    input  wire                    rst
);

reg [ADDR_WIDTH -1 :0] counter;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter_r <= INITIAL_COUNT;
    end
    else begin
        counter_r <= counter;
    end
end

always @(*) begin
    counter = counter_r;
    if (count) begin
        counter = counter_r + 1'b1;
        if (counter_r == FINAL_COUNT) begin
            counter = INITIAL_COUNT;
        end
    end
    
end

endmodule