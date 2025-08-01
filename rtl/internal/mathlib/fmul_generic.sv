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

module fmul_generic #(
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
localparam int hex_chunks = ((mantbits + 3) / 4);           // Number of hex multipliers
localparam int latency = (hex_chunks + 7);                  // Cycles: 1 in latch + hex_chunks + 2 scaler + 2 rnd + 1 out latch + 1?

typedef struct {
    logic [latency-1:0] ena;
    logic [fbits-1:0] a;
    logic [fbits-1:0] b;
    logic [fbits-1:0] result;
    logic [(latency - 2)-1:0] sign;
    logic [(mantbits + 1)-1:0] mantA[0: hex_chunks - 1];
    logic [(mantbits + 1)-1:0] mantB[0: hex_chunks - 1];
    logic [(expbits + 2)-1:0] expAB[0: (hex_chunks + 3) - 1];
    logic lzd_noscaling;
    logic [(expbits + 2)-1:0] exp_res;
    logic [(mantbits + 1)-1:0] mant_res;
    logic rnd_res;
    logic [expbits-1:0] exp_res_rnd;
    logic [mantbits-1:0] mant_res_rnd;
    logic underflow;
    logic overflow;
    logic ex;                                               // Exception: overflow or underflow
} fmul_generic_registers;

logic [3:0] wb_hex_i[0: hex_chunks - 1];
logic [(mantbits + 1)-1:0] wb_carry_i[0: hex_chunks - 1];
logic [(mantbits + 1)-1:0] wb_zres_i[0: hex_chunks - 1];
logic [(mantbits + 1)-1:0] wb_mant_lsb[0: hex_chunks - 1];
logic [(mantbits + 1)-1:0] wb_mant_msb[0: hex_chunks - 1];
logic [mantmaxbits-1:0] wb_mant_full;
logic [shiftbits-1:0] wb_mant_aligned_idx;
logic [mantmaxbits-1:0] wb_mant_aligned;
fmul_generic_registers r;
fmul_generic_registers rin;


generate
    for (genvar i = 0; i < hex_chunks; i++) begin: istage_x
        fmul_istage #(
            .ibits((mantbits + 1)),
            .mbits(4),
            .async_reset(async_reset),
            .idx(i)
        ) stagex (
            .i_clk(i_clk),
            .i_nrst(i_nrst),
            .i_a(r.mantA[i]),
            .i_m(wb_hex_i[i]),
            .i_carry(wb_carry_i[i]),
            .i_zres(wb_zres_i[i]),
            .o_result(wb_mant_lsb[i]),
            .o_carry(wb_mant_msb[i])
        );
    end: istage_x
endgenerate

lzd_scaler #(
    .ibits(mantmaxbits),
    .shiftbits(shiftbits),
    .async_reset(async_reset)
) scaler0 (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_m(wb_mant_full),
    .i_noscale(r.lzd_noscaling),
    .o_scaled(wb_mant_aligned),
    .o_scaled_factor(wb_mant_aligned_idx)
);

always_comb
begin: comb_proc
    fmul_generic_registers v;
    logic [(mantbits + 2)-1:0] vb_mant_res_rnd;
    logic [(expbits + 2)-1:0] vb_exp_res_rnd;
    logic v_underflow;
    logic v_overflow;
    logic [(mantbits + 1)-1:0] vb_mantA;
    logic [(mantbits + 1)-1:0] vb_mantB;
    logic [(expbits + 2)-1:0] vb_expA_t;
    logic [(expbits + 2)-1:0] vb_expB_t;
    logic [(expbits + 2)-1:0] vb_expAB_t;
    logic v_mant_even;
    logic v_mant05;
    logic v_mant_rnd;

    v.ena = r.ena;
    v.a = r.a;
    v.b = r.b;
    v.result = r.result;
    v.sign = r.sign;
    for (int i = 0; i < hex_chunks; i++) begin
        v.mantA[i] = r.mantA[i];
    end
    for (int i = 0; i < hex_chunks; i++) begin
        v.mantB[i] = r.mantB[i];
    end
    for (int i = 0; i < (hex_chunks + 3); i++) begin
        v.expAB[i] = r.expAB[i];
    end
    v.lzd_noscaling = r.lzd_noscaling;
    v.exp_res = r.exp_res;
    v.mant_res = r.mant_res;
    v.rnd_res = r.rnd_res;
    v.exp_res_rnd = r.exp_res_rnd;
    v.mant_res_rnd = r.mant_res_rnd;
    v.underflow = r.underflow;
    v.overflow = r.overflow;
    v.ex = r.ex;
    vb_mant_res_rnd = '0;
    vb_exp_res_rnd = '0;
    v_underflow = 1'b0;
    v_overflow = 1'b0;
    vb_mantA = '0;
    vb_mantB = '0;
    vb_expA_t = '0;
    vb_expB_t = '0;
    vb_expAB_t = '0;
    v_mant_even = 1'b0;
    v_mant05 = 1'b0;
    v_mant_rnd = 1'b0;

    v.ena = {r.ena[(latency - 2): 0], i_ena};

    v.a = i_a;
    v.b = i_b;

    v.sign = {r.sign[(latency - 4): 0], (r.a[(fbits - 1)] ^ r.b[(fbits - 1)])};

    if ((|r.a[(fbits - 2): mantbits]) == 1'b0) begin
        vb_mantA = {r.a[(mantbits - 1): 0], 1'b0};
    end else begin
        vb_mantA = {1'b1, r.a[(mantbits - 1): 0]};
    end
    if ((|r.b[(fbits - 2): mantbits]) == 1'b0) begin
        vb_mantB = {r.b[(mantbits - 1): 0], 1'b0};
    end else begin
        vb_mantB = {1'b1, r.b[(mantbits - 1): 0]};
    end


    v.mantA[0] = vb_mantA;
    v.mantB[0] = vb_mantB;
    wb_carry_i[0] = '0;
    wb_zres_i[0] = '0;
    for (int i = 0; i < (hex_chunks - 1); i++) begin
        wb_hex_i[i] = r.mantB[i][3: 0];
        wb_carry_i[(i + 1)] = wb_mant_msb[i];
        wb_zres_i[(i + 1)] = wb_mant_lsb[i];
        v.mantA[(i + 1)] = r.mantA[i];
        v.mantB[(i + 1)] = {4'd0, r.mantB[i][mantbits: 4]};
    end
    wb_hex_i[(hex_chunks - 1)] = r.mantB[(hex_chunks - 1)][3: 0];

    // expA - expB + EXPONENT_ZERO_LEVEL
    vb_expA_t = {2'd0, r.a[(fbits - 2): mantbits]};
    vb_expB_t = {2'd0, r.b[(fbits - 2): mantbits]};
    vb_expAB_t = (vb_expA_t + vb_expB_t);
    // pipeline exponent pre-scaled value:
    v.expAB[0] = (vb_expAB_t - explevel);
    for (int i = 0; i < (hex_chunks + 2); i++) begin
        v.expAB[(i + 1)] = r.expAB[i];
    end

    // Full istage output is valid when (goes to Leading Zero Detector Scaler):
    //       FP32: hex_chunks=6, ena[7]
    //       ena[hex_chunks + 1] == 1
    //       expAB[hex_chunks]
    //       {wb_mant_msb[hex_chunks - 1], wb_mant_lsb[hex_chunks - 1]}

    // Do not scale mantissa if the pre-scaled exponent <= 0:
    v.lzd_noscaling = 1'b0;
    if ((r.expAB[(hex_chunks - 1)][(expbits + 1)] == 1'b1)
            || (r.expAB[(hex_chunks - 1)] == 1'b0)) begin
        v.lzd_noscaling = r.ena[hex_chunks];
    end
    wb_mant_full = {wb_mant_msb[(hex_chunks - 1)], wb_mant_lsb[(hex_chunks - 1)]};

    v.exp_res = (r.expAB[(hex_chunks + 2)] - wb_mant_aligned_idx);
    v.mant_res = wb_mant_aligned[(mantmaxbits - 1): (mantmaxbits - (mantbits + 1))];

    // Rounding bit:
    v_mant_even = (~wb_mant_aligned[(mantmaxbits - (mantbits + 1))]);
    v_mant_rnd = wb_mant_aligned[(mantmaxbits - (mantbits + 2))];
    v_mant05 = (v_mant_rnd & (~(|wb_mant_aligned[(mantmaxbits - (mantbits + 3)): 0])));
    v.rnd_res = (v_mant_rnd && (~(v_mant05 && v_mant_even)));

    vb_mant_res_rnd = ({1'b0, r.mant_res} + {'0, r.rnd_res});
    vb_exp_res_rnd = (r.exp_res + {'0, vb_mant_res_rnd[(mantbits + 1): mantbits]});

    // Overflow: exponent is positive but out-of-range of 'expbits':
    v_overflow = ((~vb_exp_res_rnd[(expbits + 1)]) && vb_exp_res_rnd[expbits]);// FP32 (exp-8): 01.****.****
    v.overflow = v_overflow;

    // Undeflow: exponent is negative:
    v_underflow = vb_exp_res_rnd[(expbits + 1)];
    v.underflow = v_underflow;

    // De-normals are the value with the zero exponent (Intel compiler flags):
    //   FTZ enabled - when on sets denormals calculated results to zero
    //   DAZ disabled - when on treats input denormals as zero.

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

    v.result = {r.sign[(latency - 3)], r.exp_res_rnd, r.mant_res_rnd};

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v.ena = '0;
        v.a = '0;
        v.b = '0;
        v.result = '0;
        v.sign = '0;
        for (int i = 0; i < hex_chunks; i++) begin
            v.mantA[i] = '0;
        end
        for (int i = 0; i < hex_chunks; i++) begin
            v.mantB[i] = '0;
        end
        for (int i = 0; i < (hex_chunks + 3); i++) begin
            v.expAB[i] = '0;
        end
        v.lzd_noscaling = 1'b0;
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
    rin.sign = v.sign;
    for (int i = 0; i < hex_chunks; i++) begin
        rin.mantA[i] = v.mantA[i];
    end
    for (int i = 0; i < hex_chunks; i++) begin
        rin.mantB[i] = v.mantB[i];
    end
    for (int i = 0; i < (hex_chunks + 3); i++) begin
        rin.expAB[i] = v.expAB[i];
    end
    rin.lzd_noscaling = v.lzd_noscaling;
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
                r.sign <= '0;
                for (int i = 0; i < hex_chunks; i++) begin
                    r.mantA[i] <= '0;
                end
                for (int i = 0; i < hex_chunks; i++) begin
                    r.mantB[i] <= '0;
                end
                for (int i = 0; i < (hex_chunks + 3); i++) begin
                    r.expAB[i] <= '0;
                end
                r.lzd_noscaling <= 1'b0;
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
                r.sign <= rin.sign;
                for (int i = 0; i < hex_chunks; i++) begin
                    r.mantA[i] <= rin.mantA[i];
                end
                for (int i = 0; i < hex_chunks; i++) begin
                    r.mantB[i] <= rin.mantB[i];
                end
                for (int i = 0; i < (hex_chunks + 3); i++) begin
                    r.expAB[i] <= rin.expAB[i];
                end
                r.lzd_noscaling <= rin.lzd_noscaling;
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
            r.sign <= rin.sign;
            for (int i = 0; i < hex_chunks; i++) begin
                r.mantA[i] <= rin.mantA[i];
            end
            for (int i = 0; i < hex_chunks; i++) begin
                r.mantB[i] <= rin.mantB[i];
            end
            for (int i = 0; i < (hex_chunks + 3); i++) begin
                r.expAB[i] <= rin.expAB[i];
            end
            r.lzd_noscaling <= rin.lzd_noscaling;
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

endmodule: fmul_generic
