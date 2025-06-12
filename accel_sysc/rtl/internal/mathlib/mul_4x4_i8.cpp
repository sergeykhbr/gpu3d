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

#include "mul_4x4_i8.h"
#include "api_core.h"

namespace debugger {

mul_4x4_i8::mul_4x4_i8(sc_module_name name,
                       bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_signed("i_signed"),
    i_v0("i_v0"),
    i_v1("i_v1"),
    i_v2("i_v2"),
    i_v3("i_v3"),
    i_m("i_m"),
    o_res0("o_res0"),
    o_res1("o_res1"),
    o_res2("o_res2"),
    o_res3("o_res3") {

    async_reset_ = async_reset;
    m00 = 0;
    m01 = 0;
    m02 = 0;
    m03 = 0;
    m10 = 0;
    m11 = 0;
    m12 = 0;
    m13 = 0;
    m20 = 0;
    m21 = 0;
    m22 = 0;
    m23 = 0;
    m30 = 0;
    m31 = 0;
    m32 = 0;
    m33 = 0;

    // Row 0:
    m00 = new mul_i8("m00",
                      async_reset);
    m00->i_nrst(i_nrst);
    m00->i_clk(i_clk);
    m00->i_a(i_v0);
    m00->i_b(wb_b00);
    m00->i_signed(i_signed);
    m00->o_res(wb_m00);

    m01 = new mul_i8("m01",
                      async_reset);
    m01->i_nrst(i_nrst);
    m01->i_clk(i_clk);
    m01->i_a(i_v1);
    m01->i_b(wb_b01);
    m01->i_signed(i_signed);
    m01->o_res(wb_m01);

    m02 = new mul_i8("m02",
                      async_reset);
    m02->i_nrst(i_nrst);
    m02->i_clk(i_clk);
    m02->i_a(i_v2);
    m02->i_b(wb_b02);
    m02->i_signed(i_signed);
    m02->o_res(wb_m02);

    m03 = new mul_i8("m03",
                      async_reset);
    m03->i_nrst(i_nrst);
    m03->i_clk(i_clk);
    m03->i_a(i_v3);
    m03->i_b(wb_b03);
    m03->i_signed(i_signed);
    m03->o_res(wb_m03);

    // Row 1:
    m10 = new mul_i8("m10",
                      async_reset);
    m10->i_nrst(i_nrst);
    m10->i_clk(i_clk);
    m10->i_a(i_v0);
    m10->i_b(wb_b10);
    m10->i_signed(i_signed);
    m10->o_res(wb_m10);

    m11 = new mul_i8("m11",
                      async_reset);
    m11->i_nrst(i_nrst);
    m11->i_clk(i_clk);
    m11->i_a(i_v1);
    m11->i_b(wb_b11);
    m11->i_signed(i_signed);
    m11->o_res(wb_m11);

    m12 = new mul_i8("m12",
                      async_reset);
    m12->i_nrst(i_nrst);
    m12->i_clk(i_clk);
    m12->i_a(i_v2);
    m12->i_b(wb_b12);
    m12->i_signed(i_signed);
    m12->o_res(wb_m12);

    m13 = new mul_i8("m13",
                      async_reset);
    m13->i_nrst(i_nrst);
    m13->i_clk(i_clk);
    m13->i_a(i_v3);
    m13->i_b(wb_b13);
    m13->i_signed(i_signed);
    m13->o_res(wb_m13);

    // Row 2:
    m20 = new mul_i8("m20",
                      async_reset);
    m20->i_nrst(i_nrst);
    m20->i_clk(i_clk);
    m20->i_a(i_v0);
    m20->i_b(wb_b20);
    m20->i_signed(i_signed);
    m20->o_res(wb_m20);

    m21 = new mul_i8("m21",
                      async_reset);
    m21->i_nrst(i_nrst);
    m21->i_clk(i_clk);
    m21->i_a(i_v1);
    m21->i_b(wb_b21);
    m21->i_signed(i_signed);
    m21->o_res(wb_m21);

    m22 = new mul_i8("m22",
                      async_reset);
    m22->i_nrst(i_nrst);
    m22->i_clk(i_clk);
    m22->i_a(i_v2);
    m22->i_b(wb_b22);
    m22->i_signed(i_signed);
    m22->o_res(wb_m22);

    m23 = new mul_i8("m23",
                      async_reset);
    m23->i_nrst(i_nrst);
    m23->i_clk(i_clk);
    m23->i_a(i_v3);
    m23->i_b(wb_b23);
    m23->i_signed(i_signed);
    m23->o_res(wb_m23);

    // Row 3:
    m30 = new mul_i8("m30",
                      async_reset);
    m30->i_nrst(i_nrst);
    m30->i_clk(i_clk);
    m30->i_a(i_v0);
    m30->i_b(wb_b30);
    m30->i_signed(i_signed);
    m30->o_res(wb_m30);

    m31 = new mul_i8("m31",
                      async_reset);
    m31->i_nrst(i_nrst);
    m31->i_clk(i_clk);
    m31->i_a(i_v1);
    m31->i_b(wb_b31);
    m31->i_signed(i_signed);
    m31->o_res(wb_m31);

    m32 = new mul_i8("m32",
                      async_reset);
    m32->i_nrst(i_nrst);
    m32->i_clk(i_clk);
    m32->i_a(i_v2);
    m32->i_b(wb_b32);
    m32->i_signed(i_signed);
    m32->o_res(wb_m32);

    m33 = new mul_i8("m33",
                      async_reset);
    m33->i_nrst(i_nrst);
    m33->i_clk(i_clk);
    m33->i_a(i_v3);
    m33->i_b(wb_b33);
    m33->i_signed(i_signed);
    m33->o_res(wb_m33);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_signed;
    sensitive << i_v0;
    sensitive << i_v1;
    sensitive << i_v2;
    sensitive << i_v3;
    sensitive << i_m;
    sensitive << wb_b00;
    sensitive << wb_b01;
    sensitive << wb_b02;
    sensitive << wb_b03;
    sensitive << wb_b10;
    sensitive << wb_b11;
    sensitive << wb_b12;
    sensitive << wb_b13;
    sensitive << wb_b20;
    sensitive << wb_b21;
    sensitive << wb_b22;
    sensitive << wb_b23;
    sensitive << wb_b30;
    sensitive << wb_b31;
    sensitive << wb_b32;
    sensitive << wb_b33;
    sensitive << wb_m00;
    sensitive << wb_m01;
    sensitive << wb_m02;
    sensitive << wb_m03;
    sensitive << wb_m10;
    sensitive << wb_m11;
    sensitive << wb_m12;
    sensitive << wb_m13;
    sensitive << wb_m20;
    sensitive << wb_m21;
    sensitive << wb_m22;
    sensitive << wb_m23;
    sensitive << wb_m30;
    sensitive << wb_m31;
    sensitive << wb_m32;
    sensitive << wb_m33;
    sensitive << r.sum0a;
    sensitive << r.sum0b;
    sensitive << r.sum1a;
    sensitive << r.sum1b;
    sensitive << r.sum2a;
    sensitive << r.sum2b;
    sensitive << r.sum3a;
    sensitive << r.sum3b;
    sensitive << r.res0;
    sensitive << r.res1;
    sensitive << r.res2;
    sensitive << r.res3;
    sensitive << r.sign;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

mul_4x4_i8::~mul_4x4_i8() {
    if (m00) {
        delete m00;
    }
    if (m01) {
        delete m01;
    }
    if (m02) {
        delete m02;
    }
    if (m03) {
        delete m03;
    }
    if (m10) {
        delete m10;
    }
    if (m11) {
        delete m11;
    }
    if (m12) {
        delete m12;
    }
    if (m13) {
        delete m13;
    }
    if (m20) {
        delete m20;
    }
    if (m21) {
        delete m21;
    }
    if (m22) {
        delete m22;
    }
    if (m23) {
        delete m23;
    }
    if (m30) {
        delete m30;
    }
    if (m31) {
        delete m31;
    }
    if (m32) {
        delete m32;
    }
    if (m33) {
        delete m33;
    }
}

void mul_4x4_i8::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_signed, i_signed.name());
        sc_trace(o_vcd, i_v0, i_v0.name());
        sc_trace(o_vcd, i_v1, i_v1.name());
        sc_trace(o_vcd, i_v2, i_v2.name());
        sc_trace(o_vcd, i_v3, i_v3.name());
        sc_trace(o_vcd, i_m, i_m.name());
        sc_trace(o_vcd, o_res0, o_res0.name());
        sc_trace(o_vcd, o_res1, o_res1.name());
        sc_trace(o_vcd, o_res2, o_res2.name());
        sc_trace(o_vcd, o_res3, o_res3.name());
        sc_trace(o_vcd, r.sum0a, pn + ".r.sum0a");
        sc_trace(o_vcd, r.sum0b, pn + ".r.sum0b");
        sc_trace(o_vcd, r.sum1a, pn + ".r.sum1a");
        sc_trace(o_vcd, r.sum1b, pn + ".r.sum1b");
        sc_trace(o_vcd, r.sum2a, pn + ".r.sum2a");
        sc_trace(o_vcd, r.sum2b, pn + ".r.sum2b");
        sc_trace(o_vcd, r.sum3a, pn + ".r.sum3a");
        sc_trace(o_vcd, r.sum3b, pn + ".r.sum3b");
        sc_trace(o_vcd, r.res0, pn + ".r.res0");
        sc_trace(o_vcd, r.res1, pn + ".r.res1");
        sc_trace(o_vcd, r.res2, pn + ".r.res2");
        sc_trace(o_vcd, r.res3, pn + ".r.res3");
        sc_trace(o_vcd, r.sign, pn + ".r.sign");
    }

    if (m00) {
        m00->generateVCD(i_vcd, o_vcd);
    }
    if (m01) {
        m01->generateVCD(i_vcd, o_vcd);
    }
    if (m02) {
        m02->generateVCD(i_vcd, o_vcd);
    }
    if (m03) {
        m03->generateVCD(i_vcd, o_vcd);
    }
    if (m10) {
        m10->generateVCD(i_vcd, o_vcd);
    }
    if (m11) {
        m11->generateVCD(i_vcd, o_vcd);
    }
    if (m12) {
        m12->generateVCD(i_vcd, o_vcd);
    }
    if (m13) {
        m13->generateVCD(i_vcd, o_vcd);
    }
    if (m20) {
        m20->generateVCD(i_vcd, o_vcd);
    }
    if (m21) {
        m21->generateVCD(i_vcd, o_vcd);
    }
    if (m22) {
        m22->generateVCD(i_vcd, o_vcd);
    }
    if (m23) {
        m23->generateVCD(i_vcd, o_vcd);
    }
    if (m30) {
        m30->generateVCD(i_vcd, o_vcd);
    }
    if (m31) {
        m31->generateVCD(i_vcd, o_vcd);
    }
    if (m32) {
        m32->generateVCD(i_vcd, o_vcd);
    }
    if (m33) {
        m33->generateVCD(i_vcd, o_vcd);
    }
}

void mul_4x4_i8::comb() {
    v = r;

    wb_b00 = i_m.read()(7, 0).to_uint();
    wb_b01 = i_m.read()(15, 8).to_uint();
    wb_b02 = i_m.read()(23, 16).to_uint();
    wb_b03 = i_m.read()(31, 24).to_uint();
    wb_b10 = i_m.read()(39, 32).to_uint();
    wb_b11 = i_m.read()(47, 40).to_uint();
    wb_b12 = i_m.read()(55, 48).to_uint();
    wb_b13 = i_m.read()(63, 56).to_uint();
    wb_b20 = i_m.read()(71, 64).to_uint();
    wb_b21 = i_m.read()(79, 72).to_uint();
    wb_b22 = i_m.read()(87, 80).to_uint();
    wb_b23 = i_m.read()(95, 88).to_uint();
    wb_b30 = i_m.read()(103, 96).to_uint();
    wb_b31 = i_m.read()(111, 104).to_uint();
    wb_b32 = i_m.read()(119, 112).to_uint();
    wb_b33 = i_m.read()(127, 120).to_uint();

    v.sign = (r.sign.read()(4, 0), i_signed.read());
    v.sum0a = (((r.sign.read()[4] & wb_m00.read()[15]), wb_m00.read()) + ((r.sign.read()[4] & wb_m01.read()[15]), wb_m01.read()));
    v.sum0b = (((r.sign.read()[4] & wb_m02.read()[15]), wb_m02.read()) + ((r.sign.read()[4] & wb_m03.read()[15]), wb_m03.read()));

    v.sum1a = (((r.sign.read()[4] & wb_m10.read()[15]), wb_m10.read()) + ((r.sign.read()[4] & wb_m11.read()[15]), wb_m11.read()));
    v.sum1b = (((r.sign.read()[4] & wb_m12.read()[15]), wb_m12.read()) + ((r.sign.read()[4] & wb_m13.read()[15]), wb_m13.read()));

    v.sum2a = (((r.sign.read()[4] & wb_m20.read()[15]), wb_m20.read()) + ((r.sign.read()[4] & wb_m21.read()[15]), wb_m21.read()));
    v.sum2b = (((r.sign.read()[4] & wb_m22.read()[15]), wb_m22.read()) + ((r.sign.read()[4] & wb_m23.read()[15]), wb_m23.read()));

    v.sum3a = (((r.sign.read()[4] & wb_m30.read()[15]), wb_m30.read()) + ((r.sign.read()[4] & wb_m31.read()[15]), wb_m31.read()));
    v.sum3b = (((r.sign.read()[4] & wb_m32.read()[15]), wb_m32.read()) + ((r.sign.read()[4] & wb_m33.read()[15]), wb_m33.read()));

    v.res0 = (((r.sign.read()[5] & r.sum0a.read()[16]), r.sum0a.read()) + ((r.sign.read()[5] & r.sum0b.read()[16]), r.sum0b.read()));
    v.res1 = (((r.sign.read()[5] & r.sum1a.read()[16]), r.sum1a.read()) + ((r.sign.read()[5] & r.sum1b.read()[16]), r.sum1b.read()));
    v.res2 = (((r.sign.read()[5] & r.sum2a.read()[16]), r.sum2a.read()) + ((r.sign.read()[5] & r.sum2b.read()[16]), r.sum2b.read()));
    v.res3 = (((r.sign.read()[5] & r.sum3a.read()[16]), r.sum3a.read()) + ((r.sign.read()[5] & r.sum3b.read()[16]), r.sum3b.read()));

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        mul_4x4_i8_r_reset(v);
    }

    o_res0 = r.res0.read();
    o_res1 = r.res1.read();
    o_res2 = r.res2.read();
    o_res3 = r.res3.read();
}

void mul_4x4_i8::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        mul_4x4_i8_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

