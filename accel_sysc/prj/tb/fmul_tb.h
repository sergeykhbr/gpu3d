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
#include "../../rtl/internal/mathlib/fmul_generic.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(fmul_tb) {
 public:

    void init();
    void comb();
    void test_clk();
    void registers();

    fmul_tb(sc_module_name name);
    virtual ~fmul_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    struct fmul_tb_registers {
        sc_signal<sc_uint<32>> clk_cnt;
        sc_signal<sc_uint<32>> compare_cnt;
        sc_signal<sc_uint<32>> err_cnt;
        sc_signal<sc_uint<32>> compare_a[13];
    };

    void fmul_tb_r_reset(fmul_tb_registers& iv) {
        iv.clk_cnt = 0;
        iv.compare_cnt = 0;
        iv.err_cnt = 0;
        for (int i = 0; i < 13; i++) {
            iv.compare_a[i] = 0;
        }
    }

    sc_signal<bool> nrst;                                   // Power-on system reset active LOW
    sc_signal<bool> clk;
    sc_signal<bool> w_ena;
    sc_signal<sc_uint<32>> wb_a;
    sc_signal<sc_uint<32>> wb_b;
    sc_signal<sc_uint<32>> wb_res;
    sc_signal<bool> w_valid;
    sc_signal<bool> w_ex;
    sc_signal<bool> w_compare_ena;
    sc_signal<sc_uint<32>> wb_compare_a;
    sc_signal<bool> w_show_result;
    fmul_tb_registers v;
    fmul_tb_registers r;

    pll_generic *pll0;
    fmul_generic<32, 8> *mul_fp32;

};

}  // namespace debugger

