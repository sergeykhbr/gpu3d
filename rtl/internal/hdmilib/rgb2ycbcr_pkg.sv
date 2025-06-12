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
package rgb2ycbcr_pkg;


typedef struct {
    logic [7:0] hsync;
    logic [7:0] vsync;
    logic [7:0] de;
    logic [6:0] even;                                       // HIGH on samples 0, 2, 4, ...
    logic [15:0] ycbcr422;
} rgb2ycbcr_registers;

const rgb2ycbcr_registers rgb2ycbcr_r_reset = '{
    '0,                                 // hsync
    '0,                                 // vsync
    '0,                                 // de
    '0,                                 // even
    '0                                  // ycbcr422
};
endpackage: rgb2ycbcr_pkg
