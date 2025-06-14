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
#pragma once

#include <systemc.h>
#include "../../sim/mem/ram_tech.h"

namespace debugger {

SC_MODULE(framebuf) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_hsync;                                    // Horizontal sync
    sc_in<bool> i_vsync;                                    // Vertical sync
    sc_in<bool> i_de;                                       // data enable
    sc_in<sc_uint<12>> i_width_m1;                          // x-width: 4K = 3840 - 1
    sc_in<sc_uint<12>> i_height_m1;                         // y-height: 4K = 2160 - 1
    sc_out<bool> o_hsync;                                   // delayed horizontal sync
    sc_out<bool> o_vsync;                                   // delayed vertical sync
    sc_out<bool> o_de;                                      // delayed data enable
    sc_out<sc_uint<16>> o_rgb565;                           // RGB 16-bits pixels
    // DMA engine compatible interface (always read). Get pixels array:
    sc_in<bool> i_req_2d_ready;                             // 2D pixels ready to accept request
    sc_out<bool> o_req_2d_valid;                            // 2D pixels request is valid
    sc_out<sc_uint<12>> o_req_2d_bytes;                     // 0=4096 Bytes; 4=DWORD; 8=QWORD; ...
    sc_out<sc_uint<24>> o_req_2d_addr;                      // 16 MB allocated for framebuffer
    sc_in<bool> i_resp_2d_valid;                            // 2D pixels buffer response is valid
    sc_in<bool> i_resp_2d_last;                             // Last data in burst read
    sc_in<sc_uint<24>> i_resp_2d_addr;                      // 16 MB allocated for framebuffer
    sc_in<sc_uint<64>> i_resp_2d_data;                      // Read data
    sc_out<bool> o_resp_2d_ready;                           // Ready to accept 2D pixels response

    void comb();
    void registers();

    framebuf(sc_module_name name,
             bool async_reset);
    virtual ~framebuf();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    // state machine states:
    static const uint8_t STATE_Idle = 0x0;
    static const uint8_t STATE_Request = 0x1;
    static const uint8_t STATE_Writing = 0x2;
    static const uint8_t STATE_EndOfFrame = 0x3;

    struct framebuf_registers {
        sc_signal<sc_uint<12>> wr_row;
        sc_signal<sc_uint<12>> wr_col;
        sc_signal<sc_uint<8>> wr_addr;
        sc_signal<sc_uint<12>> rd_row;
        sc_signal<sc_uint<12>> rd_col;
        sc_signal<sc_uint<8>> rd_addr;
        sc_signal<sc_uint<4>> mux_ena;
        sc_signal<sc_uint<4>> ring_sel;
        sc_signal<sc_uint<4>> pix_sel;
        sc_signal<sc_uint<9>> difcnt;
        sc_signal<sc_uint<2>> state;
        sc_signal<sc_uint<25>> req_addr;                    // 32 MB (2 Bytes per pixel) allocated space split on 64 B: 32x64=2048 B
        sc_signal<bool> req_valid;
        sc_signal<bool> resp_ready;
        sc_signal<sc_uint<4>> h_sync;
        sc_signal<sc_uint<4>> v_sync;
        sc_signal<sc_uint<4>> de;
        sc_signal<sc_uint<16>> rgb;
    };

    void framebuf_r_reset(framebuf_registers& iv) {
        iv.wr_row = 0;
        iv.wr_col = 0;
        iv.wr_addr = 0;
        iv.rd_row = 0;
        iv.rd_col = 0;
        iv.rd_addr = 0;
        iv.mux_ena = 0x1;
        iv.ring_sel = 0;
        iv.pix_sel = 0;
        iv.difcnt = 0;
        iv.state = STATE_Idle;
        iv.req_addr = 0;
        iv.req_valid = 0;
        iv.resp_ready = 0;
        iv.h_sync = 0;
        iv.v_sync = 0;
        iv.de = 0;
        iv.rgb = 0;
    }

    sc_signal<sc_uint<6>> wb_ring0_addr;
    sc_signal<bool> w_ring0_wena;
    sc_signal<sc_uint<64>> wb_ring0_rdata;
    sc_signal<sc_uint<6>> wb_ring1_addr;
    sc_signal<bool> w_ring1_wena;
    sc_signal<sc_uint<64>> wb_ring1_rdata;
    sc_signal<sc_uint<6>> wb_ring2_addr;
    sc_signal<bool> w_ring2_wena;
    sc_signal<sc_uint<64>> wb_ring2_rdata;
    sc_signal<sc_uint<6>> wb_ring3_addr;
    sc_signal<bool> w_ring3_wena;
    sc_signal<sc_uint<64>> wb_ring3_rdata;
    framebuf_registers v;
    framebuf_registers r;

    ram_tech<6, 64> *ring0;
    ram_tech<6, 64> *ring1;
    ram_tech<6, 64> *ring2;
    ram_tech<6, 64> *ring3;

};

}  // namespace debugger

