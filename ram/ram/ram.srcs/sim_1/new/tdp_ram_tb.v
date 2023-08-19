`timescale  1ns / 1ns

module tdp_ram_tb;

// tdp_ram Parameters  
parameter PERIOD          = 10                                      ;  
parameter TYPE            = "block"                                 ;  
parameter WD_WIDTHA       =8                                       ;  
parameter WA_DEPTHA       = 16                                      ;  
parameter RD_WIDTHA       =4                                      ;  
parameter DELAYA          = 0                                       ;  
parameter MODEA           = "read_first"                           ;  
parameter WA_WIDTHA       = $clog2(WA_DEPTHA)                       ;  
parameter RA_DEPTHA       = WD_WIDTHA*WA_DEPTHA/RD_WIDTHA           ;  
parameter RA_WIDTHA       = $clog2(RA_DEPTHA)                       ;  
parameter ADDRMAX_WIDTHA  = WA_WIDTHA>=RA_WIDTHA?WA_WIDTHA:RA_WIDTHA;  
parameter WD_WIDTHB       = 16                                       ;  
parameter WA_DEPTHB       =8                                      ;  
parameter RD_WIDTHB       = 8                                    ;  
parameter DELAYB          = 0                                       ;  
parameter MODEB           = "read_first"                           ;  
parameter WA_WIDTHB       = $clog2(WA_DEPTHB)                       ;  
parameter RA_DEPTHB       = WD_WIDTHB*WA_DEPTHB/RD_WIDTHB           ;  
parameter RA_WIDTHB       = $clog2(RA_DEPTHB)                       ;  
parameter ADDRMAX_WIDTHB  = WA_WIDTHB>=RA_WIDTHB?WA_WIDTHB:RA_WIDTHB;  
  
// tdp_ram Inputs  
reg   rst                                  = 1 ;  
reg   clka                                 = 0 ;  
reg   ena                                  = 0 ;  
reg   wea                                  = 0 ;  
reg   [ADDRMAX_WIDTHA-1:0]  addra          = 0 ;  
reg   [WD_WIDTHA-1:0]  dina                = 0 ;  
reg   clkb                                 = 0 ;  
reg   enb                                  = 0 ;  
reg   web                                  = 0 ;  
reg   [ADDRMAX_WIDTHB-1:0]  addrb          = 0 ;  
reg   [WD_WIDTHB-1:0]  dinb                = 0 ;  
  
// tdp_ram Outputs  
wire  [RD_WIDTHA-1:0]  douta               ;  
wire  [RD_WIDTHB-1:0]  doutb               ;  
  

always #(PERIOD/2)  clka=~clka;  
always #(PERIOD/2)  clkb=~clkb;  

  
initial  
begin  
    #(PERIOD) rst  =  0;  
end  
  
tdp_ram #(  
    .TYPE           ( TYPE           ),  
    .WD_WIDTHA      ( WD_WIDTHA      ),  
    .WA_DEPTHA      ( WA_DEPTHA      ),  
    .RD_WIDTHA      ( RD_WIDTHA      ),  
    .DELAYA         ( DELAYA         ),  
    .MODEA          ( MODEA          ),  
    .WA_WIDTHA      ( WA_WIDTHA      ),  
    .RA_DEPTHA      ( RA_DEPTHA      ),  
    .RA_WIDTHA      ( RA_WIDTHA      ),  
    .ADDRMAX_WIDTHA ( ADDRMAX_WIDTHA ),  
    .WD_WIDTHB      ( WD_WIDTHB      ),  
    .WA_DEPTHB      ( WA_DEPTHB      ),  
    .RD_WIDTHB      ( RD_WIDTHB      ),  
    .DELAYB         ( DELAYB         ),  
    .MODEB          ( MODEB          ),  
    .WA_WIDTHB      ( WA_WIDTHB      ),  
    .RA_DEPTHB      ( RA_DEPTHB      ),  
    .RA_WIDTHB      ( RA_WIDTHB      ),  
    .ADDRMAX_WIDTHB ( ADDRMAX_WIDTHB ))  
 u_tdp_ram (  
    .rst                     ( rst                         ),  
    .clka                    ( clka                        ),  
    .ena                     ( ena                         ),  
    .wea                     ( wea                         ),  
    .addra                   ( addra  [ADDRMAX_WIDTHA-1:0] ),  
    .dina                    ( dina   [WD_WIDTHA-1:0]      ),  
    .clkb                    ( clkb                        ),  
    .enb                     ( enb                         ),  
    .web                     ( web                         ),  
    .addrb                   ( addrb  [ADDRMAX_WIDTHB-1:0] ),  
    .dinb                    ( dinb   [WD_WIDTHB-1:0]      ),  
    .douta                   ( douta  [RD_WIDTHA-1:0]      ),  
    .doutb                   ( doutb  [RD_WIDTHB-1:0]      )  
); 


initial begin   
    //port A write 
    #(PERIOD)
    ena=1;
    wea=1;
    addra=0;
    dina=0;
    
    enb=0;
    web=0;
    addrb=0;
    dinb=0;
//    #(PERIOD)
    repeat(16) begin
    #(PERIOD*4)
        @(negedge clka) ;
        addra = addra + 1'b1 ;
        dina = dina + 1'b1 ;
    end
    addra=0;
    dina=0;
    
//    //port A write 
//        #(PERIOD)
//        ena=1;
//        wea=1;
//        addra=0;
//        dina=0;
        
//        enb=0;
//        web=0;
//        addrb=0;
//        dinb=0;
//        #(PERIOD)
//        repeat(32) begin
//    //    #(PERIOD*4)
//            @(negedge clka) ;
//            addra = addra + 1'b1 ;
//            dina = dina + 1'b1 ;
//        end
//        addra=0;
//        dina=0;
        
    //port A  read
     #(PERIOD*5)
       ena=1;
       wea=0;
       addra=0;
       dina=0;
       
       enb=0;
       web=0;
       addrb=0;
       dinb=0;
       #(PERIOD)
       repeat(32) begin
          @(negedge clka) ;
          addra = addra + 1'b1 ;
       end
       addra = 0 ;
       
        #(PERIOD*5)
           //port B  read
                  ena=0;
           wea=0;
           addra=0;
           dina=0;
           
           enb=1;
           web=0;
           addrb=0;
           dinb=0;
           #(PERIOD)
           repeat(16) begin
              @(negedge clkb) ;
              addrb = addrb + 1'b1 ;
           end
           addrb = 0 ;
           
    //port B write
    #(PERIOD*5)
    ena=0;
    wea=0;
    addra=0;
    dina=0;
    
    enb=1;
    web=1;
    addrb=0;
    dinb=0;
    #(PERIOD)
    repeat(8) begin
//    #(PERIOD*2)
       @(negedge clkb) ;
       dinb = dinb - 1'b1 ;
       addrb = addrb + 1'b1 ;
    end
    dinb = 0 ;
    addrb = 0;
       
       
        //port A  read
           #(PERIOD*5)
             ena=1;
             wea=0;
             addra=0;
             dina=0;
             
             enb=0;
             web=0;
             addrb=0;
             dinb=0;
             #(PERIOD)
             repeat(32) begin
                @(negedge clka) ;
                addra = addra + 1'b1 ;
             end
             addra = 0 ;
             
              #(PERIOD*5)
                 //port B  read
                        ena=0;
                 wea=0;
                 addra=0;
                 dina=0;
                 
                 enb=1;
                 web=0;
                 addrb=0;
                 dinb=0;
                 #(PERIOD)
                 repeat(16) begin
                    @(negedge clkb) ;
                    addrb = addrb + 1'b1 ;
                 end
                 addrb = 0 ;
                 
    $stop;
end


   

endmodule
