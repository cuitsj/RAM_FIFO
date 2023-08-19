// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Tue Sep 27 17:40:35 2022
// Host        : DESKTOP-7AAJRE5 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/xintu_work/ram/ram_ip/ram_ip.srcs/sources_1/ip/sdp_ram_ip/sdp_ram_ip_stub.v
// Design      : sdp_ram_ip
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1157-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module sdp_ram_ip(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[3:0],dina[15:0],clkb,enb,addrb[3:0],doutb[15:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [3:0]addra;
  input [15:0]dina;
  input clkb;
  input enb;
  input [3:0]addrb;
  output [15:0]doutb;
endmodule
