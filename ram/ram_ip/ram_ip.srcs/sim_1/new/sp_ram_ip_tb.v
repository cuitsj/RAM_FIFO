`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/11 10:43:18
// Design Name: 
// Module Name: sp_ram_ip_tb
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


module sp_ram_ip_tb;
    
    // sp_ram Parameters
parameter PERIOD      = 10           ;


// sp_ram Inputs
reg   clk                                  = 0 ;
reg   ena                                   = 0 ;
reg   wea                                   = 0 ;
reg   [4:0]  addra               = 0 ;
reg   [15:0]  dina                = 0 ;

// sp_ram Outputs
wire  [3:0]  douta               ;    


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end
    
    sp_ram_ip sp_ram_ip_i (
  .clka(clk),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [4 : 0] addra
  .dina(dina),    // input wire [15 : 0] dina
  .douta(douta)  // output wire [3 : 0] douta
);
    
 initial
       begin
       #(PERIOD)
           ena=1;
           dina=0;
           wea=1;
           addra=0;
           #(PERIOD)
         repeat(8) begin
             @(negedge clk)
              #(PERIOD*4)
              addra =addra+1;
                  dina=dina+1;
             end
             
                #(PERIOD*5)
                 addra=0;
           ena=1;
           dina=0;
           wea=1;
           #(PERIOD)
         repeat(8) begin
             @(negedge clk)
              #(PERIOD*4)
              addra =addra+1;
                  dina=dina+1;
             end
        
           #(PERIOD*5)
               ena=1;
               wea=0;
                addra =0;
                #(PERIOD)
                repeat(32) begin
                          @(negedge clk) 
                          #(PERIOD*4)
                           addra =addra+1;
                          end
           
           $stop;
       end


    
endmodule
