//------------------------------------------------------------------------
//Created By:sujin
//Create Date:2022/7/13
//Compiler Tool:
//Copyrights(C):
//Description:
//History:
//------------------------------------------------------------------------

module fifo#(
    parameter WD_WIDTH = 8,         //write data width
    parameter WA_DEPTH = 4096,      //write address width
    parameter RD_WIDTH = 8,         //read data width
    parameter SYNC = 0,             //0:Asynchronous FIFO,1:Synchronous fifo
    parameter DELAY = 0,            //0:First word fall through,1:Standard FIFO
    parameter TYPE = "block"        //block,distributed
)(rst,wr_clk,wr_en,din,full,wclk_cnt,rd_clk,rd_en,dout,empty,rclk_cnt);

localparam RA_DEPTH = WD_WIDTH*WA_DEPTH/RD_WIDTH;                   //read address depth
localparam RA_WIDTH = $clog2(RA_DEPTH);                             //read address width
localparam WA_WIDTH = $clog2(WA_DEPTH);                             //write address width
localparam DATA_WIDTH = WD_WIDTH<=RD_WIDTH?WD_WIDTH:RD_WIDTH;       //data width
localparam ADDR_WIDTH = WA_WIDTH>=RA_WIDTH?WA_WIDTH:RA_WIDTH;       //address width
localparam AWIDTH_DIF = WA_WIDTH>=RA_WIDTH?WA_WIDTH-RA_WIDTH:RA_WIDTH-WA_WIDTH;   //address width differential

input                       rst;
input                       wr_clk;
input                       wr_en;          //enable write
input [WD_WIDTH-1:0]        din;
output                      full;
output reg [WA_WIDTH:0]     wclk_cnt;       //write clock domain fifo remain data count

input                       rd_clk;
input                       rd_en;          //enable read
output [RD_WIDTH-1:0]       dout;
output                      empty;
output reg [RA_WIDTH:0]     rclk_cnt;        //read clock domain fifo remain data count

wire [RD_WIDTH-1:0] outbuff0;
reg [RD_WIDTH-1:0] outbuff1;
assign dout = DELAY?outbuff1:outbuff0;

//delay out data
always @(posedge rd_clk) begin
    if (rd_en && !empty && DELAY) begin
        outbuff1 <= outbuff0;
    end
end

genvar i;
generate
    //Asynchronous FIFO,output width >= input width
    if (WD_WIDTH <= RD_WIDTH && !SYNC) begin        
        reg [WA_WIDTH:0] waddr;         //write address
        wire [WA_WIDTH:0] waddr_gray;   //write address gray code
        reg [WA_WIDTH:0] waddr_grayr0;  //write address gray code buffer0
        reg [WA_WIDTH:0] waddr_grayr1;  //write address gray code buffer1
        reg [WA_WIDTH:0] waddr_degray;  //write address binary code

        reg [RA_WIDTH:0] raddr;         //read address
        wire [WA_WIDTH:0] raddr_waddr;  //read address entend to write address
        wire [WA_WIDTH:0] raddr_gray;   //read address gray code
        reg [WA_WIDTH:0] raddr_grayr0;  //read address gray code buffer0
        reg [WA_WIDTH:0] raddr_grayr1;  //read address gray code buffer1
        reg [WA_WIDTH:0] raddr_degray;  //read address binary code

        //write pointer add 1
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                waddr <= 0;
            end
            else if (wr_en && !full) begin
                waddr <= waddr + 1'b1;
            end
        end

        //write pointer to gray code and synchronize to the read clock domain
        assign waddr_gray=(waddr>>1)^(waddr);
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                waddr_grayr0 <= 0;
                waddr_grayr1 <= 0;
            end
            else begin
                waddr_grayr0 <= waddr_gray;
                waddr_grayr1 <= waddr_grayr0;
            end
        end

        //judge if it is empty
        assign empty = (raddr_gray == waddr_grayr1)?1:0;

        //read pointer add 1
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                raddr <= 0;
            end
            else if (rd_en && !empty) begin
                raddr <= raddr + 1'b1;
            end
        end

        //read pointer to gray code and synchronize to the write clock domain
        assign raddr_waddr = raddr << AWIDTH_DIF;
        assign raddr_gray=(raddr_waddr>>1)^(raddr_waddr);
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                raddr_grayr0 <= 0;
                raddr_grayr1 <= 0;
            end
            else begin
                raddr_grayr0 <= raddr_gray;
                raddr_grayr1 <= raddr_grayr0;
            end
        end

        //judge if it is full
        assign full = (waddr_gray == {~raddr_grayr1[WA_WIDTH:WA_WIDTH-1],raddr_grayr1[WA_WIDTH-2:0]})?1:0;

        //--------------------------------------calculate fifo remain data--------------------------------------
        //Reverse gray code
        integer j=0;
        always @(*) begin
            waddr_degray[WA_WIDTH] = waddr_grayr1[WA_WIDTH];
            for (j=WA_WIDTH-1; j>=0; j=j-1) begin
                waddr_degray[j] = waddr_degray[j+1] ^ waddr_grayr1[j] ;
            end
        end

        integer k=0;
        always @(*) begin
            raddr_degray[WA_WIDTH] = raddr_grayr1[WA_WIDTH];
            for (k=WA_WIDTH-1; k>=0; k=k-1) begin
                raddr_degray[k] = raddr_degray[k+1] ^ raddr_grayr1[k] ;
            end
        end
        //write clock domain
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                wclk_cnt <= 0;
            end
            else begin
                wclk_cnt <= waddr - raddr_degray;
            end
        end
        //read clock domain
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                rclk_cnt <= 0;
            end
            else begin
                rclk_cnt <= (waddr_degray - raddr_waddr)>>AWIDTH_DIF;
            end
        end

        //Instantiate the simple double port ram
        sdp_ram #(
            .WD_WIDTH ( WD_WIDTH ),  //write data width
            .WA_DEPTH ( WA_DEPTH ),  //write address depth
            .RD_WIDTH ( RD_WIDTH ),  //read data width
            .DELAY    ( DELAY    ),  //Select the clock period for delayed output. The value can be 0,1,2
            .TYPE     ( TYPE     ))  //block,distributed
        u_sdp_ram (
            .wr_clk   ( wr_clk                  ),   //input [0:0] wr_clk
            .wr_en    ( wr_en && !full          ),   //input [0:0] wr_en
            .waddr    ( waddr    [WA_WIDTH-1:0] ),   //input [WA_WIDTH-1:0] waddr
            .din      ( din      [WD_WIDTH-1:0] ),   //input [WD_WIDTH-1:0] din
            .rd_clk   ( rd_clk                  ),   //input [0:0] rd_clk
            .rd_en    ( rd_en && !empty         ),   //input [0:0] rd_en
            .raddr    ( raddr    [RA_WIDTH-1:0] ),   //input [RA_WIDTH-1:0] raddr
            .dout     ( outbuff0                )    //input [RD_WIDTH-1:0] dout
        );
        
    end
    //Synchronous FIFO,output width >= input width
    else if (WD_WIDTH <= RD_WIDTH && SYNC) begin
        reg [WA_WIDTH:0] waddr;         //write address
        wire [WA_WIDTH:0] waddr_gray;   //write address gray code

        reg [RA_WIDTH:0] raddr;         //read address
        wire [WA_WIDTH:0] raddr_waddr;  //read address extend to write address
        wire [WA_WIDTH:0] raddr_gray;   //read address gray code

        //write pointer add 1
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                waddr <= 0;
            end
            else if (wr_en && !full) begin
                waddr <= waddr + 1'b1;
            end
        end

        //write pointer to gray code and synchronize to the read clock domain
        assign waddr_gray=(waddr>>1)^(waddr);

        //judge if it is empty
        assign empty = (raddr_gray == waddr_gray)?1:0;

        //read pointer add 1
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                raddr <= 0;
            end
            else if (rd_en && !empty) begin
                raddr <= raddr + 1'b1;
            end
        end

        //read pointer to gray code and synchronize to the write clock domain
        assign raddr_waddr = raddr << AWIDTH_DIF;
        assign raddr_gray=(raddr_waddr>>1)^(raddr_waddr);

        //judge if it is full
        assign full = (waddr_gray == {~raddr_gray[WA_WIDTH:WA_WIDTH-1],raddr_gray[WA_WIDTH-2:0]})?1:0;

        //--------------------------------------calculate fifo remain data--------------------------------------
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                wclk_cnt <= 0;
                rclk_cnt <= 0;
            end
            else begin
                wclk_cnt <= waddr - raddr_waddr;
                rclk_cnt <= (waddr - raddr_waddr)>>AWIDTH_DIF;
            end
        end

        //Instantiate the simple double port ram
        sdp_ram #(
            .WD_WIDTH ( WD_WIDTH ),  //write data width
            .WA_DEPTH ( WA_DEPTH ),  //write address depth
            .RD_WIDTH ( RD_WIDTH ),  //read data width
            .DELAY    ( DELAY    ),  //Select the clock period for delayed output. The value can be 0,1,2
            .TYPE     ( TYPE     ))  //block,distributed
        u_sdp_ram (
            .wr_clk   ( wr_clk                  ),   //input [0:0] wr_clk
            .wr_en    ( wr_en && !full          ),   //input [0:0] wr_en
            .waddr    ( waddr    [WA_WIDTH-1:0] ),   //input [WA_WIDTH-1:0] waddr
            .din      ( din      [WD_WIDTH-1:0] ),   //input [WD_WIDTH-1:0] din
            .rd_clk   ( rd_clk                  ),   //input [0:0] rd_clk
            .rd_en    ( rd_en && !empty         ),   //input [0:0] rd_en
            .raddr    ( raddr    [RA_WIDTH-1:0] ),   //input [RA_WIDTH-1:0] raddr
            .dout     ( outbuff0                )    //input [RD_WIDTH-1:0] dout
        );
    end
    //Asynchronous FIFO,input width > output width
    else if (WD_WIDTH > RD_WIDTH && !SYNC) begin
        reg [WA_WIDTH:0] waddr;         //write address
        wire [RA_WIDTH:0] waddr_raddr;  //read address entend to write address
        wire [RA_WIDTH:0] waddr_gray;   //write address gray code
        reg [RA_WIDTH:0] waddr_grayr0;  //write address gray code buffer0
        reg [RA_WIDTH:0] waddr_grayr1;  //write address gray code buffer1
        reg [RA_WIDTH:0] waddr_degray;  //write address binary code

        reg [RA_WIDTH:0] raddr;         //read address
        wire [RA_WIDTH:0] raddr_gray;   //read address gray code
        reg [RA_WIDTH:0] raddr_grayr0;  //read address gray code buffer0
        reg [RA_WIDTH:0] raddr_grayr1;  //read address gray code buffer1
        reg [RA_WIDTH:0] raddr_degray;  //read address binary code

        //write pointer add 1
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                waddr <= 0;
            end
            else if (wr_en && !full) begin
                waddr <= waddr + 1'b1;
            end
        end

        //write pointer to gray code and synchronize to the read clock domain
        assign waddr_raddr = waddr << AWIDTH_DIF;
        assign waddr_gray=(waddr_raddr>>1)^(waddr_raddr);
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                waddr_grayr0 <= 0;
                waddr_grayr1 <= 0;
            end
            else begin
                waddr_grayr0 <= waddr_gray;
                waddr_grayr1 <= waddr_grayr0;
            end
        end

        //judge if it is empty
        assign empty = (raddr_gray == waddr_grayr1)?1:0;

        //read pointer add 1
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                raddr <= 0;
            end
            else if (rd_en && !empty) begin
                raddr <= raddr + 1'b1;
            end
        end

        //read pointer to gray code and synchronize to the write clock domain
        assign raddr_gray=(raddr>>1)^(raddr);
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                raddr_grayr0 <= 0;
                raddr_grayr1 <= 0;
            end
            else begin
                raddr_grayr0 <= raddr_gray;
                raddr_grayr1 <= raddr_grayr0;
            end
        end

        //judge if it is full
        assign full = (waddr_gray == {~raddr_grayr1[RA_WIDTH:RA_WIDTH-1],raddr_grayr1[RA_WIDTH-2:0]})?1:0;
        
        //--------------------------------------calculate fifo remain data--------------------------------------
        //Reverse gray code
        integer j=0;
        always @(*) begin
            waddr_degray[RA_WIDTH] = waddr_grayr1[RA_WIDTH];
            for (j=RA_WIDTH-1; j>=0; j=j-1) begin
                waddr_degray[j] = waddr_degray[j+1] ^ waddr_grayr1[j] ;
            end
        end

        integer k=0;
        always @(*) begin
            raddr_degray[RA_WIDTH] = raddr_grayr1[RA_WIDTH];
            for (k=RA_WIDTH-1; k>=0; k=k-1) begin
                raddr_degray[k] = raddr_degray[k+1] ^ raddr_grayr1[k] ;
            end
        end
        //write clock domain
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                wclk_cnt <= 0;
            end
            else begin
                wclk_cnt <= (waddr_raddr - raddr_degray)>>AWIDTH_DIF;
            end
        end
        //read clock domain
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                rclk_cnt <= 0;
            end
            else begin
                rclk_cnt <= waddr_degray - raddr;
            end
        end

        //Instantiate the simple double port ram
        sdp_ram #(
            .WD_WIDTH ( WD_WIDTH ),  //write data width
            .WA_DEPTH ( WA_DEPTH ),  //write address depth
            .RD_WIDTH ( RD_WIDTH ),  //read data width
            .DELAY    ( DELAY    ),  //Select the clock period for delayed output. The value can be 0,1,2
            .TYPE     ( TYPE     ))  //block,distributed
        u_sdp_ram (
            .wr_clk   ( wr_clk                  ),   //input [0:0] wr_clk
            .wr_en    ( wr_en && !full          ),   //input [0:0] wr_en
            .waddr    ( waddr    [WA_WIDTH-1:0] ),   //input [WA_WIDTH-1:0] waddr
            .din      ( din      [WD_WIDTH-1:0] ),   //input [WD_WIDTH-1:0] din
            .rd_clk   ( rd_clk                  ),   //input [0:0] rd_clk
            .rd_en    ( rd_en && !empty         ),   //input [0:0] rd_en
            .raddr    ( raddr    [RA_WIDTH-1:0] ),   //input [RA_WIDTH-1:0] raddr
            .dout     ( outbuff0                )    //input [RD_WIDTH-1:0] dout
        );
    end
    //Synchronous FIFO,input width > output width
    else if (WD_WIDTH > RD_WIDTH && SYNC) begin
        reg [WA_WIDTH:0] waddr;         //write address
        wire [RA_WIDTH:0] waddr_raddr;  //read address entend to write address
        wire [RA_WIDTH:0] waddr_gray;   //write address gray code

        reg [RA_WIDTH:0] raddr;         //read address
        wire [RA_WIDTH:0] raddr_gray;   //read address gray code

        //write pointer add 1
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                waddr <= 0;
            end
            else if (wr_en && !full) begin
                waddr <= waddr + 1'b1;
            end
        end

        //write pointer to gray code and synchronize to the read clock domain
        assign waddr_raddr = waddr << AWIDTH_DIF;
        assign waddr_gray=(waddr_raddr>>1)^(waddr_raddr);

        //judge if it is empty
        assign empty = (raddr_gray == waddr_gray)?1:0;

        //read pointer add 1
        always @(posedge rd_clk or posedge rst) begin
            if (rst) begin
                raddr <= 0;
            end
            else if (rd_en && !empty) begin
                raddr <= raddr + 1'b1;
            end
        end

        //read pointer to gray code and synchronize to the write clock domain
        assign raddr_gray=(raddr>>1)^(raddr);

        //judge if it is full
        assign full = (waddr_gray == {~raddr_gray[RA_WIDTH:RA_WIDTH-1],raddr_gray[RA_WIDTH-2:0]})?1:0;

        //--------------------------------------calculate fifo remain data--------------------------------------
        always @(posedge wr_clk or posedge rst) begin
            if (rst) begin
                wclk_cnt <= 0;
                rclk_cnt <= 0;
            end
            else begin
                wclk_cnt <= (waddr_raddr - raddr)>>AWIDTH_DIF;
                rclk_cnt <= waddr_raddr - raddr;
            end
        end

        //Instantiate the simple double port ram
        sdp_ram #(
            .WD_WIDTH ( WD_WIDTH ),  //write data width
            .WA_DEPTH ( WA_DEPTH ),  //write address depth
            .RD_WIDTH ( RD_WIDTH ),  //read data width
            .DELAY    ( DELAY    ),  //Select the clock period for delayed output. The value can be 0,1,2
            .TYPE     ( TYPE     ))  //block,distributed
        u_sdp_ram (
            .wr_clk   ( wr_clk                  ),   //input [0:0] wr_clk
            .wr_en    ( wr_en && !full          ),   //input [0:0] wr_en
            .waddr    ( waddr    [WA_WIDTH-1:0] ),   //input [WA_WIDTH-1:0] waddr
            .din      ( din      [WD_WIDTH-1:0] ),   //input [WD_WIDTH-1:0] din
            .rd_clk   ( rd_clk                  ),   //input [0:0] rd_clk
            .rd_en    ( rd_en && !empty         ),   //input [0:0] rd_en
            .raddr    ( raddr    [RA_WIDTH-1:0] ),   //input [RA_WIDTH-1:0] raddr
            .dout     ( outbuff0                )    //input [RD_WIDTH-1:0] dout
        );
    end
endgenerate

endmodule
