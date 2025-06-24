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
#include "../../rtl/internal/accel/types_accel_bus0.h"
#include "../../rtl/internal/ambalib/types_pnp.h"
#include "../../rtl/internal/ambalib/types_amba.h"
#include "../../rtl/sim/pll/pll_generic.h"
#include "../../rtl/internal/accel/accel_axictrl_bus0.h"
#include "../../rtl/internal/ambalib/axi_slv.h"
#include "axi_mst_generator.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(accel_axictrl_bus0_tb) {
 public:

    void init();
    void comb();
    void test();
    void registers();

    accel_axictrl_bus0_tb(sc_module_name name);
    virtual ~accel_axictrl_bus0_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    struct accel_axictrl_bus0_tb_registers {
        sc_signal<sc_uint<32>> clk_cnt;
        sc_signal<sc_uint<32>> err_cnt;
        sc_signal<sc_uint<32>> test_cnt;
        sc_signal<sc_uint<32>> test_pause_cnt;
        sc_signal<bool> m0_start_ena;
        sc_signal<sc_uint<11>> m0_test_selector;
        sc_signal<bool> m1_start_ena;
        sc_signal<sc_uint<11>> m1_test_selector;
        sc_signal<bool> m2_start_ena;
        sc_signal<sc_uint<11>> m2_test_selector;
        sc_signal<sc_uint<2>> s0_state;
        sc_signal<bool> req_s0_ready;
        sc_signal<bool> resp_s0_valid;
        sc_signal<sc_uint<64>> resp_s0_rdata;
        sc_signal<sc_uint<3>> resp_s0_wait_states;
        sc_signal<sc_uint<3>> resp_s0_wait_cnt;
        sc_signal<bool> end_of_test;
        sc_signal<bool> end_idle;
    };

    void accel_axictrl_bus0_tb_r_reset(accel_axictrl_bus0_tb_registers& iv) {
        iv.clk_cnt = 0;
        iv.err_cnt = 0;
        iv.test_cnt = 0;
        iv.test_pause_cnt = 0;
        iv.m0_start_ena = 0;
        iv.m0_test_selector = 0;
        iv.m1_start_ena = 0;
        iv.m1_test_selector = 0;
        iv.m2_start_ena = 0;
        iv.m2_test_selector = 0;
        iv.s0_state = 0;
        iv.req_s0_ready = 0;
        iv.resp_s0_valid = 0;
        iv.resp_s0_rdata = 0;
        iv.resp_s0_wait_states = 0;
        iv.resp_s0_wait_cnt = 0;
        iv.end_of_test = 0;
        iv.end_idle = 0;
    }

    sc_signal<bool> nrst;                                   // Power-on system reset active LOW
    sc_signal<bool> clk;
    sc_signal<dev_config_type> wb_bus0_cfg;
    bus0_xmst_out_vector vec_i_xmsto;
    bus0_xmst_in_vector vec_o_xmsti;
    bus0_xslv_out_vector vec_i_xslvo;
    bus0_xslv_in_vector vec_o_xslvi;
    bus0_mapinfo_vector vec_o_mapinfo;
    sc_signal<dev_config_type> wb_s0_cfg;
    sc_signal<bool> w_s0_req_valid;
    sc_signal<sc_uint<48>> wb_s0_req_addr;
    sc_signal<sc_uint<8>> wb_s0_req_size;
    sc_signal<bool> w_s0_req_write;
    sc_signal<sc_uint<64>> wb_s0_req_wdata;
    sc_signal<sc_uint<8>> wb_s0_req_wstrb;
    sc_signal<bool> w_s0_req_last;
    sc_signal<bool> w_s0_req_ready;
    sc_signal<bool> w_s0_resp_valid;
    sc_signal<sc_uint<64>> wb_s0_resp_rdata;
    sc_signal<bool> w_s0_resp_err;
    sc_signal<dev_config_type> wb_s1_cfg;
    sc_signal<bool> w_s1_req_valid;
    sc_signal<sc_uint<48>> wb_s1_req_addr;
    sc_signal<sc_uint<8>> wb_s1_req_size;
    sc_signal<bool> w_s1_req_write;
    sc_signal<sc_uint<64>> wb_s1_req_wdata;
    sc_signal<sc_uint<8>> wb_s1_req_wstrb;
    sc_signal<bool> w_s1_req_last;
    sc_signal<bool> w_s1_req_ready;
    sc_signal<bool> w_s1_resp_valid;
    sc_signal<sc_uint<64>> wb_s1_resp_rdata;
    sc_signal<bool> w_s1_resp_err;
    sc_signal<bool> w_m0_busy;
    sc_signal<bool> w_m1_busy;
    sc_signal<bool> w_m2_busy;
    std::string msg;
    sc_uint<64> s0_mem0[16];
    sc_uint<64> s0_mem1[16];
    accel_axictrl_bus0_tb_registers v;
    accel_axictrl_bus0_tb_registers r;

    pll_generic *clk0;
    accel_axictrl_bus0 *bus0;
    axi_slv *xslv0;
    axi_slv *xslv1;
    axi_mst_generator *mst0;
    axi_mst_generator *mst1;
    axi_mst_generator *mst2;

};

}  // namespace debugger

