`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/02 11:48:20
// Design Name: 
// Module Name: ram_top
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


module ram_top
(rst,clk,dout
);

// sp_ram Parameters
parameter WD_WIDTH       = 8                                   ;
parameter WA_DEPTH       = 4096                                 ;
parameter RD_WIDTH       =4                                  ;
parameter DELAY          = 0                                   ;
parameter MODE           = "read_first"                       ;
parameter TYPE           = "block"                             ;
parameter WA_WIDTH       = $clog2(WA_DEPTH)                     ;
parameter RA_DEPTH       = WD_WIDTH*WA_DEPTH/RD_WIDTH          ;
parameter RA_WIDTH       = $clog2(RA_DEPTH)                     ;
parameter ADDRMAX_WIDTH  = WA_WIDTH>=RA_WIDTH?WA_WIDTH:RA_WIDTH;

input rst;
input clk;
output [RD_WIDTH-1:0] dout;

// sp_ram Inputs

reg   en                                   = 0 ;
reg   we                                   = 0 ;
reg   [ADDRMAX_WIDTH-1:0]  addr            = 0 ;
reg   [WD_WIDTH-1:0]  din                  = 0 ;

// sp_ram Outputs
wire  [RD_WIDTH-1:0]  dout                 ;

tdp_ram_ip your_instance_name (
  .clka(clk),    // input wire clka
  .ena(en),      // input wire ena
  .wea(we),      // input wire [0 : 0] wea
  .addra(addr),  // input wire [11 : 0] addra
  .dina(din),    // input wire [7 : 0] dina
  .douta(dout),  // output wire [3 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(en),      // input wire enb
  .web(we),      // input wire [0 : 0] web
  .addrb(addr),  // input wire [11 : 0] addrb
  .dinb(din),    // input wire [7 : 0] dinb
  .doutb(dout)  // output wire [3 : 0] doutb
);

always @(posedge clk) begin
if (rst) begin
en<=0;
we<=0;
addr<=0;
din<=0;
end
else begin
en<=1;
we<=1;
addr<=addr+1;
din<=din+1;
end

end


endmodule
