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
#include "../common/vips/clk/vip_clk.h"
#include "../../rtl/internal/mathlib/mul_i8.h"

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
    sc_signal<sc_uint<8>> wb_a;
    sc_signal<sc_uint<8>> wb_b;
    sc_signal<sc_uint<16>> wb_res;
    sc_signal<bool> w_signed;

    vip_clk *clk;
    mul_i8 *mul0;

};

}  // namespace debugger

