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
localparam bit [1:0] STATE_Request = 2'h1;
localparam bit [1:0] STATE_Writing = 2'h2;
localparam bit [1:0] STATE_Idle = 2'h0;

typedef struct {
    logic [1:0] state;
    logic pingpong;
    logic [17:0] req_addr;                                  // 16 MB allocated space split on 64 B: 32x64=2048 B
    logic req_valid;
    logic resp_ready;
    logic [10:0] raddr;
    logic [10:0] raddr_z;
    logic pix_x0;
    logic [3:0] h_sync;
    logic [3:0] v_sync;
    logic [3:0] de;
    logic [7:0] Y0;
    logic [7:0] Y1;
    logic [7:0] Cb;
    logic [7:0] Cr;
    logic [15:0] YCbCr;
} framebuf_registers;

const framebuf_registers framebuf_r_reset = '{
    STATE_Request,                      // state
    1'b0,                               // pingpong
    18'd32,                             // req_addr
    1'b0,                               // req_valid
    1'b0,                               // resp_ready
    11'd0,                              // raddr
    11'd0,                              // raddr_z
    1'b0,                               // pix_x0
    4'd0,                               // h_sync
    4'd0,                               // v_sync
    4'd0,                               // de
    8'd0,                               // Y0
    8'd0,                               // Y1
    8'd0,                               // Cb
    8'd0,                               // Cr
    '0                                  // YCbCr
};
endpackage: framebuf_pkg
