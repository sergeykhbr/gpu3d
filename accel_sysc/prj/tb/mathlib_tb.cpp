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

#include "mathlib_tb.h"
#include "api_core.h"

namespace debugger {

mathlib_tb::mathlib_tb(sc_module_name name)
    : sc_module(name) {

    clk = 0;
    mul0 = 0;

    clk = new vip_clk("clk",
                       25.0);
    clk->o_clk(w_clk);

    mul0 = new mul_i8("mul0",
                       0);
    mul0->i_nrst(w_nrst);
    mul0->i_clk(w_clk);
    mul0->i_a(wb_a);
    mul0->i_b(wb_b);
    mul0->i_signed(w_signed);
    mul0->o_res(wb_res);


    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << w_nrst;
    sensitive << w_clk;
    sensitive << wb_a;
    sensitive << wb_b;
    sensitive << wb_res;
    sensitive << w_signed;

    SC_METHOD(test_clk);
    sensitive << w_clk.posedge_event();
}

mathlib_tb::~mathlib_tb() {
    if (clk) {
        delete clk;
    }
    if (mul0) {
        delete mul0;
    }
}

void mathlib_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk) {
        clk->generateVCD(i_vcd, o_vcd);
    }
    if (mul0) {
        mul0->generateVCD(i_vcd, o_vcd);
    }
}

void mathlib_tb::init() {
    w_nrst = 0;
    wait(static_cast<int>(800.0), SC_NS);
    w_nrst = 1;
}

void mathlib_tb::comb() {
}

void mathlib_tb::test_clk() {
    if (w_nrst.read() == 0) {
        wb_clk_cnt = 0;
    } else {
        wb_clk_cnt = (wb_clk_cnt + 1);
    }
    if (wb_clk_cnt == 0x00000020) {
        wb_a = 127;
        wb_b = 0x81;                                        // -127
        w_signed = 1;
    } else if (wb_clk_cnt == 0x00000021) {
        wb_a = 255;
        wb_b = 255;
        w_signed = 0;
    } else {
        wb_a = 0;
        wb_b = 0;
        w_signed = 0;
    }
}

}  // namespace debugger

