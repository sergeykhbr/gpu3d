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
package pcie_dma_pkg;

import types_dma_pkg::*;
import types_pnp_pkg::*;
import types_amba_pkg::*;
import pcie_cfg_pkg::*;

localparam int TXFIFO_WIDTH = (64  // tx_data
        + 8  // tx_strob
        + 1  // tx_last
);
localparam int RXFIFO_WIDTH = (64  // rx_data
        + 1  // rx_last
);

endpackage: pcie_dma_pkg
