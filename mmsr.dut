module mmsr(clk,rst,sel,load,si,pi,so,po);
  input clk,rst;
  input load,si;
  input [1:0]sel;
  input [3:0]pi;
  output reg so;
  output reg [3:0]po;
  reg [3:0]mem;
  
  always@(posedge clk or negedge rst)
    begin
      if(!rst)
        mem<=0;
      else
        case(sel)
          2'b00: begin   //SISO - right shift
            mem<={si,mem[3:1]};
            so<=mem[0];
          end
          2'b01: begin   //SIPO - right shift
            mem<={si,mem[3:1]};
            po<=mem;
          end
          2'b10: begin   //PIPO
            mem<=pi;
            po<=mem;
          end
          2'b11: begin   //PISO - right shift
            if(load)
              mem<=pi;
            else begin
              mem<=mem>>1;
              so<=mem[0];
            end
          end
          default: mem<=0;
        endcase
    end
endmodule
