`timescale  1ns / 1ns

module sp_ram_tb;

// sp_ram Parameters
parameter PERIOD         = 10                                  ;
parameter WD_WIDTH       = 4                                   ;
parameter WA_DEPTH       = 32                                 ;
parameter RD_WIDTH       =8                                   ;
parameter DELAY          = 0                                   ;
parameter MODE           = "no_change"                       ;
parameter TYPE           = "block"                             ;
parameter WA_WIDTH       = $clog2(WA_DEPTH)                     ;
parameter RA_DEPTH       = WD_WIDTH*WA_DEPTH/RD_WIDTH          ;
parameter RA_WIDTH       = $clog2(RA_DEPTH)                     ;
parameter ADDRMAX_WIDTH  = WA_WIDTH>=RA_WIDTH?WA_WIDTH:RA_WIDTH;

// sp_ram Inputs
reg   rst_n                                = 0 ;
reg   clk                                  = 0 ;
reg   en                                   = 0 ;
reg   we                                   = 0 ;
reg   [ADDRMAX_WIDTH-1:0]  addr            = 0 ;
reg   [WD_WIDTH-1:0]  din                  = 0 ;

// sp_ram Outputs
wire  [RD_WIDTH-1:0]  dout                 ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

sp_ram #(
    .WD_WIDTH      ( WD_WIDTH      ),
    .WA_DEPTH      ( WA_DEPTH      ),
    .RD_WIDTH      ( RD_WIDTH      ),
    .DELAY         ( DELAY         ),
    .MODE          ( MODE          ),
    .TYPE          ( TYPE          ),
    .WA_WIDTH      ( WA_WIDTH      ),
    .RA_DEPTH      ( RA_DEPTH      ),
    .RA_WIDTH      ( RA_WIDTH      ),
    .ADDRMAX_WIDTH ( ADDRMAX_WIDTH ))
 u_sp_ram (
    .rst_n                   ( rst_n                      ),
    .clk                     ( clk                        ),
    .en                      ( en                         ),
    .we                      ( we                         ),
    .addr                    ( addr   [ADDRMAX_WIDTH-1:0] ),
    .din                     ( din    [WD_WIDTH-1:0]      ),

    .dout                    ( dout   [RD_WIDTH-1:0]      )
);

////write data width > read data width
// initial
//    begin
//    #(PERIOD)
//    rst_n=1;
//        en=1;
//        din=0;
//        we=1;
//        #(PERIOD)
//      repeat(16) begin
//          @(negedge clk) ;
//           addr =addr+1;
//               din=din+1;
//          end
     
//        #(PERIOD*5)
//            en=1;
//            we=0;
//             addr =0;
//             #(PERIOD)
//             repeat(32) begin
//                       @(negedge clk) ;
//                        addr =addr+1;
//                       end
        
//        $stop;
//    end
    
    
    //write data width < read data width
     initial
        begin
        #(PERIOD)
        rst_n=1;
            en=1;
            din=0;
            we=1;
            #(PERIOD)
          repeat(32) begin
          #(PERIOD*1)
              @(negedge clk) ;
               addr =addr+1;
                   din=din+1;
              end

            #(PERIOD*5)
                en=1;
                we=0;
                 addr =0;
                 #(PERIOD)
                 repeat(16) begin
                           @(negedge clk) ;
                            addr =addr+1;
                             din=0;
                           end
            
            $stop;
        end

endmodule