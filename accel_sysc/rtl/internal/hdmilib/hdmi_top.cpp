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

#include "hdmi_top.h"
#include "api_core.h"

namespace debugger {

hdmi_top::hdmi_top(sc_module_name name,
                   bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_hdmi_clk("i_hdmi_clk"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de"),
    o_data("o_data"),
    o_spdif("o_spdif"),
    i_spdif_out("i_spdif_out"),
    i_irq("i_irq") {

    async_reset_ = async_reset;
    sync0 = 0;
    fb0 = 0;

    sync0 = new video_sync("sync0",
                            async_reset,
                            1366,
                            70,
                            143,
                            213,
                            768,
                            3,
                            5,
                            24);
    sync0->i_nrst(i_nrst);
    sync0->i_clk(i_hdmi_clk);
    sync0->o_hsync(w_sync_hsync);
    sync0->o_vsync(w_sync_vsync);
    sync0->o_de(w_sync_de);
    sync0->o_x(wb_sync_x);
    sync0->o_y(wb_sync_y);

    fb0 = new framebuf("fb0",
                        async_reset);
    fb0->i_nrst(i_nrst);
    fb0->i_clk(i_hdmi_clk);
    fb0->i_hsync(w_sync_hsync);
    fb0->i_vsync(w_sync_vsync);
    fb0->i_de(w_sync_de);
    fb0->i_x(wb_sync_x);
    fb0->i_y(wb_sync_y);
    fb0->o_hsync(o_hsync);
    fb0->o_vsync(o_vsync);
    fb0->o_de(o_de);
    fb0->o_YCbCr(o_data);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hdmi_clk;
    sensitive << i_spdif_out;
    sensitive << i_irq;
    sensitive << w_sync_hsync;
    sensitive << w_sync_vsync;
    sensitive << w_sync_de;
    sensitive << wb_sync_x;
    sensitive << wb_sync_y;
}

hdmi_top::~hdmi_top() {
    if (sync0) {
        delete sync0;
    }
    if (fb0) {
        delete fb0;
    }
}

void hdmi_top::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_hdmi_clk, i_hdmi_clk.name());
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, o_data, o_data.name());
        sc_trace(o_vcd, o_spdif, o_spdif.name());
        sc_trace(o_vcd, i_spdif_out, i_spdif_out.name());
        sc_trace(o_vcd, i_irq, i_irq.name());
    }

    if (sync0) {
        sync0->generateVCD(i_vcd, o_vcd);
    }
    if (fb0) {
        fb0->generateVCD(i_vcd, o_vcd);
    }
}

void hdmi_top::comb() {
    o_spdif = 0;
}

}  // namespace debugger

