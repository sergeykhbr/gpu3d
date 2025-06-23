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
    sensitive << wb_m0_xmsti;
    sensitive << wb_m1_xmsti;
    sensitive << r.clk_cnt;
    sensitive << r.err_cnt;
    sensitive << r.test_cnt;
    sensitive << r.test_pause_cnt;
    sensitive << r.m0_state;
    sensitive << r.m0_xsize;
    sensitive << r.m0_aw_valid;
    sensitive << r.m0_aw_addr;
    sensitive << r.m0_aw_xlen;
    sensitive << r.m0_w_wait_states;
    sensitive << r.m0_w_wait_cnt;
    sensitive << r.m0_w_valid;
    sensitive << r.m0_w_data;
    sensitive << r.m0_w_strb;
    sensitive << r.m0_w_last;
    sensitive << r.m0_w_burst_cnt;
    sensitive << r.m0_b_wait_states;
    sensitive << r.m0_b_wait_cnt;
    sensitive << r.m0_b_ready;
    sensitive << r.m0_ar_valid;
    sensitive << r.m0_ar_addr;
    sensitive << r.m0_ar_xlen;
    sensitive << r.m0_r_wait_states;
    sensitive << r.m0_r_wait_cnt;
    sensitive << r.m0_r_ready;
    sensitive << r.m0_r_burst_cnt;
    sensitive << r.m0_compare_ena;
    sensitive << r.m0_compare_a;
    sensitive << r.m0_compare_b;
    sensitive << r.m1_state;
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
}

void accel_axictrl_bus0_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, r.clk_cnt, pn + ".r.clk_cnt");
        sc_trace(o_vcd, r.err_cnt, pn + ".r.err_cnt");
        sc_trace(o_vcd, r.test_cnt, pn + ".r.test_cnt");
        sc_trace(o_vcd, r.test_pause_cnt, pn + ".r.test_pause_cnt");
        sc_trace(o_vcd, r.m0_state, pn + ".r.m0_state");
        sc_trace(o_vcd, r.m0_xsize, pn + ".r.m0_xsize");
        sc_trace(o_vcd, r.m0_aw_valid, pn + ".r.m0_aw_valid");
        sc_trace(o_vcd, r.m0_aw_addr, pn + ".r.m0_aw_addr");
        sc_trace(o_vcd, r.m0_aw_xlen, pn + ".r.m0_aw_xlen");
        sc_trace(o_vcd, r.m0_w_wait_states, pn + ".r.m0_w_wait_states");
        sc_trace(o_vcd, r.m0_w_wait_cnt, pn + ".r.m0_w_wait_cnt");
        sc_trace(o_vcd, r.m0_w_valid, pn + ".r.m0_w_valid");
        sc_trace(o_vcd, r.m0_w_data, pn + ".r.m0_w_data");
        sc_trace(o_vcd, r.m0_w_strb, pn + ".r.m0_w_strb");
        sc_trace(o_vcd, r.m0_w_last, pn + ".r.m0_w_last");
        sc_trace(o_vcd, r.m0_w_burst_cnt, pn + ".r.m0_w_burst_cnt");
        sc_trace(o_vcd, r.m0_b_wait_states, pn + ".r.m0_b_wait_states");
        sc_trace(o_vcd, r.m0_b_wait_cnt, pn + ".r.m0_b_wait_cnt");
        sc_trace(o_vcd, r.m0_b_ready, pn + ".r.m0_b_ready");
        sc_trace(o_vcd, r.m0_ar_valid, pn + ".r.m0_ar_valid");
        sc_trace(o_vcd, r.m0_ar_addr, pn + ".r.m0_ar_addr");
        sc_trace(o_vcd, r.m0_ar_xlen, pn + ".r.m0_ar_xlen");
        sc_trace(o_vcd, r.m0_r_wait_states, pn + ".r.m0_r_wait_states");
        sc_trace(o_vcd, r.m0_r_wait_cnt, pn + ".r.m0_r_wait_cnt");
        sc_trace(o_vcd, r.m0_r_ready, pn + ".r.m0_r_ready");
        sc_trace(o_vcd, r.m0_r_burst_cnt, pn + ".r.m0_r_burst_cnt");
        sc_trace(o_vcd, r.m0_compare_ena, pn + ".r.m0_compare_ena");
        sc_trace(o_vcd, r.m0_compare_a, pn + ".r.m0_compare_a");
        sc_trace(o_vcd, r.m0_compare_b, pn + ".r.m0_compare_b");
        sc_trace(o_vcd, r.m1_state, pn + ".r.m1_state");
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
}

void accel_axictrl_bus0_tb::init() {
    nrst = 0;
    wait(static_cast<int>(200.0), SC_NS);
    nrst = 1;
}

void accel_axictrl_bus0_tb::comb() {
    axi4_master_out_type vb_m0_xmsto;
    axi4_master_out_type vb_m1_xmsto;
    sc_uint<48> vb_bar;
    sc_uint<4> vb_m0_w_burst_cnt_next;
    sc_uint<32> vb_test_cnt_inv;

    v = r;
    vb_bar = 0;
    vb_m0_w_burst_cnt_next = 0;
    vb_test_cnt_inv = 0;


    wb_m0_xmsti = vec_o_xmsti[CFG_BUS0_XMST_GROUP0];
    wb_m1_xmsti = vec_o_xmsti[CFG_BUS0_XMST_HDMI];
    vb_test_cnt_inv = (~r.test_cnt.read());
    vb_m0_w_burst_cnt_next = (r.m0_w_burst_cnt.read() + 1);
    vb_bar = 0x0000000081000000;
    v.clk_cnt = (r.clk_cnt.read() + 1);
    v.m0_compare_ena = 0;
    v.end_of_test = 0;
    v.end_idle = (r.end_of_test.read() || r.end_idle.read());

    // ddr simulation with controllable wait states
    switch (r.slvstate.read()) {
    case 0:
        v.req_ready = 1;
        v.resp_valid = 0;
        if ((w_req_valid.read() == 1) && (r.req_ready.read() == 1)) {
            if (w_req_write.read() == 1) {
                v.resp_rdata = ~0ull;
            } else {
                v.resp_rdata = mem[wb_req_addr.read()(5, 2).to_int()];
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

    // AXI master[0] request state machines
    switch (r.m0_state.read()) {
    case 0:
        if (r.test_pause_cnt.read().or_reduce() == 0) {
            if (r.end_of_test.read() == 1) {
                v.m0_state = 0xF;
            } else {
                v.m0_state = 1;
            }
        }
        break;
    case 1:                                                 // aw request
        v.m0_aw_valid = 1;
        v.m0_aw_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 5));
        v.m0_w_burst_cnt = 0;
        if ((r.m0_aw_valid.read() == 1) && (wb_m0_xmsti.read().aw_ready == 1)) {
            v.m0_aw_valid = 0;
            v.m0_w_data = (vb_test_cnt_inv, r.test_cnt.read()(27, 0), r.m0_w_burst_cnt.read());
            v.m0_w_strb = 0xFF;
            if (r.m0_w_wait_states.read().or_reduce() == 0) {
                v.m0_w_wait_cnt = 0;
                v.m0_w_valid = 1;
                v.m0_w_last = (!r.m0_aw_xlen.read().or_reduce());
                v.m0_state = 3;
            } else {
                v.m0_state = 2;
                v.m0_w_wait_cnt = r.m0_w_wait_states.read();
            }
        }
        break;
    case 2:                                                 // w wait request
        if (r.m0_w_wait_cnt.read().or_reduce() == 1) {
            v.m0_w_wait_cnt = (r.m0_w_wait_cnt.read() - 1);
        } else {
            v.m0_w_valid = 1;
            v.m0_w_last = (!r.m0_aw_xlen.read().or_reduce());
            v.m0_state = 3;
        }
        break;
    case 3:                                                 // w request
        v.m0_w_valid = 1;
        v.m0_w_data = (vb_test_cnt_inv, r.test_cnt.read()(27, 0), r.m0_w_burst_cnt.read());
        if ((r.m0_w_valid.read() == 1) && (wb_m0_xmsti.read().w_ready == 1)) {
            v.m0_w_burst_cnt = vb_m0_w_burst_cnt_next;
            v.m0_w_data = (vb_test_cnt_inv, r.test_cnt.read()(27, 0), vb_m0_w_burst_cnt_next);
            v.m0_w_valid = 0;
            v.m0_w_last = 0;
            v.m0_w_wait_cnt = r.m0_w_wait_states.read();
            if (r.m0_aw_xlen.read().or_reduce() == 1) {
                v.m0_aw_xlen = (r.m0_aw_xlen.read() - 1);
                if (r.m0_w_wait_states.read().or_reduce() == 0) {
                    v.m0_w_valid = 1;
                    v.m0_w_last = (!r.m0_aw_xlen.read()(7, 1).or_reduce());
                } else {
                    v.m0_state = 2;
                }
            } else {
                if (r.m0_b_wait_states.read().or_reduce() == 0) {
                    v.m0_b_wait_cnt = 0;
                    v.m0_b_ready = 1;
                } else {
                    v.m0_b_wait_cnt = r.m0_b_wait_states.read();
                }
                v.m0_state = 4;
            }
        }
        break;
    case 4:                                                 // b response
        v.m0_w_burst_cnt = 0;
        if (r.m0_b_wait_cnt.read().or_reduce() == 1) {
            v.m0_b_wait_cnt = (r.m0_b_wait_cnt.read() - 1);
        } else {
            v.m0_b_ready = 1;
            if ((r.m0_b_ready.read() == 1) && (wb_m0_xmsti.read().b_valid == 1)) {
                v.m0_b_ready = 0;
                v.m0_state = 5;
                v.m0_ar_valid = 1;
                v.m0_ar_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 5));
            }
        }
        break;
    case 5:                                                 // ar request
        v.m0_ar_valid = 1;
        v.m0_ar_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 5));
        if ((r.m0_ar_valid.read() == 1) && (wb_m0_xmsti.read().ar_ready == 1)) {
            v.m0_ar_valid = 0;
            v.m0_r_burst_cnt = 0;
            if (r.m0_r_wait_states.read().or_reduce() == 0) {
                v.m0_r_wait_cnt = 0;
                v.m0_r_ready = 1;
                v.m0_state = 7;
            } else {
                v.m0_state = 6;
                v.m0_r_wait_cnt = r.m0_r_wait_states.read();
            }
        }
        break;
    case 6:
        if (r.m0_r_wait_cnt.read().or_reduce() == 1) {
            v.m0_r_wait_cnt = (r.m0_r_wait_cnt.read() - 1);
        } else {
            v.m0_r_ready = 1;
            v.m0_state = 7;
        }
        break;
    case 7:                                                 // r response
        v.m0_r_ready = 1;
        if ((r.m0_r_ready.read() == 1) && (wb_m0_xmsti.read().r_valid == 1)) {
            v.m0_r_burst_cnt = (r.m0_r_burst_cnt.read() + 1);
            v.m0_r_ready = 0;
            v.m0_compare_ena = 1;
            v.m0_compare_a = wb_m0_xmsti.read().r_data;
            v.m0_compare_b = (vb_test_cnt_inv, r.test_cnt.read()(27, 0), r.m0_r_burst_cnt.read());
            if (wb_m0_xmsti.read().r_last == 1) {
                // Goto idle
                v.m0_state = 0;
            } else {
                if (r.m0_r_wait_states.read().or_reduce() == 0) {
                    v.m0_r_ready = 1;
                } else {
                    v.m0_r_wait_cnt = r.m0_r_wait_states.read();
                    v.m0_state = 6;
                }
            }
        }
        break;
    case 15:                                                // do nothing
        break;
    }

    if (r.end_idle.read() == 1) {
        // Do nothing
    } else if ((r.test_pause_cnt.read().or_reduce() == 1)
                && (r.m0_state.read().or_reduce() == 0)
                && (r.m1_state.read().or_reduce() == 0)) {
        v.test_pause_cnt = (r.test_pause_cnt.read() - 1);
    } else if (r.test_pause_cnt.read().or_reduce() == 0) {
        v.test_cnt = (r.test_cnt.read() + 1);
        v.resp_wait_states = r.test_cnt.read()(1, 0);
        v.m0_w_wait_states = r.test_cnt.read()(4, 2);
        v.m0_b_wait_states = r.test_cnt.read()(6, 5);
        v.m0_r_wait_states = r.test_cnt.read()(9, 7);
        v.m0_aw_xlen = (0, r.test_cnt.read()(11, 10));
        v.m0_ar_xlen = (0, r.test_cnt.read()(11, 10));
        v.m0_xsize = 3;                                     // 8-bytes
        if (r.test_cnt.read()[13] == 1) {
            // End of test (show err_cnt)
            v.end_of_test = 1;
        }
        v.test_pause_cnt = 10;
    } else {
        v.test_pause_cnt = 10;
    }

    if (r.m0_compare_ena.read() == 1) {
        if (r.m0_compare_a.read() != r.m0_compare_b.read()) {
            v.err_cnt = (r.err_cnt.read() + 1);
        }
    }

    vb_m0_xmsto.ar_valid = r.m0_ar_valid.read();
    vb_m0_xmsto.ar_bits.addr = r.m0_ar_addr.read();
    vb_m0_xmsto.ar_bits.len = r.m0_ar_xlen.read();
    vb_m0_xmsto.ar_bits.size = r.m0_xsize.read();
    vb_m0_xmsto.ar_bits.burst = 1;
    vb_m0_xmsto.ar_bits.lock = 0;
    vb_m0_xmsto.ar_bits.cache = 0;
    vb_m0_xmsto.ar_bits.prot = 0;
    vb_m0_xmsto.ar_bits.qos = 0;
    vb_m0_xmsto.ar_bits.region = 0;
    vb_m0_xmsto.ar_id = ~0ull;
    vb_m0_xmsto.ar_user = ~0ull;
    vb_m0_xmsto.aw_valid = r.m0_aw_valid.read();
    vb_m0_xmsto.aw_bits.addr = r.m0_aw_addr.read();
    vb_m0_xmsto.aw_bits.len = r.m0_aw_xlen.read();
    vb_m0_xmsto.aw_bits.size = r.m0_xsize.read();
    vb_m0_xmsto.aw_bits.burst = 1;
    vb_m0_xmsto.aw_bits.lock = 0;
    vb_m0_xmsto.aw_bits.cache = 0;
    vb_m0_xmsto.aw_bits.prot = 0;
    vb_m0_xmsto.aw_bits.qos = 0;
    vb_m0_xmsto.aw_bits.region = 0;
    vb_m0_xmsto.aw_id = ~0ull;
    vb_m0_xmsto.aw_user = ~0ull;
    vb_m0_xmsto.w_valid = r.m0_w_valid.read();
    vb_m0_xmsto.w_data = r.m0_w_data.read();
    vb_m0_xmsto.w_last = r.m0_w_last.read();
    vb_m0_xmsto.w_strb = r.m0_w_strb.read();
    vb_m0_xmsto.w_user = ~0ull;
    vb_m0_xmsto.b_ready = r.m0_b_ready.read();
    vb_m0_xmsto.r_ready = r.m0_r_ready.read();

    w_req_ready = r.req_ready.read();
    w_resp_valid = r.resp_valid.read();
    wb_resp_rdata = r.resp_rdata.read();
    w_resp_err = 0;

    vec_i_xmsto[CFG_BUS0_XMST_GROUP0] = vb_m0_xmsto;
    vec_i_xmsto[CFG_BUS0_XMST_PCIE] = axi4_master_out_none;
    vec_i_xmsto[CFG_BUS0_XMST_HDMI] = vb_m1_xmsto;
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
        mem[wb_req_addr.read()(5, 2).to_int()] = wb_req_wdata.read();
    }

    if (r.m0_compare_ena.read() == 1) {
        if (r.m0_compare_a.read() != r.m0_compare_b.read()) {
            std::cout << "@" << sc_time_stamp() << " + error: "
                      << std::hex << r.m0_compare_a.read() << " != "
                      << std::hex << r.m0_compare_b.read() << std::endl;
        }
    }
    if (r.end_of_test.read() == 1) {
        if (r.err_cnt.read() == 0) {
            std::cout << "@" << sc_time_stamp() << " No errors. TESTS PASSED" << std::endl;
        } else {
            std::cout << "@" << sc_time_stamp() << " TESTS FAILED. Total errors = "
                      << r.err_cnt.read() << std::endl;
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

