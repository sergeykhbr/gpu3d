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
package imul53_pkg;


typedef struct {
    logic [15:0] delay;
    logic [6:0] shift;
    logic accum_ena;
    logic [55:0] b;
    logic [105:0] sum;
    logic overflow;
} imul53_registers;

const imul53_registers imul53_r_reset = '{
    '0,                                 // delay
    '0,                                 // shift
    1'b0,                               // accum_ena
    '0,                                 // b
    '0,                                 // sum
    1'b0                                // overflow
};
endpackage: imul53_pkg
