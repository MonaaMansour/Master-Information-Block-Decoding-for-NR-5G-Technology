module mux #(parameter ADDR_WIDTH = 16) (
    output reg  [ADDR_WIDTH -1 :0] out,
    input  wire [ADDR_WIDTH -1 :0] a,
    input  wire [ADDR_WIDTH -1 :0] b,
    input  wire                    sel
);


always @(*) begin
    if (sel) begin
        out = a;
    end
    else begin
        out = b;
    end
end
endmodule