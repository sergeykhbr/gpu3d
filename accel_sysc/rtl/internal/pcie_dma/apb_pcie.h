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
#include "../ambalib/types_amba.h"
#include "../ambalib/types_pnp.h"
#include "../ambalib/types_dma.h"
#include "../ambalib/apb_slv.h"

namespace debugger {

SC_MODULE(apb_pcie) {
 public:
    sc_in<bool> i_clk;                                      // APB clock
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<mapinfo_type> i_mapinfo;                          // interconnect slot information
    sc_out<dev_config_type> o_cfg;                          // Device descriptor
    sc_in<apb_in_type> i_apbi;                              // APB input interface
    sc_out<apb_out_type> o_apbo;                            // APB output interface
    sc_in<sc_uint<16>> i_pcie_completer_id;                 // Bus, Device, Function
    sc_in<sc_uint<4>> i_dma_state;                          // DMA engine brief state
    sc_in<pcie_dma64_in_type> i_dbg_pcie_dmai;              // Debugging request from async fifo

    void comb();
    void registers();
    void rxegisters();

    SC_HAS_PROCESS(apb_pcie);

    apb_pcie(sc_module_name name,
             bool async_reset);
    virtual ~apb_pcie();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct apb_pcie_registers {
        sc_signal<bool> resp_valid;
        sc_signal<sc_uint<32>> resp_rdata;
        sc_signal<bool> resp_err;
        sc_signal<sc_uint<4>> req_cnt;
    };

    void apb_pcie_r_reset(apb_pcie_registers& iv) {
        iv.resp_valid = 0;
        iv.resp_rdata = 0;
        iv.resp_err = 0;
        iv.req_cnt = 0;
    }

    struct apb_pcie_rxegisters {
        sc_signal<sc_uint<64>> req_data_arr[16];
    };

    sc_signal<bool> w_req_valid;
    sc_signal<sc_uint<32>> wb_req_addr;
    sc_signal<bool> w_req_write;
    sc_signal<sc_uint<32>> wb_req_wdata;
    apb_pcie_registers v;
    apb_pcie_registers r;
    apb_pcie_rxegisters vx;
    apb_pcie_rxegisters rx;

    apb_slv *pslv0;

};

}  // namespace debugger

