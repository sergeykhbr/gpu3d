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
#include "../mem/ram_tech.h"

namespace debugger {

SC_MODULE(framebuf) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_hsync;                                    // Horizontal sync
    sc_in<bool> i_vsync;                                    // Vertical sync
    sc_in<bool> i_de;                                       // data enable
    sc_in<sc_uint<11>> i_x;                                 // x-pixel
    sc_in<sc_uint<10>> i_y;                                 // y-pixel
    sc_in<sc_uint<24>> i_xy_total;                          // x*y resolution, up to 16MB
    sc_out<bool> o_hsync;                                   // delayed horizontal sync
    sc_out<bool> o_vsync;                                   // delayed vertical sync
    sc_out<bool> o_de;                                      // delayed data enable
    sc_out<sc_uint<18>> o_YCbCr;                            // YCbCr multiplexed odd/even pixels
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
    static const uint8_t STATE_Request = 0x1;
    static const uint8_t STATE_Writing = 0x2;
    static const uint8_t STATE_Idle = 0x0;

    struct framebuf_registers {
        sc_signal<sc_uint<2>> state;
        sc_signal<bool> pingpong;
        sc_signal<sc_uint<18>> req_addr;                    // 16 MB allocated space split on 64 B: 32x64=2048 B
        sc_signal<bool> req_valid;
        sc_signal<bool> resp_ready;
        sc_signal<sc_uint<11>> raddr;
        sc_signal<sc_uint<11>> raddr_z;
        sc_signal<bool> pix_x0;
        sc_signal<sc_uint<4>> h_sync;
        sc_signal<sc_uint<4>> v_sync;
        sc_signal<sc_uint<4>> de;
        sc_signal<sc_uint<8>> Y0;
        sc_signal<sc_uint<8>> Y1;
        sc_signal<sc_uint<8>> Cb;
        sc_signal<sc_uint<8>> Cr;
        sc_signal<sc_uint<16>> YCbCr;
    };

    void framebuf_r_reset(framebuf_registers& iv) {
        iv.state = STATE_Request;
        iv.pingpong = 0;
        iv.req_addr = 32;
        iv.req_valid = 0;
        iv.resp_ready = 0;
        iv.raddr = 0;
        iv.raddr_z = 0;
        iv.pix_x0 = 0;
        iv.h_sync = 0;
        iv.v_sync = 0;
        iv.de = 0;
        iv.Y0 = 0;
        iv.Y1 = 0;
        iv.Cb = 0;
        iv.Cr = 0;
        iv.YCbCr = 0;
    }

    sc_signal<sc_uint<8>> wb_ping_addr;
    sc_signal<bool> w_ping_wena;
    sc_signal<sc_uint<64>> wb_ping_rdata;
    sc_signal<sc_uint<8>> wb_pong_addr;
    sc_signal<bool> w_pong_wena;
    sc_signal<sc_uint<64>> wb_pong_rdata;
    framebuf_registers v;
    framebuf_registers r;

    ram_tech<8, 64> *ping;
    ram_tech<8, 64> *pong;

};

}  // namespace debugger

