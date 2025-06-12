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

module rgb2ycbcr #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic [15:0] i_rgb565,                            // RGB 16-bits input
    input logic i_hsync,                                    // Horizontal sync
    input logic i_vsync,                                    // Vertical sync
    input logic i_de,                                       // data enable
    output logic [17:0] o_ycbcr422,                         // YCbCr 16-bits 4:2:2 format plus 2 extra bits
    output logic o_hsync,                                   // delayed horizontal sync
    output logic o_vsync,                                   // delayed vertical sync
    output logic o_de                                       // delayed data enable
);

import rgb2ycbcr_pkg::*;

logic w_signed;
logic [7:0] wb_v0;
logic [7:0] wb_v1;
logic [7:0] wb_v2;
logic [7:0] wb_v3;
logic [127:0] wb_m;
logic [17:0] wb_res0;
logic [17:0] wb_res1;
logic [17:0] wb_res2;
logic [17:0] wb_res3;
rgb2ycbcr_registers r;
rgb2ycbcr_registers rin;

mul_4x4_i8 #(
    .async_reset(async_reset)
) im8 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_signed(w_signed),
    .i_v0(wb_v0),
    .i_v1(wb_v1),
    .i_v2(wb_v2),
    .i_v3(wb_v3),
    .i_m(wb_m),
    .o_res0(wb_res0),
    .o_res1(wb_res1),
    .o_res2(wb_res2),
    .o_res3(wb_res3)
);

always_comb
begin: comb_proc
    rgb2ycbcr_registers v;
    logic [7:0] vb_m00;                                     // 0.257 * 128
    logic [7:0] vb_m01;                                     // 0.504
    logic [7:0] vb_m02;                                     // 0.0979
    logic [7:0] vb_m03;                                     // 0.0627
    logic [7:0] vb_m10;                                     // -0.148
    logic [7:0] vb_m11;                                     // -0.291
    logic [7:0] vb_m12;                                     // 0.439
    logic [7:0] vb_m13;                                     // 0.502
    logic [7:0] vb_m20;                                     // 0.439
    logic [7:0] vb_m21;                                     // -0.368
    logic [7:0] vb_m22;                                     // -0.0714
    logic [7:0] vb_m23;                                     // 0.502
    logic [7:0] vb_m30;
    logic [7:0] vb_m31;
    logic [7:0] vb_m32;
    logic [7:0] vb_m33;

    v = r;
    vb_m00 = 8'h21;
    vb_m01 = 8'h41;
    vb_m02 = 8'h0D;
    vb_m03 = 8'h08;
    vb_m10 = 8'hEE;
    vb_m11 = 8'hDC;
    vb_m12 = 8'h38;
    vb_m13 = 8'h40;
    vb_m20 = 8'h38;
    vb_m21 = 8'hD2;
    vb_m22 = 8'hF8;
    vb_m23 = 8'h40;
    vb_m30 = 8'd0;
    vb_m31 = 8'd0;
    vb_m32 = 8'd0;
    vb_m33 = 8'd1;

    wb_m = {vb_m33,
            vb_m32,
            vb_m31,
            vb_m30,
            vb_m23,
            vb_m22,
            vb_m21,
            vb_m20,
            vb_m13,
            vb_m12,
            vb_m11,
            vb_m10,
            vb_m03,
            vb_m02,
            vb_m01,
            vb_m00};

    w_signed = 1'b1;                                        // Signed operation -127..+127
    wb_v0 = {1'b0, i_rgb565[15: 11], 2'd0};                 // Red, normilizgin to 0..127
    wb_v1 = {1'b0, i_rgb565[10: 5], 1'b0};                  // Green, normilizgin to 0..127
    wb_v2 = {1'b0, i_rgb565[4: 0], 2'd0};                   // Blue, normilizgin to 0..127
    wb_v3 = 8'd127;

    v.even = {r.even[5: 0], (i_de & (~r.even[0]))};
    v.hsync = {r.hsync[6: 0], i_hsync};
    v.vsync = {r.vsync[6: 0], i_vsync};
    v.de = {r.de[6: 0], i_de};
    if (r.even[6] == 1'b1) begin
        // {Cb, Y} scaled down to 64 (multiplier gives 14 bits unsigned scale to 8-bits)
        v.ycbcr422 = {wb_res1[13: 6], wb_res0[13: 6]};
    end else begin
        // Cr, Y scaled down to 64 (multiplier gives 14 bits unsigned scale to 8-bits)
        v.ycbcr422 = {wb_res2[13: 6], wb_res0[13: 6]};
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = rgb2ycbcr_r_reset;
    end
    o_ycbcr422 = {2'd0, r.ycbcr422};
    o_hsync = r.hsync[7];
    o_vsync = r.vsync[7];
    o_de = r.de[7];

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= rgb2ycbcr_r_reset;
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

endmodule: rgb2ycbcr
