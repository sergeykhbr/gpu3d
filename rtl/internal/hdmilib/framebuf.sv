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

module framebuf #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic i_hsync,                                    // Horizontal sync
    input logic i_vsync,                                    // Vertical sync
    input logic i_de,                                       // data enable
    input logic [10:0] i_x,                                 // x-pixel
    input logic [9:0] i_y,                                  // y-pixel
    output logic o_hsync,                                   // delayed horizontal sync
    output logic o_vsync,                                   // delayed vertical sync
    output logic o_de,                                      // delayed data enable
    output logic [17:0] o_YCbCr                             // YCbCr multiplexed odd/even pixels
);

import framebuf_pkg::*;

framebuf_registers r;
framebuf_registers rin;


always_comb
begin: comb_proc
    framebuf_registers v;

    v = r;

    // delayed signals:
    v.de = {r.de[0], i_de};
    v.h_sync = {r.h_sync[0], i_hsync};
    v.v_sync = {r.v_sync[0], i_vsync};
    v.pix_x0 = i_x[0];
    if (i_x < 11'd170) begin
        // White
        v.Y0 = 8'd235;
        v.Y1 = 8'd235;
        v.Cb = 8'd128;
        v.Cr = 8'd128;
    end else if (i_x < 11'd340) begin
        // Black
        v.Y0 = 8'd219;
        v.Y1 = 8'd219;
        v.Cb = 8'd16;
        v.Cr = 8'd16;
    end else if (i_x < 11'd510) begin
        // Red
        v.Y0 = 8'd82;
        v.Y1 = 8'd82;
        v.Cb = 8'd90;
        v.Cr = 8'd240;
    end else if (i_x < 11'd680) begin
        // Green
        v.Y0 = 8'd145;
        v.Y1 = 8'd145;
        v.Cb = 8'd54;
        v.Cr = 8'd234;
    end else if (i_x < 11'd850) begin
        // Blue
        v.Y0 = 8'd41;
        v.Y1 = 8'd41;
        v.Cb = 8'd240;
        v.Cr = 8'd110;
    end else if (i_x < 11'd1020) begin
        // Yellow
        v.Y0 = 8'd200;
        v.Y1 = 8'd200;
        v.Cb = 8'd16;
        v.Cr = 8'd146;
    end else if (i_x < 11'd1190) begin
        // Cyan
        v.Y0 = 8'd105;
        v.Y1 = 8'd105;
        v.Cb = 8'd212;
        v.Cr = 8'd234;
    end else begin
        // Magneta
        v.Y0 = 8'd170;
        v.Y1 = 8'd170;
        v.Cb = 8'd166;
        v.Cr = 8'd16;
    end

    // See style 1 output:
    if (r.pix_x0 == 1'b0) begin
        v.YCbCr = {r.Y1, r.Cb};
    end else begin
        v.YCbCr = {r.Y1, r.Cr};
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = framebuf_r_reset;
    end

    o_hsync = r.h_sync;
    o_vsync = r.v_sync;
    o_de = r.de;
    o_YCbCr = {2'd0, r.YCbCr};

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= framebuf_r_reset;
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

endmodule: framebuf
