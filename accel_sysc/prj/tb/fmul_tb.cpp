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

#include "fmul_tb.h"
#include "api_core.h"

namespace debugger {

fmul_tb::fmul_tb(sc_module_name name)
    : sc_module(name) {

    pll0 = 0;
    mul_fp32 = 0;

    pll0 = new pll_generic("pll0",
                            25.0);
    pll0->o_clk(clk);

    mul_fp32 = new fmul_generic<32,
                                8>("mul_fp32",
                                   0);
    mul_fp32->i_clk(clk);
    mul_fp32->i_nrst(nrst);
    mul_fp32->i_ena(w_ena);
    mul_fp32->i_a(wb_a);
    mul_fp32->i_b(wb_b);
    mul_fp32->o_res(wb_res);
    mul_fp32->o_ex(w_ex);
    mul_fp32->o_valid(w_valid);


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
    for (int i = 0; i < 13; i++) {
        sensitive << r.compare_a[i];
    }

    SC_METHOD(test_clk);
    sensitive << clk.posedge_event();

    SC_METHOD(registers);
    sensitive << nrst;
    sensitive << clk.posedge_event();
}

fmul_tb::~fmul_tb() {
    if (pll0) {
        delete pll0;
    }
    if (mul_fp32) {
        delete mul_fp32;
    }
}

void fmul_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, r.clk_cnt, pn + ".r.clk_cnt");
        sc_trace(o_vcd, r.compare_cnt, pn + ".r.compare_cnt");
        sc_trace(o_vcd, r.err_cnt, pn + ".r.err_cnt");
        for (int i = 0; i < 13; i++) {
            sc_trace(o_vcd, r.compare_a[i], pn + ".r.compare_a(" + std::to_string(i) + ")");
        }
    }

    if (pll0) {
        pll0->generateVCD(i_vcd, o_vcd);
    }
    if (mul_fp32) {
        mul_fp32->generateVCD(i_vcd, o_vcd);
    }
}

void fmul_tb::init() {
    nrst = 0;
    wait(static_cast<int>(800.0), SC_NS);
    nrst = 1;
}

void fmul_tb::comb() {
    v.clk_cnt = r.clk_cnt.read();
    v.compare_cnt = r.compare_cnt.read();
    v.err_cnt = r.err_cnt.read();
    for (int i = 0; i < 13; i++) {
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
        wb_a = 0x0000000040466666;
        wb_b = 0x000000003BC49BA6;
        v.compare_a[0] = 0x000000003C985F07;
    } else if (r.clk_cnt.read() == 11) {
        w_ena = 1;
        wb_a = 0x000000003F800000;
        wb_b = 0x0000000000000020;
        v.compare_a[0] = 0x0000000000000020;
    } else if (r.clk_cnt.read() == 12) {
        w_ena = 1;
        wb_a = 0x00000000AFFFFFFF;
        wb_b = 0x000000007F7FFFFE;
        v.compare_a[0] = 0x00000000EFFFFFFD;
    } else if (r.clk_cnt.read() == 20) {
        w_ena = 1;
        wb_a = 0x000000003F000001;
        wb_b = 0x0000000000801010;
        v.compare_a[0] = 0x0000000000400809;
    } else if (r.clk_cnt.read() == 21) {
        w_ena = 1;
        wb_a = 0x000000003F000002;
        wb_b = 0x0000000000081010;
        v.compare_a[0] = 0x0000000000040808;
    } else if (r.clk_cnt.read() == 22) {
        w_ena = 1;
        wb_a = 0x00000000BFC00002;
        wb_b = 0x0000000001091010;
        v.compare_a[0] = 0x00000000814D981A;
    } else if (r.clk_cnt.read() == 23) {
        w_ena = 1;
        wb_a = 0x0000000035D00005;
        wb_b = 0x000000008309101F;
        v.compare_a[0] = 0x00000000800001BD;
    } else if (r.clk_cnt.read() == 24) {
        w_ena = 1;
        wb_a = 0x00000000F5400509;
        wb_b = 0x00000000A3E9103F;
        v.compare_a[0] = 0x0000000059AED0C5;
    } else if (r.clk_cnt.read() == 25) {
        w_ena = 1;
        wb_a = 0x00000000FF800001;
        wb_b = 0x00000000FF800000;
        v.compare_a[0] = 0x00000000FFC00001;
    } else if (r.clk_cnt.read() == 26) {
        w_ena = 1;
        wb_a = 0x00000000BF800001;
        wb_b = 0x00000000BF800000;
        v.compare_a[0] = 0x000000003F800001;
    } else if (r.clk_cnt.read() == 27) {
        w_ena = 1;
        wb_a = 0x00000000BFC00002;
        wb_b = 0x00000000BFC00001;
        v.compare_a[0] = 0x0000000040100002;
    } else if (r.clk_cnt.read() == 28) {
        w_ena = 1;
        wb_a = 0x0000000080800002;
        wb_b = 0x000000007F000003;
        v.compare_a[0] = 0x00000000C0000005;
    } else if (r.clk_cnt.read() == 29) {
        w_ena = 1;
        wb_a = 0x00000000007FFFFF;
        wb_b = 0x000000007E7FFFFF;
        v.compare_a[0] = 0x000000003F7FFFFD;
    } else if (r.clk_cnt.read() == 60) {
        w_show_result = 1;
    }
    for (int i = 0; i < (13 - 1); i++) {
        v.compare_a[(i + 1)] = r.compare_a[i].read();
    }

    // Prepare compare statistic:
    if ((w_valid.read() == 1) && (w_ex.read() == 0)) {
        w_compare_ena = 1;
        v.compare_cnt = (r.compare_cnt.read() + 1);
        if (wb_res.read() != r.compare_a[(13 - 1)].read()) {
            v.err_cnt = (r.err_cnt.read() + 1);
        }
    }
    wb_compare_a = r.compare_a[(13 - 1)].read();
}

void fmul_tb::test_clk() {
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

void fmul_tb::registers() {
    if (nrst.read() == 0) {
        fmul_tb_r_reset(r);
    } else {
        r.clk_cnt = v.clk_cnt.read();
        r.compare_cnt = v.compare_cnt.read();
        r.err_cnt = v.err_cnt.read();
        for (int i = 0; i < 13; i++) {
            r.compare_a[i] = v.compare_a[i].read();
        }
    }
}

}  // namespace debugger

