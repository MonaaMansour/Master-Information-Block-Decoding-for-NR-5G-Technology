module QPSK #(parameter FP = 16) (
    output reg  signed  [FP/2-1 :0]     qpsk_i,
    output reg  signed  [FP/2-1 :0]     qpsk_q,
    output reg                          out_valid,
    input  wire         [1:0]           in,
    input  wire                         in_valid,
    input  wire                         clk,
    input  wire                         rst
);

localparam PowerFactor = 7'b1011011;  // 1/sqrt(2)



always @(posedge clk or negedge rst) begin
    if (!rst) begin
        qpsk_i      <= 'd0;
        qpsk_q      <= 'd0;
        out_valid   <=   0; 
    end
    else begin
        out_valid   <= in_valid;
        if (in_valid) begin
            qpsk_i      <= PowerFactor * (2'd1 - {in[0],1'b0} );
            qpsk_q      <= PowerFactor * (2'd1 - {in[1],1'b0} );
        end
    end
end


    

endmodule