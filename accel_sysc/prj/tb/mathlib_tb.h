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
#include "../../rtl/sim/pll/pll_generic.h"
#include "../../rtl/internal/mathlib/mul_4x4_i8.h"

namespace debugger {

SC_MODULE(mathlib_tb) {
 public:

    void init();
    void comb();
    void test_clk();

    mathlib_tb(sc_module_name name);
    virtual ~mathlib_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    sc_signal<bool> w_nrst;                                 // Power-on system reset active LOW
    sc_signal<bool> w_clk;
    sc_uint<32> wb_clk_cnt;
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

    pll_generic *clk;
    mul_4x4_i8 *im8;

};

}  // namespace debugger

