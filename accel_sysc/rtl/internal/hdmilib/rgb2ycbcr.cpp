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
    o_y("o_y"),
    o_cr("o_cr"),
    o_cb("o_cb") {

    async_reset_ = async_reset;

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_rgb565;
    sensitive << r.y;
    sensitive << r.cr;
    sensitive << r.cb;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

void rgb2ycbcr::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_rgb565, i_rgb565.name());
        sc_trace(o_vcd, o_y, o_y.name());
        sc_trace(o_vcd, o_cr, o_cr.name());
        sc_trace(o_vcd, o_cb, o_cb.name());
        sc_trace(o_vcd, r.y, pn + ".r.y");
        sc_trace(o_vcd, r.cr, pn + ".r.cr");
        sc_trace(o_vcd, r.cb, pn + ".r.cb");
    }

}

void rgb2ycbcr::comb() {
    v = r;


    if ((!async_reset_) && (i_nrst.read() == 0)) {
        rgb2ycbcr_r_reset(v);
    }

    o_y = r.y.read();
    o_cb = r.cb.read();
    o_cr = r.cr.read();
}

void rgb2ycbcr::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        rgb2ycbcr_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

