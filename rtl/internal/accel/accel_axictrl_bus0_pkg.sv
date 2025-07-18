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
package accel_axictrl_bus0_pkg;

import types_accel_bus0_pkg::*;
import types_pnp_pkg::*;
import types_amba_pkg::*;

typedef struct {
    logic [(CFG_BUS0_XMST_TOTAL * CFG_BUS0_XSLV_LOG2_TOTAL)-1:0] w_select;
    logic [CFG_BUS0_XMST_TOTAL-1:0] w_active;
    logic r_def_valid;
} accel_axictrl_bus0_registers;

const accel_axictrl_bus0_registers accel_axictrl_bus0_r_reset = '{
    '0,                                 // w_select
    '0,                                 // w_active
    1'b0                                // r_def_valid
};
endpackage: accel_axictrl_bus0_pkg
