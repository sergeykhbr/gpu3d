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

#include "fadd_tb.h"
#include "api_core.h"

namespace debugger {

fadd_tb::fadd_tb(sc_module_name name)
    : sc_module(name) {

    pll0 = 0;
    tt = 0;

    pll0 = new pll_generic("pll0",
                            25.0);
    pll0->o_clk(clk);

    tt = new fadd_generic<32,
                          8,
                          6>("tt",
                             0);
    tt->i_clk(clk);
    tt->i_nrst(nrst);
    tt->i_ena(w_ena);
    tt->i_a(wb_a);
    tt->i_b(wb_b);
    tt->o_res(wb_res);
    tt->o_ex(w_ex);
    tt->o_valid(w_valid);


    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << nrst;
    sensitive << clk;
    sensitive << w_ena;
    sensitive << wb_a;
    sensitive << wb_b;
    sensitive << wb_res;
    sensitive << w_valid;
    sensitive << w_ex;
    sensitive << w_compare_ena;
    sensitive << wb_compare_a;
    sensitive << w_show_result;
    sensitive << r.clk_cnt;
    sensitive << r.compare_cnt;
    sensitive << r.err_cnt;
    for (int i = 0; i < latency; i++) {
        sensitive << r.compare_a[i];
    }

    SC_METHOD(test_clk);
    sensitive << clk.posedge_event();

    SC_METHOD(registers);
    sensitive << nrst;
    sensitive << clk.posedge_event();
}

fadd_tb::~fadd_tb() {
    if (pll0) {
        delete pll0;
    }
    if (tt) {
        delete tt;
    }
}

void fadd_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, r.clk_cnt, pn + ".r.clk_cnt");
        sc_trace(o_vcd, r.compare_cnt, pn + ".r.compare_cnt");
        sc_trace(o_vcd, r.err_cnt, pn + ".r.err_cnt");
        for (int i = 0; i < latency; i++) {
            sc_trace(o_vcd, r.compare_a[i], pn + ".r.compare_a(" + std::to_string(i) + ")");
        }
    }

    if (pll0) {
        pll0->generateVCD(i_vcd, o_vcd);
    }
    if (tt) {
        tt->generateVCD(i_vcd, o_vcd);
    }
}

void fadd_tb::init() {
    nrst = 0;
    wait(static_cast<int>(800.0), SC_NS);
    nrst = 1;
}

void fadd_tb::comb() {
    v.clk_cnt = r.clk_cnt.read();
    v.compare_cnt = r.compare_cnt.read();
    v.err_cnt = r.err_cnt.read();
    for (int i = 0; i < latency; i++) {
        v.compare_a[i] = r.compare_a[i].read();
    }

    v.clk_cnt = (r.clk_cnt.read() + 1);
    w_ena = 0;
    wb_a = 0;
    wb_b = 0;
    w_compare_ena = 0;
    w_show_result = 0;
    if (r.clk_cnt.read() == 10) {
        w_ena = 1;
        wb_a = 0x000000003F8CCCCD;
        wb_b = 0x00000000C000624E;
        v.compare_a[0] = 0x00000000BF67EF9E;
    } else if (r.clk_cnt.read() == 11) {
        w_ena = 1;
        wb_a = 0x00000000BFA66666;
        wb_b = 0x000000004000002A;
        v.compare_a[0] = 0x000000003F3333DC;
    } else if (r.clk_cnt.read() == 12) {
        w_ena = 1;
        wb_a = 0x00000000C00072B0;
        wb_b = 0x00000000C000624E;
        v.compare_a[0] = 0x00000000C0806A7F;
    } else if (r.clk_cnt.read() == 13) {
        w_ena = 1;
        wb_a = 0x0000000038E6AFCD;
        wb_b = 0x000000003F7FFF58;
        v.compare_a[0] = 0x000000003F800347;
    } else if (r.clk_cnt.read() == 14) {
        w_ena = 1;
        wb_a = 0x00000000B8E6AFCD;
        wb_b = 0x000000003908509C;
        v.compare_a[0] = 0x0000000037A7C5AC;
    } else if (r.clk_cnt.read() == 21) {
        w_ena = 1;
        wb_a = 0x00000000BF8CCCCD;
        wb_b = 0x000000003F8CCCCD;
        v.compare_a[0] = 0x0000000000000000;
    } else if (r.clk_cnt.read() == 22) {
        w_ena = 1;
        wb_a = 0x0000000042C8AAAA;
        wb_b = 0x00000000C2C8AAAA;
        v.compare_a[0] = 0x0000000000000000;
    } else if (r.clk_cnt.read() == 23) {
        w_ena = 1;
        wb_a = 0x0000000000000000;
        wb_b = 0x00000000C0554FDF;
        v.compare_a[0] = 0x00000000C0554FDF;
    } else if (r.clk_cnt.read() == 24) {
        w_ena = 1;
        wb_a = 0x0000000000000000;
        wb_b = 0x0000000000000000;
        v.compare_a[0] = 0x0000000000000000;
    } else if (r.clk_cnt.read() == 30) {
        w_ena = 1;
        wb_a = 0x000000007F800001;
        wb_b = 0x000000007F800000;
        v.compare_a[0] = 0x000000007FC00001;
    } else if (r.clk_cnt.read() == 31) {
        w_ena = 1;
        wb_a = 0x000000007F000001;
        wb_b = 0x000000007FFFFFFF;
        v.compare_a[0] = 0x000000007FFFFFFF;
    } else if (r.clk_cnt.read() == 32) {
        w_ena = 1;
        wb_a = 0x000000007CFFFFFF;
        wb_b = 0x00000000FCFFFFFF;
        v.compare_a[0] = 0x0000000000000000;
    } else if (r.clk_cnt.read() == 33) {
        w_ena = 1;
        wb_a = 0x000000007E7FFFFF;
        wb_b = 0x000000007F000003;
        v.compare_a[0] = 0x000000007F400003;
    } else if (r.clk_cnt.read() == 34) {
        w_ena = 1;
        wb_a = 0x00000000007FFFFF;
        wb_b = 0x000000007E7FFFFF;
        v.compare_a[0] = 0x000000007E7FFFFF;
    } else if (r.clk_cnt.read() == 40) {
        w_ena = 1;
        wb_a = 0x00000000557FFFFF;
        wb_b = 0x0000000054FFFFFF;
        v.compare_a[0] = 0x0000000055BFFFFF;
    } else if (r.clk_cnt.read() == 41) {
        w_ena = 1;
        wb_a = 0x0000000054C00000;
        wb_b = 0x00000000557FFFFF;
        v.compare_a[0] = 0x0000000055B00000;
    } else if (r.clk_cnt.read() == 60) {
        w_show_result = 1;
    }
    for (int i = 0; i < (latency - 1); i++) {
        v.compare_a[(i + 1)] = r.compare_a[i].read();
    }

    // Prepare compare statistic:
    if ((w_valid.read() == 1) && (w_ex.read() == 0)) {
        w_compare_ena = 1;
        v.compare_cnt = (r.compare_cnt.read() + 1);
        if (wb_res.read() != r.compare_a[(latency - 1)].read()) {
            if ((wb_res.read()(30, 0) == 0) && (r.compare_a[(latency - 1)].read()(30, 0) == 0)) {
                // Ignore -0.0f +0.0f difference
                w_compare_ena = 0;
                v.compare_cnt = r.compare_cnt.read();
            } else {
                v.err_cnt = (r.err_cnt.read() + 1);
            }
        }
    }
    wb_compare_a = r.compare_a[(latency - 1)].read();
}

void fadd_tb::test_clk() {
    if (w_compare_ena) {
        if (wb_compare_a.read() != wb_res.read()) {
            std::cout << "@" << sc_time_stamp() << " + error: "
                      << std::hex << wb_compare_a.read() << " != "
                      << std::hex << wb_res.read() << std::endl;
        }
    }
    if (w_show_result.read() == 1) {
        if (r.err_cnt.read() == 0) {
            std::cout << "@" << sc_time_stamp() << " No errors. "
                      << r.compare_cnt.read() << " TESTS PASSED" << std::endl;
        } else {
            std::cout << "@" << sc_time_stamp() << " TESTS FAILED. Total errors = "
                      << r.err_cnt.read() << std::endl;
        }
    }
}

void fadd_tb::registers() {
    if (nrst.read() == 0) {
        fadd_tb_r_reset(r);
    } else {
        r.clk_cnt = v.clk_cnt.read();
        r.compare_cnt = v.compare_cnt.read();
        r.err_cnt = v.err_cnt.read();
        for (int i = 0; i < latency; i++) {
            r.compare_a[i] = v.compare_a[i].read();
        }
    }
}

}  // namespace debugger

