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
package types_pcie_dma_pkg;




typedef struct {
    logic ready;
    logic [63:0] data;
    logic [7:0] strob;
    logic last;
    logic valid;
} pcie_dma64_out_type;

// @brief   DMA output empty values.
const pcie_dma64_out_type pcie_dma64_out_none = '{
    1'b0,                               // ready
    64'd0,                              // data
    8'd0,                               // strob
    1'b0,                               // last
    1'b0                                // valid
};

// @brief DMA device input signals.
typedef struct {
    logic ready;
    logic [63:0] data;
    logic [7:0] strob;
    logic last;
    logic [6:0] bar_hit;                                    // [0]=BAR0, [1]=BAR1.. [5]=BAR5, [6]=Expansion ROM
    logic err_fwd;                                          // Receive error Forward: packet in progress is error-poisoned
    logic ecrc_err;                                         // Receive ECRC Error: current packet has an ECRC error. Asserted at the packet EOF
    logic valid;
} pcie_dma64_in_type;

const pcie_dma64_in_type pcie_dma64_in_none = '{
    1'b0,                               // ready
    64'd0,                              // data
    8'd0,                               // strob
    1'b0,                               // last
    7'd0,                               // bar_hit
    1'b0,                               // err_fwd
    1'b0,                               // ecrc_err
    1'b0                                // valid
};

endpackage: types_pcie_dma_pkg
