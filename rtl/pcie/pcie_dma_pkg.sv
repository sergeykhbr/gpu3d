// 
//  Copyright 2022 Sergey Khabarov, sergeykhbr@gmail.com
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// 
package pcie_dma_pkg;

import types_dma_pkg::*;
import types_pnp_pkg::*;
import types_amba_pkg::*;
import pcie_cfg_pkg::*;

// 
// fmt: indicates the size of the header
localparam bit [1:0] TLP_FMT_3DW_NOPAYLOAD = 2'd0;          // 3DW header without payload
localparam bit [1:0] TLP_FMT_4DW_NOPAYLOAD = 2'd1;          // 4DW header without payload
localparam bit [1:0] TLP_FMT_3DW_PAYLOAD = 2'd2;            // 3DW header with payload
localparam bit [1:0] TLP_FMT_4DW_PAYLOAD = 2'd3;            // 4DW header with payload
// 
// TLP[30:29] = fmt; TLP[28:24] = type
localparam bit [6:0] TLP_FMT_TYPE_RD_MEM32 = 7'h00;
localparam bit [6:0] TLP_FMT_TYPE_WR_MEM32 = 7'h20;
localparam bit [6:0] TLP_FMT_TYPE_RD_MEM64 = 7'h10;
localparam bit [6:0] TLP_FMT_TYPE_WR_MEM64 = 7'h30;
localparam bit [6:0] TLP_FMT_TYPE_RD_IO32 = 7'h02;
localparam bit [6:0] TLP_FMT_TYPE_WR_IO32 = 7'h22;
// 
// State machine to parse TLP
localparam bit [7:0] STATE_RST = 8'h00;
localparam bit [7:0] STATE_DW3DW4 = 8'd1;
localparam bit [7:0] STATE_AR = 8'd2;
localparam bit [7:0] STATE_R = 8'd3;
localparam bit [7:0] STATE_AW = 8'd4;
localparam bit [7:0] STATE_W = 8'd5;
localparam bit [7:0] STATE_B = 8'd6;
localparam bit [7:0] STATE_RESP_DW0DW1 = 8'd7;
localparam bit [7:0] STATE_RESP_DW2DW3 = 8'd8;
localparam bit [7:0] STATE_RESP_PAYLOAD = 8'd9;
// 
localparam int REQ_FIFO_WIDTH = (1  // last
        + 8  // strob
        + 64  // data
);
localparam int RESP_FIFO_WIDTH = (1  // last
        + 8  // strob
        + 64  // data
);

typedef struct {
    logic [7:0] state;
    logic [31:0] dw0;
    logic [31:0] dw1;
    logic [31:0] dw2;
    logic [31:0] dw3;
    logic [7:0] xlen;                                       // AXI Burst Len - 1
    logic [2:0] xsize;                                      // AXI Burst size: 0=1B, 1=2B, 2=4B, 3=8B,..
    logic [CFG_SYSBUS_ADDR_BITS-1:0] xaddr;                 // AXI request address
    logic [CFG_SYSBUS_DATA_BYTES-1:0] xwstrb;
    logic [CFG_SYSBUS_DATA_BITS-1:0] xwdata;
    logic xwena;                                            // AXI light: RW and W at the same time without burst
    logic [CFG_SYSBUS_DATA_BITS-1:0] xrdata;
    logic resp_data_ena;                                    // TLP with payload
    logic [63:0] resp_data;
    logic resp_last;
    logic [11:0] byte_cnt;                                  // Byte counter to send in payload
    logic busy;
} pcie_dma_registers;

const pcie_dma_registers pcie_dma_r_reset = '{
    STATE_RST,                          // state
    32'd0,                              // dw0
    32'd0,                              // dw1
    32'd0,                              // dw2
    32'd0,                              // dw3
    8'd0,                               // xlen
    3'd0,                               // xsize
    48'd0,                              // xaddr
    8'd0,                               // xwstrb
    64'd0,                              // xwdata
    1'b0,                               // xwena
    64'd0,                              // xrdata
    1'b0,                               // resp_data_ena
    64'd0,                              // resp_data
    1'b0,                               // resp_last
    12'd0,                              // byte_cnt
    1'b0                                // busy
};

endpackage: pcie_dma_pkg
