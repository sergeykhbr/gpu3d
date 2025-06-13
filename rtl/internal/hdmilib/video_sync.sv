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

module video_sync #(
    parameter logic async_reset = 1'b0,
    parameter int H_ACTIVE = 1366,
    parameter int H_FRONT = 70,
    parameter int H_SYNC = 143,
    parameter int H_BACK = 213,
    parameter int V_ACTIVE = 768,
    parameter int V_FRONT = 3,
    parameter int V_SYNC = 5,
    parameter int V_BACK = 24
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    output logic o_hsync,                                   // Horisontal sync pulse
    output logic o_vsync,                                   // Vertical sync pulse
    output logic o_de                                       // Data enable, HIGH in active zone 1366x768 screen resolution
);

import video_sync_pkg::*;

localparam int H_TOTAL = ((H_ACTIVE + H_SYNC) + (H_FRONT + H_BACK));
localparam int V_TOTAL = ((V_ACTIVE + V_SYNC) + (V_FRONT + V_BACK));

video_sync_registers r;
video_sync_registers rin;


always_comb
begin: comb_proc
    video_sync_registers v;

    v = r;

    if (r.h_count == (H_TOTAL - 1)) begin
        v.h_count = 11'd0;
        if (r.v_count == (V_TOTAL - 1)) begin
            v.v_count = 10'd0;
        end else begin
            v.v_count = (r.v_count + 1);
        end
    end else begin
        v.h_count = (r.h_count + 1);
    end

    // Re-arrange sequence: active => front porch => sync => back porch
    //                      _______________________|------|____________
    // Polarity+
    if ((r.h_count >= (H_ACTIVE + H_FRONT)) && (r.h_count < ((H_ACTIVE + H_FRONT) + H_SYNC))) begin
        v.h_sync = 1'b1;
    end else begin
        v.h_sync = 1'b0;
    end
    if ((r.v_count >= (V_ACTIVE + V_FRONT)) && (r.v_count < ((V_ACTIVE + V_FRONT) + V_SYNC))) begin
        v.v_sync = 1'b1;
    end else begin
        v.v_sync = 1'b0;
    end
    if ((r.h_count < H_ACTIVE) && (r.v_count < V_ACTIVE)) begin
        v.de = 1'b1;
        v.x_pix = r.h_count;
        v.y_pix = r.v_count;
    end else begin
        v.de = 1'b0;
        v.x_pix = 11'd0;
        v.y_pix = 10'd0;
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = video_sync_r_reset;
    end

    o_de = r.de;
    o_hsync = r.h_sync;
    o_vsync = r.v_sync;

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= video_sync_r_reset;
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

endmodule: video_sync
