// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Fri Oct 14 10:02:56 2022
// Host        : DESKTOP-7AAJRE5 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               E:/xintu_work/ram/ram_ip/ram_ip.srcs/sources_1/ip/tdp_ram_ip/tdp_ram_ip_stub.v
// Design      : tdp_ram_ip
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1157-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module tdp_ram_ip(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[11:0],dina[7:0],douta[3:0],clkb,enb,web[0:0],addrb[11:0],dinb[7:0],doutb[3:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [11:0]addra;
  input [7:0]dina;
  output [3:0]douta;
  input clkb;
  input enb;
  input [0:0]web;
  input [11:0]addrb;
  input [7:0]dinb;
  output [3:0]doutb;
endmodule
