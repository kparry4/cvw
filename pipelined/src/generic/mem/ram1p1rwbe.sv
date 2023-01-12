///////////////////////////////////////////
// 1 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Basic sram with 1 read write port.
//          When clk rises Addr and LineWriteData are sampled.
//          Following the clk edge read data is output from the sampled Addr.
//          Write 
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

// WIDTH is number of bits in one "word" of the memory, DEPTH is number of such words

`include "wally-config.vh"

module ram1p1rwbe #(parameter DEPTH=128, WIDTH=256) (
  input logic                     clk,
  input logic                     ce,
  input logic [$clog2(DEPTH)-1:0] addr,
  input logic [WIDTH-1:0]         din,
  input logic                     we,
  input logic [(WIDTH-1)/8:0]     bwe,
  output logic [WIDTH-1:0]        dout);

    logic [WIDTH-1:0]               RAM[DEPTH-1:0];

  // ***************************************************************************
  // TRUE SRAM macro
  // ***************************************************************************
  if (`USE_SRAM == 1) begin
    genvar index;
    // 64 x 128-bit SRAM
    // check if the size is ok, complain if not***
    logic [WIDTH-1:0] BitWriteMask;
    for (index=0; index < WIDTH; index++) 
      assign BitWriteMask[index] = bwe[index/8];
    TS1N28HPCPSVTB64X128M4SW sram(
      .CLK(clk), .CEB(~ce), .WEB(~we),
      .A(addr), .D(din), 
      .BWEB(~BitWriteMask), .Q(dout));
    
  // ***************************************************************************
  // READ first SRAM model
  // ***************************************************************************
  end else begin: ram
    integer i;

    // Read
    always @(posedge clk) 
      if(ce) dout <= #1 RAM[addr];
 
    // Write divided into part for bytes and part for extra msbs
    if(WIDTH >= 8) 
      always @(posedge clk) 
        if (ce & we) 
          for(i = 0; i < WIDTH/8; i++) 
            if(bwe[i]) RAM[addr][i*8 +: 8] <= #1 din[i*8 +: 8];
          
    if (WIDTH%8 != 0) // handle msbs if width not a multiple of 8
      always @(posedge clk) 
        if (ce & we & bwe[WIDTH/8])
          RAM[addr][WIDTH-1:WIDTH-WIDTH%8] <= #1 din[WIDTH-1:WIDTH-WIDTH%8];
  end

endmodule
