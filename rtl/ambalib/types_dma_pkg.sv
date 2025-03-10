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
package types_dma_pkg;




typedef struct {
    logic tx_ready;
    logic [63:0] rx_data;
    logic rx_last;
    logic rx_valid;
    logic busy;                                             // DMA endine status
} dma64_out_type;

// @brief   DMA output empty values.
const dma64_out_type dma64_out_none = '{1'b0, 64'd0, '0, 1'b0, 1'b0};

// @brief DMA device input signals.
typedef struct {
    logic rx_ready;
    logic [63:0] tx_data;
    logic [7:0] tx_strob;
    logic tx_last;
    logic tx_valid;
} dma64_in_type;

const dma64_in_type dma64_in_none = '{1'b0, '0, '0, 1'b0, '0};

endpackage: types_dma_pkg
