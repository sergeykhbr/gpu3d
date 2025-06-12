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

SC_MODULE(rgb2ycbcr) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_rgb565;                                   // RGB 16-bits input
    sc_out<sc_uint<8>> o_y;                                 // Intensity component
    sc_out<sc_uint<8>> o_cr;                                // Cr compnent
    sc_out<sc_uint<8>> o_cb;                                // Cb component

    void comb();
    void registers();

    rgb2ycbcr(sc_module_name name,
              bool async_reset);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct rgb2ycbcr_registers {
        sc_signal<sc_uint<8>> y;
        sc_signal<sc_uint<8>> cr;
        sc_signal<sc_uint<8>> cb;
    };

    void rgb2ycbcr_r_reset(rgb2ycbcr_registers& iv) {
        iv.y = 0;
        iv.cr = 0;
        iv.cb = 0;
    }

    rgb2ycbcr_registers v;
    rgb2ycbcr_registers r;

};

}  // namespace debugger

