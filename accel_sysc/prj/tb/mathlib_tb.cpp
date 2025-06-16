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
    im8 = 0;

    clk = new pll_generic("clk",
                           25.0);
    clk->o_clk(w_clk);

    im8 = new mul_4x4_i8("im8",
                          0);
    im8->i_nrst(w_nrst);
    im8->i_clk(w_clk);
    im8->i_signed(w_signed);
    im8->i_v0(wb_v0);
    im8->i_v1(wb_v1);
    im8->i_v2(wb_v2);
    im8->i_v3(wb_v3);
    im8->i_m(wb_m);
    im8->o_res0(wb_res0);
    im8->o_res1(wb_res1);
    im8->o_res2(wb_res2);
    im8->o_res3(wb_res3);


    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << w_nrst;
    sensitive << w_clk;
    sensitive << w_signed;
    sensitive << wb_v0;
    sensitive << wb_v1;
    sensitive << wb_v2;
    sensitive << wb_v3;
    sensitive << wb_m;
    sensitive << wb_res0;
    sensitive << wb_res1;
    sensitive << wb_res2;
    sensitive << wb_res3;

    SC_METHOD(test_clk);
    sensitive << w_clk.posedge_event();
}

mathlib_tb::~mathlib_tb() {
    if (clk) {
        delete clk;
    }
    if (im8) {
        delete im8;
    }
}

void mathlib_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk) {
        clk->generateVCD(i_vcd, o_vcd);
    }
    if (im8) {
        im8->generateVCD(i_vcd, o_vcd);
    }
}

void mathlib_tb::init() {
    w_nrst = 0;
    wait(static_cast<int>(800.0), SC_NS);
    w_nrst = 1;
}

void mathlib_tb::comb() {
    sc_uint<8> vb_m00;                                      // 0.257 * 127
    sc_uint<8> vb_m01;                                      // 0.504
    sc_uint<8> vb_m02;                                      // 0.0979
    sc_uint<8> vb_m03;                                      // 0.0627
    sc_uint<8> vb_m10;                                      // -0.148
    sc_uint<8> vb_m11;                                      // -0.291
    sc_uint<8> vb_m12;                                      // 0.439
    sc_uint<8> vb_m13;                                      // 0.502
    sc_uint<8> vb_m20;                                      // 0.439
    sc_uint<8> vb_m21;                                      // -0.368
    sc_uint<8> vb_m22;                                      // -0.0714
    sc_uint<8> vb_m23;                                      // 0.502
    sc_uint<8> vb_m30;
    sc_uint<8> vb_m31;
    sc_uint<8> vb_m32;
    sc_uint<8> vb_m33;

    vb_m00 = 0x21;
    vb_m01 = 0x40;
    vb_m02 = 0x0C;
    vb_m03 = 0x08;
    vb_m10 = 0xEE;
    vb_m11 = 0xDC;
    vb_m12 = 0x38;
    vb_m13 = 0x40;
    vb_m20 = 0x38;
    vb_m21 = 0xD2;
    vb_m22 = 0xF8;
    vb_m23 = 0x40;
    vb_m30 = 0;
    vb_m31 = 0;
    vb_m32 = 0;
    vb_m33 = 1;

    wb_m = (vb_m33,
            vb_m32,
            vb_m31,
            vb_m30,
            vb_m23,
            vb_m22,
            vb_m21,
            vb_m20,
            vb_m13,
            vb_m12,
            vb_m11,
            vb_m10,
            vb_m03,
            vb_m02,
            vb_m01,
            vb_m00);
}

void mathlib_tb::test_clk() {
    if (w_nrst.read() == 0) {
        wb_clk_cnt = 0;
    } else {
        wb_clk_cnt = (wb_clk_cnt + 1);
    }
    if (wb_clk_cnt == 0x00000020) {
        wb_v0 = 37;
        wb_v1 = 15;
        wb_v2 = 84;
        wb_v3 = 127;
        w_signed = 1;
    } else if (wb_clk_cnt == 0x00000021) {
        wb_v0 = 255;
        wb_v1 = 255;
        wb_v2 = 255;
        wb_v3 = 255;
        w_signed = 0;
    } else {
        wb_v0 = 0;
        wb_v1 = 0;
        wb_v2 = 0;
        wb_v3 = 0;
        w_signed = 0;
    }
}

}  // namespace debugger

