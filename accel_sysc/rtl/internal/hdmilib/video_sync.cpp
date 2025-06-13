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

#include "video_sync.h"
#include "api_core.h"

namespace debugger {

video_sync::video_sync(sc_module_name name,
                       bool async_reset,
                       int H_ACTIVE,
                       int H_FRONT,
                       int H_SYNC,
                       int H_BACK,
                       int V_ACTIVE,
                       int V_FRONT,
                       int V_SYNC,
                       int V_BACK)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de") {

    async_reset_ = async_reset;
    H_ACTIVE_ = H_ACTIVE;
    H_FRONT_ = H_FRONT;
    H_SYNC_ = H_SYNC;
    H_BACK_ = H_BACK;
    V_ACTIVE_ = V_ACTIVE;
    V_FRONT_ = V_FRONT;
    V_SYNC_ = V_SYNC;
    V_BACK_ = V_BACK;
    H_TOTAL = ((H_ACTIVE_ + H_SYNC_) + (H_FRONT_ + H_BACK_));
    V_TOTAL = ((V_ACTIVE_ + V_SYNC_) + (V_FRONT_ + V_BACK_));

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << r.h_count;
    sensitive << r.v_count;
    sensitive << r.h_sync;
    sensitive << r.v_sync;
    sensitive << r.de;
    sensitive << r.x_pix;
    sensitive << r.y_pix;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

void video_sync::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, r.h_count, pn + ".r.h_count");
        sc_trace(o_vcd, r.v_count, pn + ".r.v_count");
        sc_trace(o_vcd, r.h_sync, pn + ".r.h_sync");
        sc_trace(o_vcd, r.v_sync, pn + ".r.v_sync");
        sc_trace(o_vcd, r.de, pn + ".r.de");
        sc_trace(o_vcd, r.x_pix, pn + ".r.x_pix");
        sc_trace(o_vcd, r.y_pix, pn + ".r.y_pix");
    }

}

void video_sync::comb() {
    v = r;

    if (r.h_count.read() == (H_TOTAL - 1)) {
        v.h_count = 0;
        if (r.v_count.read() == (V_TOTAL - 1)) {
            v.v_count = 0;
        } else {
            v.v_count = (r.v_count.read() + 1);
        }
    } else {
        v.h_count = (r.h_count.read() + 1);
    }

    // Re-arrange sequence: active => front porch => sync => back porch
    //                      _______________________|------|____________
    // Polarity+
    if ((r.h_count.read() >= (H_ACTIVE_ + H_FRONT_)) && (r.h_count.read() < ((H_ACTIVE_ + H_FRONT_) + H_SYNC_))) {
        v.h_sync = 1;
    } else {
        v.h_sync = 0;
    }
    if ((r.v_count.read() >= (V_ACTIVE_ + V_FRONT_)) && (r.v_count.read() < ((V_ACTIVE_ + V_FRONT_) + V_SYNC_))) {
        v.v_sync = 1;
    } else {
        v.v_sync = 0;
    }
    if ((r.h_count.read() < H_ACTIVE_) && (r.v_count.read() < V_ACTIVE_)) {
        v.de = 1;
        v.x_pix = r.h_count.read();
        v.y_pix = r.v_count.read();
    } else {
        v.de = 0;
        v.x_pix = 0;
        v.y_pix = 0;
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        video_sync_r_reset(v);
    }

    o_de = r.de.read();
    o_hsync = r.h_sync.read();
    o_vsync = r.v_sync.read();
}

void video_sync::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        video_sync_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

