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
package mul_4x4_i8_pkg;


typedef struct {
    logic [16:0] sum0a;
    logic [16:0] sum0b;
    logic [16:0] sum1a;
    logic [16:0] sum1b;
    logic [16:0] sum2a;
    logic [16:0] sum2b;
    logic [16:0] sum3a;
    logic [16:0] sum3b;
    logic [17:0] res0;
    logic [17:0] res1;
    logic [17:0] res2;
    logic [17:0] res3;
    logic [5:0] sign;
} mul_4x4_i8_registers;

const mul_4x4_i8_registers mul_4x4_i8_r_reset = '{
    17'd0,                              // sum0a
    17'd0,                              // sum0b
    17'd0,                              // sum1a
    17'd0,                              // sum1b
    17'd0,                              // sum2a
    17'd0,                              // sum2b
    17'd0,                              // sum3a
    17'd0,                              // sum3b
    18'd0,                              // res0
    18'd0,                              // res1
    18'd0,                              // res2
    18'd0,                              // res3
    6'd0                                // sign
};
endpackage: mul_4x4_i8_pkg
