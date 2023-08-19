//------------------------------------------------------------------------
//Created By:sujin
//Create Date:2022/7/8
//Compiler Tool:
//Copyrights(C):
//Description:
//History:
//------------------------------------------------------------------------

//Mode introduction
//write_first:  During write operation, the output port outputs the data currently written.
//read_first:   During write operation, the output port outputs the original data of the current write address.
//no_change:    During write operation, the output port remains unchanged. The output port changes only during a read operation.

module tdp_ram#(
    //port A
    parameter WD_WIDTHA = 8,                //write data width
    parameter WA_DEPTHA = 4096,             //write address depth
    parameter RD_WIDTHA = 8,                //read data width
    parameter DELAYA = 0,                   //Select the clock period for delayed output. The value can be 0,1,2
    parameter MODEA = "write_first",        //write_first, read_first, no_change
    //port B
    parameter WD_WIDTHB = 8,                //write data width
    parameter WA_DEPTHB = 4096,             //write address depth
    parameter RD_WIDTHB = 8,                //read data width
    parameter DELAYB = 0,                   //Select the clock period for delayed output. The value can be 0,1,2
    parameter MODEB = "write_first",        //write_first, read_first, no_change
    parameter TYPE = "block"                //block,distributed
)(rst,clka,ena,wea,addra,dina,douta,clkb,enb,web,addrb,dinb,doutb);

localparam WD_MOVEA = $clog2(WD_WIDTHA);                                //write data width bits
localparam RD_MOVEA = $clog2(RD_WIDTHA);                                //read data width bits
localparam WA_WIDTHA = $clog2(WA_DEPTHA);                               //write address width
localparam RA_DEPTHA = WD_WIDTHA*WA_DEPTHA/RD_WIDTHA;                   //read address depth
localparam RA_WIDTHA = $clog2(RA_DEPTHA);                               //read address width
localparam DATAMAX_WIDTHA = WD_WIDTHA>=RD_WIDTHA?WD_WIDTHA:RD_WIDTHA;   //data width max
localparam ADDRMIN_WIDTHA = WA_WIDTHA<=RA_WIDTHA?WA_WIDTHA:RA_WIDTHA;   //address min width
localparam ADDRMAX_WIDTHA = WA_WIDTHA>=RA_WIDTHA?WA_WIDTHA:RA_WIDTHA;   //address max width
localparam AWIDTH_DIFA = WA_WIDTHA>=RA_WIDTHA?WA_WIDTHA-RA_WIDTHA:RA_WIDTHA-WA_WIDTHA;      //address width differential
localparam DWIDTH_MULA = WD_WIDTHA>=RD_WIDTHA?WD_WIDTHA/RD_WIDTHA:RD_WIDTHA/WD_WIDTHA;      //data width multiples

localparam WD_MOVEB = $clog2(WD_WIDTHB);                                //write data width bits
localparam RD_MOVEB = $clog2(RD_WIDTHB);                                //read data width bits
localparam WA_WIDTHB = $clog2(WA_DEPTHB);                               //write address width
localparam RA_DEPTHB = WD_WIDTHB*WA_DEPTHB/RD_WIDTHB;                   //read address depth
localparam RA_WIDTHB = $clog2(RA_DEPTHB);                               //read address width
localparam DATAMAX_WIDTHB = WD_WIDTHB>=RD_WIDTHB?WD_WIDTHB:RD_WIDTHB;   //data width max
localparam ADDRMIN_WIDTHB = WA_WIDTHB<=RA_WIDTHB?WA_WIDTHB:RA_WIDTHB;   //address min width
localparam ADDRMAX_WIDTHB = WA_WIDTHB>=RA_WIDTHB?WA_WIDTHB:RA_WIDTHB;   //address max width
localparam AWIDTH_DIFB = WA_WIDTHB>=RA_WIDTHB?WA_WIDTHB-RA_WIDTHB:RA_WIDTHB-WA_WIDTHB;      //address width differential
localparam DWIDTH_MULB = WD_WIDTHB>=RD_WIDTHB?WD_WIDTHB/RD_WIDTHB:RD_WIDTHB/WD_WIDTHB;      //data width multiples

localparam DATAMAX_WIDTHAB = DATAMAX_WIDTHA>=DATAMAX_WIDTHB?DATAMAX_WIDTHA:DATAMAX_WIDTHB;                                //data width max
localparam ADDRMIN_WIDTHAB = ADDRMIN_WIDTHA<=ADDRMIN_WIDTHB?ADDRMIN_WIDTHA:ADDRMIN_WIDTHB;                                //address min width
localparam AWIDTH_DIFAB = ADDRMIN_WIDTHA>=ADDRMIN_WIDTHB?ADDRMIN_WIDTHA-ADDRMIN_WIDTHB:ADDRMIN_WIDTHB-ADDRMIN_WIDTHA;     //address width differential
localparam DWIDTH_MULAB = DATAMAX_WIDTHA>=DATAMAX_WIDTHB?DATAMAX_WIDTHA/DATAMAX_WIDTHB:DATAMAX_WIDTHB/DATAMAX_WIDTHA;     //data width multiples

input                   rst;
input                   clka;
input                   ena;
input                   wea;
input [ADDRMAX_WIDTHA-1:0]  addra;
input [WD_WIDTHA-1:0]    dina;
output  [RD_WIDTHA-1:0]  douta;

input                   clkb;
input                   enb;
input                   web;
input [ADDRMAX_WIDTHB-1:0]  addrb;
input [WD_WIDTHB-1:0]    dinb;
output  [RD_WIDTHB-1:0]  doutb;

(*ram_style=TYPE*) reg [DATAMAX_WIDTHAB-1:0] ram [(2**ADDRMIN_WIDTHAB)-1:0];

//PORT A
generate
    if (DATAMAX_WIDTHA >= DATAMAX_WIDTHB) begin
        if (WD_WIDTHA == RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0];
                reg [RD_WIDTHA-1:0] routbuffa[DELAYA:0];

                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        if (wea) begin
                            ram[addra] <= dina;
                            woutbuffa[0] <= dina; 
                            for (i=1;i<=DELAYA;i=i+1) begin
                                woutbuffa[i] <= woutbuffa[i-1];
                            end  
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena && !wea) begin
                        routbuffa[0] <= ram[addra];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first
                reg [RD_WIDTHA-1:0] outbuffa[DELAYA:0];

                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        if (wea) begin
                            ram[addra] <= dina;
                        end
                        outbuffa[0] <= ram[addra];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= outbuffa[i-1];
                        end
                    end
                end

                assign douta = outbuffa[DELAYA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change
                reg [RD_WIDTHA-1:0] outbuffa[DELAYA:0];

                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        if (wea) begin
                            ram[addra] <= dina;
                        end
                        else begin
                            outbuffa[0] <= ram[addra];
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                    end
                end

                assign douta = outbuffa[DELAYA];
            end
        end
        else if (WD_WIDTHA > RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0];       //write out buff
                reg [WD_WIDTHA-1:0] routbuffa[DELAYA:0];       //read out buff
                reg [AWIDTH_DIFA-1:0] cnt;                     //Counting the number of splices
                wire [WA_WIDTHA-1:0] waddra;

                assign waddra = wea?addra[0+:WA_WIDTHA]:addra[AWIDTH_DIFA+:WA_WIDTHA];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        cnt <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        ram[waddra] <= dina;
                        cnt <= cnt + 1;
                        woutbuffa[0] <= dina[((cnt+0)<<RD_MOVEA)+:RD_WIDTHA];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena && !wea) begin
                        routbuffa[0] <= ram[waddra];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:AWIDTH_DIFA]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first 
                reg [AWIDTH_DIFA-1:0] cnt;                     //Counting the number of splices
                reg [WD_WIDTHA-1:0] outbuffa[DELAYA:0];       //read out buff
                wire [WA_WIDTHA-1:0] waddra;

                assign waddra = wea?addra[0+:WA_WIDTHA]:addra[AWIDTH_DIFA+:WA_WIDTHA];
                //write data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        cnt <= 0;
                    end
                    else if (ena && wea) begin
                        ram[waddra] <= dina;
                        cnt <= cnt + 1;
                    end

                end

                //read data and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            outbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        outbuffa[0] <= ram[waddra];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            outbuffa[j] <= outbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?outbuffa[DELAYA][((cnt+0)<<RD_MOVEA)+:RD_WIDTHA]:outbuffa[DELAYA][((addra[0+:AWIDTH_DIFA]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change 
                reg [WD_WIDTHA-1:0] outbuffa[DELAYA:0];
                wire [WA_WIDTHA-1:0] waddra;

                assign waddra = wea?addra[0+:WA_WIDTHA]:addra[AWIDTH_DIFA+:WA_WIDTHA];

                //write read and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        if (wea) begin
                            ram[waddra] <= dina;
                        end
                        else begin
                            outbuffa[0] <= ram[waddra];
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                    end
                end

                assign douta = outbuffa[DELAYA][((addra[0+:AWIDTH_DIFA]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
        end
        else if (WD_WIDTHA < RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [RD_WIDTHA-1:0] write_buff0;
                reg [RD_WIDTHA-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [RD_WIDTHA-1:0] routbuffa[DELAYA:0]; 
                wire [RA_WIDTHA-1:0] raddra;

                assign raddra = wea?addra[AWIDTH_DIFA+:RA_WIDTHA]:addra[0+:RA_WIDTHA];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFA]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[raddra] <= routbuffa[0]&write_buff0|write_buff1;
                        woutbuffa[0][0+:WD_WIDTHA] <= dina;
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer k=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (k=0;k<=DELAYA;k=k+1) begin
                            routbuffa[k] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[raddra];
                        for (k=1;k<=DELAYA;k=k+1) begin
                            routbuffa[k] <= routbuffa[k-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first 
                reg [RD_WIDTHA-1:0] write_buff0;
                reg [RD_WIDTHA-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0];
                reg [RD_WIDTHA-1:0] routbuffa[DELAYA:0];
                wire [RA_WIDTHA-1:0] raddra;

                assign raddra = wea?addra[AWIDTH_DIFA+:RA_WIDTHA]:addra[0+:RA_WIDTHA];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULA;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFA]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[raddra] <= routbuffa[0]&write_buff0|write_buff1;
                        woutbuffa[0] <= routbuffa[0][((addra[0+:AWIDTH_DIFA]+0)<<WD_MOVEA)+:WD_WIDTHA];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[raddra];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change 
                reg [RD_WIDTHA-1:0] write_buff0;
                reg [RD_WIDTHA-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] outbuffa[DELAYA:0]; 
                wire [RA_WIDTHA-1:0] raddra;

                assign raddra = wea?addra[AWIDTH_DIFA+:RA_WIDTHA]:addra[0+:RA_WIDTHA];
                //write read and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        outbuffa[0] <= ram[raddra];
                        if (wea) begin
                            for (i=0;i<DWIDTH_MULA;i=i+1) begin
                                if (i == addra[0+:AWIDTH_DIFA]) begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                end
                            end
                            ram[raddra] <= outbuffa[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                    end
                end

                assign douta = outbuffa[DELAYA];
            end
        end
    end
    else if (DATAMAX_WIDTHA < DATAMAX_WIDTHB) begin
        if (WD_WIDTHA == RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];

                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addra>>AWIDTH_DIFAB] <= routbuffa[0]&write_buff0|write_buff1;
                        woutbuffa[0] <= dina;
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addra>>AWIDTH_DIFAB];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0];
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];

                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addra>>AWIDTH_DIFAB] <= routbuffa[0]&write_buff0|write_buff1;
                        woutbuffa[0] <= routbuffa[0][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addra>>AWIDTH_DIFAB];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] outbuffa[DELAYA:0];

                //write read and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        outbuffa[0] <= ram[addra>>AWIDTH_DIFAB];
                        if (wea) begin
                            for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                                if (i == addra[0+:AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                end
                            end
                            ram[addra>>AWIDTH_DIFAB] <= outbuffa[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                    end
                end

                assign douta = outbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
        end
        else if (WD_WIDTHA > RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFA-1:0] cnt;                           //Counting the number of splices
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffa[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        woutbuffa[0] <= dina[((cnt+0)<<RD_MOVEA)+:RD_WIDTHA];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:(AWIDTH_DIFA+AWIDTH_DIFAB)]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFA-1:0] cnt;                           //Counting the number of splices
                reg [WD_WIDTHA-1:0] read_buff;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        read_buff <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffa[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        if (cnt == 0) begin
                            read_buff <= routbuffa[0][((addra[0+:AWIDTH_DIFAB]+0)<<WD_MOVEA)+:WD_WIDTHA];
                            woutbuffa[0] <= routbuffa[0][((addra[0+:AWIDTH_DIFAB]+0)<<WD_MOVEA)+:RD_WIDTHA];
                        end
                        else begin
                            woutbuffa[0] <= read_buff[((cnt+0)<<RD_MOVEA)+:RD_WIDTHA];
                        end
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:(AWIDTH_DIFA+AWIDTH_DIFAB)]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [DATAMAX_WIDTHAB-1:0] outbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write read and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        outbuffa[0] <= ram[addr_buff];
                        if (wea) begin
                            for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                                if (i == addra[0+:AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                end
                            end
                            ram[addr_buff] <= outbuffa[0]&write_buff0|write_buff1;
                        end
                        else begin
                            
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                    end
                end
                assign douta = outbuffa[DELAYA][((addra[0+:(AWIDTH_DIFA+AWIDTH_DIFAB)]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
        end
        else if (WD_WIDTHA < RD_WIDTHA) begin
            //During a write operation, the output port outputs the data currently written.
            if (MODEA == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFA-1:0] cnt;                           //Counting the number of splices
                reg [RD_WIDTHA-1:0] read_buff;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB]:addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        read_buff <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULA*DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFA+AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffa[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        read_buff[((cnt+0)<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                        if (cnt == {AWIDTH_DIFA{1'b1}}) begin
                            for (i=0;i<cnt;i=i+1) begin
                                woutbuffa[0][(i<<WD_MOVEA)+:WD_WIDTHA] <= read_buff[(i<<WD_MOVEA)+:WD_WIDTHA];
                            end
                            woutbuffa[0][((cnt+0)<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                        end
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During the write operation, the output port outputs the original data of the current write address.
            else if (MODEA == "read_first") begin: read_first 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHA-1:0] woutbuffa[DELAYA:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB]:addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB];
                //write and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= 0;
                        end
                    end
                    else if (ena && wea) begin
                        for (i=0;i<DWIDTH_MULA*DWIDTH_MULAB;i=i+1) begin
                            if (i == addra[0+:AWIDTH_DIFA+AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffa[0]&write_buff0|write_buff1;
                        woutbuffa[0] <= routbuffa[0][((addra[0+:AWIDTH_DIFA+AWIDTH_DIFAB]+0)<<WD_MOVEA)+:WD_WIDTHA];
                        for (i=1;i<=DELAYA;i=i+1) begin
                            woutbuffa[i] <= woutbuffa[i-1];
                        end
                    end
                end

                //read and output data
                integer j=0;
                always @(posedge clka) begin
                    if (rst) begin
                        for (j=0;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= 0;
                        end
                    end
                    else if (ena) begin
                        routbuffa[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYA;j=j+1) begin
                            routbuffa[j] <= routbuffa[j-1];
                        end
                    end
                end

                assign douta = wea?woutbuffa[DELAYA]:routbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
            //During write operations, the output port remains unchanged. The output port changes only during a read operation.
            else if (MODEA == "no_change") begin: no_change 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [DATAMAX_WIDTHAB-1:0] outbuffa[DELAYA:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = wea?addra[(AWIDTH_DIFA+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB]:addra[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB];
                //write read and output data
                integer i=0;
                always @(posedge clka) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYA;i=i+1) begin
                            outbuffa[i] <= 0;
                        end
                    end
                    else if (ena) begin
                        outbuffa[0] <= ram[addr_buff];
                        if (wea) begin
                            for (i=0;i<DWIDTH_MULA*DWIDTH_MULAB;i=i+1) begin
                                if (i == addra[0+:AWIDTH_DIFA+AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= dina;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b1}};
                                    write_buff1[(i<<WD_MOVEA)+:WD_WIDTHA] <= {WD_WIDTHA{1'b0}};
                                end
                            end
                            ram[addr_buff] <= outbuffa[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYA;i=i+1) begin
                                outbuffa[i] <= outbuffa[i-1];
                            end
                        end
                        
                    end
                end

                assign douta = outbuffa[DELAYA][((addra[0+:AWIDTH_DIFAB]+0)<<RD_MOVEA)+:RD_WIDTHA];
            end
        end
    end
endgenerate

//PORT B
generate
    if (DATAMAX_WIDTHB >= DATAMAX_WIDTHA) begin
        if (WD_WIDTHB == RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0];
                reg [RD_WIDTHB-1:0] routbuffb[DELAYB:0];

                //write and output data
                integer i=0;  
                always @(posedge clkb) begin
                    if (rst) begin
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                            ram[addrb] <= dinb;
                            woutbuffb[0] <= dinb; 
                            for (i=1;i<=DELAYB;i=i+1) begin
                                woutbuffb[i] <= woutbuffb[i-1];
                            end
                    end
                end

                //read and output data
                integer j=0;  
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb && !web) begin
                        routbuffb[0] <= ram[addrb];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first
                reg [RD_WIDTHB-1:0] outbuffb[DELAYB:0];

                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        if (web) begin
                            ram[addrb] <= dinb;
                        end
                        outbuffb[0] <= ram[addrb];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= outbuffb[i-1];
                        end
                    end
                end

                assign doutb = outbuffb[DELAYB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change
                reg [RD_WIDTHB-1:0] outbuffb[DELAYB:0];

                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        if (web) begin
                            ram[addrb] <= dinb;
                        end
                        else begin
                            outbuffb[0] <= ram[addrb];
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                    end
                end

                assign doutb = outbuffb[DELAYB];
            end
        end
        else if (WD_WIDTHB > RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0];       //write out buff
                reg [WD_WIDTHB-1:0] routbuffb[DELAYB:0];       //read out buff
                reg [AWIDTH_DIFB-1:0] cnt;                           //Aounting the number of splices
                wire [WA_WIDTHB-1:0] waddrb;

                assign waddrb = web?addrb[0+:WA_WIDTHB]:addrb[AWIDTH_DIFB+:WA_WIDTHB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        cnt <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        ram[waddrb] <= dinb;
                        cnt <= cnt + 1;
                        woutbuffb[0] <= dinb[((cnt+0)<<RD_MOVEB)+:RD_WIDTHB];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb && !web) begin
                        routbuffb[0] <= ram[waddrb];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:AWIDTH_DIFB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first 
                reg [AWIDTH_DIFB-1:0] cnt;                     //Aounting the number of splices
                reg [WD_WIDTHB-1:0] outbuffb[DELAYB:0];       //read out buff
                wire [WA_WIDTHB-1:0] waddrb;

                assign waddrb = web?addrb[0+:WA_WIDTHB]:addrb[AWIDTH_DIFB+:WA_WIDTHB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        cnt <= 0;
                    end
                    else if (enb && web) begin
                        ram[waddrb] <= dinb;
                        cnt <= cnt + 1;
                    end
                end

                //read data bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            outbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        outbuffb[0] <= ram[waddrb];
                         for (j=1;j<=DELAYB;j=j+1) begin
                            outbuffb[j] <= outbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?outbuffb[DELAYB][((cnt+0)<<RD_MOVEB)+:RD_WIDTHB]:outbuffb[DELAYB][((addrb[0+:AWIDTH_DIFB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change 
                reg [WD_WIDTHB-1:0] outbuffb[DELAYB:0];
                wire [WA_WIDTHB-1:0] waddrb;

                assign waddrb = web?addrb[0+:WA_WIDTHB]:addrb[AWIDTH_DIFB+:WA_WIDTHB];
                //write read bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        if (web) begin
                            ram[waddrb] <= dinb;
                        end
                        else begin
                            outbuffb[0] <= ram[waddrb];
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                    end
                end

                assign doutb = outbuffb[DELAYB][((addrb[0+:AWIDTH_DIFB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
        end
        else if (WD_WIDTHB < RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [RD_WIDTHB-1:0] write_buff0;
                reg [RD_WIDTHB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [RD_WIDTHB-1:0] routbuffb[DELAYB:0]; 
                wire [RA_WIDTHB-1:0] raddrb;

                assign raddrb = web?addrb[AWIDTH_DIFB+:RA_WIDTHB]:addrb[0+:RA_WIDTHB];
                //write and output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[raddrb] <= routbuffb[0]&write_buff0|write_buff1;
                        woutbuffb[0][0+:WD_WIDTHB] <= dinb;
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer k=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (k=0;k<=DELAYB;k=k+1) begin
                            routbuffb[k] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[raddrb];
                        for (k=1;k<=DELAYB;k=k+1) begin
                            routbuffb[k] <= routbuffb[k-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first 
                reg [RD_WIDTHB-1:0] write_buff0;
                reg [RD_WIDTHB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0];
                reg [RD_WIDTHB-1:0] routbuffb[DELAYB:0];
                wire [RA_WIDTHB-1:0] raddrb;

                assign raddrb = web?addrb[AWIDTH_DIFB+:RA_WIDTHB]:addrb[0+:RA_WIDTHB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[raddrb] <= routbuffb[0]&write_buff0|write_buff1;
                        woutbuffb[0] <= routbuffb[0][((addrb[0+:AWIDTH_DIFB]+0)<<WD_MOVEB)+:WD_WIDTHB];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[raddrb];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change 
                reg [RD_WIDTHB-1:0] write_buff0;
                reg [RD_WIDTHB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] outbuffb[DELAYB:0]; 
                wire [RA_WIDTHB-1:0] raddrb;

                assign raddrb = web?addrb[AWIDTH_DIFB+:RA_WIDTHB]:addrb[0+:RA_WIDTHB];
                //write read bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        outbuffb[0] <= ram[raddrb];
                        if (web) begin
                            for (i=0;i<DWIDTH_MULB;i=i+1) begin
                                if (i == addrb[0+:AWIDTH_DIFB]) begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                end
                            end
                            ram[raddrb] <= outbuffb[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                    end
                end

                assign doutb = outbuffb[DELAYB];
            end
        end
    end
    else if (DATAMAX_WIDTHB < DATAMAX_WIDTHA) begin
        if (WD_WIDTHB == RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];

                //write and output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addrb>>AWIDTH_DIFAB] <= routbuffb[0]&write_buff0|write_buff1;
                        woutbuffb[0] <= dinb;
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addrb>>AWIDTH_DIFAB];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0];
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];

                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addrb>>AWIDTH_DIFAB] <= routbuffb[0]&write_buff0|write_buff1;
                        woutbuffb[0] <= routbuffb[0][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addrb>>AWIDTH_DIFAB];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] outbuffb[DELAYB:0];

                //write read bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        outbuffb[0] <= ram[addrb>>AWIDTH_DIFAB];
                        if (web) begin
                            for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                                if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                end
                            end
                            ram[addrb>>AWIDTH_DIFAB] <= outbuffb[0]&write_buff0|write_buff1;
                        end
                        else begin
                            
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                    end
                end

                assign doutb = outbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
        end
        else if (WD_WIDTHB > RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFB-1:0] cnt;                           //Aounting the number of splices
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addrb[(AWIDTH_DIFB+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffb[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        woutbuffb[0] <= dinb[((cnt+0)<<RD_MOVEB)+:RD_WIDTHB];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:(AWIDTH_DIFB+AWIDTH_DIFAB)]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFB-1:0] cnt;                           //Aounting the number of splices
                reg [WD_WIDTHB-1:0] read_buff;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addrb[(AWIDTH_DIFB+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        read_buff <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffb[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        if (cnt == 0) begin
                            read_buff <= routbuffb[0][((addrb[0+:AWIDTH_DIFAB]+0)<<WD_MOVEB)+:WD_WIDTHB];
                            woutbuffb[0] <= routbuffb[0][((addrb[0+:AWIDTH_DIFAB]+0)<<WD_MOVEB)+:RD_WIDTHB];
                        end
                        else begin
                            woutbuffb[0] <= read_buff[((cnt+0)<<RD_MOVEB)+:RD_WIDTHB];
                        end
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:(AWIDTH_DIFB+AWIDTH_DIFAB)]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [DATAMAX_WIDTHAB-1:0] outbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB]:addrb[(AWIDTH_DIFB+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB];
                //write read bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        outbuffb[0] <= ram[addr_buff];
                        if (web) begin
                            for (i=0;i<DWIDTH_MULAB;i=i+1) begin
                                if (i == addrb[0+:AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                end
                            end
                            ram[addr_buff] <= outbuffb[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                    end
                end
                assign doutb = outbuffb[DELAYB][((addrb[0+:(AWIDTH_DIFB+AWIDTH_DIFAB)]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
        end
        else if (WD_WIDTHB < RD_WIDTHB) begin
            //During b write operbtion, the output port outputs the data currently written.
            if (MODEB == "write_first") begin: write_first
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [AWIDTH_DIFB-1:0] cnt;                           //Aounting the number of splices
                reg [RD_WIDTHB-1:0] read_buff;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb[(AWIDTH_DIFB+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB]:addrb[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        cnt <= 0;
                        read_buff <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULB*DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFB+AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffb[0]&write_buff0|write_buff1;
                        cnt <= cnt + 1;
                        read_buff[((cnt+0)<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                        if (cnt == {AWIDTH_DIFB{1'b1}}) begin
                            for (i=0;i<cnt;i=i+1) begin
                                woutbuffb[0][(i<<WD_MOVEB)+:WD_WIDTHB] <= read_buff[(i<<WD_MOVEB)+:WD_WIDTHB];
                            end
                            woutbuffb[0][((cnt+0)<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                        end
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During the write operbtion, the output port outputs the originbl data of the current write bddress.
            else if (MODEB == "read_first") begin: read_first 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [RD_WIDTHB-1:0] woutbuffb[DELAYB:0]; 
                reg [DATAMAX_WIDTHAB-1:0] routbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb[(AWIDTH_DIFB+AWIDTH_DIFAB)+:ADDRMIN_WIDTHAB]:addrb[AWIDTH_DIFAB+:ADDRMIN_WIDTHAB];
                //write bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= 0;
                        end
                    end
                    else if (enb && web) begin
                        for (i=0;i<DWIDTH_MULB*DWIDTH_MULAB;i=i+1) begin
                            if (i == addrb[0+:AWIDTH_DIFB+AWIDTH_DIFAB]) begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                            end
                            else begin
                                write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                            end
                        end
                        ram[addr_buff] <= routbuffb[0]&write_buff0|write_buff1;
                        woutbuffb[0] <= routbuffb[0][((addrb[0+:AWIDTH_DIFB+AWIDTH_DIFAB]+0)<<WD_MOVEB)+:WD_WIDTHB];
                        for (i=1;i<=DELAYB;i=i+1) begin
                            woutbuffb[i] <= woutbuffb[i-1];
                        end
                    end
                end

                //read bnd output data
                integer j=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        for (j=0;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= 0;
                        end
                    end
                    else if (enb) begin
                        routbuffb[0] <= ram[addr_buff];
                        for (j=1;j<=DELAYB;j=j+1) begin
                            routbuffb[j] <= routbuffb[j-1];
                        end
                    end
                end

                assign doutb = web?woutbuffb[DELAYB]:routbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
            //During write operbtions, the output port rembins unchanged. The output port changes only during b read operbtion.
            else if (MODEB == "no_change") begin: no_change 
                reg [DATAMAX_WIDTHAB-1:0] write_buff0;
                reg [DATAMAX_WIDTHAB-1:0] write_buff1;
                reg [DATAMAX_WIDTHAB-1:0] outbuffb[DELAYB:0];
                wire [ADDRMIN_WIDTHAB-1:0] addr_buff;

                assign addr_buff = web?addrb>>AWIDTH_DIFB+AWIDTH_DIFAB:addrb>>AWIDTH_DIFAB;
                //write read bnd output data
                integer i=0;
                always @(posedge clkb) begin
                    if (rst) begin
                        write_buff0 <= 0;
                        write_buff1 <= 0;
                        for (i=0;i<=DELAYB;i=i+1) begin
                            outbuffb[i] <= 0;
                        end
                    end
                    else if (enb) begin
                        outbuffb[0] <= ram[addr_buff];
                        if (web) begin
                            for (i=0;i<DWIDTH_MULB*DWIDTH_MULAB;i=i+1) begin
                                if (i == addrb[0+:AWIDTH_DIFB+AWIDTH_DIFAB]) begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= dinb;
                                end
                                else begin
                                    write_buff0[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b1}};
                                    write_buff1[(i<<WD_MOVEB)+:WD_WIDTHB] <= {WD_WIDTHB{1'b0}};
                                end
                            end
                            ram[addr_buff] <= outbuffb[0]&write_buff0|write_buff1;
                        end
                        else begin
                            for (i=1;i<=DELAYB;i=i+1) begin
                                outbuffb[i] <= outbuffb[i-1];
                            end
                        end
                        
                    end
                end

                assign doutb = outbuffb[DELAYB][((addrb[0+:AWIDTH_DIFAB]+0)<<RD_MOVEB)+:RD_WIDTHB];
            end
        end
    end
endgenerate

endmodule