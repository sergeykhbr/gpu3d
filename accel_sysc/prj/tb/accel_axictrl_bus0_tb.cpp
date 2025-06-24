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
    mst0 = 0;
    mst1 = 0;

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
    xslv0->o_cfg(wb_xslv0_cfg);
    xslv0->i_xslvi(vec_o_xslvi[CFG_BUS0_XSLV_DDR]);
    xslv0->o_xslvo(vec_i_xslvo[CFG_BUS0_XSLV_DDR]);
    xslv0->o_req_valid(w_req_valid);
    xslv0->o_req_addr(wb_req_addr);
    xslv0->o_req_size(wb_req_size);
    xslv0->o_req_write(w_req_write);
    xslv0->o_req_wdata(wb_req_wdata);
    xslv0->o_req_wstrb(wb_req_wstrb);
    xslv0->o_req_last(w_req_last);
    xslv0->i_req_ready(w_req_ready);
    xslv0->i_resp_valid(w_resp_valid);
    xslv0->i_resp_rdata(wb_resp_rdata);
    xslv0->i_resp_err(w_resp_err);

    mst0 = new axi_mst_generator("mst0",
                                  0x000081000000);
    mst0->i_nrst(nrst);
    mst0->i_clk(clk);
    mst0->i_xmst(vec_o_xmsti[CFG_BUS0_XMST_GROUP0]);
    mst0->o_xmst(vec_i_xmsto[CFG_BUS0_XMST_GROUP0]);
    mst0->i_start_test(r.m0_start_ena);
    mst0->i_test_selector(r.m0_test_selector);
    mst0->i_show_result(r.end_of_test);
    mst0->o_test_busy(w_m0_busy);

    mst1 = new axi_mst_generator("mst1",
                                  0x000082000000);
    mst1->i_nrst(nrst);
    mst1->i_clk(clk);
    mst1->i_xmst(vec_o_xmsti[CFG_BUS0_XMST_HDMI]);
    mst1->o_xmst(vec_i_xmsto[CFG_BUS0_XMST_HDMI]);
    mst1->i_start_test(r.m1_start_ena);
    mst1->i_test_selector(r.m1_test_selector);
    mst1->i_show_result(r.end_of_test);
    mst1->o_test_busy(w_m1_busy);

    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << nrst;
    sensitive << clk;
    sensitive << wb_bus0_cfg;
    sensitive << wb_xslv0_cfg;
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
    sensitive << w_req_valid;
    sensitive << wb_req_addr;
    sensitive << wb_req_size;
    sensitive << w_req_write;
    sensitive << wb_req_wdata;
    sensitive << wb_req_wstrb;
    sensitive << w_req_last;
    sensitive << w_req_ready;
    sensitive << w_resp_valid;
    sensitive << wb_resp_rdata;
    sensitive << w_resp_err;
    sensitive << w_m0_busy;
    sensitive << w_m1_busy;
    sensitive << r.clk_cnt;
    sensitive << r.err_cnt;
    sensitive << r.test_cnt;
    sensitive << r.test_pause_cnt;
    sensitive << r.m0_start_ena;
    sensitive << r.m0_test_selector;
    sensitive << r.m1_start_ena;
    sensitive << r.m1_test_selector;
    sensitive << r.end_of_test;
    sensitive << r.end_idle;
    sensitive << r.slvstate;
    sensitive << r.req_ready;
    sensitive << r.resp_valid;
    sensitive << r.resp_rdata;
    sensitive << r.resp_wait_states;
    sensitive << r.resp_wait_cnt;

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
    if (mst0) {
        delete mst0;
    }
    if (mst1) {
        delete mst1;
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
        sc_trace(o_vcd, r.end_of_test, pn + ".r.end_of_test");
        sc_trace(o_vcd, r.end_idle, pn + ".r.end_idle");
        sc_trace(o_vcd, r.slvstate, pn + ".r.slvstate");
        sc_trace(o_vcd, r.req_ready, pn + ".r.req_ready");
        sc_trace(o_vcd, r.resp_valid, pn + ".r.resp_valid");
        sc_trace(o_vcd, r.resp_rdata, pn + ".r.resp_rdata");
        sc_trace(o_vcd, r.resp_wait_states, pn + ".r.resp_wait_states");
        sc_trace(o_vcd, r.resp_wait_cnt, pn + ".r.resp_wait_cnt");
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
    if (mst0) {
        mst0->generateVCD(i_vcd, o_vcd);
    }
    if (mst1) {
        mst1->generateVCD(i_vcd, o_vcd);
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

    // ddr simulation with controllable wait states
    switch (r.slvstate.read()) {
    case 0:
        v.req_ready = 1;
        v.resp_valid = 0;
        if ((w_req_valid.read() == 1) && (r.req_ready.read() == 1)) {
            if (w_req_write.read() == 1) {
                v.resp_rdata = ~0ull;
            } else {
                if (wb_req_addr.read()[25] == 0) {
                    v.resp_rdata = mem0[wb_req_addr.read()(5, 2).to_int()];
                } else {
                    v.resp_rdata = mem1[wb_req_addr.read()(5, 2).to_int()];
                }
            }
            if (r.resp_wait_states.read().or_reduce() == 0) {
                v.resp_valid = 1;
            } else {
                v.req_ready = 0;
                v.resp_wait_cnt = (r.resp_wait_states.read() - 1);
                v.slvstate = 1;
            }
        }
        break;
    case 1:
        if (r.resp_wait_cnt.read().or_reduce() == 1) {
            v.resp_wait_cnt = (r.resp_wait_cnt.read() - 1);
        } else {
            v.resp_valid = 1;
            v.slvstate = 2;
        }
        break;
    case 2:
        v.resp_valid = 0;
        v.slvstate = 0;
        break;
    }

    if (r.end_idle.read() == 1) {
        // Do nothing
    } else if ((r.test_pause_cnt.read().or_reduce() == 1)
                && (w_m0_busy.read() == 0)
                && (w_m1_busy.read() == 0)) {
        v.test_pause_cnt = (r.test_pause_cnt.read() - 1);
    } else if (r.test_pause_cnt.read().or_reduce() == 0) {
        v.test_cnt = (r.test_cnt.read() + 1);
        v.resp_wait_states = r.test_cnt.read()(1, 0);
        v.m0_test_selector = r.test_cnt.read()(11, 2);
        v.m0_start_ena = 1;
        v.m1_test_selector = r.test_cnt.read()(10, 1);
        v.m1_start_ena = 1;
        if (r.test_cnt.read()[13] == 1) {
            // End of test (show err_cnt)
            v.end_of_test = 1;
        }
        v.test_pause_cnt = 10;
    } else {
        v.test_pause_cnt = 10;
    }

    w_req_ready = r.req_ready.read();
    w_resp_valid = r.resp_valid.read();
    wb_resp_rdata = r.resp_rdata.read();
    w_resp_err = 0;

    vec_i_xmsto[CFG_BUS0_XMST_PCIE] = axi4_master_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_BOOTROM] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_CLINT] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_SRAM] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_PLIC] = axi4_slave_out_none;
    vec_i_xslvo[CFG_BUS0_XSLV_PBRIDGE] = axi4_slave_out_none;
    w_resp_valid = r.resp_valid.read();
    wb_resp_rdata = r.resp_rdata.read();
    w_resp_err = 0;
}

void accel_axictrl_bus0_tb::test() {
    if ((w_req_write.read() == 1) && (w_req_valid.read() == 1)) {
        if (wb_req_addr.read()[25] == 0) {
            mem0[wb_req_addr.read()(5, 2).to_int()] = wb_req_wdata.read();
        } else {
            mem1[wb_req_addr.read()(5, 2).to_int()] = wb_req_wdata.read();
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

