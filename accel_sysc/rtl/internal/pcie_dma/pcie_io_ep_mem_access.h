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
#include "../mem/ram_bytes_tech.h"

namespace debugger {

SC_MODULE(pcie_io_ep_mem_access) {
 public:
    sc_in<bool> i_nrst;
    sc_in<bool> i_clk;                                      // System bus clock
    // Read Port
    sc_in<sc_uint<11>> i_rd_addr;
    sc_in<sc_uint<4>> i_rd_be;
    sc_out<sc_uint<32>> o_rd_data;
    // Write Port
    sc_in<sc_uint<11>> i_wr_addr;
    sc_in<sc_uint<4>> i_wr_be;
    sc_in<sc_uint<32>> i_wr_data;
    sc_in<bool> i_wr_en;
    sc_out<bool> o_wr_busy;

    void comb();
    void reqff();

    pcie_io_ep_mem_access(sc_module_name name);
    virtual ~pcie_io_ep_mem_access();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    sc_signal<sc_uint<11>> wb_addr;
    bool r_wr_busy;

    ram_bytes_tech<11, 2> *ram0;

};

}  // namespace debugger

