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
        sc_signal<sc_uint<4>> m0_state;
        sc_signal<sc_uint<3>> m0_xsize;
        sc_signal<bool> m0_aw_valid;
        sc_signal<sc_uint<48>> m0_aw_addr;
        sc_signal<sc_uint<8>> m0_aw_xlen;
        sc_signal<sc_uint<3>> m0_w_wait_states;
        sc_signal<sc_uint<3>> m0_w_wait_cnt;
        sc_signal<bool> m0_w_valid;
        sc_signal<sc_uint<64>> m0_w_data;
        sc_signal<sc_uint<8>> m0_w_strb;
        sc_signal<sc_uint<8>> m0_w_last;
        sc_signal<sc_uint<4>> m0_w_burst_cnt;
        sc_signal<sc_uint<2>> m0_b_wait_states;
        sc_signal<sc_uint<2>> m0_b_wait_cnt;
        sc_signal<bool> m0_b_ready;
        sc_signal<bool> m0_ar_valid;
        sc_signal<sc_uint<48>> m0_ar_addr;
        sc_signal<sc_uint<8>> m0_ar_xlen;
        sc_signal<sc_uint<3>> m0_r_wait_states;
        sc_signal<sc_uint<3>> m0_r_wait_cnt;
        sc_signal<bool> m0_r_ready;
        sc_signal<sc_uint<4>> m0_r_burst_cnt;
        sc_signal<bool> m0_compare_ena;
        sc_signal<sc_uint<64>> m0_compare_a;
        sc_signal<sc_uint<64>> m0_compare_b;
        sc_signal<sc_uint<3>> m1_state;
        sc_signal<bool> end_of_test;
        sc_signal<bool> end_idle;
        sc_signal<sc_uint<2>> slvstate;
        sc_signal<bool> req_ready;
        sc_signal<bool> resp_valid;
        sc_signal<sc_uint<64>> resp_rdata;
        sc_signal<sc_uint<3>> resp_wait_states;
        sc_signal<sc_uint<3>> resp_wait_cnt;
    };

    void accel_axictrl_bus0_tb_r_reset(accel_axictrl_bus0_tb_registers& iv) {
        iv.clk_cnt = 0;
        iv.err_cnt = 0;
        iv.test_cnt = 0;
        iv.test_pause_cnt = 0;
        iv.m0_state = 0;
        iv.m0_xsize = 3;
        iv.m0_aw_valid = 0;
        iv.m0_aw_addr = 0;
        iv.m0_aw_xlen = 0;
        iv.m0_w_wait_states = 0;
        iv.m0_w_wait_cnt = 0;
        iv.m0_w_valid = 0;
        iv.m0_w_data = 0;
        iv.m0_w_strb = 0;
        iv.m0_w_last = 0;
        iv.m0_w_burst_cnt = 0;
        iv.m0_b_wait_states = 0;
        iv.m0_b_wait_cnt = 0;
        iv.m0_b_ready = 0;
        iv.m0_ar_valid = 0;
        iv.m0_ar_addr = 0;
        iv.m0_ar_xlen = 0;
        iv.m0_r_wait_states = 0;
        iv.m0_r_wait_cnt = 0;
        iv.m0_r_ready = 0;
        iv.m0_r_burst_cnt = 0;
        iv.m0_compare_ena = 0;
        iv.m0_compare_a = 0;
        iv.m0_compare_b = 0;
        iv.m1_state = 0;
        iv.end_of_test = 0;
        iv.end_idle = 0;
        iv.slvstate = 0;
        iv.req_ready = 0;
        iv.resp_valid = 0;
        iv.resp_rdata = 0;
        iv.resp_wait_states = 0;
        iv.resp_wait_cnt = 0;
    }

    sc_signal<bool> nrst;                                   // Power-on system reset active LOW
    sc_signal<bool> clk;
    sc_signal<dev_config_type> wb_bus0_cfg;
    sc_signal<dev_config_type> wb_xslv0_cfg;
    bus0_xmst_out_vector vec_i_xmsto;
    bus0_xmst_in_vector vec_o_xmsti;
    bus0_xslv_out_vector vec_i_xslvo;
    bus0_xslv_in_vector vec_o_xslvi;
    bus0_mapinfo_vector vec_o_mapinfo;
    sc_signal<bool> w_req_valid;
    sc_signal<sc_uint<48>> wb_req_addr;
    sc_signal<sc_uint<8>> wb_req_size;
    sc_signal<bool> w_req_write;
    sc_signal<sc_uint<64>> wb_req_wdata;
    sc_signal<sc_uint<8>> wb_req_wstrb;
    sc_signal<bool> w_req_last;
    sc_signal<bool> w_req_ready;
    sc_signal<bool> w_resp_valid;
    sc_signal<sc_uint<64>> wb_resp_rdata;
    sc_signal<bool> w_resp_err;
    sc_signal<axi4_master_in_type> wb_m0_xmsti;
    sc_signal<axi4_master_in_type> wb_m1_xmsti;
    std::string msg;
    sc_uint<64> mem[16];
    accel_axictrl_bus0_tb_registers v;
    accel_axictrl_bus0_tb_registers r;

    pll_generic *clk0;
    accel_axictrl_bus0 *bus0;
    axi_slv *xslv0;

};

}  // namespace debugger

