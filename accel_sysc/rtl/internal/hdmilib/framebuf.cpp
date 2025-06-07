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
    i_xy_total("i_xy_total"),
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
    ping->i_wdata(i_resp_2d_data);
    ping->o_rdata(wb_ping_rdata);

    pong = new ram_tech<8,
                        64>("pong");
    pong->i_clk(i_clk);
    pong->i_addr(wb_pong_addr);
    pong->i_wena(w_pong_wena);
    pong->i_wdata(i_resp_2d_data);
    pong->o_rdata(wb_pong_rdata);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hsync;
    sensitive << i_vsync;
    sensitive << i_de;
    sensitive << i_x;
    sensitive << i_y;
    sensitive << i_xy_total;
    sensitive << i_req_2d_ready;
    sensitive << i_resp_2d_valid;
    sensitive << i_resp_2d_last;
    sensitive << i_resp_2d_addr;
    sensitive << i_resp_2d_data;
    sensitive << wb_ping_addr;
    sensitive << w_ping_wena;
    sensitive << wb_ping_rdata;
    sensitive << wb_pong_addr;
    sensitive << w_pong_wena;
    sensitive << wb_pong_rdata;
    sensitive << r.state;
    sensitive << r.pingpong;
    sensitive << r.req_addr;
    sensitive << r.req_valid;
    sensitive << r.resp_ready;
    sensitive << r.raddr;
    sensitive << r.raddr_z;
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
        sc_trace(o_vcd, i_xy_total, i_xy_total.name());
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
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.pingpong, pn + ".r.pingpong");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.req_valid, pn + ".r.req_valid");
        sc_trace(o_vcd, r.resp_ready, pn + ".r.resp_ready");
        sc_trace(o_vcd, r.raddr, pn + ".r.raddr");
        sc_trace(o_vcd, r.raddr_z, pn + ".r.raddr_z");
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

    if ((r.req_valid.read() == 1) && (i_req_2d_ready.read() == 1)) {
        v.req_valid = 0;
    }
    if (i_de.read() == 1) {
        v.raddr = (r.raddr.read() + 1);
        v.raddr_z = r.raddr.read();
    }

    switch (r.state.read()) {
    case STATE_Request:
        v.req_valid = 1;
        v.resp_ready = 0;
        if ((r.req_valid.read() == 1) && (i_req_2d_ready.read() == 1)) {
            v.req_valid = 0;
            v.resp_ready = 1;
            v.state = STATE_Writing;
        }
        break;
    case STATE_Writing:
        if (i_resp_2d_valid.read() == 1) {
            if (i_resp_2d_last.read() == 1) {
                v.resp_ready = 0;
                if (i_resp_2d_addr.read()(10, 3).and_reduce() == 1) {
                    v.state = STATE_Idle;
                } else {
                    v.req_valid = 1;
                    v.req_addr = (r.req_addr.read() + 1);
                    v.state = STATE_Request;
                }
            }
        }
        break;
    case STATE_Idle:
        if (i_vsync.read() == 1) {
            v.raddr = 0;
            v.req_addr = 32;                                // 32-burst transactions 64B each => 2048 B
            v.req_valid = 1;
            v.state = STATE_Request;
        } else if (r.raddr.read()[10] != r.raddr_z.read()[10]) {
            v.pingpong = (!r.pingpong.read());
            if ((r.req_addr.read() + 1) >= i_xy_total.read()(22, 5)) {// 2048 B = 1024 pixel (16 bits each)
                // request first data while processing the last one:
                v.req_addr = 0;
            } else {
                v.req_addr = (r.req_addr.read() + 1);
            }
            v.req_valid = 1;
            v.state = STATE_Request;
        }
        break;
    default:
        break;
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

    if (r.pingpong.read() == 1) {
        wb_ping_addr = r.raddr.read()(9, 2);
        wb_pong_addr = i_resp_2d_addr.read()(10, 3);
        if (r.de.read().or_reduce() == 1) {
            if (r.raddr_z.read()(1, 0) == 0) {
                v.YCbCr = wb_ping_rdata.read()(15, 0);
            } else if (r.raddr_z.read()(1, 0) == 1) {
                v.YCbCr = wb_ping_rdata.read()(31, 16);
            } else if (r.raddr_z.read()(1, 0) == 2) {
                v.YCbCr = wb_ping_rdata.read()(47, 32);
            } else {
                v.YCbCr = wb_ping_rdata.read()(63, 48);
            }
        } else {
            v.YCbCr = 0;
        }
    } else {
        wb_ping_addr = i_resp_2d_addr.read()(10, 3);
        wb_pong_addr = r.raddr.read()(9, 2);
        if (r.de.read().or_reduce() == 1) {
            if (r.raddr_z.read()(1, 0) == 0) {
                v.YCbCr = wb_pong_rdata.read()(15, 0);
            } else if (r.raddr_z.read()(1, 0) == 1) {
                v.YCbCr = wb_pong_rdata.read()(31, 16);
            } else if (r.raddr_z.read()(1, 0) == 2) {
                v.YCbCr = wb_pong_rdata.read()(47, 32);
            } else {
                v.YCbCr = wb_pong_rdata.read()(63, 48);
            }
        } else {
            v.YCbCr = 0;
        }
    }
    w_ping_wena = (i_resp_2d_valid.read() & (!r.pingpong.read()));
    w_pong_wena = (i_resp_2d_valid.read() & r.pingpong.read());

    o_hsync = r.h_sync.read()[1];
    o_vsync = r.v_sync.read()[1];
    o_de = r.de.read()[1];
    o_YCbCr = (0, r.YCbCr.read());

    o_req_2d_valid = r.req_valid.read();
    o_req_2d_bytes = 64;                                    // Xilinx MIG is limited to burst beat length 8
    o_req_2d_addr = (r.req_addr.read() << 6);
    o_resp_2d_ready = r.resp_ready.read();
}

void framebuf::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        framebuf_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

