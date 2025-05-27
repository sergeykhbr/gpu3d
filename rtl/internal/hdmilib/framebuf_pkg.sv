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


typedef struct {
    logic pix_x0;
    logic [1:0] h_sync;
    logic [1:0] v_sync;
    logic [1:0] de;
    logic [7:0] Y0;
    logic [7:0] Y1;
    logic [7:0] Cb;
    logic [7:0] Cr;
    logic [15:0] YCbCr;
} framebuf_registers;

const framebuf_registers framebuf_r_reset = '{
    1'b0,                               // pix_x0
    2'd0,                               // h_sync
    2'd0,                               // v_sync
    2'd0,                               // de
    8'd0,                               // Y0
    8'd0,                               // Y1
    8'd0,                               // Cb
    8'd0,                               // Cr
    '0                                  // YCbCr
};
endpackage: framebuf_pkg
