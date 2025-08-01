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

module fmul_istage #(
    parameter int ibits = 22,                               // Input signal bitwise
    parameter int mbits = 4,                                // Operator m bitwise: possible values 4 (and potentially 3)
    parameter logic async_reset = 1'b0,
    parameter int idx = 0                                   // stage index
)
(
    input logic i_clk,                                      // CPU clock
    input logic i_nrst,                                     // Reset: active LOW
    input logic [ibits-1:0] i_a,                            // integer value
    input logic [mbits-1:0] i_m,                            // 4-bits value to multiply 0..15 using adders
    input logic [ibits-1:0] i_carry,                        // Carry value: A * M + Carry
    input logic [ibits-1:0] i_zres,                         // value to delay. Only (4*idx) of ibits will be delayed
    output logic [ibits-1:0] o_result,                      // resulting bits concatated with z-value
    output logic [ibits-1:0] o_carry                        // resulting carry bits
);

typedef struct {
    logic [ibits-1:0] zres;                                 // cannot create array of template with different width bits
    logic [(ibits + 4)-1:0] res;
} fmul_istage_registers;

const fmul_istage_registers fmul_istage_r_reset = '{
    '0,                                 // zres
    '0                                  // res
};
fmul_istage_registers r;
fmul_istage_registers rin;


always_comb
begin: comb_proc
    fmul_istage_registers v;
    logic [(ibits + 4)-1:0] vb_mux[0: 17-1];
    logic [ibits-1:0] vb_zres;
    logic [(ibits + 4)-1:0] vb_res;
    logic [ibits-1:0] vb_res_idx;

    v = r;
    for (int i = 0; i < 17; i++) begin
        vb_mux[i] = '0;
    end
    vb_zres = '0;
    vb_res = '0;
    vb_res_idx = '0;

    vb_mux[0] = '0;
    vb_mux[1] = i_a;
    vb_mux[2] = {i_a, 1'b0};
    vb_mux[3] = (vb_mux[2] + vb_mux[1]);
    vb_mux[4] = {i_a, 2'd0};
    vb_mux[5] = (vb_mux[4] + vb_mux[1]);
    vb_mux[6] = (vb_mux[4] + vb_mux[2]);
    vb_mux[8] = {i_a, 3'd0};
    vb_mux[7] = (vb_mux[8] - vb_mux[1]);
    vb_mux[9] = (vb_mux[8] + vb_mux[1]);
    vb_mux[10] = (vb_mux[8] + vb_mux[2]);
    vb_mux[11] = (vb_mux[10] + vb_mux[1]);
    vb_mux[12] = (vb_mux[8] + vb_mux[4]);
    vb_mux[16] = {i_a, 4'd0};
    vb_mux[13] = (vb_mux[16] - vb_mux[3]);
    vb_mux[14] = (vb_mux[16] - vb_mux[2]);
    vb_mux[15] = (vb_mux[16] - vb_mux[1]);

    case (i_m)
    4'd1: begin
        vb_res = (vb_mux[1] + {4'd0, i_carry});
    end
    4'd2: begin
        vb_res = (vb_mux[2] + {4'd0, i_carry});
    end
    4'd3: begin
        vb_res = (vb_mux[3] + {4'd0, i_carry});
    end
    4'd4: begin
        vb_res = (vb_mux[4] + {4'd0, i_carry});
    end
    4'd5: begin
        vb_res = (vb_mux[5] + {4'd0, i_carry});
    end
    4'd6: begin
        vb_res = (vb_mux[6] + {4'd0, i_carry});
    end
    4'd7: begin
        vb_res = (vb_mux[7] + {4'd0, i_carry});
    end
    4'd8: begin
        vb_res = (vb_mux[8] + {4'd0, i_carry});
    end
    4'd9: begin
        vb_res = (vb_mux[9] + {4'd0, i_carry});
    end
    4'd10: begin
        vb_res = (vb_mux[10] + {4'd0, i_carry});
    end
    4'd11: begin
        vb_res = (vb_mux[11] + {4'd0, i_carry});
    end
    4'd12: begin
        vb_res = (vb_mux[12] + {4'd0, i_carry});
    end
    4'd13: begin
        vb_res = (vb_mux[13] + {4'd0, i_carry});
    end
    4'd14: begin
        vb_res = (vb_mux[14] + {4'd0, i_carry});
    end
    4'd15: begin
        vb_res = (vb_mux[15] + {4'd0, i_carry});
    end
    default: begin
        vb_res = {4'd0, i_carry};
    end
    endcase

    v.res = vb_res;

    if ((|idx) == 1'b1) begin: n0
        vb_zres[((idx * mbits) - 1): 0] = i_zres[((idx * mbits) - 1): 0];
        vb_res_idx[((idx * mbits) - 1): 0] = r.zres;
    end: n0
    v.zres = vb_zres;
    vb_res_idx[(idx * mbits) +: 4] = r.res[3: 0];

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = fmul_istage_r_reset;
    end

    o_result = vb_res_idx;
    o_carry = r.res[(ibits + 3): 4];

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= fmul_istage_r_reset;
            end else begin
                r <= rin;
            end
        end

    end: async_r_en
    else begin: async_r_dis

        always_ff @(posedge i_clk) begin
            r <= rin;
        end

    end: async_r_dis
endgenerate

endmodule: fmul_istage
