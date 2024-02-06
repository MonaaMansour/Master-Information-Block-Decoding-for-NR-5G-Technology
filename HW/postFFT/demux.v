module demux #(parameter ADDR_WIDTH = 16) (
    output reg  [ADDR_WIDTH -1 :0] out1,
    output reg  [ADDR_WIDTH -1 :0] out2,
    input  wire [ADDR_WIDTH -1 :0] in,
    input  wire                    sel
);


always @(*) begin
    out1 = 'd0;
    out2 = 'd0;
    if (sel) begin
        out1 = in;
    end
    else begin
        out2 = in;
    end
end
endmodule