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
package mul_i8_pkg;


typedef struct {
    logic [7:0] ua;
    logic [7:0] ub;
    logic [3:0] inv;
    logic [9:0] lvl1_0;
    logic [9:0] lvl1_1;
    logic [9:0] lvl1_2;
    logic [9:0] lvl1_3;
    logic [12:0] lvl2_0;
    logic [12:0] lvl2_1;
    logic [15:0] lvl3;
    logic [15:0] res;
} mul_i8_registers;

const mul_i8_registers mul_i8_r_reset = '{
    '0,                                 // ua
    '0,                                 // ub
    4'd0,                               // inv
    10'd0,                              // lvl1_0
    10'd0,                              // lvl1_1
    10'd0,                              // lvl1_2
    10'd0,                              // lvl1_3
    13'd0,                              // lvl2_0
    13'd0,                              // lvl2_1
    '0,                                 // lvl3
    '0                                  // res
};
endpackage: mul_i8_pkg
