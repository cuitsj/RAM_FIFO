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


module ram_top(rst,clk,ena,wea,douta,enb,web,doutb);

// sp_ram Parameters
parameter WD_WIDTH       = 8                                   ;
parameter WA_DEPTH       = 4096                                 ;
parameter RD_WIDTH       = 8                                 ;
parameter DELAY          = 0                                   ;
parameter MODE           = "write_first"                       ;
parameter TYPE           = "block"                             ;
parameter WA_WIDTH       = $clog2(WA_DEPTH)                     ;
parameter RA_DEPTH       = WD_WIDTH*WA_DEPTH/RD_WIDTH          ;
parameter RA_WIDTH       = $clog2(RA_DEPTH)                     ;
parameter ADDRMAX_WIDTH  = WA_WIDTH>=RA_WIDTH?WA_WIDTH:RA_WIDTH;

input rst;
input clk;
input ena;
input wea;
output [RD_WIDTH-1:0] douta;
input enb;
input web;
output [RD_WIDTH-1:0] doutb;

// sp_ram Inputs
reg   [ADDRMAX_WIDTH-1:0]  addra            = 0 ;
reg   [WD_WIDTH-1:0]  dina                  = 0 ;

// sp_ram Inputs
reg   [ADDRMAX_WIDTH-1:0]  addrb            = 0 ;
reg   [WD_WIDTH-1:0]  dinb                  = 0 ;

//sp_ram #(
//    .WD_WIDTH (WD_WIDTH             ),    //write data width     
//    .WA_DEPTH ( WA_DEPTH          ),    //write addr depth
//    .RD_WIDTH ( RD_WIDTH             ),    //read data width
//    .DELAY    ( DELAY             ),    //Select the clock period for delayed output. The value can be 0,1,2
//    .MODE     ( MODE ),    //write_first, read_first, no_change
//    .TYPE     ( TYPE       ))    //block,distributed  
// your_instance_name (
//    .rst      ( rst    ),   //input [0:0] rst active-HIGH
//    .clk      ( clk    ),   //input [0:0] clk
//    .en       ( en     ),   //input [0:0] en
//    .we       ( we     ),   //input [0:0] we
//    .addr     ( addr   [ADDRMAX_WIDTH-1:0]    ),   //input [ADDRMAX_WIDTH-1:0] addr
//    .din      ( din    [WD_WIDTH-1:0]    ),   //input [WD_WIDTH-1:0] din
//    .dout     ( dout   [RD_WIDTH-1:0]   )    //output [RD_WIDTH-1:0] dout
//);

tdp_ram #(
    .WD_WIDTHA ( WD_WIDTH             ),   //write data width
    .WA_DEPTHA ( WA_DEPTH          ),   //write address depth
    .RD_WIDTHA ( RD_WIDTH             ),   //read data width
    .DELAYA    ( DELAY             ),   //Select the clock period for delayed output. The value can be 0,1,2
    .MODEA     ( MODE ),   //write_first, read_first, no_change
    .WD_WIDTHB ( WD_WIDTH             ),   //write data width   
    .WA_DEPTHB ( WA_DEPTH          ),   //write address depth
    .RD_WIDTHB ( RD_WIDTH             ),   //read data width
    .DELAYB    ( DELAY             ),   //Select the clock period for delayed output. The value can be 0,1,2
    .MODEB     ( MODE ),   //write_first, read_first, no_change
    .TYPE      ( TYPE       ))   //block,distributed
 your_instance_name1 (
    .rst       ( rst   ),   //input [0:0] rst active-HIGH
    .clka      ( clk  ),   //input [0:0] clka
    .ena       ( ena   ),   //input [0:0] ena
    .wea       ( wea   ),   //input [0:0] wea
    .addra     ( addra ),   //input [ADDRMAX_WIDTHA-1:0] addra
    .dina      ( dina  ),   //input [WD_WIDTHA-1:0] dina
    .douta     ( douta ),   //output [RD_WIDTHA-1:0] douta
    .clkb      ( clk  ),   //input [0:0] clkb
    .enb       ( enb   ),   //input [0:0] enb
    .web       ( web   ),   //input [0:0] web
    .addrb     ( addrb ),   //input [ADDRMAX_WIDTHB-1:0] addrb
    .dinb      ( dinb  ),   //input [WD_WIDTHB-1:0] dinb
    .doutb     ( doutb )    //output [RD_WIDTHB-1:0] doutb
);

always @(posedge clk) begin
    if (rst) begin
        addra<=0;
        dina<=0;
    end
    else if (ena) begin
        if (wea) begin
            addra<=addra+1;
            dina<=dina+1;
        end
        else begin
            addra<=addra+1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        addrb<=0;
        dinb<=0;
    end
    else if (enb) begin
        if (web) begin
            addrb<=addrb+1;
            dinb<=dinb+1;
        end
        else begin
            addrb<=addrb+1;
        end
    end
end

endmodule
