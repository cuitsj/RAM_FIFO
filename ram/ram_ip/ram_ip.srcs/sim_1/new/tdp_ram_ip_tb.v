`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/11 15:36:45
// Design Name: 
// Module Name: tdp_ram_ip_tb
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


module tdp_ram_ip_tb;
// tdp_ram Parameters
parameter PERIOD      = 10           ;
parameter DATA_WIDTH  = 10        ;
parameter ADDR_WIDTH  = 10       ;
parameter AMODE       = "write_first";
parameter BMODE       = "write_first";
parameter ADELAY      = "one"       ;
parameter BDELAY      = "one"       ;
parameter TYPE        = "block"      ;

// tdp_ram Inputs
reg   clk                                 = 0 ;
reg   ena                                  = 0 ;
reg   wea                                  = 0 ;
reg   [ADDR_WIDTH-1:0]  addra              = 0 ;
reg   [DATA_WIDTH-1:0]  dina               = 0 ;
reg   enb                                  = 0 ;
reg   web                                  = 0 ;
reg   [ADDR_WIDTH-1:0]  addrb              = 0 ;
reg   [DATA_WIDTH-1:0]  dinb               = 0 ;

// tdp_ram Outputs
wire  [DATA_WIDTH-1:0]  douta              ;
wire  [DATA_WIDTH-1:0]  doutb              ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

tdp_ram_ip tdp_ram_ip_i (
  .clka(clk),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [9 : 0] addra
  .dina(dina),    // input wire [9 : 0] dina
  .douta(douta),  // output wire [9 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(enb),      // input wire enb
  .web(web),      // input wire [0 : 0] web
  .addrb(addrb),  // input wire [9 : 0] addrb
  .dinb(dinb),    // input wire [9 : 0] dinb
  .doutb(doutb)  // output wire [9 : 0] doutb
);

  reg rst=0;
    initial
    begin     
        #(PERIOD) rst=1;
    end
    
    always @(posedge clk) begin
    if (!rst) begin
        ena<=1;
        wea<=1;
        addra<=0;
        
        enb=1;
        web=0;
        addrb=0;
    end
    else begin
        addra <= addra + 1'b1 ;
        dina <= dina + 1'b1 ;
        addrb = addrb + 1'b1 ;
    end
    end

endmodule
