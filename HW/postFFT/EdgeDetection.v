module EdgeDetection (
    output  reg     Level_signal,
    input   wire    Pulse_signal,
    input   wire    clk,
    input   wire    rst
);
    

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        Level_signal <= 'd0;
    end
    else if (Pulse_signal)
    begin
        Level_signal <= 1;
    end
    else begin
        Level_signal <= Level_signal;
    end
end

endmodule