//------------------------------------------------------------------------
//Created By:sujin
//Create Date:2022/07/08
//Compiler Tool:
//Copyrights(C):
//Description:
//History:
//------------------------------------------------------------------------

//Mode introduction
//write_first:  During write operation, the output port outputs the data currently written.
//read_first:   During write operation, ththe output port outputs the original data of e current write address.
//no_change:    During write operation, the output port remains unchanged. The output port changes only during a read operation.

module sp_ram#(
    parameter WD_WIDTH = 8,             //write data width
    parameter WA_DEPTH = 4096,          //write address depth
    parameter RD_WIDTH = 8,             //read data width
    parameter DELAY = 0,                //Select the clock period for delayed output. The value can be 0,1,2
    parameter MODE = "write_first",     //write_first, read_first, no_change
    parameter TYPE = "block"            //block,distributed
)(rst,clk,en,we,addr,din,dout);

localparam WD_MOVE = $clog2(WD_WIDTH);                          //write data width bits
localparam RD_MOVE = $clog2(RD_WIDTH);                          //read data width bits
localparam WA_WIDTH = $clog2(WA_DEPTH);                         //write address width
localparam RA_DEPTH = WD_WIDTH*WA_DEPTH/RD_WIDTH;               //read address depth
localparam RA_WIDTH = $clog2(RA_DEPTH);                         //read address width
localparam DATA_WIDTH = WD_WIDTH>=RD_WIDTH?WD_WIDTH:RD_WIDTH;   //data width
localparam ADDRMIN_WIDTH = WA_WIDTH<=RA_WIDTH?WA_WIDTH:RA_WIDTH;    //address min width
localparam ADDRMAX_WIDTH = WA_WIDTH>=RA_WIDTH?WA_WIDTH:RA_WIDTH;    //address max width
localparam AWIDTH_DIF = WA_WIDTH>=RA_WIDTH?WA_WIDTH-RA_WIDTH:RA_WIDTH-WA_WIDTH; //address width differential
localparam DWIDTH_MUL = WD_WIDTH>=RD_WIDTH?WD_WIDTH/RD_WIDTH:RD_WIDTH/WD_WIDTH; //data width multiples

input                       rst;
input                       clk;
input                       en;
input                       we;
input [ADDRMAX_WIDTH-1:0]   addr;
input [WD_WIDTH-1:0]        din;
output  [RD_WIDTH-1:0]      dout;

(*ram_style=TYPE*)reg [DATA_WIDTH-1:0] ram [(2**ADDRMIN_WIDTH)-1:0];

generate
    if (WD_WIDTH == RD_WIDTH) begin
        //During a write operation, the output port outputs the data currently written.
        if (MODE == "write_first") begin: write_first
            reg [RD_WIDTH-1:0] outbuff[DELAY:0];
            
            //write data
            always @(posedge clk) begin
                if (en && we) begin
                    ram[addr] <= din;
                end
            end
            
            //read and output data
            integer i=0;  
            always @(posedge clk) begin
                if (rst) begin
                    for (i=0;i<=DELAY;i=i+1) begin
                        outbuff[i] <= 0;
                    end
                end
                else if (en) begin
                    if (we) begin
                        outbuff[0] <= din;
                    end
                    else begin
                        outbuff[0] <= ram[addr];
                    end
                    for (i=1;i<=DELAY;i=i+1) begin
                        outbuff[i] <= outbuff[i-1];
                    end
                end
            end
            assign dout = outbuff[DELAY];
        end
        //During the write operation, the output port outputs the original data of the current write address.
        else if (MODE == "read_first") begin: read_first 
            reg [RD_WIDTH-1:0] outbuff[DELAY:0];

            //write data
            always @(posedge clk) begin
                if (en && we) begin
                    ram[addr] <= din;
                end
            end

            //read and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (i=0;i<=DELAY;i=i+1) begin
                        outbuff[i] <= 0;
                    end
                end
                else if (en) begin
                    outbuff[0] <= ram[addr];
                    for (i=1;i<=DELAY;i=i+1) begin
                        outbuff[i] <= outbuff[i-1];
                    end
                end
            end
            assign dout = outbuff[DELAY];
        end
        //During write operations, the output port remains unchanged. The output port changes only during a read operation.
        else if (MODE == "no_change") begin: no_change  
            reg [RD_WIDTH-1:0] outbuff[DELAY:0]; 

            //write data
            always @(posedge clk) begin
                if (en && we) begin
                    ram[addr] <= din;
                end
            end

            //read and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (i=0;i<=DELAY;i=i+1) begin
                        outbuff[i] <= 0;
                    end
                end
                else if (en) begin
                    if (!we) begin
                        outbuff[0] <= ram[addr];
                        for (i=1;i<=DELAY;i=i+1) begin
                            outbuff[i] <= outbuff[i-1];
                        end
                    end
                end
            end
            assign dout = outbuff[DELAY];
        end
    end
    else if (WD_WIDTH > RD_WIDTH) begin
        //During a write operation, the output port outputs the data currently written.
        if (MODE == "write_first") begin: write_first
            reg [RD_WIDTH-1:0] woutbuff[DELAY:0];       //write out buff
            reg [WD_WIDTH-1:0] routbuff[DELAY:0];       //read out buff
            reg [AWIDTH_DIF-1:0] cnt;                   //Counting the number of splices

            //write and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= 0;
                    for (i=0;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= 0;
                    end
                end
                else if (en && we) begin
                    ram[addr] <= din;
                    cnt <= cnt + 1;
                    woutbuff[0] <= din[((cnt+0)<<RD_MOVE)+:RD_WIDTH];
                    for (i=1;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= woutbuff[i-1];
                    end
                end
            end

            //read and output data
            integer j=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (j=0;j<=DELAY;j=j+1) begin
                        routbuff[j] <= 0;
                    end
                end
                else if (en && !we) begin
                    routbuff[0] <= ram[addr>>AWIDTH_DIF];
                    for (j=1;j<=DELAY;j=j+1) begin
                        routbuff[j] <= routbuff[j-1];
                    end
                end
            end
            
            assign dout = we?woutbuff[DELAY]:routbuff[DELAY][((addr[0+:AWIDTH_DIF]+0)<<RD_MOVE)+:RD_WIDTH];
        end
        //During the write operation, the output port outputs the original data of the current write address.
        else if (MODE == "read_first") begin: read_first 
            reg [WD_WIDTH-1:0] woutbuff[DELAY:0];       //write out buff
            reg [WD_WIDTH-1:0] routbuff[DELAY:0];       //read out buff
            reg [AWIDTH_DIF-1:0] cnt;                   //Counting the number of splices

            //write and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    cnt <= 0;
                    for (i=0;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= 0;
                    end
                end
                else if (en && we) begin
                    ram[addr] <= din;
                    cnt <= cnt + 1;
                    if (cnt == 0) begin
                        woutbuff[0] <= ram[addr];
                    end
                    for (i=1;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= woutbuff[i-1];
                    end
                end
            end

            //read and output data
            integer j=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (j=0;j<=DELAY;j=j+1) begin
                        routbuff[j] <= 0;
                    end
                end
                else if (en && !we) begin
                    routbuff[0] <= ram[addr>>AWIDTH_DIF];
                    for (j=1;j<=DELAY;j=j+1) begin
                        routbuff[j] <= routbuff[j-1];
                    end
                end
            end
            assign dout = we?woutbuff[DELAY][((cnt+0)<<RD_MOVE)+:RD_WIDTH]:routbuff[DELAY][((addr[0+:AWIDTH_DIF]+0)<<RD_MOVE)+:RD_WIDTH];
        end
        //During write operations, the output port remains unchanged. The output port changes only during a read operation.
        else if (MODE == "no_change") begin: no_change 
            reg [WD_WIDTH-1:0] outbuff[DELAY:0]; 
            
            //write read output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (i=0;i<=DELAY;i=i+1) begin
                        outbuff[i] <= 0;
                    end
                end
                else if (en) begin
                    if (we) begin
                        ram[addr] <= din;
                    end
                    else begin
                        outbuff[0] <= ram[addr>>AWIDTH_DIF];
                        for (i=1;i<=DELAY;i=i+1) begin
                            outbuff[i] <= outbuff[i-1];
                        end
                    end
                end
            end
            assign dout = outbuff[DELAY][((addr[0+:AWIDTH_DIF]+0)<<RD_MOVE)+:RD_WIDTH];
        end
    end
    else if (WD_WIDTH < RD_WIDTH) begin
        //During a write operation, the output port outputs the data currently written.
        if (MODE == "write_first") begin: write_first
            reg [AWIDTH_DIF-1:0] cnt;                           //Counting the number of splices
            reg [RD_WIDTH-1:0] write_buff0;
            reg [RD_WIDTH-1:0] write_buff1;
            reg [RD_WIDTH-1:0] read_buff;
            reg [RD_WIDTH-1:0] woutbuff[DELAY:0]; 
            reg [RD_WIDTH-1:0] routbuff[DELAY:0]; 
            reg [RA_WIDTH-1:0] waddr_buff;
            wire [RA_WIDTH-1:0] raddr_buff;

            assign raddr_buff = we?addr[AWIDTH_DIF+:RA_WIDTH]:addr[0+:RA_WIDTH];
            //write data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    write_buff0 <= 0;
                    write_buff1 <= 0;
                    cnt <= 0;
                    read_buff <= 0;
                    waddr_buff <= 0;
                end
                else if (en && we) begin
                    for (i=0;i<DWIDTH_MUL;i=i+1) begin
                        if (i == addr[0+:AWIDTH_DIF]) begin
                            write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                            write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= din;
                        end
                        else begin
                            write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b1}};
                            write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                        end
                    end
                    waddr_buff <= addr>>AWIDTH_DIF;
                    ram[waddr_buff] <= routbuff[0]&write_buff0|write_buff1;
                    cnt <= cnt + 1;
                    read_buff[((cnt+0)<<WD_MOVE)+:WD_WIDTH] <= din;//Splicing the write data
                end
            end

            //output write data
            integer j=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (j=0;j<=DELAY;j=j+1) begin
                        woutbuff[j] <= 0;
                    end
                end
                else if (en && we && cnt=={AWIDTH_DIF{1'b1}}) begin
                    for (j=0;j<cnt;j=j+1) begin
                        woutbuff[0][(j<<WD_MOVE)+:WD_WIDTH] <= read_buff[(j<<WD_MOVE)+:WD_WIDTH];
                    end
                    woutbuff[0][((cnt+0)<<WD_MOVE)+:WD_WIDTH] <= din;
                    for (j=1;j<=DELAY;j=j+1) begin
                        woutbuff[j] <= woutbuff[j-1];
                    end
                end
            end

            //read and output data
            integer k=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (k=0;k<=DELAY;k=k+1) begin
                        routbuff[k] <= 0;
                    end
                end
                else if (en) begin
                    routbuff[0] <= ram[raddr_buff];
                    for (k=1;k<=DELAY;k=k+1) begin
                        routbuff[k] <= routbuff[k-1];
                    end
                end
            end

            assign dout = we?woutbuff[DELAY]:routbuff[DELAY];
        end
        //During the write operation, the output port outputs the original data of the current write address.
        else if (MODE == "read_first") begin: read_first 
            reg [RD_WIDTH-1:0] write_buff0;
            reg [RD_WIDTH-1:0] write_buff1;
            reg [RD_WIDTH-1:0] woutbuff[DELAY:0];
            reg [RD_WIDTH-1:0] routbuff[DELAY:0];
            reg [RA_WIDTH-1:0] waddr_buff;
            wire [RA_WIDTH-1:0] raddr_buff;

            assign raddr_buff = we?addr[AWIDTH_DIF+:RA_WIDTH]:addr[0+:RA_WIDTH];
            //write and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    write_buff0 <= 0;
                    write_buff1 <= 0;
                    waddr_buff <= 0;
                    for (i=0;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= 0;
                    end
                end
                else if (en && we) begin
                    waddr_buff <= addr>>AWIDTH_DIF;
                    for (i=0;i<DWIDTH_MUL;i=i+1) begin
                        if (i == addr[0+:AWIDTH_DIF]) begin
                            write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                            write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= din;
                        end
                        else begin
                            write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b1}};
                            write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                        end
                    end
                    ram[waddr_buff] <= routbuff[0]&write_buff0|write_buff1;
                    woutbuff[0] <= routbuff[0][((addr[0+:AWIDTH_DIF]+0)<<WD_MOVE)+:WD_WIDTH];
                    for (i=1;i<=DELAY;i=i+1) begin
                        woutbuff[i] <= woutbuff[i-1];
                    end
                end
            end

            //read and output data
            integer j=0;
            always @(posedge clk) begin
                if (rst) begin
                    for (j=0;j<=DELAY;j=j+1) begin
                        routbuff[j] <= 0;
                    end
                end
                else if (en) begin
                    routbuff[0] <= ram[raddr_buff];
                    for (j=1;j<=DELAY;j=j+1) begin
                        routbuff[j] <= routbuff[j-1];
                    end
                end
            end

            assign dout = we?woutbuff[DELAY]:routbuff[DELAY];
        end
        //During write operations, the output port remains unchanged. The output port changes only during a read operation.
        else if (MODE == "no_change") begin: no_change 
            reg [RD_WIDTH-1:0] write_buff0;
            reg [RD_WIDTH-1:0] write_buff1;
            reg [RD_WIDTH-1:0] outbuff[DELAY:0]; 
            reg [RA_WIDTH-1:0] waddr_buff;
            wire [RA_WIDTH-1:0] raddr_buff;

            assign raddr_buff = we?addr[AWIDTH_DIF+:RA_WIDTH]:addr[0+:RA_WIDTH];

            //write read and output data
            integer i=0;
            always @(posedge clk) begin
                if (rst) begin
                    write_buff0 <= 0;
                    write_buff1 <= 0;
                    waddr_buff <= 0;
                    for (i=0;i<=DELAY;i=i+1) begin
                        outbuff[i] <= 0;
                    end
                end
                else if (en) begin
                    outbuff[0] <= ram[raddr_buff];
                    if (we) begin
                        waddr_buff <= addr>>AWIDTH_DIF;
                        for (i=0;i<DWIDTH_MUL;i=i+1) begin
                            if (i == addr[0+:AWIDTH_DIF]) begin
                                write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                                write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= din;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b1}};
                                write_buff1[(i<<WD_MOVE)+:WD_WIDTH] <= {WD_WIDTH{1'b0}};
                            end
                        end
                        ram[waddr_buff] <= outbuff[0]&write_buff0|write_buff1;
                    end
                    else begin
                        
                        for (i=1;i<=DELAY;i=i+1) begin
                            outbuff[i] <= outbuff[i-1];
                        end
                    end
                end
            end

            assign dout = outbuff[DELAY];
        end
    end

endgenerate

endmodule
