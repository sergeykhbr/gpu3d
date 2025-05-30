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
package vip_uart_top_pkg;


localparam bit [7:0] EOF_0x0D = 8'h0D;

typedef struct {
    logic [1:0] initdone;
} vip_uart_top_registers;

const vip_uart_top_registers vip_uart_top_r_reset = '{
    2'd0                                // initdone
};
endpackage: vip_uart_top_pkg
