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
#include "fmul_istage.h"
#include "lzd_scaler.h"
#include "api_core.h"

namespace debugger {

template<int fbits = 32,                                    // Input format: FP32 = 32, FP16 = 16, BF16 = 16
         int expbits = 8,                                   // Exponent bitwidth: FP64 = 11, FP32 = 8, FP16 = 5, BF16 = 8
         int shiftbits = 6>                                 // Mantissa scale factor bits: must be $clog2(2*(fbits-expbits)), avoid using $clog2
SC_MODULE(fmul_generic) {
 public:
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_ena;
    sc_in<sc_uint<fbits>> i_a;                              // Operand 1
    sc_in<sc_uint<fbits>> i_b;                              // Operand 2
    sc_out<sc_uint<fbits>> o_res;                           // Result
    sc_out<bool> o_ex;                                      // Exception, overflow or underflow
    sc_out<bool> o_valid;                                   // Result is valid

    void comb();
    void registers();

    fmul_generic(sc_module_name name,
                 bool async_reset);
    virtual ~fmul_generic();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    static const int mantbits = ((fbits - expbits) - 1);    // Encoded mantissa bitwidth: FP64 = 52, FP32 = 23, FP16 = 10, BF16 = 7
    static const int mantmaxbits = (2 * (mantbits + 1));    // Mantissa maximum bitwidth before shifting
    static const int explevel = ((1 << (expbits - 1)) - 1); // Level 1 for exponent: 1023 (double); 127 (fp32)
    static const int hex_chunks = ((mantbits + 3) / 4);     // Number of hex multipliers
    static const int latency = (hex_chunks + 7);            // Cycles: 1 in latch + hex_chunks + 2 scaler + 2 rnd + 1 out latch + 1?

    struct fmul_generic_registers {
        sc_signal<sc_uint<latency>> ena;
        sc_signal<sc_uint<fbits>> a;
        sc_signal<sc_uint<fbits>> b;
        sc_signal<sc_uint<fbits>> result;
        sc_signal<sc_uint<(latency - 2)>> sign;
        sc_signal<sc_uint<(mantbits + 1)>> mantA[hex_chunks];
        sc_signal<sc_uint<(mantbits + 1)>> mantB[hex_chunks];
        sc_signal<sc_uint<(expbits + 2)>> expAB[(hex_chunks + 3)];
        sc_signal<bool> lzd_noscaling;
        sc_signal<sc_uint<(expbits + 2)>> exp_res;
        sc_signal<sc_uint<(mantbits + 1)>> mant_res;
        sc_signal<bool> rnd_res;
        sc_signal<sc_uint<expbits>> exp_res_rnd;
        sc_signal<sc_uint<mantbits>> mant_res_rnd;
        sc_signal<bool> underflow;
        sc_signal<bool> overflow;
        sc_signal<bool> ex;                                 // Exception: overflow or underflow
    };

    void fmul_generic_r_reset(fmul_generic_registers& iv) {
        iv.ena = 0;
        iv.a = 0;
        iv.b = 0;
        iv.result = 0;
        iv.sign = 0;
        for (int i = 0; i < hex_chunks; i++) {
            iv.mantA[i] = 0;
        }
        for (int i = 0; i < hex_chunks; i++) {
            iv.mantB[i] = 0;
        }
        for (int i = 0; i < (hex_chunks + 3); i++) {
            iv.expAB[i] = 0;
        }
        iv.lzd_noscaling = 0;
        iv.exp_res = 0;
        iv.mant_res = 0;
        iv.rnd_res = 0;
        iv.exp_res_rnd = 0;
        iv.mant_res_rnd = 0;
        iv.underflow = 0;
        iv.overflow = 0;
        iv.ex = 0;
    }

    sc_signal<sc_uint<4>> wb_hex_i[hex_chunks];
    sc_signal<sc_uint<(mantbits + 1)>> wb_carry_i[hex_chunks];
    sc_signal<sc_uint<(mantbits + 1)>> wb_zres_i[hex_chunks];
    sc_signal<sc_uint<(mantbits + 1)>> wb_mant_lsb[hex_chunks];
    sc_signal<sc_uint<(mantbits + 1)>> wb_mant_msb[hex_chunks];
    sc_signal<sc_uint<mantmaxbits>> wb_mant_full;
    sc_signal<sc_uint<shiftbits>> wb_mant_aligned_idx;
    sc_signal<sc_uint<mantmaxbits>> wb_mant_aligned;
    fmul_generic_registers v;
    fmul_generic_registers r;

    fmul_istage<(mantbits + 1), 4> *stagex[hex_chunks];
    lzd_scaler<mantmaxbits, shiftbits> *scaler0;

};

template<int fbits, int expbits, int shiftbits>
fmul_generic<fbits, expbits, shiftbits>::fmul_generic(sc_module_name name,
                                                      bool async_reset)
    : sc_module(name),
    i_clk("i_clk"),
    i_nrst("i_nrst"),
    i_ena("i_ena"),
    i_a("i_a"),
    i_b("i_b"),
    o_res("o_res"),
    o_ex("o_ex"),
    o_valid("o_valid") {

    async_reset_ = async_reset;
    for (int i = 0; i < hex_chunks; i++) {
        stagex[i] = 0;
    }
    scaler0 = 0;


    // generate
    for (int i = 0; i < hex_chunks; i++) {
        char tstr[256];
        RISCV_sprintf(tstr, sizeof(tstr), "stagex%d", i);
        stagex[i] = new fmul_istage<(mantbits + 1),
                                    4>(tstr,
                                       async_reset,
                                       i);
        stagex[i]->i_clk(i_clk);
        stagex[i]->i_nrst(i_nrst);
        stagex[i]->i_a(r.mantA[i]);
        stagex[i]->i_m(wb_hex_i[i]);
        stagex[i]->i_carry(wb_carry_i[i]);
        stagex[i]->i_zres(wb_zres_i[i]);
        stagex[i]->o_result(wb_mant_lsb[i]);
        stagex[i]->o_carry(wb_mant_msb[i]);
    }
    // endgenerate

    scaler0 = new lzd_scaler<mantmaxbits,
                             shiftbits>("scaler0",
                                        async_reset);
    scaler0->i_clk(i_clk);
    scaler0->i_nrst(i_nrst);
    scaler0->i_m(wb_mant_full);
    scaler0->i_noscale(r.lzd_noscaling);
    scaler0->o_scaled(wb_mant_aligned);
    scaler0->o_scaled_factor(wb_mant_aligned_idx);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_ena;
    sensitive << i_a;
    sensitive << i_b;
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << wb_hex_i[i];
    }
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << wb_carry_i[i];
    }
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << wb_zres_i[i];
    }
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << wb_mant_lsb[i];
    }
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << wb_mant_msb[i];
    }
    sensitive << wb_mant_full;
    sensitive << wb_mant_aligned_idx;
    sensitive << wb_mant_aligned;
    sensitive << r.ena;
    sensitive << r.a;
    sensitive << r.b;
    sensitive << r.result;
    sensitive << r.sign;
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << r.mantA[i];
    }
    for (int i = 0; i < hex_chunks; i++) {
        sensitive << r.mantB[i];
    }
    for (int i = 0; i < (hex_chunks + 3); i++) {
        sensitive << r.expAB[i];
    }
    sensitive << r.lzd_noscaling;
    sensitive << r.exp_res;
    sensitive << r.mant_res;
    sensitive << r.rnd_res;
    sensitive << r.exp_res_rnd;
    sensitive << r.mant_res_rnd;
    sensitive << r.underflow;
    sensitive << r.overflow;
    sensitive << r.ex;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

template<int fbits, int expbits, int shiftbits>
fmul_generic<fbits, expbits, shiftbits>::~fmul_generic() {
    for (int i = 0; i < hex_chunks; i++) {
        if (stagex[i]) {
            delete stagex[i];
        }
    }
    if (scaler0) {
        delete scaler0;
    }
}

template<int fbits, int expbits, int shiftbits>
void fmul_generic<fbits, expbits, shiftbits>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_ena, i_ena.name());
        sc_trace(o_vcd, i_a, i_a.name());
        sc_trace(o_vcd, i_b, i_b.name());
        sc_trace(o_vcd, o_res, o_res.name());
        sc_trace(o_vcd, o_ex, o_ex.name());
        sc_trace(o_vcd, o_valid, o_valid.name());
        sc_trace(o_vcd, r.ena, pn + ".r.ena");
        sc_trace(o_vcd, r.a, pn + ".r.a");
        sc_trace(o_vcd, r.b, pn + ".r.b");
        sc_trace(o_vcd, r.result, pn + ".r.result");
        sc_trace(o_vcd, r.sign, pn + ".r.sign");
        for (int i = 0; i < hex_chunks; i++) {
            sc_trace(o_vcd, r.mantA[i], pn + ".r.mantA(" + std::to_string(i) + ")");
        }
        for (int i = 0; i < hex_chunks; i++) {
            sc_trace(o_vcd, r.mantB[i], pn + ".r.mantB(" + std::to_string(i) + ")");
        }
        for (int i = 0; i < (hex_chunks + 3); i++) {
            sc_trace(o_vcd, r.expAB[i], pn + ".r.expAB(" + std::to_string(i) + ")");
        }
        sc_trace(o_vcd, r.lzd_noscaling, pn + ".r.lzd_noscaling");
        sc_trace(o_vcd, r.exp_res, pn + ".r.exp_res");
        sc_trace(o_vcd, r.mant_res, pn + ".r.mant_res");
        sc_trace(o_vcd, r.rnd_res, pn + ".r.rnd_res");
        sc_trace(o_vcd, r.exp_res_rnd, pn + ".r.exp_res_rnd");
        sc_trace(o_vcd, r.mant_res_rnd, pn + ".r.mant_res_rnd");
        sc_trace(o_vcd, r.underflow, pn + ".r.underflow");
        sc_trace(o_vcd, r.overflow, pn + ".r.overflow");
        sc_trace(o_vcd, r.ex, pn + ".r.ex");
    }

    for (int i = 0; i < hex_chunks; i++) {
        if (stagex[i]) {
            stagex[i]->generateVCD(i_vcd, o_vcd);
        }
    }
    if (scaler0) {
        scaler0->generateVCD(i_vcd, o_vcd);
    }
}

template<int fbits, int expbits, int shiftbits>
void fmul_generic<fbits, expbits, shiftbits>::comb() {
    sc_uint<5> vb_ena;
    sc_uint<(mantbits + 2)> vb_mant_res_rnd;
    sc_uint<(expbits + 2)> vb_exp_res_rnd;
    bool v_underflow;
    bool v_overflow;
    sc_uint<(mantbits + 1)> vb_mantA;
    sc_uint<(mantbits + 1)> vb_mantB;
    sc_uint<(expbits + 2)> vb_expA_t;
    sc_uint<(expbits + 2)> vb_expB_t;
    sc_uint<(expbits + 2)> vb_expAB_t;
    bool mant_even;
    bool mant05;
    sc_uint<1> rndBit;

    v.ena = r.ena.read();
    v.a = r.a.read();
    v.b = r.b.read();
    v.result = r.result.read();
    v.sign = r.sign.read();
    for (int i = 0; i < hex_chunks; i++) {
        v.mantA[i] = r.mantA[i].read();
    }
    for (int i = 0; i < hex_chunks; i++) {
        v.mantB[i] = r.mantB[i].read();
    }
    for (int i = 0; i < (hex_chunks + 3); i++) {
        v.expAB[i] = r.expAB[i].read();
    }
    v.lzd_noscaling = r.lzd_noscaling.read();
    v.exp_res = r.exp_res.read();
    v.mant_res = r.mant_res.read();
    v.rnd_res = r.rnd_res.read();
    v.exp_res_rnd = r.exp_res_rnd.read();
    v.mant_res_rnd = r.mant_res_rnd.read();
    v.underflow = r.underflow.read();
    v.overflow = r.overflow.read();
    v.ex = r.ex.read();
    vb_ena = 0;
    vb_mant_res_rnd = 0;
    vb_exp_res_rnd = 0;
    v_underflow = 0;
    v_overflow = 0;
    vb_mantA = 0;
    vb_mantB = 0;
    vb_expA_t = 0;
    vb_expB_t = 0;
    vb_expAB_t = 0;
    mant_even = 0;
    mant05 = 0;
    rndBit = 0;

    vb_ena[0] = i_ena.read();
    v.ena = (r.ena.read()((latency - 2), 0), i_ena.read());

    v.a = i_a.read();
    v.b = i_b.read();

    v.sign = (r.sign.read()((latency - 4), 0), (r.a.read()[(fbits - 1)] ^ r.b.read()[(fbits - 1)]));

    if (r.a.read()((fbits - 2), mantbits) == 0) {
        vb_mantA = (r.a.read()((mantbits - 1), 0) << 1);
    } else {
        vb_mantA = (1, r.a.read()((mantbits - 1), 0));
    }
    if (r.b.read()((fbits - 2), mantbits) == 0) {
        vb_mantB = (r.b.read()((mantbits - 1), 0) << 1);
    } else {
        vb_mantB = (1, r.b.read()((mantbits - 1), 0));
    }


    v.mantA[0] = vb_mantA;
    v.mantB[0] = vb_mantB;
    wb_carry_i[0] = 0;
    wb_zres_i[0] = 0;
    for (int i = 0; i < (hex_chunks - 1); i++) {
        wb_hex_i[i] = r.mantB[i].read()(3, 0);
        wb_carry_i[(i + 1)] = wb_mant_msb[i].read();
        wb_zres_i[(i + 1)] = wb_mant_lsb[i].read();
        v.mantA[(i + 1)] = r.mantA[i].read();
        v.mantB[(i + 1)] = (0, r.mantB[i].read()(mantbits, 4));
    }
    wb_hex_i[(hex_chunks - 1)] = r.mantB[(hex_chunks - 1)].read()(3, 0);

    // expA - expB + EXPONENT_ZERO_LEVEL
    vb_expA_t = (0, r.a.read()((fbits - 2), mantbits));
    vb_expB_t = (0, r.b.read()((fbits - 2), mantbits));
    vb_expAB_t = (vb_expA_t + vb_expB_t);
    // pipeline exponent pre-scaled value:
    v.expAB[0] = (vb_expAB_t - static_cast<sc_uint<(expbits + 2)>>(explevel));
    for (int i = 0; i < (hex_chunks + 2); i++) {
        v.expAB[(i + 1)] = r.expAB[i].read();
    }

    // Full istage output is valid when (goes to Leading Zero Detector Scaler):
    //       FP32: hex_chunks=6, ena[7]
    //       ena[hex_chunks + 1] == 1
    //       expAB[hex_chunks]
    //       {wb_mant_msb[hex_chunks - 1], wb_mant_lsb[hex_chunks - 1]}

    // Do not scale mantissa if the pre-scaled exponent <= 0:
    v.lzd_noscaling = 0;
    if ((r.expAB[(hex_chunks - 1)].read()[(expbits + 1)] != 0)
            || (r.expAB[(hex_chunks - 1)].read() == 0)) {
        v.lzd_noscaling = r.ena.read()[hex_chunks];
    }
    wb_mant_full = (wb_mant_msb[(hex_chunks - 1)].read(), wb_mant_lsb[(hex_chunks - 1)].read());

    v.exp_res = (r.expAB[(hex_chunks + 2)].read() - wb_mant_aligned_idx.read());
    v.mant_res = wb_mant_aligned.read()((mantmaxbits - 1), (mantmaxbits - (mantbits + 1)));

    // Rounding bit:
    mant_even = (!wb_mant_aligned.read()[(mantmaxbits - (mantbits + 1))]);
    rndBit = wb_mant_aligned.read()[(mantmaxbits - (mantbits + 2))];
    mant05 = (rndBit & (!wb_mant_aligned.read()((mantmaxbits - (mantbits + 3)), 0).or_reduce()));
    v.rnd_res = (rndBit && (!(mant05 && mant_even)));

    vb_mant_res_rnd = ((0, r.mant_res.read()) + (0, r.rnd_res.read()));
    vb_exp_res_rnd = (r.exp_res.read() + (0, vb_mant_res_rnd((mantbits + 1), mantbits)));

    // Overflow: exponent is positive but out-of-range of 'expbits':
    v_overflow = ((!vb_exp_res_rnd[(expbits + 1)]) && vb_exp_res_rnd[expbits]);// FP32 (exp-8): 01.****.****
    v.overflow = v_overflow;

    // Undeflow: exponent is negative:
    v_underflow = vb_exp_res_rnd[(expbits + 1)];
    v.underflow = v_underflow;

    // De-normals are the value with the zero exponent (Intel compiler flags):
    //   FTZ enabled - when on sets denormals calculated results to zero
    //   DAZ disabled - when on treats input denormals as zero.

    // No make sense to detect NaN and other things for GPU computation. No error handling
    if (v_overflow == 1) {
        v.exp_res_rnd = ~0ull;
        v.mant_res_rnd = ~0ull;
    } else if (v_underflow == 1) {
        v.exp_res_rnd = 0;
        v.mant_res_rnd = 0;
    } else {
        v.exp_res_rnd = vb_exp_res_rnd((expbits - 1), 0);
        v.mant_res_rnd = vb_mant_res_rnd((mantbits - 1), 0);
    }
    v.ex = (r.ena.read()[(latency - 2)] & (r.overflow.read() | r.underflow.read()));

    v.result = (r.sign.read()[(latency - 3)], r.exp_res_rnd.read(), r.mant_res_rnd.read());

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        fmul_generic_r_reset(v);
    }

    o_res = r.result.read();
    o_ex = r.ex.read();
    o_valid = r.ena.read()[(latency - 1)];
}

template<int fbits, int expbits, int shiftbits>
void fmul_generic<fbits, expbits, shiftbits>::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        fmul_generic_r_reset(r);
    } else {
        r.ena = v.ena.read();
        r.a = v.a.read();
        r.b = v.b.read();
        r.result = v.result.read();
        r.sign = v.sign.read();
        for (int i = 0; i < hex_chunks; i++) {
            r.mantA[i] = v.mantA[i].read();
        }
        for (int i = 0; i < hex_chunks; i++) {
            r.mantB[i] = v.mantB[i].read();
        }
        for (int i = 0; i < (hex_chunks + 3); i++) {
            r.expAB[i] = v.expAB[i].read();
        }
        r.lzd_noscaling = v.lzd_noscaling.read();
        r.exp_res = v.exp_res.read();
        r.mant_res = v.mant_res.read();
        r.rnd_res = v.rnd_res.read();
        r.exp_res_rnd = v.exp_res_rnd.read();
        r.mant_res_rnd = v.mant_res_rnd.read();
        r.underflow = v.underflow.read();
        r.overflow = v.overflow.read();
        r.ex = v.ex.read();
    }
}

}  // namespace debugger

