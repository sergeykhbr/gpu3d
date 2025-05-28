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

#include "framebuf.h"
#include "api_core.h"

namespace debugger {

framebuf::framebuf(sc_module_name name,
                   bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_hsync("i_hsync"),
    i_vsync("i_vsync"),
    i_de("i_de"),
    i_x("i_x"),
    i_y("i_y"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de"),
    o_YCbCr("o_YCbCr") {

    async_reset_ = async_reset;

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hsync;
    sensitive << i_vsync;
    sensitive << i_de;
    sensitive << i_x;
    sensitive << i_y;
    sensitive << r.pix_x0;
    sensitive << r.h_sync;
    sensitive << r.v_sync;
    sensitive << r.de;
    sensitive << r.Y0;
    sensitive << r.Y1;
    sensitive << r.Cb;
    sensitive << r.Cr;
    sensitive << r.YCbCr;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

void framebuf::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_hsync, i_hsync.name());
        sc_trace(o_vcd, i_vsync, i_vsync.name());
        sc_trace(o_vcd, i_de, i_de.name());
        sc_trace(o_vcd, i_x, i_x.name());
        sc_trace(o_vcd, i_y, i_y.name());
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, o_YCbCr, o_YCbCr.name());
        sc_trace(o_vcd, r.pix_x0, pn + ".r.pix_x0");
        sc_trace(o_vcd, r.h_sync, pn + ".r.h_sync");
        sc_trace(o_vcd, r.v_sync, pn + ".r.v_sync");
        sc_trace(o_vcd, r.de, pn + ".r.de");
        sc_trace(o_vcd, r.Y0, pn + ".r.Y0");
        sc_trace(o_vcd, r.Y1, pn + ".r.Y1");
        sc_trace(o_vcd, r.Cb, pn + ".r.Cb");
        sc_trace(o_vcd, r.Cr, pn + ".r.Cr");
        sc_trace(o_vcd, r.YCbCr, pn + ".r.YCbCr");
    }

}

void framebuf::comb() {
    v = r;

    // delayed signals:
    v.de = (r.de.read()[0], i_de.read());
    v.h_sync = (r.h_sync.read()[0], i_hsync.read());
    v.v_sync = (r.v_sync.read()[0], i_vsync.read());
    v.pix_x0 = i_x.read()[0];
    if (i_x.read() < 170) {
        // White
        v.Y0 = 235;
        v.Y1 = 235;
        v.Cb = 128;
        v.Cr = 128;
    } else if (i_x.read() < 340) {
        // Black
        v.Y0 = 16;
        v.Y1 = 16;
        v.Cb = 128;
        v.Cr = 128;
    } else if (i_x.read() < 510) {
        // Red
        v.Y0 = 82;
        v.Y1 = 82;
        v.Cb = 90;
        v.Cr = 240;
    } else if (i_x.read() < 680) {
        // Green
        v.Y0 = 145;
        v.Y1 = 145;
        v.Cb = 54;
        v.Cr = 34;
    } else if (i_x.read() < 850) {
        // Blue
        v.Y0 = 41;
        v.Y1 = 41;
        v.Cb = 240;
        v.Cr = 110;
    } else if (i_x.read() < 1020) {
        // Yellow
        v.Y0 = 200;
        v.Y1 = 200;
        v.Cb = 16;
        v.Cr = 146;
    } else if (i_x.read() < 1190) {
        // Cyan
        v.Y0 = 170;
        v.Y1 = 170;
        v.Cb = 166;
        v.Cr = 16;
    } else {
        // Magneta
        v.Y0 = 106;
        v.Y1 = 106;
        v.Cb = 102;
        v.Cr = 222;
    }

    // See style 1 output:
    if (r.pix_x0.read() == 0) {
        v.YCbCr = (r.Cb.read(), r.Y1.read());
    } else {
        v.YCbCr = (r.Cr.read(), r.Y1.read());
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        framebuf_r_reset(v);
    }

    o_hsync = r.h_sync.read();
    o_vsync = r.v_sync.read();
    o_de = r.de.read();
    o_YCbCr = (0, r.YCbCr.read());
}

void framebuf::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        framebuf_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

