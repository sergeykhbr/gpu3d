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

#include "rgb2ycbcr.h"
#include "api_core.h"

namespace debugger {

rgb2ycbcr::rgb2ycbcr(sc_module_name name,
                     bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_rgb565("i_rgb565"),
    i_hsync("i_hsync"),
    i_vsync("i_vsync"),
    i_de("i_de"),
    o_ycbcr422("o_ycbcr422"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de") {

    async_reset_ = async_reset;
    im8 = 0;

    im8 = new mul_4x4_i8("im8",
                          async_reset);
    im8->i_nrst(i_nrst);
    im8->i_clk(i_clk);
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

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_rgb565;
    sensitive << i_hsync;
    sensitive << i_vsync;
    sensitive << i_de;
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
    sensitive << r.hsync;
    sensitive << r.vsync;
    sensitive << r.de;
    sensitive << r.even;
    sensitive << r.ycbcr422;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

rgb2ycbcr::~rgb2ycbcr() {
    if (im8) {
        delete im8;
    }
}

void rgb2ycbcr::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_rgb565, i_rgb565.name());
        sc_trace(o_vcd, i_hsync, i_hsync.name());
        sc_trace(o_vcd, i_vsync, i_vsync.name());
        sc_trace(o_vcd, i_de, i_de.name());
        sc_trace(o_vcd, o_ycbcr422, o_ycbcr422.name());
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, r.hsync, pn + ".r.hsync");
        sc_trace(o_vcd, r.vsync, pn + ".r.vsync");
        sc_trace(o_vcd, r.de, pn + ".r.de");
        sc_trace(o_vcd, r.even, pn + ".r.even");
        sc_trace(o_vcd, r.ycbcr422, pn + ".r.ycbcr422");
    }

    if (im8) {
        im8->generateVCD(i_vcd, o_vcd);
    }
}

void rgb2ycbcr::comb() {
    sc_uint<8> vb_m00;                                      // 0.257 * 128
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

    v = r;
    vb_m00 = 0x21;
    vb_m01 = 0x41;
    vb_m02 = 0x0D;
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

    w_signed = 1;                                           // Signed operation -127..+127
    wb_v0 = (i_rgb565.read()(15, 11) << 2);                 // Red, normilizgin to 0..127
    wb_v1 = (i_rgb565.read()(10, 5) << 1);                  // Green, normilizgin to 0..127
    wb_v2 = (i_rgb565.read()(4, 0) << 2);                   // Blue, normilizgin to 0..127
    wb_v3 = 127;

    v.even = (r.even.read()(5, 0), (i_de.read() & (!r.even.read()[0])));
    v.hsync = (r.hsync.read()(6, 0), i_hsync.read());
    v.vsync = (r.vsync.read()(6, 0), i_vsync.read());
    v.de = (r.de.read()(6, 0), i_de.read());
    if (r.even.read()[6] != 0) {
        // {Cb, Y} scaled down to 64 (multiplier gives 14 bits unsigned scale to 8-bits)
        v.ycbcr422 = (wb_res1.read()(13, 6), wb_res0.read()(13, 6));
    } else {
        // Cr, Y scaled down to 64 (multiplier gives 14 bits unsigned scale to 8-bits)
        v.ycbcr422 = (wb_res2.read()(13, 6), wb_res0.read()(13, 6));
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        rgb2ycbcr_r_reset(v);
    }
    o_ycbcr422 = (0, r.ycbcr422.read());
    o_hsync = r.hsync.read()[7];
    o_vsync = r.vsync.read()[7];
    o_de = r.de.read()[7];
}

void rgb2ycbcr::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        rgb2ycbcr_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

