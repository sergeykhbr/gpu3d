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
#include "../../rtl/internal/ambalib/types_pnp.h"
#include "../../rtl/internal/ambalib/types_amba.h"
#include "../../rtl/internal/pcie_dma/types_pcie_dma.h"
#include "../../rtl/sim/pll/pll_generic.h"
#include "../../rtl/internal/ambalib/axi_slv.h"
#include "../../rtl/internal/pcie_dma/pcie_dma.h"

namespace debugger {

SC_MODULE(pcie_dma_tb) {
 public:

    void comb();
    void test();
    void bus();

    pcie_dma_tb(sc_module_name name);
    virtual ~pcie_dma_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    sc_signal<bool> i_nrst;                                 // Power-on system reset active LOW
    sc_signal<bool> i_clk;
    sc_signal<bool> w_pci_clk;
    sc_uint<32> wb_clk_cnt;
    sc_signal<sc_uint<16>> wb_i_pcie_completer_id;
    sc_signal<sc_uint<4>> wb_o_dma_state;
    sc_signal<pcie_dma64_in_type> wb_i_pcie_dmai;           // PCIE-EP to system DMA requests
    sc_signal<pcie_dma64_out_type> wb_o_pcie_dmao;          // System DMA responds to PCIE EP
    sc_signal<dev_config_type> wb_o_xmst_cfg;               // PCIE DMA master interface descriptor
    sc_signal<axi4_master_in_type> wb_i_xmsti;
    sc_signal<axi4_master_out_type> wb_o_xmsto;
    sc_signal<bool> w_o_dbg_valid;
    sc_signal<sc_uint<64>> wb_o_dbg_payload;
    sc_signal<mapinfo_type> wb_slv_i_mapinfo;               // Base address information from the interconnect port
    sc_signal<dev_config_type> wb_slv_o_cfg;                // Slave config descriptor
    sc_signal<axi4_slave_in_type> wb_slv_i_xslvi;           // AXI Slave input interface
    sc_signal<axi4_slave_out_type> wb_slv_o_xslvo;          // AXI Slave output interface
    sc_signal<bool> w_slv_o_req_valid;
    sc_signal<sc_uint<CFG_SYSBUS_ADDR_BITS>> wb_slv_o_req_addr;
    sc_signal<sc_uint<8>> wb_slv_o_req_size;
    sc_signal<bool> w_slv_o_req_write;
    sc_signal<sc_uint<CFG_SYSBUS_DATA_BITS>> wb_slv_o_req_wdata;
    sc_signal<sc_uint<CFG_SYSBUS_DATA_BYTES>> wb_slv_o_req_wstrb;
    sc_signal<bool> w_slv_o_req_last;
    sc_signal<bool> w_slv_i_req_ready;
    sc_signal<bool> w_slv_i_resp_valid;
    sc_signal<sc_uint<CFG_SYSBUS_DATA_BITS>> wb_slv_i_resp_rdata;
    sc_signal<bool> w_slv_i_resp_err;
    bool rd_valid;
    sc_uint<4> rd_addr;
    sc_uint<64> mem[16];

    pll_generic *clk0;
    pll_generic *clk1;
    axi_slv *slv0;
    pcie_dma *tt;

};

}  // namespace debugger

