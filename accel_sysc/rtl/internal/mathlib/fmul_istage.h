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
#include "api_core.h"

namespace debugger {

template<int ibits = 22,                                    // Input signal bitwise
         int mbits = 4>                                     // Operator m bitwise: possible values 4 (and potentially 3)
SC_MODULE(fmul_istage) {
 public:
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<sc_uint<ibits>> i_a;                              // integer value
    sc_in<sc_uint<mbits>> i_m;                              // 4-bits value to multiply 0..15 using adders
    sc_in<sc_uint<ibits>> i_carry;                          // Carry value: A * M + Carry
    sc_in<sc_uint<ibits>> i_zres;                           // value to delay. Only (4*idx) of ibits will be delayed
    sc_out<sc_uint<ibits>> o_result;                        // resulting bits concatated with z-value
    sc_out<sc_uint<ibits>> o_carry;                         // resulting carry bits

    void comb();
    void registers();

    fmul_istage(sc_module_name name,
                bool async_reset,
                int idx);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;
    int idx_;

    struct fmul_istage_registers {
        sc_signal<sc_uint<ibits>> zres;                     // cannot create array of template with different width bits
        sc_signal<sc_uint<(ibits + 4)>> res;
    };

    void fmul_istage_r_reset(fmul_istage_registers& iv) {
        iv.zres = 0;
        iv.res = 0;
    }

    fmul_istage_registers v;
    fmul_istage_registers r;

};

template<int ibits, int mbits>
fmul_istage<ibits, mbits>::fmul_istage(sc_module_name name,
                                       bool async_reset,
                                       int idx)
    : sc_module(name),
    i_clk("i_clk"),
    i_nrst("i_nrst"),
    i_a("i_a"),
    i_m("i_m"),
    i_carry("i_carry"),
    i_zres("i_zres"),
    o_result("o_result"),
    o_carry("o_carry") {

    async_reset_ = async_reset;
    idx_ = idx;

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_a;
    sensitive << i_m;
    sensitive << i_carry;
    sensitive << i_zres;
    sensitive << r.zres;
    sensitive << r.res;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

template<int ibits, int mbits>
void fmul_istage<ibits, mbits>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_a, i_a.name());
        sc_trace(o_vcd, i_m, i_m.name());
        sc_trace(o_vcd, i_carry, i_carry.name());
        sc_trace(o_vcd, i_zres, i_zres.name());
        sc_trace(o_vcd, o_result, o_result.name());
        sc_trace(o_vcd, o_carry, o_carry.name());
        sc_trace(o_vcd, r.zres, pn + ".r.zres");
        sc_trace(o_vcd, r.res, pn + ".r.res");
    }

}

template<int ibits, int mbits>
void fmul_istage<ibits, mbits>::comb() {
    sc_uint<(ibits + 4)> vb_mux[17];
    sc_uint<ibits> vb_zres;
    sc_uint<(ibits + 4)> vb_res;
    sc_uint<ibits> vb_res_idx;

    v = r;
    for (int i = 0; i < 17; i++) {
        vb_mux[i] = 0;
    }
    vb_zres = 0;
    vb_res = 0;
    vb_res_idx = 0;

    vb_mux[0] = 0;
    vb_mux[1] = i_a.read();
    vb_mux[2] = (i_a.read() << 1);
    vb_mux[3] = (vb_mux[2] + vb_mux[1]);
    vb_mux[4] = (i_a.read() << 2);
    vb_mux[5] = (vb_mux[4] + vb_mux[1]);
    vb_mux[6] = (vb_mux[4] + vb_mux[2]);
    vb_mux[8] = (i_a.read() << 3);
    vb_mux[7] = (vb_mux[8] - vb_mux[1]);
    vb_mux[9] = (vb_mux[8] + vb_mux[1]);
    vb_mux[10] = (vb_mux[8] + vb_mux[2]);
    vb_mux[11] = (vb_mux[10] + vb_mux[1]);
    vb_mux[12] = (vb_mux[8] + vb_mux[4]);
    vb_mux[16] = (i_a.read() << 4);
    vb_mux[13] = (vb_mux[16] - vb_mux[3]);
    vb_mux[14] = (vb_mux[16] - vb_mux[2]);
    vb_mux[15] = (vb_mux[16] - vb_mux[1]);

    switch (i_m.read()) {
    case 1:
        vb_res = (vb_mux[1] + (0, i_carry.read()));
        break;
    case 2:
        vb_res = (vb_mux[2] + (0, i_carry.read()));
        break;
    case 3:
        vb_res = (vb_mux[3] + (0, i_carry.read()));
        break;
    case 4:
        vb_res = (vb_mux[4] + (0, i_carry.read()));
        break;
    case 5:
        vb_res = (vb_mux[5] + (0, i_carry.read()));
        break;
    case 6:
        vb_res = (vb_mux[6] + (0, i_carry.read()));
        break;
    case 7:
        vb_res = (vb_mux[7] + (0, i_carry.read()));
        break;
    case 8:
        vb_res = (vb_mux[8] + (0, i_carry.read()));
        break;
    case 9:
        vb_res = (vb_mux[9] + (0, i_carry.read()));
        break;
    case 10:
        vb_res = (vb_mux[10] + (0, i_carry.read()));
        break;
    case 11:
        vb_res = (vb_mux[11] + (0, i_carry.read()));
        break;
    case 12:
        vb_res = (vb_mux[12] + (0, i_carry.read()));
        break;
    case 13:
        vb_res = (vb_mux[13] + (0, i_carry.read()));
        break;
    case 14:
        vb_res = (vb_mux[14] + (0, i_carry.read()));
        break;
    case 15:
        vb_res = (vb_mux[15] + (0, i_carry.read()));
        break;
    default:
        vb_res = (0, i_carry.read());
        break;
    }

    v.res = vb_res;

    if (idx_ != 0) {
        vb_zres(((idx_ * mbits) - 1), 0) = i_zres.read()(((idx_ * mbits) - 1), 0);
        vb_res_idx(((idx_ * mbits) - 1), 0) = r.zres.read();
    }
    v.zres = vb_zres;
    vb_res_idx((idx_ * mbits) + 4 - 1, (idx_ * mbits)) = r.res.read()(3, 0);

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        fmul_istage_r_reset(v);
    }

    o_result = vb_res_idx;
    o_carry = r.res.read()((ibits + 3), 4);
}

template<int ibits, int mbits>
void fmul_istage<ibits, mbits>::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        fmul_istage_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

