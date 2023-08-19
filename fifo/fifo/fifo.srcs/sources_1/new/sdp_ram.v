//------------------------------------------------------------------------
//Created By:sujin
//Create Date:2022/7/8
//Compiler Tool:
//Copyrights(C):
//Description:
//History:
//------------------------------------------------------------------------

module sdp_ram#(
    parameter WD_WIDTH = 8,             //write data width
    parameter WA_DEPTH = 4096,          //write address depth
    parameter RD_WIDTH = 8,             //read data width
    parameter DELAY = 0,                //Select the clock period for delayed output. The value can be 0,1,2
    parameter TYPE = "block"            //block,distributed
)(wr_clk,wr_en,waddr,din,rd_clk,rd_en,raddr,dout);

localparam WD_MOVE = $clog2(WD_WIDTH);                              //write data width bits
localparam RD_MOVE = $clog2(RD_WIDTH);                              //read data width bits
localparam WA_WIDTH = $clog2(WA_DEPTH);                             //write address width
localparam RA_DEPTH = WD_WIDTH*WA_DEPTH/RD_WIDTH;                   //read address depth
localparam RA_WIDTH = $clog2(RA_DEPTH);                             //read address width
localparam DATA_WIDTH = WD_WIDTH>=RD_WIDTH?WD_WIDTH:RD_WIDTH;       //data width
localparam ADDR_WIDTH = WA_WIDTH<=RA_WIDTH?WA_WIDTH:RA_WIDTH;       //address width
localparam AWIDTH_DIF = WA_WIDTH>=RA_WIDTH?WA_WIDTH-RA_WIDTH:RA_WIDTH-WA_WIDTH;     //address width differential
localparam DWIDTH_MUL = WD_WIDTH>=RD_WIDTH?WD_WIDTH/RD_WIDTH:RD_WIDTH/WD_WIDTH;     //data width multiples

input                   wr_clk; //write clock
input                   wr_en;  //write enable
input [WA_WIDTH-1:0]    waddr;  //write address
input [WD_WIDTH-1:0]    din;    //write data
input                   rd_clk; //read clock
input                   rd_en;  //read enable
input [RA_WIDTH-1:0]    raddr;  //read address
output [RD_WIDTH-1:0]   dout;   //read data

(*ram_style=TYPE*)reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

generate
    //write addr == read addr
    if (WD_WIDTH == RD_WIDTH) begin
        reg [WD_WIDTH-1:0] outbuff [DELAY:0];
        //write data
        always @(posedge wr_clk) begin
            if (wr_en) begin
                ram[waddr] <= din;
            end
        end

        //read data
        integer i=0;
        always @(posedge rd_clk) begin
            if (rd_en) begin
                outbuff[0] <= ram[raddr];
                for (i=1;i<=DELAY;i=i+1) begin
                    outbuff[i] <= outbuff[i-1];
                end
            end
            else outbuff[0] <= 0;
        end
        assign dout = outbuff[DELAY];
    end
    //write data width > read data width
    else if (WD_WIDTH > RD_WIDTH) begin
        reg [WD_WIDTH-1:0] outbuff [DELAY:0];
        //write data
        always @(posedge wr_clk) begin
            if (wr_en) begin
                ram[waddr] <= din;
            end
        end

        //read data
        integer i=0;
        always @(posedge rd_clk) begin
            if (rd_en) begin
                outbuff[0] <= ram[raddr>>AWIDTH_DIF];
                for (i=1;i<=DELAY;i=i+1) begin
                    outbuff[i] <= outbuff[i-1];
                end
            end
            else outbuff[0] <= 0;
        end
        assign dout = outbuff[DELAY][((raddr[0+:AWIDTH_DIF]+0)<<RD_MOVE)+:RD_WIDTH];
    end
    //write data width < read data width
    else if (WD_WIDTH < RD_WIDTH) begin
        reg [RD_WIDTH-1:0] write_buff0;
        reg [RD_WIDTH-1:0] write_buff1;
        reg [RD_WIDTH-1:0] write_buff2;
        reg [RA_WIDTH-1:0] addr_buff;
        reg [WD_WIDTH-1:0] outbuff [DELAY:0];

        //write data
        integer i=0;
        always @(posedge wr_clk) begin
            if (wr_en) begin
                addr_buff <= waddr>>AWIDTH_DIF;
                for (i=0;i<DWIDTH_MUL;i=i+1) begin
                    if (i == waddr[0+:AWIDTH_DIF]) begin
                        write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                        write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= din;
                    end
                    else begin
                        write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b1}};
                        write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                    end
                end
                write_buff2 <= ram[addr_buff];
                ram[addr_buff] <= write_buff2&write_buff0|write_buff1;
            end
            else begin
                write_buff0 <= 0;
                write_buff1 <= 0;
                write_buff2 <= 0;
                addr_buff <= 0;
            end
        end

        //read data
        integer j=0;
        always @(posedge rd_clk) begin
            if (rd_en) begin
                outbuff[0] <= ram[raddr];
                for (j=1;j<=DELAY;j=j+1) begin
                    outbuff[j] <= outbuff[j-1];
                end
            end
            else outbuff[0] <= 0;
        end
        assign dout = outbuff[DELAY];
    end
endgenerate

 
endmodule
