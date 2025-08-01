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

`timescale 1ns/10ps

module fadd_generic #(
    parameter int fbits = 32,                               // Input format: FP32 = 32, FP16 = 16, BF16 = 16
    parameter int expbits = 8,                              // Exponent bitwidth: FP64 = 11, FP32 = 8, FP16 = 5, BF16 = 8
    parameter int shiftbits = 6,                            // Mantissa scale factor bits: must be $clog2(2*(fbits-expbits)), avoid using $clog2
    parameter logic async_reset = 1'b0
)
(
    input logic i_clk,                                      // CPU clock
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_ena,
    input logic [fbits-1:0] i_a,                            // Operand 1
    input logic [fbits-1:0] i_b,                            // Operand 2
    output logic [fbits-1:0] o_res,                         // Result
    output logic o_ex,                                      // Exception, overflow or underflow
    output logic o_valid                                    // Result is valid
);

localparam int mantbits = ((fbits - expbits) - 1);          // Encoded mantissa bitwidth: FP64 = 52, FP32 = 23, FP16 = 10, BF16 = 7
localparam int mantmaxbits = (2 * (mantbits + 1));          // Mantissa maximum bitwidth before shifting
localparam int explevel = ((2**(expbits - 1)) - 1);         // Level 1 for exponent: 1023 (double); 127 (fp32)
localparam int latency = 10;                                // Cycles: 1 in latch + 2 scaler + 2 rnd + 1 out latch + 1?

typedef struct {
    logic [latency-1:0] ena;
    logic [fbits-1:0] a;
    logic [fbits-1:0] b;
    logic [fbits-1:0] result;
    logic [2:0] sub;                                        // 0=adder; 1=substruct
    logic [1:0] inv;                                        // 1=mant result should be inverted
    logic signA;
    logic signB;
    logic [(mantbits + 1)-1:0] mantA;
    logic [(mantbits + 1)-1:0] mantB;
    logic [(mantbits + 1)-1:0] mantA_swapped;
    logic [(mantbits + 1)-1:0] mantB_swapped;
    logic [(mantmaxbits - 1)-1:0] mantA_descaled;
    logic [(mantmaxbits - 1)-1:0] mantB_descaled;
    logic [expbits-1:0] expA;
    logic [expbits-1:0] expB;
    logic [(expbits + 2)-1:0] expAB;
    logic [(expbits + 2)-1:0] exp_dif;
    logic [(expbits + 2)-1:0] exp_max[0: 5 - 1];
    logic [mantmaxbits-1:0] mant_sum_mod;                   // Module after mantissas adding
    logic lzd_noscaling;
    logic lzd_noscaling_z;
    logic [4:0] sign_res;
    logic [(expbits + 2)-1:0] exp_res;
    logic [mantbits-1:0] mant_res;
    logic rnd_res;
    logic [expbits-1:0] exp_res_rnd;
    logic [mantbits-1:0] mant_res_rnd;
    logic underflow;
    logic overflow;
    logic ex;                                               // Exception: overflow or underflow
} fadd_generic_registers;

logic [shiftbits-1:0] wb_mant_aligned_idx;
logic [mantmaxbits-1:0] wb_mant_aligned;
fadd_generic_registers r;
fadd_generic_registers rin;


lzd_scaler #(
    .ibits(mantmaxbits),
    .shiftbits(shiftbits),
    .async_reset(async_reset)
) scaler0 (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_m(r.mant_sum_mod),
    .i_noscale(r.lzd_noscaling_z),
    .o_scaled(wb_mant_aligned),
    .o_scaled_factor(wb_mant_aligned_idx)
);

always_comb
begin: comb_proc
    fadd_generic_registers v;
    logic v_expa_nzero;
    logic v_expb_nzero;
    logic [(mantbits + 1)-1:0] vb_mant_res_rnd;
    logic [(expbits + 2)-1:0] vb_exp_res_rnd;
    logic v_underflow;
    logic v_overflow;
    logic [(mantbits + 1)-1:0] vb_mantA;
    logic [(mantbits + 1)-1:0] vb_mantB;
    logic [(mantmaxbits - 1)-1:0] vb_mantB_descaled;
    logic [(expbits + 2)-1:0] vb_expA_t;
    logic [(expbits + 2)-1:0] vb_expB_t;
    logic [(expbits + 2)-1:0] vb_expAB_t;
    logic [shiftbits-1:0] vb_mant_idx_normal;
    logic [(mantmaxbits + 1)-1:0] vb_mant_sum;
    logic v_mant_even;
    logic v_mant05;
    logic v_mant_rnd;

    v.ena = r.ena;
    v.a = r.a;
    v.b = r.b;
    v.result = r.result;
    v.sub = r.sub;
    v.inv = r.inv;
    v.signA = r.signA;
    v.signB = r.signB;
    v.mantA = r.mantA;
    v.mantB = r.mantB;
    v.mantA_swapped = r.mantA_swapped;
    v.mantB_swapped = r.mantB_swapped;
    v.mantA_descaled = r.mantA_descaled;
    v.mantB_descaled = r.mantB_descaled;
    v.expA = r.expA;
    v.expB = r.expB;
    v.expAB = r.expAB;
    v.exp_dif = r.exp_dif;
    for (int i = 0; i < 5; i++) begin
        v.exp_max[i] = r.exp_max[i];
    end
    v.mant_sum_mod = r.mant_sum_mod;
    v.lzd_noscaling = r.lzd_noscaling;
    v.lzd_noscaling_z = r.lzd_noscaling_z;
    v.sign_res = r.sign_res;
    v.exp_res = r.exp_res;
    v.mant_res = r.mant_res;
    v.rnd_res = r.rnd_res;
    v.exp_res_rnd = r.exp_res_rnd;
    v.mant_res_rnd = r.mant_res_rnd;
    v.underflow = r.underflow;
    v.overflow = r.overflow;
    v.ex = r.ex;
    v_expa_nzero = 1'b0;
    v_expb_nzero = 1'b0;
    vb_mant_res_rnd = '0;
    vb_exp_res_rnd = '0;
    v_underflow = 1'b0;
    v_overflow = 1'b0;
    vb_mantA = '0;
    vb_mantB = '0;
    vb_mantB_descaled = '0;
    vb_expA_t = '0;
    vb_expB_t = '0;
    vb_expAB_t = '0;
    vb_mant_idx_normal = '0;
    vb_mant_sum = '0;
    v_mant_even = 1'b0;
    v_mant05 = 1'b0;
    v_mant_rnd = 1'b0;

    v.ena = {r.ena[(latency - 2): 0], i_ena};

    v.a = i_a;
    v.b = i_b;

    v_expa_nzero = (|r.a[(fbits - 2): mantbits]);
    v_expb_nzero = (|r.b[(fbits - 2): mantbits]);
    vb_mantA = {v_expa_nzero, r.a[(mantbits - 1): 0]};
    vb_mantB = {v_expb_nzero, r.b[(mantbits - 1): 0]};

    v.sub = {r.sub[1: 0], (r.a[(fbits - 1)] ^ r.b[(fbits - 1)])};
    v.signA = r.a[(fbits - 1)];
    v.signB = r.b[(fbits - 1)];
    v.mantA = vb_mantA;
    v.mantB = vb_mantB;

    // expA - expB + EXPONENT_ZERO_LEVEL
    vb_expA_t = ({2'd0, r.a[(fbits - 2): mantbits]} - v_expa_nzero);
    vb_expB_t = ({2'd0, r.b[(fbits - 2): mantbits]} - v_expb_nzero);
    vb_expAB_t = (vb_expA_t - vb_expB_t);
    v.expA = (r.a[(fbits - 2): mantbits] - v_expa_nzero);
    v.expB = (r.b[(fbits - 2): mantbits] - v_expb_nzero);
    v.expAB = vb_expAB_t;

    // Swap value, so that exponent is always A >= B:
    if (r.expAB[(expbits + 1)] == 1'b0) begin
        v.mantA_swapped = r.mantA;
        v.mantB_swapped = r.mantB;
        v.exp_dif = r.expAB;
        v.exp_max[0] = r.expA;
        v.inv = {r.inv[0], r.signA};
    end else begin
        // Swap A <-> B
        v.mantA_swapped = r.mantB;
        v.mantB_swapped = r.mantA;
        v.exp_dif = ((~r.expAB) + 1);
        v.exp_max[0] = r.expB;
        v.inv = {r.inv[0], r.signB};
    end
    for (int i = 0; i < (5 - 1); i++) begin
        v.exp_max[(i + 1)] = r.exp_max[i];
    end

    v.mantA_descaled = {r.mantA_swapped, 23'd0};
    vb_mantB_descaled = {r.mantB_swapped, 23'd0};
    if (r.exp_dif >= mantbits) begin
        v.mantB_descaled = 47'd0;
    end else begin
        v.mantB_descaled = (vb_mantB_descaled >> int'(r.exp_dif));
    end

    // Do not scale mantissa if the pre-scaled exponent <= 0:
    v.lzd_noscaling = 1'b0;
    if ((r.exp_dif[(expbits + 1)] == 1'b1)
            || ((|r.exp_dif) == 1'b0)) begin
        v.lzd_noscaling = r.ena[2];
    end
    v.lzd_noscaling_z = r.lzd_noscaling;

    // Make mantissa always positive and latch was inversion or not
    //       - Goes to scaler input when ena[4] == 1
    //       - Output is ready on        ena[6] == 1
    if (r.sub[2] == 1'b1) begin
        vb_mant_sum = ({2'd0, r.mantA_descaled} - {2'd0, r.mantB_descaled});
    end else begin
        vb_mant_sum = ({2'd0, r.mantA_descaled} + {2'd0, r.mantB_descaled});
    end
    if (vb_mant_sum[mantmaxbits] == 1'b1) begin
        v.sign_res = {r.sign_res[4: 0], (1'b1 ^ r.inv[1])};
        v.mant_sum_mod = ((~vb_mant_sum[(mantmaxbits - 1): 0]) + 1);
    end else begin
        v.sign_res = {r.sign_res[4: 0], r.inv[1]};
        v.mant_sum_mod = vb_mant_sum[(mantmaxbits - 1): 0];
    end

    // mant_res_unsigned goes to 'scaler0' submodule input
    //   - latency for output is 2 clocks
    if (wb_mant_aligned[(mantmaxbits - 1)] == 1'b1) begin
        vb_mant_idx_normal = (wb_mant_aligned_idx - 6'd2);
        if ((|wb_mant_aligned_idx) == 1'b0) begin
            v.exp_res = (r.exp_max[4] + 2);
        end else if (wb_mant_aligned_idx == 6'd1) begin
            v.exp_res = (r.exp_max[4] + 1);
        end else begin
            v.exp_res = (r.exp_max[4] - vb_mant_idx_normal);
        end
    end else begin
        v.exp_res = 10'd0;
    end
    v.mant_res = wb_mant_aligned[(mantmaxbits - 2): (mantmaxbits - (mantbits + 1))];// exclude 1 older bit

    // Rounding bit:
    v_mant_even = (~wb_mant_aligned[(mantmaxbits - (mantbits + 1))]);
    v_mant_rnd = wb_mant_aligned[(mantmaxbits - (mantbits + 2))];
    v_mant05 = (v_mant_rnd & (~(|wb_mant_aligned[(mantmaxbits - (mantbits + 3)): 0])));
    v.rnd_res = (v_mant_rnd && (~(v_mant05 && v_mant_even)));

    vb_mant_res_rnd = ({1'b0, r.mant_res} + {'0, r.rnd_res});
    vb_exp_res_rnd = (r.exp_res + {'0, vb_mant_res_rnd[mantbits]});

    // Overflow: exponent is positive but out-of-range of 'expbits':
    v_overflow = ((~vb_exp_res_rnd[(expbits + 1)]) && vb_exp_res_rnd[expbits]);// FP32 (exp-8): 01.****.****
    v.overflow = v_overflow;

    // Undeflow: exponent is negative:
    v_underflow = vb_exp_res_rnd[(expbits + 1)];
    v.underflow = v_underflow;

    // No make sense to detect NaN and other things for GPU computation. No error handling
    if (v_overflow == 1'b1) begin
        v.exp_res_rnd = '1;
        v.mant_res_rnd = '1;
    end else if (v_underflow == 1'b1) begin
        v.exp_res_rnd = '0;
        v.mant_res_rnd = '0;
    end else begin
        v.exp_res_rnd = vb_exp_res_rnd[(expbits - 1): 0];
        v.mant_res_rnd = vb_mant_res_rnd[(mantbits - 1): 0];
    end
    v.ex = (r.ena[(latency - 2)] & (r.overflow | r.underflow));

    v.result = {r.sign_res[4], r.exp_res_rnd, r.mant_res_rnd};

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v.ena = '0;
        v.a = '0;
        v.b = '0;
        v.result = '0;
        v.sub = '0;
        v.inv = '0;
        v.signA = '0;
        v.signB = '0;
        v.mantA = '0;
        v.mantB = '0;
        v.mantA_swapped = '0;
        v.mantB_swapped = '0;
        v.mantA_descaled = '0;
        v.mantB_descaled = '0;
        v.expA = '0;
        v.expB = '0;
        v.expAB = '0;
        v.exp_dif = '0;
        for (int i = 0; i < 5; i++) begin
            v.exp_max[i] = '0;
        end
        v.mant_sum_mod = '0;
        v.lzd_noscaling = 1'b0;
        v.lzd_noscaling_z = 1'b0;
        v.sign_res = '0;
        v.exp_res = '0;
        v.mant_res = '0;
        v.rnd_res = 1'b0;
        v.exp_res_rnd = '0;
        v.mant_res_rnd = '0;
        v.underflow = 1'b0;
        v.overflow = 1'b0;
        v.ex = 1'b0;
    end

    o_res = r.result;
    o_ex = r.ex;
    o_valid = r.ena[(latency - 1)];

    rin.ena = v.ena;
    rin.a = v.a;
    rin.b = v.b;
    rin.result = v.result;
    rin.sub = v.sub;
    rin.inv = v.inv;
    rin.signA = v.signA;
    rin.signB = v.signB;
    rin.mantA = v.mantA;
    rin.mantB = v.mantB;
    rin.mantA_swapped = v.mantA_swapped;
    rin.mantB_swapped = v.mantB_swapped;
    rin.mantA_descaled = v.mantA_descaled;
    rin.mantB_descaled = v.mantB_descaled;
    rin.expA = v.expA;
    rin.expB = v.expB;
    rin.expAB = v.expAB;
    rin.exp_dif = v.exp_dif;
    for (int i = 0; i < 5; i++) begin
        rin.exp_max[i] = v.exp_max[i];
    end
    rin.mant_sum_mod = v.mant_sum_mod;
    rin.lzd_noscaling = v.lzd_noscaling;
    rin.lzd_noscaling_z = v.lzd_noscaling_z;
    rin.sign_res = v.sign_res;
    rin.exp_res = v.exp_res;
    rin.mant_res = v.mant_res;
    rin.rnd_res = v.rnd_res;
    rin.exp_res_rnd = v.exp_res_rnd;
    rin.mant_res_rnd = v.mant_res_rnd;
    rin.underflow = v.underflow;
    rin.overflow = v.overflow;
    rin.ex = v.ex;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r.ena <= '0;
                r.a <= '0;
                r.b <= '0;
                r.result <= '0;
                r.sub <= '0;
                r.inv <= '0;
                r.signA <= '0;
                r.signB <= '0;
                r.mantA <= '0;
                r.mantB <= '0;
                r.mantA_swapped <= '0;
                r.mantB_swapped <= '0;
                r.mantA_descaled <= '0;
                r.mantB_descaled <= '0;
                r.expA <= '0;
                r.expB <= '0;
                r.expAB <= '0;
                r.exp_dif <= '0;
                for (int i = 0; i < 5; i++) begin
                    r.exp_max[i] <= '0;
                end
                r.mant_sum_mod <= '0;
                r.lzd_noscaling <= 1'b0;
                r.lzd_noscaling_z <= 1'b0;
                r.sign_res <= '0;
                r.exp_res <= '0;
                r.mant_res <= '0;
                r.rnd_res <= 1'b0;
                r.exp_res_rnd <= '0;
                r.mant_res_rnd <= '0;
                r.underflow <= 1'b0;
                r.overflow <= 1'b0;
                r.ex <= 1'b0;
            end else begin
                r.ena <= rin.ena;
                r.a <= rin.a;
                r.b <= rin.b;
                r.result <= rin.result;
                r.sub <= rin.sub;
                r.inv <= rin.inv;
                r.signA <= rin.signA;
                r.signB <= rin.signB;
                r.mantA <= rin.mantA;
                r.mantB <= rin.mantB;
                r.mantA_swapped <= rin.mantA_swapped;
                r.mantB_swapped <= rin.mantB_swapped;
                r.mantA_descaled <= rin.mantA_descaled;
                r.mantB_descaled <= rin.mantB_descaled;
                r.expA <= rin.expA;
                r.expB <= rin.expB;
                r.expAB <= rin.expAB;
                r.exp_dif <= rin.exp_dif;
                for (int i = 0; i < 5; i++) begin
                    r.exp_max[i] <= rin.exp_max[i];
                end
                r.mant_sum_mod <= rin.mant_sum_mod;
                r.lzd_noscaling <= rin.lzd_noscaling;
                r.lzd_noscaling_z <= rin.lzd_noscaling_z;
                r.sign_res <= rin.sign_res;
                r.exp_res <= rin.exp_res;
                r.mant_res <= rin.mant_res;
                r.rnd_res <= rin.rnd_res;
                r.exp_res_rnd <= rin.exp_res_rnd;
                r.mant_res_rnd <= rin.mant_res_rnd;
                r.underflow <= rin.underflow;
                r.overflow <= rin.overflow;
                r.ex <= rin.ex;
            end
        end

    end: async_r_en
    else begin: async_r_dis

        always_ff @(posedge i_clk) begin
            r.ena <= rin.ena;
            r.a <= rin.a;
            r.b <= rin.b;
            r.result <= rin.result;
            r.sub <= rin.sub;
            r.inv <= rin.inv;
            r.signA <= rin.signA;
            r.signB <= rin.signB;
            r.mantA <= rin.mantA;
            r.mantB <= rin.mantB;
            r.mantA_swapped <= rin.mantA_swapped;
            r.mantB_swapped <= rin.mantB_swapped;
            r.mantA_descaled <= rin.mantA_descaled;
            r.mantB_descaled <= rin.mantB_descaled;
            r.expA <= rin.expA;
            r.expB <= rin.expB;
            r.expAB <= rin.expAB;
            r.exp_dif <= rin.exp_dif;
            for (int i = 0; i < 5; i++) begin
                r.exp_max[i] <= rin.exp_max[i];
            end
            r.mant_sum_mod <= rin.mant_sum_mod;
            r.lzd_noscaling <= rin.lzd_noscaling;
            r.lzd_noscaling_z <= rin.lzd_noscaling_z;
            r.sign_res <= rin.sign_res;
            r.exp_res <= rin.exp_res;
            r.mant_res <= rin.mant_res;
            r.rnd_res <= rin.rnd_res;
            r.exp_res_rnd <= rin.exp_res_rnd;
            r.mant_res_rnd <= rin.mant_res_rnd;
            r.underflow <= rin.underflow;
            r.overflow <= rin.overflow;
            r.ex <= rin.ex;
        end

    end: async_r_dis
endgenerate

endmodule: fadd_generic
