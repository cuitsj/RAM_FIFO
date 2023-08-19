`timescale  1ns / 1ns

module fifo_tb;      

// fifo Parameters
parameter PERIOD    = 10                        ;
parameter WD_WIDTH  = 8                         ;
parameter WA_DEPTH  = 16                      ;
parameter RD_WIDTH  = 4                       ;
parameter SYNC      = 1                         ;
parameter RD_DELAY  = 0                         ;
parameter RAM_TYPE  = "block"                   ;
parameter RA_DEPTH  = WD_WIDTH*WA_DEPTH/RD_WIDTH;
parameter RA_WIDTH  = $clog2(RA_DEPTH)           ;
parameter WA_WIDTH  = $clog2(WA_DEPTH)          ;

// fifo Inputs
reg   rst                                  = 1 ; 
reg   wr_clk                               = 0 ; 
reg   wr_en                                = 0 ; 
reg   [WD_WIDTH-1:0]  din                  = 0 ; 
reg   rd_clk                               = 0 ; 
reg   rd_en                                = 0 ; 

// fifo Outputs
wire  full                                 ;     
wire  [WA_WIDTH:0]  wclk_cnt               ;     
wire  [RD_WIDTH-1:0]  dout                 ;     
wire  empty                                ;     
wire  [RA_WIDTH:0]  rclk_cnt               ;

always #(PERIOD/2/4) wr_clk = ~wr_clk ;
always #(PERIOD/2-1) rd_clk = ~rd_clk ;

initial
begin
    #(PERIOD*2) rst  =  0;
end

fifo #(
    .WD_WIDTH ( WD_WIDTH ),
    .WA_DEPTH ( WA_DEPTH ),
    .RD_WIDTH ( RD_WIDTH ),
    .SYNC     ( SYNC     ),
    .RD_DELAY ( RD_DELAY ),
    .RAM_TYPE ( RAM_TYPE ),
    .RA_DEPTH ( RA_DEPTH ),
    .RA_WIDTH ( RA_WIDTH ),
    .WA_WIDTH ( WA_WIDTH ))
 u_fifo (
    .rst                     ( rst                      ),
    .wr_clk                  ( wr_clk                   ),
    .wr_en                   ( wr_en                    ),
    .din                     ( din       [WD_WIDTH-1:0] ),
    .rd_clk                  ( wr_clk                   ),
    .rd_en                   ( rd_en                    ),

    .full                    ( full                     ),
    .wclk_cnt                ( wclk_cnt  [WA_WIDTH:0]   ),
    .dout                    ( dout      [RD_WIDTH-1:0] ),
    .empty                   ( empty                    ),
    .rclk_cnt                ( rclk_cnt  [RA_WIDTH:0]   )
);

initial
begin
        din = 0 ;
        wait (!rst) ;
        //(1) test full and empty signal
        rd_en=0;
        repeat(16) begin
        @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din = din+1;
        end
        @(negedge wr_clk) wr_en = 1'b0 ;
        
        //(2) test read data
        #(PERIOD*5) 
        rd_en=1;
        repeat(32) begin
         @(negedge rd_clk) ;
//         wr_en = 1'b1 ;
//         din    = {$random()} % 16;
        end

        //(3) test data read and write
        #(PERIOD*5) 
        rst = 1 ;
        #(PERIOD*3)  rst = 0 ;
        rd_en=1;
        repeat(100) begin
         @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din    = {$random()} % 16;
        end
        
        //(4) stop read, and test empty and full signal one more time
        repeat(16) begin
         @(negedge wr_clk) ;
         wr_en = 1'b1 ;
         din    = {$random()} % 16;
        end
        
        $stop;
end

endmodule
