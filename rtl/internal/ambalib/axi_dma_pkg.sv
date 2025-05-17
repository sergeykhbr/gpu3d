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
package axi_dma_pkg;

import types_amba_pkg::*;

localparam bit [2:0] state_idle = 3'd0;
localparam bit [2:0] state_ar = 3'd1;
localparam bit [2:0] state_r = 3'd2;
localparam bit [2:0] state_r_wait_accept = 3'd3;
localparam bit [2:0] state_aw = 3'd4;
localparam bit [2:0] state_w = 3'd5;
localparam bit [2:0] state_w_wait_accept = 3'd6;
localparam bit [2:0] state_b = 3'd7;

typedef struct {
    logic [2:0] state;
    logic ar_valid;
    logic aw_valid;
    logic w_valid;
    logic r_ready;
    logic b_ready;
    logic [CFG_SYSBUS_ADDR_BITS-1:0] req_addr;
    logic [CFG_SYSBUS_DATA_BITS-1:0] req_wdata;
    logic [CFG_SYSBUS_DATA_BYTES-1:0] req_wstrb;
    logic [2:0] req_size;
    logic [7:0] req_len;
    logic req_last;
    logic req_ready;
    logic resp_valid;
    logic [CFG_SYSBUS_DATA_BITS-1:0] resp_data;
    logic resp_error;
    logic [CFG_SYSBUS_USER_BITS-1:0] user_count;
} axi_dma_registers;

const axi_dma_registers axi_dma_r_reset = '{
    state_idle,                         // state
    1'b0,                               // ar_valid
    1'b0,                               // aw_valid
    1'b0,                               // w_valid
    1'b0,                               // r_ready
    1'b0,                               // b_ready
    '0,                                 // req_addr
    '0,                                 // req_wdata
    '0,                                 // req_wstrb
    '0,                                 // req_size
    '0,                                 // req_len
    1'b0,                               // req_last
    1'b1,                               // req_ready
    '0,                                 // resp_valid
    '0,                                 // resp_data
    1'b0,                               // resp_error
    '0                                  // user_count
};
endpackage: axi_dma_pkg
