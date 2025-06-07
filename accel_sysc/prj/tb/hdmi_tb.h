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
#include "../../rtl/internal/ambalib/types_amba.h"
#include "../../rtl/internal/ambalib/types_pnp.h"
#include "../common/vips/clk/vip_clk.h"
#include "../../rtl/internal/ambalib/axi_slv.h"
#include "../../rtl/internal/hdmilib/hdmi_top.h"

namespace debugger {

SC_MODULE(hdmi_tb) {
 public:

    void comb();
    void test_clk();

    hdmi_tb(sc_module_name name);
    virtual ~hdmi_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    sc_signal<bool> i_nrst;                                 // Power-on system reset active LOW
    sc_signal<bool> w_clk;
    sc_uint<32> wb_clk_cnt;
    sc_signal<bool> w_hdmi_hsync;
    sc_signal<bool> w_hdmi_vsync;
    sc_signal<bool> w_hdmi_de;
    sc_signal<sc_uint<18>> wb_hdmi_data;
    sc_signal<bool> w_hdmi_spdif;
    sc_signal<bool> w_hdmi_spdif_out;
    sc_signal<bool> w_hdmi_irq;
    sc_signal<axi4_master_out_type> wb_xmsto;               // Clock 2 output
    sc_signal<axi4_master_in_type> wb_xmsti;                // Clock 2 input
    sc_signal<dev_config_type> wb_mst_o_cfg;                // Master config descriptor
    sc_signal<axi4_slave_in_type> wb_xslvi;
    sc_signal<axi4_slave_out_type> wb_xslvo;
    sc_signal<dev_config_type> wb_slv_o_cfg;                // Slave config descriptor
    sc_signal<mapinfo_type> wb_slv_mapinfo;
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
    bool v_busy;
    sc_uint<3> rd_valid;
    bool req_ready;
    sc_uint<4> rd_addr;
    sc_uint<64> rd_data;
    sc_uint<64> mem[16];

    vip_clk *clk;
    axi_slv *slv0;
    hdmi_top *tt;

};

}  // namespace debugger

