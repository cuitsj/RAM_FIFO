`timescale  1ns / 1ns

module sdp_ram_tb;

// sdp_ram Parameters
parameter PERIOD    = 10                        ;
parameter WD_WIDTH  = 4                         ;
parameter WA_DEPTH  = 32                        ;
parameter RD_WIDTH  = 8                         ;
parameter DELAY     = 0                         ;
parameter TYPE      = "block"                   ;
parameter WA_WIDTH  = $clog2(WA_DEPTH)           ;
parameter RA_DEPTH  = WD_WIDTH*WA_DEPTH/RD_WIDTH;
parameter RA_WIDTH  = $clog2(RA_DEPTH)           ;

// sdp_ram Inputs
reg   clk                               = 0 ;
reg   wr_en                                = 0 ;
reg   [WA_WIDTH-1:0]  waddr                = 0 ;
reg   [WD_WIDTH-1:0]  din                  = 0 ;
reg   rd_en                                = 0 ;
reg   [RA_WIDTH-1:0]  raddr                = 0 ;

// sdp_ram Outputs
wire  [RD_WIDTH-1:0]  dout                 ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

sdp_ram #(
    .WD_WIDTH ( WD_WIDTH ),
    .WA_DEPTH ( WA_DEPTH ),
    .RD_WIDTH ( RD_WIDTH ),
    .DELAY    ( DELAY    ),
    .TYPE     ( TYPE     ),
    .WA_WIDTH ( WA_WIDTH ),
    .RA_DEPTH ( RA_DEPTH ),
    .RA_WIDTH ( RA_WIDTH ))
 u_sdp_ram (
    .wr_clk                  ( clk                 ),
    .wr_en                   ( wr_en                  ),
    .waddr                   ( waddr   [WA_WIDTH-1:0] ),
    .din                     ( din     [WD_WIDTH-1:0] ),
    .rd_clk                  ( clk                 ),
    .rd_en                   ( rd_en                  ),
    .raddr                   ( raddr   [RA_WIDTH-1:0] ),

    .dout                    ( dout    [RD_WIDTH-1:0] )
);

initial begin    
  #(PERIOD)
          wr_en=1;
          din=0;
            #(PERIOD)
        repeat(32) begin
            @(negedge clk) ;
             waddr =waddr+1;
                 din=din+1;
            end
            din=0;

          #(PERIOD*5)
                rd_en=1;
                raddr = 0;
                  #(PERIOD)
               repeat(16) begin
                         @(negedge clk) ;
                          raddr =raddr+1;
                           din=0;
                         end
    $stop;
end

endmodule
