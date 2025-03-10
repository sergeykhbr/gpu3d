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
package pcie_cfg_pkg;


// PCIE end-point config:
localparam int CFG_PCIE_DATA_WIDTH = 64;
localparam int CFG_PCIE_DMAFIFO_DEPTH = 2;                  // FIFO depth in PCIE DMA engine

endpackage: pcie_cfg_pkg
