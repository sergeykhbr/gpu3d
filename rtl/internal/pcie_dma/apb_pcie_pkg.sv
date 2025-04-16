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
package apb_pcie_pkg;

import types_amba_pkg::*;
import types_pnp_pkg::*;
import types_dma_pkg::*;

typedef struct {
    logic resp_valid;
    logic [31:0] resp_rdata;
    logic resp_err;
    logic [3:0] req_cnt;
} apb_pcie_registers;

const apb_pcie_registers apb_pcie_r_reset = '{
    1'b0,                               // resp_valid
    '0,                                 // resp_rdata
    1'b0,                               // resp_err
    4'd0                                // req_cnt
};

typedef struct {
    logic [63:0] req_data_arr[0: 16 - 1];
} apb_pcie_rxegisters;

endpackage: apb_pcie_pkg
