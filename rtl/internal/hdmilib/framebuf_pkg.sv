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
package framebuf_pkg;


// state machine states:
localparam bit [1:0] STATE_Idle = 2'h0;
localparam bit [1:0] STATE_Request = 2'h1;
localparam bit [1:0] STATE_Writing = 2'h2;
localparam bit [1:0] STATE_EndOfFrame = 2'h3;

typedef struct {
    logic [11:0] wr_row;
    logic [11:0] wr_col;
    logic [7:0] wr_addr;
    logic [11:0] rd_row;
    logic [11:0] rd_col;
    logic [7:0] rd_addr;
    logic [3:0] mux_ena;
    logic [3:0] ring_sel;
    logic [3:0] pix_sel;
    logic [8:0] difcnt;
    logic [1:0] state;
    logic [24:0] req_addr;                                  // 32 MB (2 Bytes per pixel) allocated space split on 64 B: 32x64=2048 B
    logic req_valid;
    logic resp_ready;
    logic [3:0] h_sync;
    logic [3:0] v_sync;
    logic [3:0] de;
    logic [15:0] rgb;
} framebuf_registers;

const framebuf_registers framebuf_r_reset = '{
    '0,                                 // wr_row
    '0,                                 // wr_col
    '0,                                 // wr_addr
    '0,                                 // rd_row
    '0,                                 // rd_col
    '0,                                 // rd_addr
    4'h1,                               // mux_ena
    '0,                                 // ring_sel
    '0,                                 // pix_sel
    '0,                                 // difcnt
    STATE_Idle,                         // state
    '0,                                 // req_addr
    1'b0,                               // req_valid
    1'b0,                               // resp_ready
    4'd0,                               // h_sync
    4'd0,                               // v_sync
    4'd0,                               // de
    '0                                  // rgb
};
endpackage: framebuf_pkg
