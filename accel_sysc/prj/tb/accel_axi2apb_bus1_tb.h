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
#include "../../rtl/internal/accel/types_accel_bus1.h"
#include "../../rtl/internal/ambalib/types_amba.h"
#include "../../rtl/internal/ambalib/types_pnp.h"
#include "../../rtl/sim/pll/pll_generic.h"
#include "../../rtl/internal/accel/accel_axi2apb_bus1.h"
#include "../../rtl/internal/ambalib/apb_slv.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(accel_axi2apb_bus1_tb) {
 public:

    void init();
    void comb();
    void test();
    void registers();

    accel_axi2apb_bus1_tb(sc_module_name name);
    virtual ~accel_axi2apb_bus1_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    struct accel_axi2apb_bus1_tb_registers {
        sc_signal<sc_uint<32>> clk_cnt;
        sc_signal<sc_uint<32>> err_cnt;
        sc_signal<sc_uint<32>> compare_cnt;
        sc_signal<sc_uint<32>> test_cnt;
        sc_signal<sc_uint<3>> test_state;
        sc_signal<sc_uint<2>> apb_wait_states;
        sc_signal<sc_uint<32>> test_pause_cnt;
        sc_signal<sc_uint<3>> xsize;
        sc_signal<bool> aw_valid;
        sc_signal<sc_uint<48>> aw_addr;
        sc_signal<sc_uint<4>> w_wait_states;
        sc_signal<sc_uint<4>> w_wait_cnt;
        sc_signal<bool> w_valid;
        sc_signal<sc_uint<64>> w_data;
        sc_signal<sc_uint<8>> w_strb;
        sc_signal<sc_uint<2>> b_wait_states;
        sc_signal<sc_uint<2>> b_wait_cnt;
        sc_signal<bool> b_ready;
        sc_signal<bool> ar_valid;
        sc_signal<sc_uint<48>> ar_addr;
        sc_signal<sc_uint<4>> r_wait_states;
        sc_signal<sc_uint<4>> r_wait_cnt;
        sc_signal<bool> r_ready;
        sc_signal<bool> compare_ena;
        sc_signal<sc_uint<64>> compare_a;
        sc_signal<sc_uint<64>> compare_b;
        sc_signal<bool> end_of_test;
        sc_signal<sc_uint<2>> apbstate;
        sc_signal<sc_uint<64>> apbram;
        sc_signal<bool> preq_ready;
        sc_signal<bool> presp_valid;
        sc_signal<sc_uint<32>> presp_rdata;
        sc_signal<sc_uint<2>> presp_delay;
    };

    void accel_axi2apb_bus1_tb_r_reset(accel_axi2apb_bus1_tb_registers& iv) {
        iv.clk_cnt = 0;
        iv.err_cnt = 0;
        iv.compare_cnt = 0;
        iv.test_cnt = 0;
        iv.test_state = 0;
        iv.apb_wait_states = 0;
        iv.test_pause_cnt = 0;
        iv.xsize = 2;
        iv.aw_valid = 0;
        iv.aw_addr = 0;
        iv.w_wait_states = 0;
        iv.w_wait_cnt = 0;
        iv.w_valid = 0;
        iv.w_data = 0;
        iv.w_strb = 0;
        iv.b_wait_states = 0;
        iv.b_wait_cnt = 0;
        iv.b_ready = 0;
        iv.ar_valid = 0;
        iv.ar_addr = 0;
        iv.r_wait_states = 0;
        iv.r_wait_cnt = 0;
        iv.r_ready = 0;
        iv.compare_ena = 0;
        iv.compare_a = 0;
        iv.compare_b = 0;
        iv.end_of_test = 0;
        iv.apbstate = 0;
        iv.apbram = 0x7FFFFFFFFFFFFFFF;
        iv.preq_ready = 0;
        iv.presp_valid = 0;
        iv.presp_rdata = 0;
        iv.presp_delay = 0;
    }

    sc_signal<bool> nrst;                                   // Power-on system reset active LOW
    sc_signal<bool> clk;
    sc_signal<mapinfo_type> wb_xslv_mapinfo;                // Mapped address of the axi2apb bridge
    sc_signal<mapinfo_type> wb_pslv_mapinfo;                // Mapped address of the testing APB device (UART)
    bus1_mapinfo_vector vec_o_mapinfo;
    sc_signal<dev_config_type> wb_xslv_cfg;
    sc_signal<dev_config_type> wb_pslv_cfg;
    sc_signal<axi4_slave_in_type> wb_i_xslvi;
    sc_signal<axi4_slave_out_type> wb_o_xslvo;
    bus1_apb_in_vector vec_apbi;
    bus1_apb_out_vector vec_apbo;
    sc_signal<bool> w_req_valid;
    sc_signal<sc_uint<32>> wb_req_addr;
    sc_signal<bool> w_req_write;
    sc_signal<sc_uint<32>> wb_req_wdata;
    sc_signal<bool> w_resp_valid;
    sc_signal<sc_uint<32>> wb_resp_rdata;
    sc_signal<bool> w_resp_err;
    std::string msg;
    accel_axi2apb_bus1_tb_registers v;
    accel_axi2apb_bus1_tb_registers r;

    pll_generic *clk0;
    accel_axi2apb_bus1 *bus1;
    apb_slv *pslv0;

};

}  // namespace debugger

