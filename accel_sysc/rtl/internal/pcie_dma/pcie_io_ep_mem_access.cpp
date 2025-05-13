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

#include "pcie_io_ep_mem_access.h"
#include "api_core.h"

namespace debugger {

pcie_io_ep_mem_access::pcie_io_ep_mem_access(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_rd_addr("i_rd_addr"),
    i_rd_be("i_rd_be"),
    o_rd_data("o_rd_data"),
    i_wr_addr("i_wr_addr"),
    i_wr_be("i_wr_be"),
    i_wr_data("i_wr_data"),
    i_wr_en("i_wr_en"),
    o_wr_busy("o_wr_busy") {

    ram0 = 0;

    ram0 = new ram_bytes_tech<11,
                              2>("ram0");
    ram0->i_clk(i_clk);
    ram0->i_addr(wb_addr);
    ram0->i_wena(i_wr_en);
    ram0->i_wstrb(i_wr_be);
    ram0->i_wdata(i_wr_data);
    ram0->o_rdata(o_rd_data);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_rd_addr;
    sensitive << i_rd_be;
    sensitive << i_wr_addr;
    sensitive << i_wr_be;
    sensitive << i_wr_data;
    sensitive << i_wr_en;
    sensitive << wb_addr;

    SC_METHOD(reqff);
    sensitive << i_clk.pos();
}

pcie_io_ep_mem_access::~pcie_io_ep_mem_access() {
    if (ram0) {
        delete ram0;
    }
}

void pcie_io_ep_mem_access::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_rd_addr, i_rd_addr.name());
        sc_trace(o_vcd, i_rd_be, i_rd_be.name());
        sc_trace(o_vcd, o_rd_data, o_rd_data.name());
        sc_trace(o_vcd, i_wr_addr, i_wr_addr.name());
        sc_trace(o_vcd, i_wr_be, i_wr_be.name());
        sc_trace(o_vcd, i_wr_data, i_wr_data.name());
        sc_trace(o_vcd, i_wr_en, i_wr_en.name());
        sc_trace(o_vcd, o_wr_busy, o_wr_busy.name());
    }

}

void pcie_io_ep_mem_access::comb() {
    if (i_wr_en.read() == 1) {
        wb_addr = i_wr_addr.read();
    } else {
        wb_addr = i_rd_addr.read();
    }
    o_wr_busy = r_wr_busy;
}

void pcie_io_ep_mem_access::reqff() {
    if (i_nrst.read() == 0) {
        r_wr_busy = 0;
    } else {
        r_wr_busy = i_wr_en.read();
    }
}

}  // namespace debugger

