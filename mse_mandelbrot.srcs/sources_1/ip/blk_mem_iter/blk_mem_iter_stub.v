// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Mon May 28 21:32:53 2018
// Host        : quartus running 64-bit Debian GNU/Linux 9.3 (stretch)
// Command     : write_verilog -force -mode synth_stub
//               /home/quartus/workspace/LPSC/mse_mandelbrot.srcs/sources_1/ip/blk_mem_iter/blk_mem_iter_stub.v
// Design      : blk_mem_iter
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tsbg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_1,Vivado 2017.4" *)
module blk_mem_iter(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[19:0],dina[11:0],clkb,addrb[19:0],doutb[11:0]" */;
  input clka;
  input [0:0]wea;
  input [19:0]addra;
  input [11:0]dina;
  input clkb;
  input [19:0]addrb;
  output [11:0]doutb;
endmodule
