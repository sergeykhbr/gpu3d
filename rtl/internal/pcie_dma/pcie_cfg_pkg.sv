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
localparam int CFG_PCIE_DMAFIFO_DEPTH = 3;                  // FIFO depth in PCIE DMA engine
localparam int CFG_PCIE_DMAADDR_WIDTH = 34;                 // Address width between axi_dma and PHY modules
// 
// Completions packets {Fmt[1:0], Type[4:0]} for non-posted TLPs:
localparam bit [6:0] PCIE_CPL_NODATA = 7'h0A;               // Completion without data (IOWr, CfgWr1, CfgWr2)
localparam bit [6:0] PCIE_CPL_DATA = 7'h4A;                 // Completion with data (MemRd, IORd, CfgRd1, CfgRd2)
localparam bit [6:0] PCIE_CPL_LOCKED_READ_NODATA = 7'h0B;   // Completion for Locked Memory Read without Data (only when error)
localparam bit [6:0] PCIE_CPL_LOCKED_READ = 7'h4B;          // Completion for locked memory read

endpackage: pcie_cfg_pkg
