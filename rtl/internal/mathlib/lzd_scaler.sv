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

module lzd_scaler #(
    parameter int ibits = 22,                               // Input/output bitwise
    parameter int shiftbits = 4,                            // Operand shift value: must be $clog2(ibits)
    parameter logic async_reset = 1'b0
)
(
    input logic i_clk,                                      // CPU clock
    input logic i_nrst,                                     // Reset: active LOW
    input logic [ibits-1:0] i_m,                            // input operand
    input logic i_noscale,                                  // pass unscaled value directly to output
    output logic [ibits-1:0] o_scaled,                      // Scaled operand. 2 Cyles delay
    output logic [shiftbits-1:0] o_scaled_factor            // Scaling factor. 2 Cyles delay
);

localparam int lzd_chunks = ((ibits + 7) / 8);              // Leading Zero Detector chunks, each 8 bits
localparam int lzd_bits = (8 * lzd_chunks);                 // 8 bits aligned bitwise

typedef struct {
    logic [shiftbits-1:0] lzd_factor[0: lzd_chunks - 1];
    logic [lzd_bits-1:0] lzd_m[0: lzd_chunks - 1];
    logic lzd_noscale;
    logic [shiftbits-1:0] scaled_factor;
    logic [ibits-1:0] scaled;
} lzd_scaler_registers;

lzd_scaler_registers r;
lzd_scaler_registers rin;


always_comb
begin: comb_proc
    lzd_scaler_registers v;
    logic [(8 * lzd_chunks)-1:0] vb_lzd;
    logic [lzd_chunks-1:0] vb_lzd_noscaling;

    for (int i = 0; i < lzd_chunks; i++) begin
        v.lzd_factor[i] = r.lzd_factor[i];
    end
    for (int i = 0; i < lzd_chunks; i++) begin
        v.lzd_m[i] = r.lzd_m[i];
    end
    v.lzd_noscale = r.lzd_noscale;
    v.scaled_factor = r.scaled_factor;
    v.scaled = r.scaled;
    vb_lzd = '0;
    vb_lzd_noscaling = '1;

    v.lzd_noscale = i_noscale;

    // Detect Leading bit of Mantissa MSB.
    // Two stages:
    //       - Use chunks 8-bits each and save shifted mantissa for each chunk
    //       - Select the first non-zero shift
    //       - Ignore bits that out-of-range of exponent
    vb_lzd[(lzd_bits - 1): (lzd_bits - ibits)] = i_m;
    for (int i = 0; i < lzd_chunks; i++) begin
        if ((vb_lzd[((8 * i) + 7)] == 1'b1)
                || (i_noscale == 1'b1)) begin
            // No shift:
            v.lzd_factor[i] = (ibits - ((8 * i) + 8));
            if (i != (lzd_chunks - 1)) begin
                v.lzd_m[i] = (vb_lzd << (8 * ((lzd_chunks - 1) - i)));
            end else begin
                v.lzd_m[i] = vb_lzd;
            end
        end else if (vb_lzd[((8 * i) + 6)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 7));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 1));
        end else if (vb_lzd[((8 * i) + 5)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 6));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 2));
        end else if (vb_lzd[((8 * i) + 4)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 5));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 3));
        end else if (vb_lzd[((8 * i) + 3)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 4));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 4));
        end else if (vb_lzd[((8 * i) + 2)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 3));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 5));
        end else if (vb_lzd[((8 * i) + 1)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 2));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 6));
        end else if (vb_lzd[((8 * i) + 0)] == 1'b1) begin
            v.lzd_factor[i] = (ibits - ((8 * i) + 1));
            v.lzd_m[i] = (vb_lzd << ((8 * ((lzd_chunks - 1) - i)) + 7));
        end else begin
            v.lzd_factor[i] = '0;
            v.lzd_m[i] = '0;
        end
    end

    v.scaled_factor = 4'd0;
    v.scaled = 22'd0;
    if (r.lzd_noscale == 1'b1) begin
        v.scaled_factor = 4'd0;
        v.scaled = r.lzd_m[(lzd_chunks - 1)][(lzd_bits - 1): (lzd_bits - ibits)];
    end else begin
        for (int i = 0; i < lzd_chunks; i++) begin
            if (r.lzd_m[i][(lzd_bits - 1)] == 1'b1) begin
                v.scaled_factor = r.lzd_factor[i];
                v.scaled = r.lzd_m[i][(lzd_bits - 1): (lzd_bits - ibits)];
            end
        end
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        for (int i = 0; i < lzd_chunks; i++) begin
            v.lzd_factor[i] = '0;
        end
        for (int i = 0; i < lzd_chunks; i++) begin
            v.lzd_m[i] = '0;
        end
        v.lzd_noscale = 1'b0;
        v.scaled_factor = '0;
        v.scaled = '0;
    end

    o_scaled = r.scaled;
    o_scaled_factor = r.scaled_factor;

    for (int i = 0; i < lzd_chunks; i++) begin
        rin.lzd_factor[i] = v.lzd_factor[i];
    end
    for (int i = 0; i < lzd_chunks; i++) begin
        rin.lzd_m[i] = v.lzd_m[i];
    end
    rin.lzd_noscale = v.lzd_noscale;
    rin.scaled_factor = v.scaled_factor;
    rin.scaled = v.scaled;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                for (int i = 0; i < lzd_chunks; i++) begin
                    r.lzd_factor[i] <= '0;
                end
                for (int i = 0; i < lzd_chunks; i++) begin
                    r.lzd_m[i] <= '0;
                end
                r.lzd_noscale <= 1'b0;
                r.scaled_factor <= '0;
                r.scaled <= '0;
            end else begin
                for (int i = 0; i < lzd_chunks; i++) begin
                    r.lzd_factor[i] <= rin.lzd_factor[i];
                end
                for (int i = 0; i < lzd_chunks; i++) begin
                    r.lzd_m[i] <= rin.lzd_m[i];
                end
                r.lzd_noscale <= rin.lzd_noscale;
                r.scaled_factor <= rin.scaled_factor;
                r.scaled <= rin.scaled;
            end
        end

    end: async_r_en
    else begin: async_r_dis

        always_ff @(posedge i_clk) begin
            for (int i = 0; i < lzd_chunks; i++) begin
                r.lzd_factor[i] <= rin.lzd_factor[i];
            end
            for (int i = 0; i < lzd_chunks; i++) begin
                r.lzd_m[i] <= rin.lzd_m[i];
            end
            r.lzd_noscale <= rin.lzd_noscale;
            r.scaled_factor <= rin.scaled_factor;
            r.scaled <= rin.scaled;
        end

    end: async_r_dis
endgenerate

endmodule: lzd_scaler
