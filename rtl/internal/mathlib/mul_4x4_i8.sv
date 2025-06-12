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

module mul_4x4_i8 #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic i_signed,                                   // 0=unsigned; 1=signed operation
    input logic [7:0] i_v0,                                 // input vector coordinate 0
    input logic [7:0] i_v1,                                 // input vector coordinate 1
    input logic [7:0] i_v2,                                 // input vector coordinate 2
    input logic [7:0] i_v3,                                 // input vector coordinate 3
    input logic [127:0] i_m,                                // matrix rates 16 x 8 bits each
    output logic [17:0] o_res0,                             // result vector coordinate 0
    output logic [17:0] o_res1,                             // result vector coordinate 1
    output logic [17:0] o_res2,                             // result vector coordinate 2
    output logic [17:0] o_res3                              // result vector coordinate 3
);

import mul_4x4_i8_pkg::*;

logic [7:0] wb_b00;
logic [7:0] wb_b01;
logic [7:0] wb_b02;
logic [7:0] wb_b03;
logic [7:0] wb_b10;
logic [7:0] wb_b11;
logic [7:0] wb_b12;
logic [7:0] wb_b13;
logic [7:0] wb_b20;
logic [7:0] wb_b21;
logic [7:0] wb_b22;
logic [7:0] wb_b23;
logic [7:0] wb_b30;
logic [7:0] wb_b31;
logic [7:0] wb_b32;
logic [7:0] wb_b33;
logic [15:0] wb_m00;
logic [15:0] wb_m01;
logic [15:0] wb_m02;
logic [15:0] wb_m03;
logic [15:0] wb_m10;
logic [15:0] wb_m11;
logic [15:0] wb_m12;
logic [15:0] wb_m13;
logic [15:0] wb_m20;
logic [15:0] wb_m21;
logic [15:0] wb_m22;
logic [15:0] wb_m23;
logic [15:0] wb_m30;
logic [15:0] wb_m31;
logic [15:0] wb_m32;
logic [15:0] wb_m33;
mul_4x4_i8_registers r;
mul_4x4_i8_registers rin;

// Row 0:
mul_i8 #(
    .async_reset(async_reset)
) m00 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v0),
    .i_b(wb_b00),
    .i_signed(i_signed),
    .o_res(wb_m00)
);

mul_i8 #(
    .async_reset(async_reset)
) m01 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v1),
    .i_b(wb_b01),
    .i_signed(i_signed),
    .o_res(wb_m01)
);

mul_i8 #(
    .async_reset(async_reset)
) m02 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v2),
    .i_b(wb_b02),
    .i_signed(i_signed),
    .o_res(wb_m02)
);

mul_i8 #(
    .async_reset(async_reset)
) m03 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v3),
    .i_b(wb_b03),
    .i_signed(i_signed),
    .o_res(wb_m03)
);

// Row 1:
mul_i8 #(
    .async_reset(async_reset)
) m10 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v0),
    .i_b(wb_b10),
    .i_signed(i_signed),
    .o_res(wb_m10)
);

mul_i8 #(
    .async_reset(async_reset)
) m11 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v1),
    .i_b(wb_b11),
    .i_signed(i_signed),
    .o_res(wb_m11)
);

mul_i8 #(
    .async_reset(async_reset)
) m12 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v2),
    .i_b(wb_b12),
    .i_signed(i_signed),
    .o_res(wb_m12)
);

mul_i8 #(
    .async_reset(async_reset)
) m13 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v3),
    .i_b(wb_b13),
    .i_signed(i_signed),
    .o_res(wb_m13)
);

// Row 2:
mul_i8 #(
    .async_reset(async_reset)
) m20 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v0),
    .i_b(wb_b20),
    .i_signed(i_signed),
    .o_res(wb_m20)
);

mul_i8 #(
    .async_reset(async_reset)
) m21 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v1),
    .i_b(wb_b21),
    .i_signed(i_signed),
    .o_res(wb_m21)
);

mul_i8 #(
    .async_reset(async_reset)
) m22 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v2),
    .i_b(wb_b22),
    .i_signed(i_signed),
    .o_res(wb_m22)
);

mul_i8 #(
    .async_reset(async_reset)
) m23 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v3),
    .i_b(wb_b23),
    .i_signed(i_signed),
    .o_res(wb_m23)
);

// Row 3:
mul_i8 #(
    .async_reset(async_reset)
) m30 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v0),
    .i_b(wb_b30),
    .i_signed(i_signed),
    .o_res(wb_m30)
);

mul_i8 #(
    .async_reset(async_reset)
) m31 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v1),
    .i_b(wb_b31),
    .i_signed(i_signed),
    .o_res(wb_m31)
);

mul_i8 #(
    .async_reset(async_reset)
) m32 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v2),
    .i_b(wb_b32),
    .i_signed(i_signed),
    .o_res(wb_m32)
);

mul_i8 #(
    .async_reset(async_reset)
) m33 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_a(i_v3),
    .i_b(wb_b33),
    .i_signed(i_signed),
    .o_res(wb_m33)
);

always_comb
begin: comb_proc
    mul_4x4_i8_registers v;

    v = r;


    v.sign = {r.sign[4: 0], i_signed};
    v.sum0a = ({(r.sign[4] & wb_m00[15]), wb_m00} + {(r.sign[4] & wb_m01[15]), wb_m01});
    v.sum0b = ({(r.sign[4] & wb_m02[15]), wb_m02} + {(r.sign[4] & wb_m03[15]), wb_m03});

    v.sum1a = ({(r.sign[4] & wb_m10[15]), wb_m10} + {(r.sign[4] & wb_m11[15]), wb_m11});
    v.sum1b = ({(r.sign[4] & wb_m12[15]), wb_m12} + {(r.sign[4] & wb_m13[15]), wb_m13});

    v.sum2a = ({(r.sign[4] & wb_m20[15]), wb_m20} + {(r.sign[4] & wb_m21[15]), wb_m21});
    v.sum2b = ({(r.sign[4] & wb_m22[15]), wb_m22} + {(r.sign[4] & wb_m23[15]), wb_m23});

    v.sum3a = ({(r.sign[4] & wb_m30[15]), wb_m30} + {(r.sign[4] & wb_m31[15]), wb_m31});
    v.sum3b = ({(r.sign[4] & wb_m32[15]), wb_m32} + {(r.sign[4] & wb_m33[15]), wb_m33});

    v.res0 = ({(r.sign[5] & r.sum0a[16]), r.sum0a} + {(r.sign[5] & r.sum0b[16]), r.sum0b});
    v.res1 = ({(r.sign[5] & r.sum1a[16]), r.sum1a} + {(r.sign[5] & r.sum1b[16]), r.sum1b});
    v.res2 = ({(r.sign[5] & r.sum2a[16]), r.sum2a} + {(r.sign[5] & r.sum2b[16]), r.sum2b});
    v.res3 = ({(r.sign[5] & r.sum3a[16]), r.sum3a} + {(r.sign[5] & r.sum3b[16]), r.sum3b});

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = mul_4x4_i8_r_reset;
    end

    o_res0 = r.res0;
    o_res1 = r.res1;
    o_res2 = r.res2;
    o_res3 = r.res3;

    rin = v;
end: comb_proc

assign wb_b00 = i_m[7: 0];
assign wb_b01 = i_m[15: 8];
assign wb_b02 = i_m[23: 16];
assign wb_b03 = i_m[31: 24];
assign wb_b10 = i_m[39: 32];
assign wb_b11 = i_m[47: 40];
assign wb_b12 = i_m[55: 48];
assign wb_b13 = i_m[63: 56];
assign wb_b20 = i_m[71: 64];
assign wb_b21 = i_m[79: 72];
assign wb_b22 = i_m[87: 80];
assign wb_b23 = i_m[95: 88];
assign wb_b30 = i_m[103: 96];
assign wb_b31 = i_m[111: 104];
assign wb_b32 = i_m[119: 112];
assign wb_b33 = i_m[127: 120];

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= mul_4x4_i8_r_reset;
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

endmodule: mul_4x4_i8
