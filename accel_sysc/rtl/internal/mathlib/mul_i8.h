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

SC_MODULE(mul_i8) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<sc_uint<8>> i_a;                                  // multiplier A
    sc_in<sc_uint<8>> i_b;                                  // multiplier B
    sc_in<bool> i_signed;                                   // 0=unsigned; 1=signed operation
    sc_out<sc_uint<16>> o_res;                              // result

    void comb();
    void registers();

    mul_i8(sc_module_name name,
           bool async_reset);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct mul_i8_registers {
        sc_signal<sc_uint<8>> ua;
        sc_signal<sc_uint<8>> ub;
        sc_signal<sc_uint<4>> inv;
        sc_signal<sc_uint<10>> lvl1_0;
        sc_signal<sc_uint<10>> lvl1_1;
        sc_signal<sc_uint<10>> lvl1_2;
        sc_signal<sc_uint<10>> lvl1_3;
        sc_signal<sc_uint<13>> lvl2_0;
        sc_signal<sc_uint<13>> lvl2_1;
        sc_signal<sc_uint<16>> lvl3;
        sc_signal<sc_uint<16>> res;
    };

    void mul_i8_r_reset(mul_i8_registers& iv) {
        iv.ua = 0;
        iv.ub = 0;
        iv.inv = 0;
        iv.lvl1_0 = 0;
        iv.lvl1_1 = 0;
        iv.lvl1_2 = 0;
        iv.lvl1_3 = 0;
        iv.lvl2_0 = 0;
        iv.lvl2_1 = 0;
        iv.lvl3 = 0;
        iv.res = 0;
    }

    mul_i8_registers v;
    mul_i8_registers r;

};

}  // namespace debugger

