`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/11 11:25:58
// Design Name: 
// Module Name: SDP_RAM_IP_TB
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


module sdp_ram_ip_tb;

  // sp_ram Parameters
parameter PERIOD      = 10           ;
parameter DATA_WIDTH  = 10            ;
parameter ADDR_WIDTH  = 10           ;

// sp_ram Inputs
reg   clk                                  = 0 ;
reg   ena                                   = 0 ;
reg   enb                                   = 0 ;
reg   wea                                   = 0 ;
reg   [ADDR_WIDTH-1:0]  addra               = 0 ;
reg   [ADDR_WIDTH-1:0]  addrb               = 0 ;
reg   [DATA_WIDTH-1:0]  dina                = 0 ;

// sp_ram Outputs
wire  [DATA_WIDTH-1:0]  doutb               ;    


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

sdp_ram_ip sdp_ram_ip_i (
  .clka(clk),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [9 : 0] addra
  .dina(dina),    // input wire [9 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(enb),      // input wire enb
  .addrb(addrb),  // input wire [9 : 0] addrb
  .doutb(doutb)  // output wire [9 : 0] doutb
);

integer i;

initial
begin    
#0.099
#(PERIOD/2)       
#(PERIOD*2) ena=1;
            wea=1;
            addra=0;
            dina=0;
            enb=0;
            addrb=0;
            for (i=0; i<16; i=i+1) begin
                #PERIOD ;
                addra = addra + 1'b1 ;
                addrb = addrb + 1'b1 ;
                dina = dina + 1'b1 ;
            end  
            
            ena=1;
            wea=0;
            addra=0;
            dina=16;
            enb=1;
            addrb=0;
            for (i=0; i<32; i=i+1) begin
                #PERIOD ;
                addra = addra + 1'b1 ;
                addrb = addrb + 1'b1 ;
                dina = dina - 1'b1 ;
            end  
            
//            ena=1;
//            wea=1;
//            addra=512;
//            dina=1024;
//            enb=1;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//               #PERIOD ;
//               addrb = addrb + 1'b1 ;
//            end  
    $stop;
end

//integer i;
//reg rst=0;
//initial
//begin     
//    #(PERIOD) rst=1;
//end

//always @(posedge clk) begin
//if (!rst) begin
//    ena=1;
//    wea=1;
//    addra=0;
//    enb=1;
//    addrb=0;
//end
//else begin
//    addra <= addra + 1'b1 ;
//    addrb <= addrb + 1'b1 ;
//    dina <= dina + 1'b1 ;
//end
//end

//always begin
//   #(PERIOD/2)       
//#(PERIOD*2) ena=1;
//            wea=1;
//            addra=0;
//            dina=0;
//            enb=0;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//                #PERIOD ;
//                addra = addra + 1'b1 ;
//                addrb = addrb + 1'b1 ;
//                dina = dina + 1'b1 ;
//            end  
            
//            ena=1;
//            wea=0;
//            addra=0;
//            dina=1024;
//            enb=1;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//                #PERIOD ;
//                addra = addra + 1'b1 ;
//                addrb = addrb + 1'b1 ;
//                dina = dina - 1'b1 ;
//            end  
            
//            ena=1;
//            wea=1;
//            addra=512;
//            dina=1024;
//            enb=1;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//               #PERIOD ;
//               addrb = addrb + 1'b1 ;
//            end  
//    $stop;
//end



//initial
//begin     
//#(PERIOD/2)       
//#(PERIOD*2) ena=1;
//            wea=1;
//            addra=0;
//            dina=0;
//            enb=0;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//                #PERIOD ;
//                addra = addra + 1'b1 ;
//                addrb = addrb + 1'b1 ;
//                dina = dina + 1'b1 ;
//            end  
            
//            ena=1;
//            wea=0;
//            addra=0;
//            dina=1024;
//            enb=1;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//                #PERIOD ;
//                addra = addra + 1'b1 ;
//                addrb = addrb + 1'b1 ;
//                dina = dina - 1'b1 ;
//            end  
            
//            ena=1;
//            wea=1;
//            addra=512;
//            dina=1024;
//            enb=1;
//            addrb=0;
//            for (i=0; i<1024; i=i+1) begin
//               #PERIOD ;
//               addrb = addrb + 1'b1 ;
//            end  
//    $stop;
//end

endmodule
