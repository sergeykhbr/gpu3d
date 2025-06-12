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

module mul_i8 #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic [7:0] i_a,                                  // multiplier A
    input logic [7:0] i_b,                                  // multiplier B
    input logic i_signed,                                   // 0=unsigned; 1=signed operation
    output logic [15:0] o_res                               // result
);

import mul_i8_pkg::*;

mul_i8_registers r;
mul_i8_registers rin;


always_comb
begin: comb_proc
    mul_i8_registers v;
    logic [9:0] vb_lvl1_00;
    logic [9:0] vb_lvl1_01;
    logic [9:0] vb_lvl1_10;
    logic [9:0] vb_lvl1_11;
    logic [9:0] vb_lvl1_20;
    logic [9:0] vb_lvl1_21;
    logic [9:0] vb_lvl1_30;
    logic [9:0] vb_lvl1_31;

    v = r;
    vb_lvl1_00 = '0;
    vb_lvl1_01 = '0;
    vb_lvl1_10 = '0;
    vb_lvl1_11 = '0;
    vb_lvl1_20 = '0;
    vb_lvl1_21 = '0;
    vb_lvl1_30 = '0;
    vb_lvl1_31 = '0;

    if ((i_signed == 1'b1) && (i_a[7] == 1'b1)) begin
        v.ua = ((~i_a) + 1);
    end else begin
        v.ua = i_a;
    end
    if ((i_signed == 1'b1) && (i_b[7] == 1'b1)) begin
        v.ub = ((~i_b) + 1);
    end else begin
        v.ub = i_b;
    end
    v.inv = {r.inv[2: 0], (i_signed & (i_a[7] ^ i_b[7]))};

    // Level 1, bits[1:0]
    if (r.ub[0] == 1'b1) begin
        vb_lvl1_00 = {2'd0, r.ua};
    end
    if (r.ub[1] == 1'b1) begin
        vb_lvl1_01 = {1'b0, r.ua, 1'b0};
    end
    v.lvl1_0 = (vb_lvl1_00 + vb_lvl1_01);

    // Level 1, bits[3:2]
    if (r.ub[2] == 1'b1) begin
        vb_lvl1_10 = {2'd0, r.ua};
    end
    if (r.ub[3] == 1'b1) begin
        vb_lvl1_11 = {2'd0, r.ua, 1'b0};
    end
    v.lvl1_1 = (vb_lvl1_10 + vb_lvl1_11);

    // Level 1, bits[5:4]
    if (r.ub[4] == 1'b1) begin
        vb_lvl1_20 = {2'd0, r.ua};
    end
    if (r.ub[5] == 1'b1) begin
        vb_lvl1_21 = {1'b0, r.ua, 1'b0};
    end
    v.lvl1_2 = (vb_lvl1_20 + vb_lvl1_21);

    // Level 1, bits[7:6]
    if (r.ub[6] == 1'b1) begin
        vb_lvl1_30 = {2'd0, r.ua};
    end
    if (r.ub[7] == 1'b1) begin
        vb_lvl1_31 = {1'b0, r.ua, 1'b0};
    end
    v.lvl1_3 = (vb_lvl1_30 + vb_lvl1_31);


    // Level 2, bits[3:0]
    v.lvl2_0 = ({3'd0, r.lvl1_0} + {1'b0, r.lvl1_1, 2'd0});
    // Level 2, bits[7:4]
    v.lvl2_1 = ({3'd0, r.lvl1_2} + {1'b0, r.lvl1_3, 2'd0});


    // Level 3, result
    v.lvl3 = ({3'd0, r.lvl2_0} + {r.lvl2_1[11: 0], 4'd0});
    if (r.inv[3] == 1'b1) begin
        v.res = ((~r.lvl3) + 1);
    end else begin
        v.res = r.lvl3;
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = mul_i8_r_reset;
    end

    o_res = r.res;

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= mul_i8_r_reset;
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

endmodule: mul_i8
