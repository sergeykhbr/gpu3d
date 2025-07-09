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

#include "accel_axictrl_bus0_tb.h"
#include "api_core.h"

namespace debugger {

accel_axictrl_bus0_tb::accel_axictrl_bus0_tb(sc_module_name name)
    : sc_module(name),
    vec_i_xmsto("vec_i_xmsto", CFG_BUS0_XMST_TOTAL),
    vec_o_xmsti("vec_o_xmsti", CFG_BUS0_XMST_TOTAL),
    vec_i_xslvo("vec_i_xslvo", CFG_BUS0_XSLV_TOTAL),
    vec_o_xslvi("vec_o_xslvi", CFG_BUS0_XSLV_TOTAL),
    vec_o_mapinfo("vec_o_mapinfo", CFG_BUS0_XSLV_TOTAL) {

    clk0 = 0;
    bus0 = 0;
    xslv0 = 0;
    xslv1 = 0;
    mst0 = 0;
    mst1 = 0;
    mst2 = 0;

    clk0 = new pll_generic("clk0",
                            10.0);
    clk0->o_clk(clk);

    bus0 = new accel_axictrl_bus0("bus0",
                                   0);
    bus0->i_clk(clk);
    bus0->i_nrst(nrst);
    bus0->o_cfg(wb_bus0_cfg);
    bus0->i_xmsto(vec_i_xmsto);
    bus0->o_xmsti(vec_o_xmsti);
    bus0->i_xslvo(vec_i_xslvo);
    bus0->o_xslvi(vec_o_xslvi);
    bus0->o_mapinfo(vec_o_mapinfo);

    xslv0 = new axi_slv("xslv0",
                         0,
                         0,
                         0);
    xslv0->i_clk(clk);
    xslv0->i_nrst(nrst);
    xslv0->i_mapinfo(vec_o_mapinfo[CFG_BUS0_XSLV_DDR]);
    xslv0->o_cfg(wb_s0_cfg);
    xslv0->i_xslvi(vec_o_xslvi[CFG_BUS0_XSLV_DDR]);
    xslv0->o_xslvo(vec_i_xslvo[CFG_BUS0_XSLV_DDR]);
    xslv0->o_req_valid(w_s0_req_valid);
    xslv0->o_req_addr(wb_s0_req_addr);
    xslv0->o_req_size(wb_s0_req_size);
    xslv0->o_req_write(w_s0_req_write);
    xslv0->o_req_wdata(wb_s0_req_wdata);
    xslv0->o_req_wstrb(wb_s0_req_wstrb);
    xslv0->o_req_last(w_s0_req_last);
    xslv0->i_req_ready(w_s0_req_ready);
    xslv0->i_resp_valid(w_s0_resp_valid);
    xslv0->i_resp_rdata(wb_s0_resp_rdata);
    xslv0->i_resp_err(w_s0_resp_err);

    xslv1 = new axi_slv("xslv1",
                         0,
                         0,
                         0);
    xslv1->i_clk(clk);
    xslv1->i_nrst(nrst);
    xslv1->i_mapinfo(vec_o_mapinfo[CFG_BUS0_XSLV_SRAM]);
    xslv1->o_cfg(wb_s1_cfg);
    xslv1->i_xslvi(vec_o_xslvi[CFG_BUS0_XSLV_SRAM]);
    xslv1->o_xslvo(vec_i_xslvo[CFG_BUS0_XSLV_SRAM]);
    xslv1->o_req_valid(w_s1_req_valid);
    xslv1->o_req_addr(wb_s1_req_addr);
    xslv1->o_req_size(wb_s1_req_size);
    xslv1->o_req_write(w_s1_req_write);
    xslv1->o_req_wdata(wb_s1_req_wdata);
    xslv1->o_req_wstrb(wb_s1_req_wstrb);
    xslv1->o_req_last(w_s1_req_last);
    xslv1->i_req_ready(w_s1_req_ready);
    xslv1->i_resp_valid(w_s1_resp_valid);
    xslv1->i_resp_rdata(wb_s1_resp_rdata);
    xslv1->i_resp_err(w_s1_resp_err);

    mst0 = new axi_mst_generator("mst0",
                                  0x000081000000,
                                  0x0,
                                  0x7FFFFFFFFFFFFFFF,
                                  0);
    mst0->i_nrst(nrst);
    mst0->i_clk(clk);
    mst0->i_xmst(vec_o_xmsti[CFG_BUS0_XMST_GROUP0]);
    mst0->o_xmst(vec_i_xmsto[CFG_BUS0_XMST_GROUP0]);
    mst0->i_start_test(r.m0_start_ena);
    mst0->i_test_selector(r.m0_test_selector);
    mst0->i_show_result(r.end_of_test);
    mst0->o_writing(w_m0_writing);
    mst0->o_reading(w_m0_reading);

    mst1 = new axi_mst_generator("mst1",
                                  0x000082000000,
                                  0x1,
                                  0x7FFFFFFFFFFFFFFF,
                                  0);
    mst1->i_nrst(nrst);
    mst1->i_clk(clk);
    mst1->i_xmst(vec_o_xmsti[CFG_BUS0_XMST_PCIE]);
    mst1->o_xmst(vec_i_xmsto[CFG_BUS0_XMST_PCIE]);
    mst1->i_start_test(r.m1_start_ena);
    mst1->i_test_selector(r.m1_test_selector);
    mst1->i_show_result(r.end_of_test);
    mst1->o_writing(w_m1_writing);
    mst1->o_reading(w_m1_reading);

    mst2 = new axi_mst_generator("mst2",
                                  0x000008000000,
                                  0x2,
                                  0xCAFEF00D33221100,
                                  1);
    mst2->i_nrst(nrst);
    mst2->i_clk(clk);
    mst2->i_xmst(vec_o_xmsti[CFG_BUS0_XMST_HDMI]);
    mst2->o_xmst(vec_i_xmsto[CFG_BUS0_XMST_HDMI]);
    mst2->i_start_test(r.m2_start_ena);
    mst2->i_test_selector(r.m2_test_selector);
    mst2->i_show_result(r.end_of_test);
    mst2->o_writing(w_m2_writing);
    mst2->o_reading(w_m2_reading);

    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << nrst;
    sensitive << clk;
    sensitive << wb_bus0_cfg;
    for (int i = 0; i < CFG_BUS0_XMST_TOTAL; i++) {
        sensitive << vec_i_xmsto[i];
    }
    for (int i = 0; i < CFG_BUS0_XMST_TOTAL; i++) {
        sensitive << vec_o_xmsti[i];
    }
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << vec_i_xslvo[i];
    }
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << vec_o_xslvi[i];
    }
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << vec_o_mapinfo[i];
    }
    sensitive << wb_s0_cfg;
    sensitive << w_s0_req_valid;
    sensitive << wb_s0_req_addr;
    sensitive << wb_s0_req_size;
    sensitive << w_s0_req_write;
    sensitive << wb_s0_req_wdata;
    sensitive << wb_s0_req_wstrb;
    sensitive << w_s0_req_last;
    sensitive << w_s0_req_ready;
    sensitive << w_s0_resp_valid;
    sensitive << wb_s0_resp_rdata;
    sensitive << w_s0_resp_err;
    sensitive << wb_s1_cfg;
    sensitive << w_s1_req_valid;
    sensitive << wb_s1_req_addr;
    sensitive << wb_s1_req_size;
    sensitive << w_s1_req_write;
    sensitive << wb_s1_req_wdata;
    sensitive << wb_s1_req_wstrb;
    sensitive << w_s1_req_last;
    sensitive << w_s1_req_ready;
    sensitive << w_s1_resp_valid;
    sensitive << wb_s1_resp_rdata;
    sensitive << w_s1_resp_err;
    sensitive << w_m0_writing;
    sensitive << w_m0_reading;
    sensitive << w_m1_writing;
    sensitive << w_m1_reading;
    sensitive << w_m2_writing;
    sensitive << w_m2_reading;
    sensitive << r.clk_cnt;
    sensitive << r.err_cnt;
    sensitive << r.test_cnt;
    sensitive << r.test_pause_cnt;
    sensitive << r.m0_start_ena;
    sensitive << r.m0_test_selector;
    sensitive << r.m1_start_ena;
    sensitive << r.m1_test_selector;
    sensitive << r.m2_start_ena;
    sensitive << r.m2_test_selector;
    sensitive << r.s0_state;
    sensitive << r.req_s0_ready;
    sensitive << r.resp_s0_valid;
    sensitive << r.resp_s0_rdata;
    sensitive << r.resp_s0_wait_states;
    sensitive << r.resp_s0_wait_cnt;
    sensitive << r.end_of_test;
    sensitive << r.end_idle;

    SC_METHOD(test);
    sensitive << clk.posedge_event();

    SC_METHOD(registers);
    sensitive << nrst;
    sensitive << clk.posedge_event();
}

accel_axictrl_bus0_tb::~accel_axictrl_bus0_tb() {
    if (clk0) {
        delete clk0;
    }
    if (bus0) {
        delete bus0;
    }
    if (xslv0) {
        delete xslv0;
    }
    if (xslv1) {
        delete xslv1;
    }
    if (mst0) {
        delete mst0;
    }
    if (mst1) {
        delete mst1;
    }
    if (mst2) {
        delete mst2;
    }
}

void accel_axictrl_bus0_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, r.clk_cnt, pn + ".r.clk_cnt");
        sc_trace(o_vcd, r.err_cnt, pn + ".r.err_cnt");
        sc_trace(o_vcd, r.test_cnt, pn + ".r.test_cnt");
        sc_trace(o_vcd, r.test_pause_cnt, pn + ".r.test_pause_cnt");
        sc_trace(o_vcd, r.m0_start_ena, pn + ".r.m0_start_ena");
        sc_trace(o_vcd, r.m0_test_selector, pn + ".r.m0_test_selector");
        sc_trace(o_vcd, r.m1_start_ena, pn + ".r.m1_start_ena");
        sc_trace(o_vcd, r.m1_test_selector, pn + ".r.m1_test_selector");
        sc_trace(o_vcd, r.m2_start_ena, pn + ".r.m2_start_ena");
        sc_trace(o_vcd, r.m2_test_selector, pn + ".r.m2_test_selector");
        sc_trace(o_vcd, r.s0_state, pn + ".r.s0_state");
        sc_trace(o_vcd, r.req_s0_ready, pn + ".r.req_s0_ready");
        sc_trace(o_vcd, r.resp_s0_valid, pn + ".r.resp_s0_valid");
        sc_trace(o_vcd, r.resp_s0_rdata, pn + ".r.resp_s0_rdata");
        sc_trace(o_vcd, r.resp_s0_wait_states, pn + ".r.resp_s0_wait_states");
        sc_trace(o_vcd, r.resp_s0_wait_cnt, pn + ".r.resp_s0_wait_cnt");
        sc_trace(o_vcd, r.end_of_test, pn + ".r.end_of_test");
        sc_trace(o_vcd, r.end_idle, pn + ".r.end_idle");
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
    if (bus0) {
        bus0->generateVCD(i_vcd, o_vcd);
    }
    if (xslv0) {
        xslv0->generateVCD(i_vcd, o_vcd);
    }
    if (xslv1) {
        xslv1->generateVCD(i_vcd, o_vcd);
    }
    if (mst0) {
        mst0->generateVCD(i_vcd, o_vcd);
    }
    if (mst1) {
        mst1->generateVCD(i_vcd, o_vcd);
    }
    if (mst2) {
        mst2->generateVCD(i_vcd, o_vcd);
    }
}

void accel_axictrl_bus0_tb::init() {
    nrst = 0;
    wait(static_cast<int>(200.0), SC_NS);
    nrst = 1;
}

void accel_axictrl_bus0_tb::comb() {
    sc_uint<32> vb_test_cnt_inv;

    v = r;
    vb_test_cnt_inv = 0;


    vb_test_cnt_inv = (~r.test_cnt.read());
    v.clk_cnt = (r.clk_cnt.read() + 1);
    v.end_of_test = 0;
    v.end_idle = (r.end_of_test.read() || r.end_idle.read());
    v.m0_start_ena = 0;
    v.m1_start_ena = 0;
    v.m2_start_ena = 0;

    // ddr simulation with controllable wait states
    switch (r.s0_state.read()) {
    case 0:
        v.req_s0_ready = 1;
        v.resp_s0_valid = 0;
        if ((w_s0_req_valid.read() == 1) && (r.req_s0_ready.read() == 1)) {
            if (w_s0_req_write.read() == 1) {
                v.resp_s0_rdata = ~0ull;
            } else {
                if (wb_s0_req_addr.read()[25] == 0) {
                    v.resp_s0_rdata = s0_mem0[wb_s0_req_addr.read()(5, 2).to_int()];
                } else {
                    v.resp_s0_rdata = s0_mem1[wb_s0_req_addr.read()(5, 2).to_int()];
                }
            }
            if (r.resp_s0_wait_states.read().or_reduce() == 0) {
                v.resp_s0_valid = 1;
            } else {
                v.req_s0_ready = 0;
                v.resp_s0_wait_cnt = (r.resp_s0_wait_states.read() - 1);
                v.s0_state = 1;
            }
        }
        break;
    case 1:
        if (r.resp_s0_wait_cnt.read().or_reduce() == 1) {
            v.resp_s0_wait_cnt = (r.resp_s0_wait_cnt.read() - 1);
        } else {
            v.resp_s0_valid = 1;
            v.s0_state = 2;
        }
        break;
    case 2:
        v.resp_s0_valid = 0;
        v.s0_state = 0;
        break;
    }

    if (r.end_idle.read() == 1) {
        // Do nothing
    } else if ((r.test_pause_cnt.read().or_reduce() == 1)
                && (w_m0_writing.read() == 0)
                && (w_m0_reading.read() == 0)
                && (w_m1_writing.read() == 0)
                && (w_m1_reading.read() == 0)
                && (w_m2_writing.read() == 0)) {
        v.test_pause_cnt = (r.test_pause_cnt.read() - 1);
    } else if (r.test_pause_cnt.read().or_reduce() == 0) {
        v.test_cnt = (r.test_cnt.read() + 1);
        v.resp_s0_wait_states = r.test_cnt.read()(1, 0);
        v.m0_test_selector = (0, r.test_cnt.read()(31, 2));
        v.m0_start_ena = 1;
        if (r.test_cnt.read()[0] == 0) {
            v.m1_test_selector = (0, r.test_cnt.read()(31, 1));
            v.m1_start_ena = 1;
        }
        v.m2_test_selector = 0x00000C00;                    // Burst 4, with zero wait states
        v.m2_start_ena = 1;
        if (r.test_cnt.read()[15] == 1) {
            // End of test (show err_cnt)
            v.end_of_test = 1;
        }
        v.test_pause_cnt = 10;
    } else {
        v.test_pause_cnt = 10;
    }
    if ((r.test_cnt.read()[0] == 1)
            && (w_m0_reading.read() == 1)
            && ((w_m1_writing.read() | w_m1_reading.read()) == 0)) {
        // Check delayed writing after reading
        v.m1_test_selector = r.test_cnt.read()(11, 1);
        v.m1_start_ena = 1;
    }

    w_s0_req_ready = r.req_s0_ready.read();
    w_s0_resp_valid = r.resp_s0_valid.read();
    wb_s0_resp_rdata = r.resp_s0_rdata.read();
    w_s0_resp_err = 0;

    w_s1_req_ready = 1;
    w_s1_resp_valid = 1;
    wb_s1_resp_rdata = 0xCAFEF00D33221100;
    w_s1_resp_err = 0;

    vec_i_xslvo[CFG_BUS0_XSLV_BOOTROM] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_CLINT] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_PLIC] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_PBRIDGE] = axi4_slave_out_none;
}

void accel_axictrl_bus0_tb::test() {
    if ((w_s0_req_write.read() == 1) && (w_s0_req_valid.read() == 1)) {
        if (wb_s0_req_addr.read()[25] == 0) {
            s0_mem0[wb_s0_req_addr.read()(5, 2).to_int()] = wb_s0_req_wdata.read();
        } else {
            s0_mem1[wb_s0_req_addr.read()(5, 2).to_int()] = wb_s0_req_wdata.read();
        }
    }
}

void accel_axictrl_bus0_tb::registers() {
    if (nrst.read() == 0) {
        accel_axictrl_bus0_tb_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

