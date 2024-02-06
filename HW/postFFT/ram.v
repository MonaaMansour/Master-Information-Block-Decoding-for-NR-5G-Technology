module ram #(parameter RAM_WIDTH = 32 , RAM_DEPTH = 240 , ADDR_WIDTH = 10) (
    output reg  signed [RAM_WIDTH    -1 : 0]   dout, // Real concatenated with Imag
    input  wire signed [RAM_WIDTH    -1 : 0]   din,
    input  wire        [ADDR_WIDTH   -1 : 0]   addr,
    input  wire                                wre, //WriteReadEnable , wre = 1 --> Write , wre = 0 --> Read
    input  wire                                clk,
    input  wire                                rst
);

reg signed [RAM_WIDTH-1 :0] RAM [RAM_DEPTH-1 :0];
integer i;
initial begin
    for (i = 0; i<RAM_DEPTH; i=i+1 ) begin
        RAM [i] <= 'd0;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        dout <= 'd0;
    end else begin
        if (wre) begin
            RAM[addr] <= din;   
        end
        else begin
            dout <= RAM[addr];
        end
    end
end


endmodule