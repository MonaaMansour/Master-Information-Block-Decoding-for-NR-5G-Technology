module flip_flop (
    output  reg     reg_out,
    input   wire    reg_in ,
    input   wire    clk,
    input   wire    rst
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        reg_out <= 'd0 ;
    end else begin
        reg_out <= reg_in ;
    end
end
    
endmodule