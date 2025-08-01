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
#include "lzd_scaler.h"
#include "api_core.h"

namespace debugger {

template<int fbits = 32,                                    // Input format: FP32 = 32, FP16 = 16, BF16 = 16
         int expbits = 8,                                   // Exponent bitwidth: FP64 = 11, FP32 = 8, FP16 = 5, BF16 = 8
         int shiftbits = 6>                                 // Mantissa scale factor bits: must be $clog2(2*(fbits-expbits)), avoid using $clog2
SC_MODULE(fadd_generic) {
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

    fadd_generic(sc_module_name name,
                 bool async_reset);
    virtual ~fadd_generic();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    static const int mantbits = ((fbits - expbits) - 1);    // Encoded mantissa bitwidth: FP64 = 52, FP32 = 23, FP16 = 10, BF16 = 7
    static const int mantmaxbits = (2 * (mantbits + 1));    // Mantissa maximum bitwidth before shifting
    static const int explevel = ((1 << (expbits - 1)) - 1); // Level 1 for exponent: 1023 (double); 127 (fp32)
    static const int latency = 10;                          // Cycles: 1 in latch + 2 scaler + 2 rnd + 1 out latch + 1?

    struct fadd_generic_registers {
        sc_signal<sc_uint<latency>> ena;
        sc_signal<sc_uint<fbits>> a;
        sc_signal<sc_uint<fbits>> b;
        sc_signal<sc_uint<fbits>> result;
        sc_signal<sc_uint<3>> sub;                          // 0=adder; 1=substruct
        sc_signal<sc_uint<2>> inv;                          // 1=mant result should be inverted
        sc_signal<bool> signA;
        sc_signal<bool> signB;
        sc_signal<sc_uint<(mantbits + 1)>> mantA;
        sc_signal<sc_uint<(mantbits + 1)>> mantB;
        sc_signal<sc_uint<(mantbits + 1)>> mantA_swapped;
        sc_signal<sc_uint<(mantbits + 1)>> mantB_swapped;
        sc_signal<sc_uint<(mantmaxbits - 1)>> mantA_descaled;
        sc_signal<sc_uint<(mantmaxbits - 1)>> mantB_descaled;
        sc_signal<sc_uint<expbits>> expA;
        sc_signal<sc_uint<expbits>> expB;
        sc_signal<sc_uint<(expbits + 2)>> expAB;
        sc_signal<sc_uint<(expbits + 2)>> exp_dif;
        sc_signal<sc_uint<(expbits + 2)>> exp_max[5];
        sc_signal<sc_uint<mantmaxbits>> mant_sum_mod;       // Module after mantissas adding
        sc_signal<bool> lzd_noscaling;
        sc_signal<bool> lzd_noscaling_z;
        sc_signal<sc_uint<5>> sign_res;
        sc_signal<sc_uint<(expbits + 2)>> exp_res;
        sc_signal<sc_uint<mantbits>> mant_res;
        sc_signal<bool> rnd_res;
        sc_signal<sc_uint<expbits>> exp_res_rnd;
        sc_signal<sc_uint<mantbits>> mant_res_rnd;
        sc_signal<bool> underflow;
        sc_signal<bool> overflow;
        sc_signal<bool> ex;                                 // Exception: overflow or underflow
    };

    void fadd_generic_r_reset(fadd_generic_registers& iv) {
        iv.ena = 0;
        iv.a = 0;
        iv.b = 0;
        iv.result = 0;
        iv.sub = 0;
        iv.inv = 0;
        iv.signA = 0;
        iv.signB = 0;
        iv.mantA = 0;
        iv.mantB = 0;
        iv.mantA_swapped = 0;
        iv.mantB_swapped = 0;
        iv.mantA_descaled = 0;
        iv.mantB_descaled = 0;
        iv.expA = 0;
        iv.expB = 0;
        iv.expAB = 0;
        iv.exp_dif = 0;
        for (int i = 0; i < 5; i++) {
            iv.exp_max[i] = 0;
        }
        iv.mant_sum_mod = 0;
        iv.lzd_noscaling = 0;
        iv.lzd_noscaling_z = 0;
        iv.sign_res = 0;
        iv.exp_res = 0;
        iv.mant_res = 0;
        iv.rnd_res = 0;
        iv.exp_res_rnd = 0;
        iv.mant_res_rnd = 0;
        iv.underflow = 0;
        iv.overflow = 0;
        iv.ex = 0;
    }

    sc_signal<sc_uint<shiftbits>> wb_mant_aligned_idx;
    sc_signal<sc_uint<mantmaxbits>> wb_mant_aligned;
    fadd_generic_registers v;
    fadd_generic_registers r;

    lzd_scaler<mantmaxbits, shiftbits> *scaler0;

};

template<int fbits, int expbits, int shiftbits>
fadd_generic<fbits, expbits, shiftbits>::fadd_generic(sc_module_name name,
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
    scaler0 = 0;


    scaler0 = new lzd_scaler<mantmaxbits,
                             shiftbits>("scaler0",
                                        async_reset);
    scaler0->i_clk(i_clk);
    scaler0->i_nrst(i_nrst);
    scaler0->i_m(r.mant_sum_mod);
    scaler0->i_noscale(r.lzd_noscaling_z);
    scaler0->o_scaled(wb_mant_aligned);
    scaler0->o_scaled_factor(wb_mant_aligned_idx);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_ena;
    sensitive << i_a;
    sensitive << i_b;
    sensitive << wb_mant_aligned_idx;
    sensitive << wb_mant_aligned;
    sensitive << r.ena;
    sensitive << r.a;
    sensitive << r.b;
    sensitive << r.result;
    sensitive << r.sub;
    sensitive << r.inv;
    sensitive << r.signA;
    sensitive << r.signB;
    sensitive << r.mantA;
    sensitive << r.mantB;
    sensitive << r.mantA_swapped;
    sensitive << r.mantB_swapped;
    sensitive << r.mantA_descaled;
    sensitive << r.mantB_descaled;
    sensitive << r.expA;
    sensitive << r.expB;
    sensitive << r.expAB;
    sensitive << r.exp_dif;
    for (int i = 0; i < 5; i++) {
        sensitive << r.exp_max[i];
    }
    sensitive << r.mant_sum_mod;
    sensitive << r.lzd_noscaling;
    sensitive << r.lzd_noscaling_z;
    sensitive << r.sign_res;
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
fadd_generic<fbits, expbits, shiftbits>::~fadd_generic() {
    if (scaler0) {
        delete scaler0;
    }
}

template<int fbits, int expbits, int shiftbits>
void fadd_generic<fbits, expbits, shiftbits>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
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
        sc_trace(o_vcd, r.sub, pn + ".r.sub");
        sc_trace(o_vcd, r.inv, pn + ".r.inv");
        sc_trace(o_vcd, r.signA, pn + ".r.signA");
        sc_trace(o_vcd, r.signB, pn + ".r.signB");
        sc_trace(o_vcd, r.mantA, pn + ".r.mantA");
        sc_trace(o_vcd, r.mantB, pn + ".r.mantB");
        sc_trace(o_vcd, r.mantA_swapped, pn + ".r.mantA_swapped");
        sc_trace(o_vcd, r.mantB_swapped, pn + ".r.mantB_swapped");
        sc_trace(o_vcd, r.mantA_descaled, pn + ".r.mantA_descaled");
        sc_trace(o_vcd, r.mantB_descaled, pn + ".r.mantB_descaled");
        sc_trace(o_vcd, r.expA, pn + ".r.expA");
        sc_trace(o_vcd, r.expB, pn + ".r.expB");
        sc_trace(o_vcd, r.expAB, pn + ".r.expAB");
        sc_trace(o_vcd, r.exp_dif, pn + ".r.exp_dif");
        for (int i = 0; i < 5; i++) {
            sc_trace(o_vcd, r.exp_max[i], pn + ".r.exp_max(" + std::to_string(i) + ")");
        }
        sc_trace(o_vcd, r.mant_sum_mod, pn + ".r.mant_sum_mod");
        sc_trace(o_vcd, r.lzd_noscaling, pn + ".r.lzd_noscaling");
        sc_trace(o_vcd, r.lzd_noscaling_z, pn + ".r.lzd_noscaling_z");
        sc_trace(o_vcd, r.sign_res, pn + ".r.sign_res");
        sc_trace(o_vcd, r.exp_res, pn + ".r.exp_res");
        sc_trace(o_vcd, r.mant_res, pn + ".r.mant_res");
        sc_trace(o_vcd, r.rnd_res, pn + ".r.rnd_res");
        sc_trace(o_vcd, r.exp_res_rnd, pn + ".r.exp_res_rnd");
        sc_trace(o_vcd, r.mant_res_rnd, pn + ".r.mant_res_rnd");
        sc_trace(o_vcd, r.underflow, pn + ".r.underflow");
        sc_trace(o_vcd, r.overflow, pn + ".r.overflow");
        sc_trace(o_vcd, r.ex, pn + ".r.ex");
    }

    if (scaler0) {
        scaler0->generateVCD(i_vcd, o_vcd);
    }
}

template<int fbits, int expbits, int shiftbits>
void fadd_generic<fbits, expbits, shiftbits>::comb() {
    bool v_expa_nzero;
    bool v_expb_nzero;
    sc_uint<(mantbits + 1)> vb_mant_res_rnd;
    sc_uint<(expbits + 2)> vb_exp_res_rnd;
    bool v_underflow;
    bool v_overflow;
    sc_uint<(mantbits + 1)> vb_mantA;
    sc_uint<(mantbits + 1)> vb_mantB;
    sc_uint<(mantmaxbits - 1)> vb_mantB_descaled;
    sc_uint<(expbits + 2)> vb_expA_t;
    sc_uint<(expbits + 2)> vb_expB_t;
    sc_uint<(expbits + 2)> vb_expAB_t;
    sc_uint<shiftbits> vb_mant_idx_normal;
    sc_uint<(mantmaxbits + 1)> vb_mant_sum;
    bool v_mant_even;
    bool v_mant05;
    sc_uint<1> v_mant_rnd;

    v.ena = r.ena.read();
    v.a = r.a.read();
    v.b = r.b.read();
    v.result = r.result.read();
    v.sub = r.sub.read();
    v.inv = r.inv.read();
    v.signA = r.signA.read();
    v.signB = r.signB.read();
    v.mantA = r.mantA.read();
    v.mantB = r.mantB.read();
    v.mantA_swapped = r.mantA_swapped.read();
    v.mantB_swapped = r.mantB_swapped.read();
    v.mantA_descaled = r.mantA_descaled.read();
    v.mantB_descaled = r.mantB_descaled.read();
    v.expA = r.expA.read();
    v.expB = r.expB.read();
    v.expAB = r.expAB.read();
    v.exp_dif = r.exp_dif.read();
    for (int i = 0; i < 5; i++) {
        v.exp_max[i] = r.exp_max[i].read();
    }
    v.mant_sum_mod = r.mant_sum_mod.read();
    v.lzd_noscaling = r.lzd_noscaling.read();
    v.lzd_noscaling_z = r.lzd_noscaling_z.read();
    v.sign_res = r.sign_res.read();
    v.exp_res = r.exp_res.read();
    v.mant_res = r.mant_res.read();
    v.rnd_res = r.rnd_res.read();
    v.exp_res_rnd = r.exp_res_rnd.read();
    v.mant_res_rnd = r.mant_res_rnd.read();
    v.underflow = r.underflow.read();
    v.overflow = r.overflow.read();
    v.ex = r.ex.read();
    v_expa_nzero = 0;
    v_expb_nzero = 0;
    vb_mant_res_rnd = 0;
    vb_exp_res_rnd = 0;
    v_underflow = 0;
    v_overflow = 0;
    vb_mantA = 0;
    vb_mantB = 0;
    vb_mantB_descaled = 0;
    vb_expA_t = 0;
    vb_expB_t = 0;
    vb_expAB_t = 0;
    vb_mant_idx_normal = 0;
    vb_mant_sum = 0;
    v_mant_even = 0;
    v_mant05 = 0;
    v_mant_rnd = 0;

    v.ena = (r.ena.read()((latency - 2), 0), i_ena.read());

    v.a = i_a.read();
    v.b = i_b.read();

    v_expa_nzero = r.a.read()((fbits - 2), mantbits).or_reduce();
    v_expb_nzero = r.b.read()((fbits - 2), mantbits).or_reduce();
    vb_mantA = (v_expa_nzero, r.a.read()((mantbits - 1), 0));
    vb_mantB = (v_expb_nzero, r.b.read()((mantbits - 1), 0));

    v.sub = (r.sub.read()(1, 0), (r.a.read()[(fbits - 1)] ^ r.b.read()[(fbits - 1)]));
    v.signA = r.a.read()[(fbits - 1)];
    v.signB = r.b.read()[(fbits - 1)];
    v.mantA = vb_mantA;
    v.mantB = vb_mantB;

    // expA - expB + EXPONENT_ZERO_LEVEL
    vb_expA_t = ((0, r.a.read()((fbits - 2), mantbits)) - v_expa_nzero);
    vb_expB_t = ((0, r.b.read()((fbits - 2), mantbits)) - v_expb_nzero);
    vb_expAB_t = (vb_expA_t - vb_expB_t);
    v.expA = (r.a.read()((fbits - 2), mantbits) - v_expa_nzero);
    v.expB = (r.b.read()((fbits - 2), mantbits) - v_expb_nzero);
    v.expAB = vb_expAB_t;

    // Swap value, so that exponent is always A >= B:
    if (r.expAB.read()[(expbits + 1)] == 0) {
        v.mantA_swapped = r.mantA.read();
        v.mantB_swapped = r.mantB.read();
        v.exp_dif = r.expAB.read();
        v.exp_max[0] = r.expA.read();
        v.inv = (r.inv.read()[0], r.signA.read());
    } else {
        // Swap A <-> B
        v.mantA_swapped = r.mantB.read();
        v.mantB_swapped = r.mantA.read();
        v.exp_dif = ((~r.expAB.read()) + 1);
        v.exp_max[0] = r.expB.read();
        v.inv = (r.inv.read()[0], r.signB.read());
    }
    for (int i = 0; i < (5 - 1); i++) {
        v.exp_max[(i + 1)] = r.exp_max[i].read();
    }

    v.mantA_descaled = (r.mantA_swapped.read() << ((fbits - expbits) - 1));
    vb_mantB_descaled = (r.mantB_swapped.read() << ((fbits - expbits) - 1));
    if (r.exp_dif.read() >= mantbits) {
        v.mantB_descaled = 0;
    } else {
        v.mantB_descaled = (vb_mantB_descaled >> r.exp_dif.read().to_int());
    }

    // Do not scale mantissa if the pre-scaled exponent <= 0:
    v.lzd_noscaling = 0;
    if ((r.exp_dif.read()[(expbits + 1)] != 0)
            || (r.exp_dif.read().or_reduce() == 0)) {
        v.lzd_noscaling = r.ena.read()[2];
    }
    v.lzd_noscaling_z = r.lzd_noscaling.read();

    // Make mantissa always positive and latch was inversion or not
    //       - Goes to scaler input when ena[4] == 1
    //       - Output is ready on        ena[6] == 1
    if (r.sub.read()[2] != 0) {
        vb_mant_sum = ((0, r.mantA_descaled.read()) - (0, r.mantB_descaled.read()));
    } else {
        vb_mant_sum = ((0, r.mantA_descaled.read()) + (0, r.mantB_descaled.read()));
    }
    if (vb_mant_sum[mantmaxbits] != 0) {
        v.sign_res = (r.sign_res.read()(4, 0), (1 ^ r.inv.read()[1]));
        v.mant_sum_mod = ((~vb_mant_sum((mantmaxbits - 1), 0)) + 1);
    } else {
        v.sign_res = (r.sign_res.read()(4, 0), r.inv.read()[1]);
        v.mant_sum_mod = vb_mant_sum((mantmaxbits - 1), 0);
    }

    // mant_res_unsigned goes to 'scaler0' submodule input
    //   - latency for output is 2 clocks
    if (wb_mant_aligned.read()[(mantmaxbits - 1)] != 0) {
        vb_mant_idx_normal = (wb_mant_aligned_idx.read() - 2);
        if (wb_mant_aligned_idx.read().or_reduce() == 0) {
            v.exp_res = (r.exp_max[4].read() + 2);
        } else if (wb_mant_aligned_idx.read() == 1) {
            v.exp_res = (r.exp_max[4].read() + 1);
        } else {
            v.exp_res = (r.exp_max[4].read() - vb_mant_idx_normal);
        }
    } else {
        v.exp_res = 0;
    }
    v.mant_res = wb_mant_aligned.read()((mantmaxbits - 2), (mantmaxbits - (mantbits + 1)));// exclude 1 older bit

    // Rounding bit:
    v_mant_even = (!wb_mant_aligned.read()[(mantmaxbits - (mantbits + 1))]);
    v_mant_rnd = wb_mant_aligned.read()[(mantmaxbits - (mantbits + 2))];
    v_mant05 = (v_mant_rnd & (!wb_mant_aligned.read()((mantmaxbits - (mantbits + 3)), 0).or_reduce()));
    v.rnd_res = (v_mant_rnd && (!(v_mant05 && v_mant_even)));

    vb_mant_res_rnd = ((0, r.mant_res.read()) + (0, r.rnd_res.read()));
    vb_exp_res_rnd = (r.exp_res.read() + (0, vb_mant_res_rnd[mantbits]));

    // Overflow: exponent is positive but out-of-range of 'expbits':
    v_overflow = ((!vb_exp_res_rnd[(expbits + 1)]) && vb_exp_res_rnd[expbits]);// FP32 (exp-8): 01.****.****
    v.overflow = v_overflow;

    // Undeflow: exponent is negative:
    v_underflow = vb_exp_res_rnd[(expbits + 1)];
    v.underflow = v_underflow;

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

    v.result = (r.sign_res.read()[4], r.exp_res_rnd.read(), r.mant_res_rnd.read());

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        fadd_generic_r_reset(v);
    }

    o_res = r.result.read();
    o_ex = r.ex.read();
    o_valid = r.ena.read()[(latency - 1)];
}

template<int fbits, int expbits, int shiftbits>
void fadd_generic<fbits, expbits, shiftbits>::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        fadd_generic_r_reset(r);
    } else {
        r.ena = v.ena.read();
        r.a = v.a.read();
        r.b = v.b.read();
        r.result = v.result.read();
        r.sub = v.sub.read();
        r.inv = v.inv.read();
        r.signA = v.signA.read();
        r.signB = v.signB.read();
        r.mantA = v.mantA.read();
        r.mantB = v.mantB.read();
        r.mantA_swapped = v.mantA_swapped.read();
        r.mantB_swapped = v.mantB_swapped.read();
        r.mantA_descaled = v.mantA_descaled.read();
        r.mantB_descaled = v.mantB_descaled.read();
        r.expA = v.expA.read();
        r.expB = v.expB.read();
        r.expAB = v.expAB.read();
        r.exp_dif = v.exp_dif.read();
        for (int i = 0; i < 5; i++) {
            r.exp_max[i] = v.exp_max[i].read();
        }
        r.mant_sum_mod = v.mant_sum_mod.read();
        r.lzd_noscaling = v.lzd_noscaling.read();
        r.lzd_noscaling_z = v.lzd_noscaling_z.read();
        r.sign_res = v.sign_res.read();
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

