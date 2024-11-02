// (c) Copyright 2007 - 2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
/*------------------------------------------------------------------------------
Module Description:

This module emulates the NI-DRU for faster simulation of SD-SDI. Because the
simulation will have no jitter, this emulation of the DRU always uses a fixed
sampling point, passing through every 11th sample.

*/

`timescale 1ns / 1ps

module dru_inferred (
    input  [19:0]   DT_IN,
    input  [36:0]   CENTER_F,
    input           EN,
    input  [4:0]    G1,
    input  [4:0]    G1_P,
    input  [4:0]    G2,
    input           CLK,
    input           PL,
    input  [31:0]   PHASE_IN,
    input           RST,
    input           RST_FREQ,
    input           EN_INTEG,
    input           PH_EST_DIS,
    output [20:0]   PH_OUT,
    output [31:0]   INTEG,
    output [31:0]   DIRECT,
    output [31:0]   CTRL,
    output          AL_PPM,
    output [19:0]   RECCLK,
    output [3:0]    SAMV,
    output [9:0]    SAM,
    output [7:0]    VER
);

localparam [4:0]    CNTR0_START = 5'd0;
localparam [4:0]    CNTR1_START = 5'd11;

reg     [4:0]   cntr0 = CNTR0_START;
reg     [4:0]   cntr1 = CNTR1_START;
wire    [4:0]   index0;
reg     [4:0]   index1;
reg     [3:0]   samv_reg = 0;
reg     [9:0]   sam_reg = 0;
reg     [19:0]  in_reg = 0;

always @ (posedge CLK)
    in_reg <= DT_IN;

always @ (posedge CLK)
    if (RST)
        cntr0 <= CNTR0_START;
    else if (cntr0 == 5'd10)
        cntr0 <= 5'd1;
    else if (cntr0 == 5'd9)
        cntr0 <= 5'd0;
    else
        cntr0 <= cntr0 + 5'd2;

assign index0 = cntr0;

always @ (posedge CLK)
    if (RST)
        cntr1 <= CNTR1_START;
    else if (cntr1 == 5'd21)
        cntr1 <= 5'd12;
    else if (cntr1 == 5'd20)
        cntr1 <= 5'd11;
    else
        cntr1 <= cntr1 + 5'd2;

always @ (*)
    if (cntr1 >= 5'd20)
        index1 <= 0;
    else
        index1 <= cntr1;

always @ (posedge CLK)
    if (cntr1 < 20)
        sam_reg <= {8'b0, in_reg[index1], in_reg[index0]};
    else
        sam_reg <= {8'b0, 1'b0, in_reg[index0]};

always @ (posedge CLK)
    if (cntr1 >= 20)
        samv_reg <= 4'b0001;
    else
        samv_reg <= 4'b0010;

assign SAM    = sam_reg;
assign SAMV   = samv_reg;
assign RECCLK = 20'b0;
assign PH_OUT = 21'b0;
assign CTRL   = 31'b0;
assign DIRECT = 31'b0;
assign INTEG  = 31'b0;
assign VER    = 8'b0;
assign AL_PPM = 1'b0;

endmodule
