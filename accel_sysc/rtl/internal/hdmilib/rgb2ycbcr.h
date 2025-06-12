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
#include "../mathlib/mul_4x4_i8.h"

namespace debugger {

SC_MODULE(rgb2ycbcr) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<sc_uint<16>> i_rgb565;                            // RGB 16-bits input
    sc_in<bool> i_hsync;                                    // Horizontal sync
    sc_in<bool> i_vsync;                                    // Vertical sync
    sc_in<bool> i_de;                                       // data enable
    sc_out<sc_uint<18>> o_ycbcr422;                         // YCbCr 16-bits 4:2:2 format plus 2 extra bits
    sc_out<bool> o_hsync;                                   // delayed horizontal sync
    sc_out<bool> o_vsync;                                   // delayed vertical sync
    sc_out<bool> o_de;                                      // delayed data enable

    void comb();
    void registers();

    rgb2ycbcr(sc_module_name name,
              bool async_reset);
    virtual ~rgb2ycbcr();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct rgb2ycbcr_registers {
        sc_signal<sc_uint<8>> hsync;
        sc_signal<sc_uint<8>> vsync;
        sc_signal<sc_uint<8>> de;
        sc_signal<sc_uint<7>> even;                         // HIGH on samples 0, 2, 4, ...
        sc_signal<sc_uint<16>> ycbcr422;
    };

    void rgb2ycbcr_r_reset(rgb2ycbcr_registers& iv) {
        iv.hsync = 0;
        iv.vsync = 0;
        iv.de = 0;
        iv.even = 0;
        iv.ycbcr422 = 0;
    }

    sc_signal<bool> w_signed;
    sc_signal<sc_uint<8>> wb_v0;
    sc_signal<sc_uint<8>> wb_v1;
    sc_signal<sc_uint<8>> wb_v2;
    sc_signal<sc_uint<8>> wb_v3;
    sc_signal<sc_biguint<128>> wb_m;
    sc_signal<sc_uint<18>> wb_res0;
    sc_signal<sc_uint<18>> wb_res1;
    sc_signal<sc_uint<18>> wb_res2;
    sc_signal<sc_uint<18>> wb_res3;
    rgb2ycbcr_registers v;
    rgb2ycbcr_registers r;

    mul_4x4_i8 *im8;

};

}  // namespace debugger

