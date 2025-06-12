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
#include "mul_i8.h"

namespace debugger {

SC_MODULE(mul_4x4_i8) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_signed;                                   // 0=unsigned; 1=signed operation
    sc_in<sc_uint<8>> i_v0;                                 // input vector coordinate 0
    sc_in<sc_uint<8>> i_v1;                                 // input vector coordinate 1
    sc_in<sc_uint<8>> i_v2;                                 // input vector coordinate 2
    sc_in<sc_uint<8>> i_v3;                                 // input vector coordinate 3
    sc_in<sc_biguint<128>> i_m;                             // matrix rates 16 x 8 bits each
    sc_out<sc_uint<18>> o_res0;                             // result vector coordinate 0
    sc_out<sc_uint<18>> o_res1;                             // result vector coordinate 1
    sc_out<sc_uint<18>> o_res2;                             // result vector coordinate 2
    sc_out<sc_uint<18>> o_res3;                             // result vector coordinate 3

    void comb();
    void registers();

    mul_4x4_i8(sc_module_name name,
               bool async_reset);
    virtual ~mul_4x4_i8();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    struct mul_4x4_i8_registers {
        sc_signal<sc_uint<17>> sum0a;
        sc_signal<sc_uint<17>> sum0b;
        sc_signal<sc_uint<17>> sum1a;
        sc_signal<sc_uint<17>> sum1b;
        sc_signal<sc_uint<17>> sum2a;
        sc_signal<sc_uint<17>> sum2b;
        sc_signal<sc_uint<17>> sum3a;
        sc_signal<sc_uint<17>> sum3b;
        sc_signal<sc_uint<18>> res0;
        sc_signal<sc_uint<18>> res1;
        sc_signal<sc_uint<18>> res2;
        sc_signal<sc_uint<18>> res3;
        sc_signal<sc_uint<6>> sign;
    };

    void mul_4x4_i8_r_reset(mul_4x4_i8_registers& iv) {
        iv.sum0a = 0;
        iv.sum0b = 0;
        iv.sum1a = 0;
        iv.sum1b = 0;
        iv.sum2a = 0;
        iv.sum2b = 0;
        iv.sum3a = 0;
        iv.sum3b = 0;
        iv.res0 = 0;
        iv.res1 = 0;
        iv.res2 = 0;
        iv.res3 = 0;
        iv.sign = 0;
    }

    sc_signal<sc_uint<8>> wb_b00;
    sc_signal<sc_uint<8>> wb_b01;
    sc_signal<sc_uint<8>> wb_b02;
    sc_signal<sc_uint<8>> wb_b03;
    sc_signal<sc_uint<8>> wb_b10;
    sc_signal<sc_uint<8>> wb_b11;
    sc_signal<sc_uint<8>> wb_b12;
    sc_signal<sc_uint<8>> wb_b13;
    sc_signal<sc_uint<8>> wb_b20;
    sc_signal<sc_uint<8>> wb_b21;
    sc_signal<sc_uint<8>> wb_b22;
    sc_signal<sc_uint<8>> wb_b23;
    sc_signal<sc_uint<8>> wb_b30;
    sc_signal<sc_uint<8>> wb_b31;
    sc_signal<sc_uint<8>> wb_b32;
    sc_signal<sc_uint<8>> wb_b33;
    sc_signal<sc_uint<16>> wb_m00;
    sc_signal<sc_uint<16>> wb_m01;
    sc_signal<sc_uint<16>> wb_m02;
    sc_signal<sc_uint<16>> wb_m03;
    sc_signal<sc_uint<16>> wb_m10;
    sc_signal<sc_uint<16>> wb_m11;
    sc_signal<sc_uint<16>> wb_m12;
    sc_signal<sc_uint<16>> wb_m13;
    sc_signal<sc_uint<16>> wb_m20;
    sc_signal<sc_uint<16>> wb_m21;
    sc_signal<sc_uint<16>> wb_m22;
    sc_signal<sc_uint<16>> wb_m23;
    sc_signal<sc_uint<16>> wb_m30;
    sc_signal<sc_uint<16>> wb_m31;
    sc_signal<sc_uint<16>> wb_m32;
    sc_signal<sc_uint<16>> wb_m33;
    mul_4x4_i8_registers v;
    mul_4x4_i8_registers r;

    mul_i8 *m00;
    mul_i8 *m01;
    mul_i8 *m02;
    mul_i8 *m03;
    mul_i8 *m10;
    mul_i8 *m11;
    mul_i8 *m12;
    mul_i8 *m13;
    mul_i8 *m20;
    mul_i8 *m21;
    mul_i8 *m22;
    mul_i8 *m23;
    mul_i8 *m30;
    mul_i8 *m31;
    mul_i8 *m32;
    mul_i8 *m33;

};

}  // namespace debugger

