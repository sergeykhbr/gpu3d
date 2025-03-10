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

typedef struct {
    logic lnk_up;
    logic [7:0] cfg_bus_number;
    logic [4:0] cfg_device_number;
    logic [2:0] cfg_function_number;
    logic resp_valid;
    logic [31:0] resp_rdata;
    logic resp_err;
} apb_pcie_registers;

const apb_pcie_registers apb_pcie_r_reset = '{
    1'b0,                               // lnk_up
    8'd0,                               // cfg_bus_number
    5'd0,                               // cfg_device_number
    3'd0,                               // cfg_function_number
    1'b0,                               // resp_valid
    '0,                                 // resp_rdata
    1'b0                                // resp_err
};

endpackage: apb_pcie_pkg
