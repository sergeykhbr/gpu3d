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
    i_width_m1("i_width_m1"),
    i_height_m1("i_height_m1"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de"),
    o_rgb565("o_rgb565"),
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
    ring0 = 0;
    ring1 = 0;
    ring2 = 0;
    ring3 = 0;

    ring0 = new ram_tech<6,
                         64>("ring0");
    ring0->i_clk(i_clk);
    ring0->i_addr(wb_ring0_addr);
    ring0->i_wena(w_ring0_wena);
    ring0->i_wdata(i_resp_2d_data);
    ring0->o_rdata(wb_ring0_rdata);

    ring1 = new ram_tech<6,
                         64>("ring1");
    ring1->i_clk(i_clk);
    ring1->i_addr(wb_ring1_addr);
    ring1->i_wena(w_ring1_wena);
    ring1->i_wdata(i_resp_2d_data);
    ring1->o_rdata(wb_ring1_rdata);

    ring2 = new ram_tech<6,
                         64>("ring2");
    ring2->i_clk(i_clk);
    ring2->i_addr(wb_ring2_addr);
    ring2->i_wena(w_ring2_wena);
    ring2->i_wdata(i_resp_2d_data);
    ring2->o_rdata(wb_ring2_rdata);

    ring3 = new ram_tech<6,
                         64>("ring3");
    ring3->i_clk(i_clk);
    ring3->i_addr(wb_ring3_addr);
    ring3->i_wena(w_ring3_wena);
    ring3->i_wdata(i_resp_2d_data);
    ring3->o_rdata(wb_ring3_rdata);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hsync;
    sensitive << i_vsync;
    sensitive << i_de;
    sensitive << i_width_m1;
    sensitive << i_height_m1;
    sensitive << i_req_2d_ready;
    sensitive << i_resp_2d_valid;
    sensitive << i_resp_2d_last;
    sensitive << i_resp_2d_addr;
    sensitive << i_resp_2d_data;
    sensitive << wb_ring0_addr;
    sensitive << w_ring0_wena;
    sensitive << wb_ring0_rdata;
    sensitive << wb_ring1_addr;
    sensitive << w_ring1_wena;
    sensitive << wb_ring1_rdata;
    sensitive << wb_ring2_addr;
    sensitive << w_ring2_wena;
    sensitive << wb_ring2_rdata;
    sensitive << wb_ring3_addr;
    sensitive << w_ring3_wena;
    sensitive << wb_ring3_rdata;
    sensitive << r.wr_row;
    sensitive << r.wr_col;
    sensitive << r.wr_addr;
    sensitive << r.rd_row;
    sensitive << r.rd_col;
    sensitive << r.rd_addr;
    sensitive << r.mux_ena;
    sensitive << r.ring_sel;
    sensitive << r.pix_sel;
    sensitive << r.difcnt;
    sensitive << r.state;
    sensitive << r.req_addr;
    sensitive << r.req_valid;
    sensitive << r.resp_ready;
    sensitive << r.h_sync;
    sensitive << r.v_sync;
    sensitive << r.de;
    sensitive << r.rgb;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

framebuf::~framebuf() {
    if (ring0) {
        delete ring0;
    }
    if (ring1) {
        delete ring1;
    }
    if (ring2) {
        delete ring2;
    }
    if (ring3) {
        delete ring3;
    }
}

void framebuf::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_hsync, i_hsync.name());
        sc_trace(o_vcd, i_vsync, i_vsync.name());
        sc_trace(o_vcd, i_de, i_de.name());
        sc_trace(o_vcd, i_width_m1, i_width_m1.name());
        sc_trace(o_vcd, i_height_m1, i_height_m1.name());
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, o_rgb565, o_rgb565.name());
        sc_trace(o_vcd, i_req_2d_ready, i_req_2d_ready.name());
        sc_trace(o_vcd, o_req_2d_valid, o_req_2d_valid.name());
        sc_trace(o_vcd, o_req_2d_bytes, o_req_2d_bytes.name());
        sc_trace(o_vcd, o_req_2d_addr, o_req_2d_addr.name());
        sc_trace(o_vcd, i_resp_2d_valid, i_resp_2d_valid.name());
        sc_trace(o_vcd, i_resp_2d_last, i_resp_2d_last.name());
        sc_trace(o_vcd, i_resp_2d_addr, i_resp_2d_addr.name());
        sc_trace(o_vcd, i_resp_2d_data, i_resp_2d_data.name());
        sc_trace(o_vcd, o_resp_2d_ready, o_resp_2d_ready.name());
        sc_trace(o_vcd, r.wr_row, pn + ".r.wr_row");
        sc_trace(o_vcd, r.wr_col, pn + ".r.wr_col");
        sc_trace(o_vcd, r.wr_addr, pn + ".r.wr_addr");
        sc_trace(o_vcd, r.rd_row, pn + ".r.rd_row");
        sc_trace(o_vcd, r.rd_col, pn + ".r.rd_col");
        sc_trace(o_vcd, r.rd_addr, pn + ".r.rd_addr");
        sc_trace(o_vcd, r.mux_ena, pn + ".r.mux_ena");
        sc_trace(o_vcd, r.ring_sel, pn + ".r.ring_sel");
        sc_trace(o_vcd, r.pix_sel, pn + ".r.pix_sel");
        sc_trace(o_vcd, r.difcnt, pn + ".r.difcnt");
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.req_valid, pn + ".r.req_valid");
        sc_trace(o_vcd, r.resp_ready, pn + ".r.resp_ready");
        sc_trace(o_vcd, r.h_sync, pn + ".r.h_sync");
        sc_trace(o_vcd, r.v_sync, pn + ".r.v_sync");
        sc_trace(o_vcd, r.de, pn + ".r.de");
        sc_trace(o_vcd, r.rgb, pn + ".r.rgb");
    }

}

void framebuf::comb() {
    bool v_rd_ena;
    sc_uint<64> vb_ring_rdata;
    sc_uint<16> vb_pix;

    v = r;
    v_rd_ena = 0;
    vb_ring_rdata = 0;
    vb_pix = 0;

    // delayed signals:
    v.de = (r.de.read()(2, 0), i_de.read());
    v.h_sync = (r.h_sync.read()(2, 0), i_hsync.read());
    v.v_sync = (r.v_sync.read()(2, 0), i_vsync.read());

    if ((i_vsync.read() == 1) && (r.v_sync.read()[0] == 0)) {
        // Posedge of vsync:
        v.state = STATE_EndOfFrame;
    }

    switch (r.state.read()) {
    case STATE_Idle:
        if ((r.difcnt.read()[8] != 0) || (r.difcnt.read() <= 96)) {
            v.req_valid = 1;
            v.req_addr = (r.wr_row.read(), r.wr_col.read(), 0);// 2 Bytes per pixel
            v.state = STATE_Request;
        }
        break;
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
            v.wr_col = (r.wr_col.read() + 4);               // 64-bits contains 4x16-bits pixels
            v.wr_addr = (r.wr_addr.read() + 1);
            if (i_resp_2d_last.read() == 1) {
                v.resp_ready = 0;
                v.state = STATE_Idle;
                if (r.wr_col.read() >= i_width_m1.read()) {
                    v.wr_col = 0;
                    v.wr_row = (r.wr_row.read() + 1);
                    v.wr_addr = ((r.wr_addr.read()(7, 6) + 1) << 6);
                }
            }
        }
        break;
    case STATE_EndOfFrame:
        if (i_vsync.read() == 0) {
            // Negedge of vsync:
            v.wr_col = 0;
            v.wr_row = 0;
            v.wr_addr = 0;
            v.difcnt = 0;
            v.rd_row = 0;
            v.rd_col = 0;
            v.rd_addr = 0;
            v.mux_ena = 0x1;
            v.state = STATE_Idle;
        }
        break;
    }

    if (i_de.read() == 1) {
        v.mux_ena = (r.mux_ena.read()(2, 0), r.mux_ena.read()[3]);
        if (r.mux_ena.read()[0] != 0) {
            v_rd_ena = 1;
            v.rd_addr = (r.rd_addr.read() + 1);
            v.rd_col = (r.rd_col.read() + 4);               // 64-bits contains 4x16-bits pixels
        }
    } else if ((r.de.read()[0] != 0) && (i_de.read() == 0)) {
        // Back front of the de (end of row)
        v.rd_addr = ((r.rd_addr.read()(7, 6) + 1) << 6);
        v.mux_ena = 0x1;
        v.rd_col = 0;
        v.rd_row = (r.rd_row.read() + 1);
    }
    if ((i_resp_2d_valid.read() == 1) && (v_rd_ena == 0)) {
        v.difcnt = (r.difcnt.read() + 1);
    } else if ((i_resp_2d_valid.read() == 0) && (v_rd_ena == 1)) {
        v.difcnt = (r.difcnt.read() - 1);
    } else if ((i_hsync.read() == 0) && (r.h_sync.read()[0] != 0)) {
        // correction, we can write more than used
        v.difcnt = r.wr_col.read()(11, 2);
    }

    if (r.wr_addr.read()(7, 6) == 0) {
        w_ring0_wena = i_resp_2d_valid.read();
        wb_ring0_addr = r.wr_addr.read()(6, 0);
        w_ring1_wena = 0;
        wb_ring1_addr = r.rd_addr.read()(6, 0);
        w_ring2_wena = 0;
        wb_ring2_addr = r.rd_addr.read()(6, 0);
        w_ring3_wena = 0;
        wb_ring3_addr = r.rd_addr.read()(6, 0);
    } else if (r.wr_addr.read()(7, 6) == 1) {
        w_ring0_wena = 0;
        wb_ring0_addr = r.rd_addr.read()(6, 0);
        w_ring1_wena = i_resp_2d_valid.read();
        wb_ring1_addr = r.wr_addr.read()(6, 0);
        w_ring2_wena = 0;
        wb_ring2_addr = r.rd_addr.read()(6, 0);
        w_ring3_wena = 0;
        wb_ring3_addr = r.rd_addr.read()(6, 0);
    } else if (r.wr_addr.read()(7, 6) == 2) {
        w_ring0_wena = 0;
        wb_ring0_addr = r.rd_addr.read()(6, 0);
        w_ring1_wena = 0;
        wb_ring1_addr = r.rd_addr.read()(6, 0);
        w_ring2_wena = i_resp_2d_valid.read();
        wb_ring2_addr = r.wr_addr.read()(6, 0);
        w_ring3_wena = 0;
        wb_ring3_addr = r.rd_addr.read()(6, 0);
    } else {
        w_ring0_wena = 0;
        wb_ring0_addr = r.rd_addr.read()(6, 0);
        w_ring1_wena = 0;
        wb_ring1_addr = r.rd_addr.read()(6, 0);
        w_ring2_wena = 0;
        wb_ring2_addr = r.rd_addr.read()(6, 0);
        w_ring3_wena = i_resp_2d_valid.read();
        wb_ring3_addr = r.wr_addr.read()(6, 0);
    }
    if (r.rd_addr.read()(7, 6) == 0) {
        v.ring_sel = 0x1;
    } else if (r.rd_addr.read()(7, 6) == 1) {
        v.ring_sel = 0x2;
    } else if (r.rd_addr.read()(7, 6) == 2) {
        v.ring_sel = 0x4;
    } else {
        v.ring_sel = 0x8;
    }
    v.pix_sel = r.mux_ena.read();

    if (r.ring_sel.read()[0] != 0) {
        vb_ring_rdata = wb_ring0_rdata.read();
    } else if (r.ring_sel.read()[1] != 0) {
        vb_ring_rdata = wb_ring1_rdata.read();
    } else if (r.ring_sel.read()[2] != 0) {
        vb_ring_rdata = wb_ring2_rdata.read();
    } else {
        vb_ring_rdata = wb_ring3_rdata.read();
    }
    if (r.de.read().or_reduce() == 0) {
        vb_pix = 0;
    } else if (r.pix_sel.read()[0] != 0) {
        vb_pix = vb_ring_rdata(15, 0);
    } else if (r.pix_sel.read()[1] != 0) {
        vb_pix = vb_ring_rdata(31, 16);
    } else if (r.pix_sel.read()[2] != 0) {
        vb_pix = vb_ring_rdata(47, 32);
    } else {
        vb_pix = vb_ring_rdata(63, 48);
    }
    v.rgb = vb_pix;

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        framebuf_r_reset(v);
    }

    o_hsync = r.h_sync.read()[1];
    o_vsync = r.v_sync.read()[1];
    o_de = r.de.read()[1];
    o_rgb565 = r.rgb.read();

    o_req_2d_valid = r.req_valid.read();
    o_req_2d_bytes = 64;                                    // Xilinx MIG is limited to burst beat length 8
    o_req_2d_addr = r.req_addr.read()(23, 0);
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

