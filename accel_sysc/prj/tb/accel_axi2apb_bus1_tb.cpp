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

#include "accel_axi2apb_bus1_tb.h"
#include "api_core.h"

namespace debugger {

accel_axi2apb_bus1_tb::accel_axi2apb_bus1_tb(sc_module_name name)
    : sc_module(name),
    vec_o_mapinfo("vec_o_mapinfo", CFG_BUS1_PSLV_TOTAL),
    vec_apbi("vec_apbi", CFG_BUS1_PSLV_TOTAL),
    vec_apbo("vec_apbo", CFG_BUS1_PSLV_TOTAL) {

    clk0 = 0;
    bus1 = 0;
    pslv0 = 0;

    clk0 = new pll_generic("clk0",
                            10.0);
    clk0->o_clk(clk);

    bus1 = new accel_axi2apb_bus1("bus1",
                                   0);
    bus1->i_clk(clk);
    bus1->i_nrst(nrst);
    bus1->i_mapinfo(wb_xslv_mapinfo);
    bus1->o_cfg(wb_xslv_cfg);
    bus1->i_xslvi(wb_i_xslvi);
    bus1->o_xslvo(wb_o_xslvo);
    bus1->i_apbo(vec_apbo);
    bus1->o_apbi(vec_apbi);
    bus1->o_mapinfo(vec_o_mapinfo);

    pslv0 = new apb_slv("pslv0",
                         0,
                         0,
                         0);
    pslv0->i_clk(clk);
    pslv0->i_nrst(nrst);
    pslv0->i_mapinfo(wb_pslv_mapinfo);
    pslv0->o_cfg(wb_pslv_cfg);
    pslv0->i_apbi(vec_apbi[CFG_BUS1_PSLV_UART1]);
    pslv0->o_apbo(vec_apbo[CFG_BUS1_PSLV_UART1]);
    pslv0->o_req_valid(w_req_valid);
    pslv0->o_req_addr(wb_req_addr);
    pslv0->o_req_write(w_req_write);
    pslv0->o_req_wdata(wb_req_wdata);
    pslv0->i_resp_valid(w_resp_valid);
    pslv0->i_resp_rdata(wb_resp_rdata);
    pslv0->i_resp_err(w_resp_err);

    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << nrst;
    sensitive << clk;
    sensitive << wb_xslv_mapinfo;
    sensitive << wb_pslv_mapinfo;
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << vec_o_mapinfo[i];
    }
    sensitive << wb_xslv_cfg;
    sensitive << wb_pslv_cfg;
    sensitive << wb_i_xslvi;
    sensitive << wb_o_xslvo;
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << vec_apbi[i];
    }
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << vec_apbo[i];
    }
    sensitive << w_req_valid;
    sensitive << wb_req_addr;
    sensitive << w_req_write;
    sensitive << wb_req_wdata;
    sensitive << w_resp_valid;
    sensitive << wb_resp_rdata;
    sensitive << w_resp_err;
    sensitive << r.clk_cnt;
    sensitive << r.err_cnt;
    sensitive << r.compare_cnt;
    sensitive << r.test_cnt;
    sensitive << r.test_state;
    sensitive << r.apb_wait_states;
    sensitive << r.test_pause_cnt;
    sensitive << r.xsize;
    sensitive << r.aw_valid;
    sensitive << r.aw_addr;
    sensitive << r.w_wait_states;
    sensitive << r.w_wait_cnt;
    sensitive << r.w_valid;
    sensitive << r.w_data;
    sensitive << r.w_strb;
    sensitive << r.b_wait_states;
    sensitive << r.b_wait_cnt;
    sensitive << r.b_ready;
    sensitive << r.ar_valid;
    sensitive << r.ar_addr;
    sensitive << r.r_wait_states;
    sensitive << r.r_wait_cnt;
    sensitive << r.r_ready;
    sensitive << r.compare_ena;
    sensitive << r.compare_a;
    sensitive << r.compare_b;
    sensitive << r.end_of_test;
    sensitive << r.apbstate;
    sensitive << r.apbram;
    sensitive << r.preq_ready;
    sensitive << r.presp_valid;
    sensitive << r.presp_rdata;
    sensitive << r.presp_delay;

    SC_METHOD(test);
    sensitive << clk.posedge_event();

    SC_METHOD(registers);
    sensitive << nrst;
    sensitive << clk.posedge_event();
}

accel_axi2apb_bus1_tb::~accel_axi2apb_bus1_tb() {
    if (clk0) {
        delete clk0;
    }
    if (bus1) {
        delete bus1;
    }
    if (pslv0) {
        delete pslv0;
    }
}

void accel_axi2apb_bus1_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, r.clk_cnt, pn + ".r.clk_cnt");
        sc_trace(o_vcd, r.err_cnt, pn + ".r.err_cnt");
        sc_trace(o_vcd, r.compare_cnt, pn + ".r.compare_cnt");
        sc_trace(o_vcd, r.test_cnt, pn + ".r.test_cnt");
        sc_trace(o_vcd, r.test_state, pn + ".r.test_state");
        sc_trace(o_vcd, r.apb_wait_states, pn + ".r.apb_wait_states");
        sc_trace(o_vcd, r.test_pause_cnt, pn + ".r.test_pause_cnt");
        sc_trace(o_vcd, r.xsize, pn + ".r.xsize");
        sc_trace(o_vcd, r.aw_valid, pn + ".r.aw_valid");
        sc_trace(o_vcd, r.aw_addr, pn + ".r.aw_addr");
        sc_trace(o_vcd, r.w_wait_states, pn + ".r.w_wait_states");
        sc_trace(o_vcd, r.w_wait_cnt, pn + ".r.w_wait_cnt");
        sc_trace(o_vcd, r.w_valid, pn + ".r.w_valid");
        sc_trace(o_vcd, r.w_data, pn + ".r.w_data");
        sc_trace(o_vcd, r.w_strb, pn + ".r.w_strb");
        sc_trace(o_vcd, r.b_wait_states, pn + ".r.b_wait_states");
        sc_trace(o_vcd, r.b_wait_cnt, pn + ".r.b_wait_cnt");
        sc_trace(o_vcd, r.b_ready, pn + ".r.b_ready");
        sc_trace(o_vcd, r.ar_valid, pn + ".r.ar_valid");
        sc_trace(o_vcd, r.ar_addr, pn + ".r.ar_addr");
        sc_trace(o_vcd, r.r_wait_states, pn + ".r.r_wait_states");
        sc_trace(o_vcd, r.r_wait_cnt, pn + ".r.r_wait_cnt");
        sc_trace(o_vcd, r.r_ready, pn + ".r.r_ready");
        sc_trace(o_vcd, r.compare_ena, pn + ".r.compare_ena");
        sc_trace(o_vcd, r.compare_a, pn + ".r.compare_a");
        sc_trace(o_vcd, r.compare_b, pn + ".r.compare_b");
        sc_trace(o_vcd, r.end_of_test, pn + ".r.end_of_test");
        sc_trace(o_vcd, r.apbstate, pn + ".r.apbstate");
        sc_trace(o_vcd, r.apbram, pn + ".r.apbram");
        sc_trace(o_vcd, r.preq_ready, pn + ".r.preq_ready");
        sc_trace(o_vcd, r.presp_valid, pn + ".r.presp_valid");
        sc_trace(o_vcd, r.presp_rdata, pn + ".r.presp_rdata");
        sc_trace(o_vcd, r.presp_delay, pn + ".r.presp_delay");
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
    if (bus1) {
        bus1->generateVCD(i_vcd, o_vcd);
    }
    if (pslv0) {
        pslv0->generateVCD(i_vcd, o_vcd);
    }
}

void accel_axi2apb_bus1_tb::init() {
    nrst = 0;
    wait(static_cast<int>(200.0), SC_NS);
    nrst = 1;
}

void accel_axi2apb_bus1_tb::comb() {
    mapinfo_type vb_xslv_mapinfo;
    mapinfo_type vb_pslv_mapinfo;
    axi4_slave_in_type vb_xslvi;
    sc_uint<48> vb_bar;
    sc_uint<32> vb_test_cnt_inv;

    v = r;
    vb_bar = 0;
    vb_test_cnt_inv = 0;

    vb_xslv_mapinfo.addr_start = 0x000008000000;
    vb_xslv_mapinfo.addr_end = 0x000009000000;
    wb_xslv_mapinfo = vb_xslv_mapinfo;

    vb_pslv_mapinfo.addr_start = 0x000000010000;
    vb_pslv_mapinfo.addr_end = 0x000000011000;
    wb_pslv_mapinfo = vb_pslv_mapinfo;

    vb_test_cnt_inv = (~r.test_cnt.read());
    vb_bar = 0x0000000008100000;
    v.clk_cnt = (r.clk_cnt.read() + 1);
    v.compare_ena = 0;
    v.end_of_test = 0;

    // APB memory simulation with controllable wait states
    switch (r.apbstate.read()) {
    case 0:
        v.preq_ready = 1;
        v.presp_valid = 0;
        if ((w_req_valid.read() == 1) && (r.preq_ready.read() == 1)) {
            if (w_req_write.read() == 1) {
                if (wb_req_addr.read()[2] == 0) {
                    v.apbram = (r.apbram.read()(63, 32), wb_req_wdata.read());
                } else {
                    v.apbram = (wb_req_wdata.read(), r.apbram.read()(31, 0));
                }
                v.presp_rdata = ~0ull;
            } else {
                if (wb_req_addr.read()[2] == 0) {
                    v.presp_rdata = r.apbram.read()(31, 0);
                } else {
                    v.presp_rdata = r.apbram.read()(63, 32);
                }
            }
            if (r.apb_wait_states.read().or_reduce() == 0) {
                v.presp_valid = 1;
            } else {
                v.preq_ready = 0;
                v.presp_delay = (r.apb_wait_states.read() - 1);
                v.apbstate = 1;
            }
        }
        break;
    case 1:
        if (r.presp_delay.read().or_reduce() == 1) {
            v.presp_delay = (r.presp_delay.read() - 1);
        } else {
            v.presp_valid = 1;
            v.apbstate = 2;
        }
        break;
    case 2:
        v.presp_valid = 0;
        v.apbstate = 0;
        break;
    }

    // AXI request state machines
    switch (r.test_state.read()) {
    case 0:
        if (r.test_pause_cnt.read().or_reduce() == 1) {
            v.test_pause_cnt = (r.test_pause_cnt.read() - 1);
        } else {
            v.test_cnt = (r.test_cnt.read() + 1);
            v.apb_wait_states = r.test_cnt.read()(1, 0);
            v.w_wait_states = r.test_cnt.read()(5, 2);
            v.b_wait_states = r.test_cnt.read()(7, 6);
            v.r_wait_states = r.test_cnt.read()(11, 8);
            if (r.test_cnt.read()[12] != 0) {
                v.xsize = 3;                                // 8-bytes
            } else {
                v.xsize = 2;                                // 4-bytes
            }
            if (r.test_cnt.read()[13] != 0) {
                // End of test (show err_cnt)
                v.end_of_test = 1;
                v.test_state = 7;
            } else {
                v.test_state = 1;
            }
        }
        break;
    case 1:                                                 // aw request
        v.aw_valid = 1;
        v.aw_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 2));
        if ((r.aw_valid.read() == 1) && (wb_o_xslvo.read().aw_ready == 1)) {
            v.aw_valid = 0;
            v.test_state = 2;
            v.w_data = (vb_test_cnt_inv, r.test_cnt.read());
            if (r.xsize.read() == 2) {
                if (r.test_cnt.read()[0] == 0) {
                    v.w_strb = 0x0F;
                } else {
                    v.w_strb = 0xF0;
                }
            } else {
                v.w_strb = 0xFF;
            }
            if (r.w_wait_states.read().or_reduce() == 0) {
                v.w_wait_cnt = 0;
                v.w_valid = 1;
            } else {
                v.w_wait_cnt = r.w_wait_states.read();
            }
        }
        break;
    case 2:                                                 // w request
        if (r.w_wait_cnt.read().or_reduce() == 1) {
            v.w_wait_cnt = (r.w_wait_cnt.read() - 1);
        } else {
            v.w_valid = 1;
            v.w_data = (vb_test_cnt_inv, r.test_cnt.read());
            if ((r.w_valid.read() == 1) && (wb_o_xslvo.read().w_ready == 1)) {
                v.w_valid = 0;
                v.test_state = 3;
                if (r.b_wait_states.read().or_reduce() == 0) {
                    v.b_wait_cnt = 0;
                    v.b_ready = 1;
                } else {
                    v.b_wait_cnt = r.b_wait_states.read();
                }
            }
        }
        break;
    case 3:                                                 // b response
        if (r.b_wait_cnt.read().or_reduce() == 1) {
            v.b_wait_cnt = (r.b_wait_cnt.read() - 1);
        } else {
            v.b_ready = 1;
            if ((r.b_ready.read() == 1) && (wb_o_xslvo.read().b_valid == 1)) {
                v.b_ready = 0;
                v.test_state = 4;
                v.ar_valid = 1;
                v.ar_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 2));
            }
        }
        break;
    case 4:                                                 // ar request
        v.ar_valid = 1;
        v.ar_addr = (vb_bar + (r.test_cnt.read()(11, 0) << 2));
        if ((r.ar_valid.read() == 1) && (wb_o_xslvo.read().ar_ready == 1)) {
            v.ar_valid = 0;
            v.test_state = 5;
            if (r.r_wait_states.read().or_reduce() == 0) {
                v.r_wait_cnt = 0;
                v.r_ready = 1;
            } else {
                v.r_wait_cnt = r.r_wait_states.read();
            }
        }
        break;
    case 5:                                                 // r response
        if (r.r_wait_cnt.read().or_reduce() == 1) {
            v.r_wait_cnt = (r.r_wait_cnt.read() - 1);
        } else {
            v.r_ready = 1;
            if ((r.r_ready.read() == 1) && (wb_o_xslvo.read().r_valid == 1)) {
                v.r_ready = 0;
                v.compare_ena = 1;
                v.compare_a = wb_o_xslvo.read().r_data;
                if (r.xsize.read() == 2) {
                    if (r.test_cnt.read()[0] == 0) {
                        v.compare_b = (r.w_data.read()(31, 0), r.w_data.read()(31, 0));
                    } else {
                        v.compare_b = (r.w_data.read()(63, 32), r.w_data.read()(63, 32));
                    }
                } else if (r.test_cnt.read()[0] == 0) {
                    v.compare_b = r.w_data.read();
                } else {
                    // Error response
                    v.compare_b = ~0ull;
                }
                if (wb_o_xslvo.read().r_last == 1) {
                    // Goto idle
                    v.test_pause_cnt = 10;
                    v.test_state = 0;
                } else {
                    if (r.r_wait_states.read().or_reduce() == 0) {
                        v.r_ready = 1;
                    } else {
                        v.r_wait_cnt = r.r_wait_states.read();
                    }
                }
            }
        }
        break;
    case 7:                                                 // do nothing
        break;
    }

    if (r.compare_ena.read() == 1) {
        v.compare_cnt = (r.compare_cnt.read() + 1);
        if (r.compare_a.read() != r.compare_b.read()) {
            v.err_cnt = (r.err_cnt.read() + 1);
        }
    }

    vb_xslvi.ar_valid = r.ar_valid.read();
    vb_xslvi.ar_bits.addr = r.ar_addr.read();
    vb_xslvi.ar_bits.len = 0;
    vb_xslvi.ar_bits.size = r.xsize.read();
    vb_xslvi.ar_bits.burst = 1;
    vb_xslvi.ar_bits.lock = 0;
    vb_xslvi.ar_bits.cache = 0;
    vb_xslvi.ar_bits.prot = 0;
    vb_xslvi.ar_bits.qos = 0;
    vb_xslvi.ar_bits.region = 0;
    vb_xslvi.ar_id = 0;
    vb_xslvi.ar_user = 0;

    vb_xslvi.aw_valid = r.aw_valid.read();
    vb_xslvi.aw_bits.addr = r.aw_addr.read();
    vb_xslvi.aw_bits.len = 0;
    vb_xslvi.aw_bits.size = r.xsize.read();
    vb_xslvi.aw_bits.burst = 1;
    vb_xslvi.aw_bits.lock = 0;
    vb_xslvi.aw_bits.cache = 0;
    vb_xslvi.aw_bits.prot = 0;
    vb_xslvi.aw_bits.qos = 0;
    vb_xslvi.aw_bits.region = 0;
    vb_xslvi.aw_id = 0;
    vb_xslvi.aw_user = 0;

    vb_xslvi.w_valid = r.w_valid.read();
    vb_xslvi.w_data = r.w_data.read();
    vb_xslvi.w_last = 1;
    vb_xslvi.w_strb = r.w_strb.read();
    vb_xslvi.w_user = 0;
    vb_xslvi.b_ready = r.b_ready.read();
    vb_xslvi.r_ready = r.r_ready.read();
    wb_i_xslvi = vb_xslvi;

    vec_apbo[CFG_BUS1_PSLV_PRCI] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_DMI] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_I2C0] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_GPIO] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_DDR] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_PCIE] = apb_out_none;
    vec_apbo[CFG_BUS1_PSLV_PNP] = apb_out_none;
    w_resp_valid = r.presp_valid.read();
    wb_resp_rdata = r.presp_rdata.read();
    w_resp_err = 0;
}

void accel_axi2apb_bus1_tb::test() {
    if (r.compare_ena.read() == 1) {
        if (r.compare_a.read() != r.compare_b.read()) {
            std::cout << "@" << sc_time_stamp() << " + error: "
                      << std::hex << r.compare_a.read() << " != "
                      << std::hex << r.compare_b.read() << std::endl;
        }
    }
    if (r.end_of_test.read() == 1) {
        if (r.err_cnt.read() == 0) {
            std::cout << "@" << sc_time_stamp() << " No errors. "
                      << r.compare_cnt.read() << " TESTS PASSED" << std::endl;
        } else {
            std::cout << "@" << sc_time_stamp() << " TESTS FAILED. Total errors = "
                      << r.err_cnt.read() << std::endl;
        }
    }
}

void accel_axi2apb_bus1_tb::registers() {
    if (nrst.read() == 0) {
        accel_axi2apb_bus1_tb_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

