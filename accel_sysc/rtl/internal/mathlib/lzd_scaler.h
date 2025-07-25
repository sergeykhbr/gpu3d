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

template<int ibits = 22,                                    // Input/output bitwise
         int shiftbits = 4>                                 // Operand shift value: must be $clog2(ibits)
SC_MODULE(lzd_scaler) {
 public:
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<sc_uint<ibits>> i_m;                              // input operand
    sc_in<bool> i_noscale;                                  // pass unscaled value directly to output
    sc_out<sc_uint<ibits>> o_scaled;                        // Scaled operand. 2 Cyles delay
    sc_out<sc_uint<shiftbits>> o_scaled_factor;             // Scaling factor. 2 Cyles delay

    void comb();
    void registers();

    lzd_scaler(sc_module_name name,
               bool async_reset);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    static const int lzd_chunks = ((ibits + 7) / 8);        // Leading Zero Detector chunks, each 8 bits
    static const int lzd_bits = (8 * lzd_chunks);           // 8 bits aligned bitwise

    struct lzd_scaler_registers {
        sc_signal<sc_uint<shiftbits>> lzd_factor[lzd_chunks];
        sc_signal<sc_uint<lzd_bits>> lzd_m[lzd_chunks];
        sc_signal<bool> lzd_noscale;
        sc_signal<sc_uint<shiftbits>> scaled_factor;
        sc_signal<sc_uint<ibits>> scaled;
    };

    void lzd_scaler_r_reset(lzd_scaler_registers& iv) {
        for (int i = 0; i < lzd_chunks; i++) {
            iv.lzd_factor[i] = 0;
        }
        for (int i = 0; i < lzd_chunks; i++) {
            iv.lzd_m[i] = 0;
        }
        iv.lzd_noscale = 0;
        iv.scaled_factor = 0;
        iv.scaled = 0;
    }

    lzd_scaler_registers v;
    lzd_scaler_registers r;

};

template<int ibits, int shiftbits>
lzd_scaler<ibits, shiftbits>::lzd_scaler(sc_module_name name,
                                         bool async_reset)
    : sc_module(name),
    i_clk("i_clk"),
    i_nrst("i_nrst"),
    i_m("i_m"),
    i_noscale("i_noscale"),
    o_scaled("o_scaled"),
    o_scaled_factor("o_scaled_factor") {

    async_reset_ = async_reset;

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_m;
    sensitive << i_noscale;
    for (int i = 0; i < lzd_chunks; i++) {
        sensitive << r.lzd_factor[i];
    }
    for (int i = 0; i < lzd_chunks; i++) {
        sensitive << r.lzd_m[i];
    }
    sensitive << r.lzd_noscale;
    sensitive << r.scaled_factor;
    sensitive << r.scaled;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

template<int ibits, int shiftbits>
void lzd_scaler<ibits, shiftbits>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_m, i_m.name());
        sc_trace(o_vcd, i_noscale, i_noscale.name());
        sc_trace(o_vcd, o_scaled, o_scaled.name());
        sc_trace(o_vcd, o_scaled_factor, o_scaled_factor.name());
        for (int i = 0; i < lzd_chunks; i++) {
            sc_trace(o_vcd, r.lzd_factor[i], pn + ".r.lzd_factor(" + std::to_string(i) + ")");
        }
        for (int i = 0; i < lzd_chunks; i++) {
            sc_trace(o_vcd, r.lzd_m[i], pn + ".r.lzd_m(" + std::to_string(i) + ")");
        }
        sc_trace(o_vcd, r.lzd_noscale, pn + ".r.lzd_noscale");
        sc_trace(o_vcd, r.scaled_factor, pn + ".r.scaled_factor");
        sc_trace(o_vcd, r.scaled, pn + ".r.scaled");
    }

}

template<int ibits, int shiftbits>
void lzd_scaler<ibits, shiftbits>::comb() {
    sc_uint<(8 * lzd_chunks)> vb_lzd;
    sc_uint<lzd_chunks> vb_lzd_noscaling;

    for (int i = 0; i < lzd_chunks; i++) {
        v.lzd_factor[i] = r.lzd_factor[i].read();
    }
    for (int i = 0; i < lzd_chunks; i++) {
        v.lzd_m[i] = r.lzd_m[i].read();
    }
    v.lzd_noscale = r.lzd_noscale.read();
    v.scaled_factor = r.scaled_factor.read();
    v.scaled = r.scaled.read();
    vb_lzd = 0;
    vb_lzd_noscaling = ~0ull;

    v.lzd_noscale = i_noscale.read();

    // Detect Leading bit of Mantissa MSB.
    // Two stages:
    //       - Use chunks 8-bits each and save shifted mantissa for each chunk
    //       - Select the first non-zero shift
    //       - Ignore bits that out-of-range of exponent
    vb_lzd((lzd_bits - 1), (lzd_bits - ibits)) = i_m.read();
    for (int i = 0; i < lzd_chunks; i++) {
        if ((vb_lzd[((8 * i) + 7)] != 0)
                || (i_noscale.read() == 1)) {
            // No shift:
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 8)));
            if (i != (lzd_chunks - 1)) {
                v.lzd_m[i] = (vb_lzd << (8 * ((lzd_chunks - 1) - i)));
            } else {
                v.lzd_m[i] = vb_lzd;
            }
        } else if (vb_lzd[((8 * i) + 6)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 7)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 1));
        } else if (vb_lzd[((8 * i) + 5)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 6)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 2));
        } else if (vb_lzd[((8 * i) + 4)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 5)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 3));
        } else if (vb_lzd[((8 * i) + 3)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 4)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 4));
        } else if (vb_lzd[((8 * i) + 2)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 3)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 5));
        } else if (vb_lzd[((8 * i) + 1)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 2)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 6));
        } else if (vb_lzd[((8 * i) + 0)] != 0) {
            v.lzd_factor[i] = static_cast<sc_uint<shiftbits>>((ibits - ((8 * i) + 1)));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 7));
        } else {
            v.lzd_factor[i] = 0;
            v.lzd_m[i] = 0;
        }
    }

    v.scaled_factor = 0;
    v.scaled = 0;
    if (r.lzd_noscale.read() == 1) {
        v.scaled_factor = 0;
        v.scaled = r.lzd_m[(lzd_chunks - 1)].read()((lzd_bits - 1), (lzd_bits - ibits));
    } else {
        for (int i = 0; i < lzd_chunks; i++) {
            if (r.lzd_m[i].read()[(lzd_bits - 1)] != 0) {
                v.scaled_factor = r.lzd_factor[i].read();
                v.scaled = r.lzd_m[i].read()((lzd_bits - 1), (lzd_bits - ibits));
            }
        }
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        lzd_scaler_r_reset(v);
    }

    o_scaled = r.scaled.read();
    o_scaled_factor = r.scaled_factor.read();
}

template<int ibits, int shiftbits>
void lzd_scaler<ibits, shiftbits>::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        lzd_scaler_r_reset(r);
    } else {
        for (int i = 0; i < lzd_chunks; i++) {
            r.lzd_factor[i] = v.lzd_factor[i].read();
        }
        for (int i = 0; i < lzd_chunks; i++) {
            r.lzd_m[i] = v.lzd_m[i].read();
        }
        r.lzd_noscale = v.lzd_noscale.read();
        r.scaled_factor = v.scaled_factor.read();
        r.scaled = v.scaled.read();
    }
}

}  // namespace debugger

