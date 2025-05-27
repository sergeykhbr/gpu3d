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
package video_sync_pkg;


typedef struct {
    logic [10:0] h_count;
    logic [9:0] v_count;
    logic h_sync;
    logic v_sync;
    logic de;
    logic [10:0] x_pix;
    logic [9:0] y_pix;
} video_sync_registers;

const video_sync_registers video_sync_r_reset = '{
    '0,                                 // h_count
    '0,                                 // v_count
    1'b0,                               // h_sync
    1'b0,                               // v_sync
    1'b0,                               // de
    '0,                                 // x_pix
    '0                                  // y_pix
};
endpackage: video_sync_pkg
