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
    o_YCbCr("o_YCbCr"),
    i_req_2d_ready("i_req_2d_ready"),
    o_req_2d_valid("o_req_2d_valid"),
    o_req_2d_bytes("o_req_2d_bytes"),
    o_req_2d_addr("o_req_2d_addr"),
    i_resp_2d_valid("i_resp_2d_valid"),
    i_resp_2d_last("i_resp_2d_last"),
    i_resp_2d_addr("i_resp_2d_addr"),
    i_resp_2d_data("i_resp_2d_data"),
    o_resp_2d_ready("o_resp_2d_ready") {

    async_reset_ = async_reset;
    ping = 0;
    pong = 0;

    ping = new ram_tech<8,
                        64>("ping");
    ping->i_clk(i_clk);
    ping->i_addr(wb_ping_addr);
    ping->i_wena(w_ping_wena);
    ping->i_wdata(wb_ping_wdata);
    ping->o_rdata(wb_ping_rdata);

    pong = new ram_tech<8,
                        64>("pong");
    pong->i_clk(i_clk);
    pong->i_addr(wb_pong_addr);
    pong->i_wena(w_pong_wena);
    pong->i_wdata(wb_pong_wdata);
    pong->o_rdata(wb_pong_rdata);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hsync;
    sensitive << i_vsync;
    sensitive << i_de;
    sensitive << i_x;
    sensitive << i_y;
    sensitive << i_req_2d_ready;
    sensitive << i_resp_2d_valid;
    sensitive << i_resp_2d_last;
    sensitive << i_resp_2d_addr;
    sensitive << i_resp_2d_data;
    sensitive << wb_ping_addr;
    sensitive << w_ping_wena;
    sensitive << wb_ping_wdata;
    sensitive << wb_ping_rdata;
    sensitive << wb_pong_addr;
    sensitive << w_pong_wena;
    sensitive << wb_pong_wdata;
    sensitive << wb_pong_rdata;
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

framebuf::~framebuf() {
    if (ping) {
        delete ping;
    }
    if (pong) {
        delete pong;
    }
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
        sc_trace(o_vcd, i_req_2d_ready, i_req_2d_ready.name());
        sc_trace(o_vcd, o_req_2d_valid, o_req_2d_valid.name());
        sc_trace(o_vcd, o_req_2d_bytes, o_req_2d_bytes.name());
        sc_trace(o_vcd, o_req_2d_addr, o_req_2d_addr.name());
        sc_trace(o_vcd, i_resp_2d_valid, i_resp_2d_valid.name());
        sc_trace(o_vcd, i_resp_2d_last, i_resp_2d_last.name());
        sc_trace(o_vcd, i_resp_2d_addr, i_resp_2d_addr.name());
        sc_trace(o_vcd, i_resp_2d_data, i_resp_2d_data.name());
        sc_trace(o_vcd, o_resp_2d_ready, o_resp_2d_ready.name());
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
    sc_uint<19> fb_addr;                                    // 1 value per 2 pixels

    v = r;
    fb_addr = 0;

    // delayed signals:
    v.de = (r.de.read()[0], i_de.read());
    v.h_sync = (r.h_sync.read()[0], i_hsync.read());
    v.v_sync = (r.v_sync.read()[0], i_vsync.read());
    v.pix_x0 = i_x.read()[0];

    fb_addr = (i_y.read(), i_x.read()(10, 2));

    if (i_x.read()(1, 0) == 0) {
    } else if (i_x.read()(1, 0) == 1) {
    } else if (i_x.read()(1, 0) == 2) {
    } else {
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

