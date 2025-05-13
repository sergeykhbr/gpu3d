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

// 
localparam int C_DATA_WIDTH = 64;
localparam int KEEP_WIDTH = (C_DATA_WIDTH / 8);
// 
localparam int REQ_FIFO_WIDTH = (7  // bar_hit
        + 1  // ecrc_err
        + 1  // err_fwd
        + 1  // last
        + 8  // strob
        + 64  // data
);
localparam int RESP_FIFO_WIDTH = (1  // last
        + 8  // strob
        + 64  // data
);

endpackage: pcie_dma_pkg
