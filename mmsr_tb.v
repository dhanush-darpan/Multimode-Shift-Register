module usr_tb;
  reg clk,rst;
  reg load,si;
  reg [1:0]sel;
  reg [3:0]pi;
  wire so;
  wire [3:0]po;
  
  mmsr dut(clk,rst,sel,load,si,pi,so,po);
  
  initial begin
    clk=0;
    rst=0;
    load=0;
    si=0;
    pi=4'b0000;
    #5 rst=1;sel=2'b00;
    #10 si=1;
    #10 si=0;
    #10 si=1;
    #10 si=0;
    #10 si=1;
    #10 si=1;sel=2'b01;
    #20 si=1;
    #10 si=1;
    #10 si=0;
    #20 pi=4'b1000;sel=2'b10;
    #10 pi=4'b0100;
    #10 pi=4'b0010;
    #10 pi=4'b0001;
    #20 load=1;pi=4'b1000;sel=2'b11;
    #10 load=0;
    #40 load=1;pi=4'b0100;
    #10 load=0;
    #40 load=1;pi=4'b0010;
    #10 load=0;
    #40 load=1;pi=4'b0001;
    #50 $finish;
  end
  
  always #5 clk=~clk;
  
  initial begin
    $monitor("sim time=%0t | sel=%b, load=%b, si=%b, pi=%b, so=%b, po=%b", $time, sel, load, si, pi, so, po);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,usr_tb);
   end
endmodule
