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
    sc_out<bool> o_hsync;                                   // delayed horizontal sync
    sc_out<bool> o_vsync;                                   // delayed vertical sync
    sc_out<bool> o_de;                                      // delayed data enable
    sc_out<sc_uint<18>> o_YCbCr;                            // YCbCr multiplexed odd/even pixels

    void comb();
    void registers();

    framebuf(sc_module_name name,
             bool async_reset);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct framebuf_registers {
        sc_signal<bool> pix_x0;
        sc_signal<sc_uint<2>> h_sync;
        sc_signal<sc_uint<2>> v_sync;
        sc_signal<sc_uint<2>> de;
        sc_signal<sc_uint<8>> Y0;
        sc_signal<sc_uint<8>> Y1;
        sc_signal<sc_uint<8>> Cb;
        sc_signal<sc_uint<8>> Cr;
        sc_signal<sc_uint<16>> YCbCr;
    };

    void framebuf_r_reset(framebuf_registers& iv) {
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

    framebuf_registers v;
    framebuf_registers r;

};

}  // namespace debugger

