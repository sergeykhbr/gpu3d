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

#include "mul_i8.h"
#include "api_core.h"

namespace debugger {

mul_i8::mul_i8(sc_module_name name,
               bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_a("i_a"),
    i_b("i_b"),
    i_signed("i_signed"),
    o_res("o_res") {

    async_reset_ = async_reset;

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_a;
    sensitive << i_b;
    sensitive << i_signed;
    sensitive << r.ua;
    sensitive << r.ub;
    sensitive << r.inv;
    sensitive << r.lvl1_0;
    sensitive << r.lvl1_1;
    sensitive << r.lvl1_2;
    sensitive << r.lvl1_3;
    sensitive << r.lvl2_0;
    sensitive << r.lvl2_1;
    sensitive << r.lvl3;
    sensitive << r.res;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

void mul_i8::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_a, i_a.name());
        sc_trace(o_vcd, i_b, i_b.name());
        sc_trace(o_vcd, i_signed, i_signed.name());
        sc_trace(o_vcd, o_res, o_res.name());
        sc_trace(o_vcd, r.ua, pn + ".r.ua");
        sc_trace(o_vcd, r.ub, pn + ".r.ub");
        sc_trace(o_vcd, r.inv, pn + ".r.inv");
        sc_trace(o_vcd, r.lvl1_0, pn + ".r.lvl1_0");
        sc_trace(o_vcd, r.lvl1_1, pn + ".r.lvl1_1");
        sc_trace(o_vcd, r.lvl1_2, pn + ".r.lvl1_2");
        sc_trace(o_vcd, r.lvl1_3, pn + ".r.lvl1_3");
        sc_trace(o_vcd, r.lvl2_0, pn + ".r.lvl2_0");
        sc_trace(o_vcd, r.lvl2_1, pn + ".r.lvl2_1");
        sc_trace(o_vcd, r.lvl3, pn + ".r.lvl3");
        sc_trace(o_vcd, r.res, pn + ".r.res");
    }

}

void mul_i8::comb() {
    sc_uint<10> vb_lvl1_00;
    sc_uint<10> vb_lvl1_01;
    sc_uint<10> vb_lvl1_10;
    sc_uint<10> vb_lvl1_11;
    sc_uint<10> vb_lvl1_20;
    sc_uint<10> vb_lvl1_21;
    sc_uint<10> vb_lvl1_30;
    sc_uint<10> vb_lvl1_31;

    v = r;
    vb_lvl1_00 = 0;
    vb_lvl1_01 = 0;
    vb_lvl1_10 = 0;
    vb_lvl1_11 = 0;
    vb_lvl1_20 = 0;
    vb_lvl1_21 = 0;
    vb_lvl1_30 = 0;
    vb_lvl1_31 = 0;

    if ((i_signed.read() == 1) && (i_a.read()[7] == 1)) {
        v.ua = ((~i_a.read()) + 1);
    } else {
        v.ua = i_a.read();
    }
    if ((i_signed.read() == 1) && (i_b.read()[7] == 1)) {
        v.ub = ((~i_b.read()) + 1);
    } else {
        v.ub = i_b.read();
    }
    v.inv = (r.inv.read()(2, 0), (i_signed.read() & (i_a.read()[7] ^ i_b.read()[7])));

    // Level 1, bits[1:0]
    if (r.ub.read()[0] == 1) {
        vb_lvl1_00 = (0, r.ua.read());
    }
    if (r.ub.read()[1] == 1) {
        vb_lvl1_01 = (r.ua.read() << 1);
    }
    v.lvl1_0 = (vb_lvl1_00 + vb_lvl1_01);

    // Level 1, bits[3:2]
    if (r.ub.read()[2] == 1) {
        vb_lvl1_10 = (0, r.ua.read());
    }
    if (r.ub.read()[3] == 1) {
        vb_lvl1_11 = (r.ua.read() << 1);
    }
    v.lvl1_1 = (vb_lvl1_10 + vb_lvl1_11);

    // Level 1, bits[5:4]
    if (r.ub.read()[4] == 1) {
        vb_lvl1_20 = (0, r.ua.read());
    }
    if (r.ub.read()[5] == 1) {
        vb_lvl1_21 = (r.ua.read() << 1);
    }
    v.lvl1_2 = (vb_lvl1_20 + vb_lvl1_21);

    // Level 1, bits[7:6]
    if (r.ub.read()[6] == 1) {
        vb_lvl1_30 = (0, r.ua.read());
    }
    if (r.ub.read()[7] == 1) {
        vb_lvl1_31 = (r.ua.read() << 1);
    }
    v.lvl1_3 = (vb_lvl1_30 + vb_lvl1_31);


    // Level 2, bits[3:0]
    v.lvl2_0 = ((0, r.lvl1_0.read()) + (r.lvl1_1.read() << 2));
    // Level 2, bits[7:4]
    v.lvl2_1 = ((0, r.lvl1_2.read()) + (r.lvl1_3.read() << 2));


    // Level 3, result
    v.lvl3 = ((0, r.lvl2_0.read()) + (r.lvl2_1.read()(11, 0) << 4));
    if (r.inv.read()[3] == 1) {
        v.res = ((~r.lvl3.read()) + 1);
    } else {
        v.res = r.lvl3.read();
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        mul_i8_r_reset(v);
    }

    o_res = r.res.read();
}

void mul_i8::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        mul_i8_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

