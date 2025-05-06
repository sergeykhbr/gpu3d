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
#pragma once

#include <systemc.h>

namespace debugger {

// PCIE end-point config:
static const int CFG_PCIE_DATA_WIDTH = 64;
static const int CFG_PCIE_DMAFIFO_DEPTH = 2;                // FIFO depth in PCIE DMA engine
// 
// Completions packets {Fmt[1:0], Type[4:0]} for non-posted TLPs:
static const uint8_t PCIE_CPL_NODATA = 0x0A;                // Completion without data (IOWr, CfgWr1, CfgWr2)
static const uint8_t PCIE_CPL_DATA = 0x4A;                  // Completion with data (MemRd, IORd, CfgRd1, CfgRd2)
static const uint8_t PCIE_CPL_LOCKED_READ_NODATA = 0x0B;    // Completion for Locked Memory Read without Data (only when error)
static const uint8_t PCIE_CPL_LOCKED_READ = 0x4B;           // Completion for locked memory read

}  // namespace debugger

