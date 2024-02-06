module Buffer#(parameter FP = 10)  
            (  output reg  signed  [FP/2-1:0] bf_out_i, 
               output reg  signed  [FP/2-1:0] bf_out_q,  
			         input  wire                    clk, 
               input  wire                    rst, 
               input  wire                    pop, 
               input  wire                    push, 
               input  wire signed  [FP/2-1:0] bf_in_i,
               input  wire signed  [FP/2-1:0] bf_in_q
               );
  
  reg signed [FP/2-1:0] bf_i [0:143];
  reg signed [FP/2-1:0] bf_q [0:143];
  
  reg [7:0] add_wr;
  reg [7:0] add_rd;
  reg [7:0] em_pl;
  reg [7:0] add_wr_nx;
  reg [7:0] add_rd_nx;
  reg [7:0] em_pl_nx;
  wire [FP/2-1:0] bf_out_i_intern, bf_out_q_intern ;
  integer i;
  
  assign bf_out_i_intern = bf_i[add_rd];
  assign bf_out_q_intern = bf_q[add_rd];
  
always @(posedge clk or negedge rst) begin
  if (!rst) begin
    bf_out_i <= 'd0 ;
    bf_out_q <= 'd0 ;
  end else begin
    bf_out_i <= bf_out_i_intern;
    bf_out_q <= bf_out_q_intern;
  end
end

  always @(posedge clk or negedge rst)
  begin
    if(!rst)
    begin
      for (i =0 ;i<144 ;i=i+1 ) begin
          bf_i[i] <= 'd0;
          bf_q[i] <= 'd0;
      end
      em_pl  <= 'd144;
      add_wr <= 'd0;
      add_rd <= 'd0;
    end
    else
    begin
      em_pl <=em_pl_nx ;
      add_wr<= add_wr_nx ;
      add_rd<= add_rd_nx ;
      if(push == 1 && pop == 0 && em_pl > 'd0)
      begin
        bf_i[add_wr] <= bf_in_i;
        bf_q[add_wr] <= bf_in_q;
      end 
      else if(push == 1 && pop == 1)
      begin
        if(em_pl == 'd144)
        begin
          bf_i[add_wr] <= bf_in_i;
          bf_q[add_wr] <= bf_in_q;
        end
        else
        begin
          bf_i[add_wr] <= bf_in_i;
          bf_q[add_wr] <= bf_in_q;
        end
      end
    end
    
  end
  

always @(*) begin
  add_wr_nx = add_wr ;
  add_rd_nx = add_rd ;
  em_pl_nx  = em_pl ;
  if(push == 1'd1 && pop == 0 && em_pl > 'd0)
      begin
        em_pl_nx  = em_pl - 'd1;
        if (add_wr == 'd143) begin
          add_wr_nx = 'd0 ;
        end else begin
          add_wr_nx = add_wr + 'd1;
        end
      end
  else if(push == 1'd0 && pop == 1'd1 && em_pl < 'd144)
      begin
        em_pl_nx     = em_pl + 'd1;
        if (add_rd == 'd143) begin
          add_rd_nx = 'd0 ;
        end else begin
          add_rd_nx = add_rd + 'd1;
        end
      end
  else if(push == 1'd1 && pop == 1'd1)
      begin
        if(em_pl == 'd144)
        begin
          add_wr_nx = add_wr + 1'd1;
          em_pl_nx  = em_pl - 1'd1;
        end
        else
        begin
          add_wr_nx = add_wr + 1'd1;
          add_rd_nx = add_rd + 1'd1;
        end
      end
end

endmodule

//force -freeze sim:/Buffer/clk 1 0, 0 {50 ps} -r 100
//force -freeze sim:/Buffer/rst 1 0
//force -freeze sim:/Buffer/rst 0 10
//force -freeze sim:/Buffer/rst 1 20
//force -freeze sim:/Buffer/bf_in_i 11 0
//force -freeze sim:/Buffer/bf_in_q 11 0
//force -freeze sim:/Buffer/push 0 0
//force -freeze sim:/Buffer/pop 0 0
//force -freeze sim:/Buffer/push 1 300
//force -freeze sim:/Buffer/push 0 400
//force -freeze sim:/Buffer/pop 1 700
//force -freeze sim:/Buffer/pop 1 800
//force -freeze sim:/Buffer/pop 0 900