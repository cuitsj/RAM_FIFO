`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/19 17:43:24
// Design Name: 
// Module Name: fifo_ip_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_ip_tb;

// fifo Parameters
parameter PERIOD    = 40     ;
parameter WD_WIDTH  = 4     ;
parameter WA_DEPTH  = 32   ;
parameter RD_WIDTH  = 16     ;
parameter RD_DELAY  = 0      ;
parameter RAM_TYPE  = "block";

// fifo Inputs
reg   rst                                = 1 ;
reg   wr_clk                               = 0 ;
reg   wr_en                                = 0 ;
reg   [WD_WIDTH-1:0]  din                  = 0 ;
reg   rd_clk                               = 0 ;
reg   rd_en                                = 0 ;

// fifo Outputs
wire  full                                 ;
wire  [RD_WIDTH-1:0]  dout                 ;
wire  empty                                ;

always #(PERIOD/2/4) wr_clk = ~wr_clk ;
always #(PERIOD/2-1) rd_clk = ~rd_clk ;

initial
begin
    #(PERIOD*2) rst  =  0;
end

fifo_ip  u_fifo_ip (
    .rst                   ( rst                  ),
    .wr_clk                  ( wr_clk                 ),
    .wr_en                   ( wr_en                  ),
    .din                     ( din     [WD_WIDTH-1:0] ),
    .rd_clk                  ( rd_clk                 ),
    .rd_en                   ( rd_en                  ),

    .full                    ( full                   ),
    .dout                    ( dout    [RD_WIDTH-1:0] ),
    .empty                   ( empty                  )
);

initial
    begin
          din = 0 ;
        wait (!rst) ;
        //(1) test full and empty signal
        rd_en=0;
        repeat(32) begin
        @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din = din+1;
        end
        @(negedge wr_clk) wr_en = 1'b0 ;
        
        //(2) test read data
        #500 ;
        rd_en=1;
        repeat(20) begin
         @(negedge rd_clk) ;
//         wr_en = 1'b1 ;
//         din    = {$random()} % 16;
        end

        //(3) test data read and write
        #500 ;
        rst = 1 ;
        #10 rst = 0 ;
        rd_en=1;
        repeat(100) begin
         @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din    = {$random()} % 16;
        end
        
        //(4) stop read, and test empty and full signal one more time
        repeat(18) begin
         @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din    = {$random()} % 16;
        end
        
        $stop;
end

endmodule
