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
    input logic [11:0] i_width_m1,                          // x-width: 4K = 3840 - 1
    input logic [11:0] i_height_m1,                         // y-height: 4K = 2160 - 1
    output logic o_hsync,                                   // delayed horizontal sync
    output logic o_vsync,                                   // delayed vertical sync
    output logic o_de,                                      // delayed data enable
    output logic [15:0] o_rgb565,                           // RGB 16-bits pixels
    // DMA engine compatible interface (always read). Get pixels array:
    input logic i_req_2d_ready,                             // 2D pixels ready to accept request
    output logic o_req_2d_valid,                            // 2D pixels request is valid
    output logic [11:0] o_req_2d_bytes,                     // 0=4096 Bytes; 4=DWORD; 8=QWORD; ...
    output logic [23:0] o_req_2d_addr,                      // 16 MB allocated for framebuffer
    input logic i_resp_2d_valid,                            // 2D pixels buffer response is valid
    input logic i_resp_2d_last,                             // Last data in burst read
    input logic [23:0] i_resp_2d_addr,                      // 16 MB allocated for framebuffer
    input logic [63:0] i_resp_2d_data,                      // Read data
    output logic o_resp_2d_ready                            // Ready to accept 2D pixels response
);

import framebuf_pkg::*;

logic [5:0] wb_ring0_addr;
logic w_ring0_wena;
logic [63:0] wb_ring0_rdata;
logic [5:0] wb_ring1_addr;
logic w_ring1_wena;
logic [63:0] wb_ring1_rdata;
logic [5:0] wb_ring2_addr;
logic w_ring2_wena;
logic [63:0] wb_ring2_rdata;
logic [5:0] wb_ring3_addr;
logic w_ring3_wena;
logic [63:0] wb_ring3_rdata;
framebuf_registers r;
framebuf_registers rin;

ram_tech #(
    .abits(6),
    .dbits(64)
) ring0 (
    .i_clk(i_clk),
    .i_addr(wb_ring0_addr),
    .i_wena(w_ring0_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_ring0_rdata)
);

ram_tech #(
    .abits(6),
    .dbits(64)
) ring1 (
    .i_clk(i_clk),
    .i_addr(wb_ring1_addr),
    .i_wena(w_ring1_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_ring1_rdata)
);

ram_tech #(
    .abits(6),
    .dbits(64)
) ring2 (
    .i_clk(i_clk),
    .i_addr(wb_ring2_addr),
    .i_wena(w_ring2_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_ring2_rdata)
);

ram_tech #(
    .abits(6),
    .dbits(64)
) ring3 (
    .i_clk(i_clk),
    .i_addr(wb_ring3_addr),
    .i_wena(w_ring3_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_ring3_rdata)
);

always_comb
begin: comb_proc
    framebuf_registers v;
    logic v_rd_ena;
    logic [63:0] vb_ring_rdata;
    logic [15:0] vb_pix;

    v = r;
    v_rd_ena = 1'b0;
    vb_ring_rdata = '0;
    vb_pix = '0;

    // delayed signals:
    v.de = {r.de[2: 0], i_de};
    v.h_sync = {r.h_sync[2: 0], i_hsync};
    v.v_sync = {r.v_sync[2: 0], i_vsync};

    if ((i_vsync == 1'b1) && (r.v_sync[0] == 1'b0)) begin
        // Posedge of vsync:
        v.state = STATE_EndOfFrame;
    end

    case (r.state)
    STATE_Idle: begin
        if ((r.difcnt[8] == 1'b1) || (r.difcnt <= 9'd96)) begin
            v.req_valid = 1'b1;
            v.req_addr = {r.wr_row, r.wr_col, 1'b0};        // 2 Bytes per pixel
            v.state = STATE_Request;
        end
    end
    STATE_Request: begin
        v.req_valid = 1'b1;
        v.resp_ready = 1'b0;
        if ((r.req_valid == 1'b1) && (i_req_2d_ready == 1'b1)) begin
            v.req_valid = 1'b0;
            v.resp_ready = 1'b1;
            v.state = STATE_Writing;
        end
    end
    STATE_Writing: begin
        if (i_resp_2d_valid == 1'b1) begin
            v.wr_col = (r.wr_col + 12'd4);                  // 64-bits contains 4x16-bits pixels
            v.wr_addr = (r.wr_addr + 1);
            if (i_resp_2d_last == 1'b1) begin
                v.resp_ready = 1'b0;
                v.state = STATE_Idle;
                if (r.wr_col >= i_width_m1) begin
                    v.wr_col = 12'd0;
                    v.wr_row = (r.wr_row + 1);
                    v.wr_addr = {(r.wr_addr[7: 6] + 1), 6'd0};
                end
            end
        end
    end
    STATE_EndOfFrame: begin
        if (i_vsync == 1'b0) begin
            // Negedge of vsync:
            v.wr_col = 12'd0;
            v.wr_row = 12'd0;
            v.wr_addr = 8'd0;
            v.difcnt = 9'd0;
            v.rd_row = 12'd0;
            v.rd_col = 12'd0;
            v.rd_addr = 8'd0;
            v.mux_ena = 4'h1;
            v.state = STATE_Idle;
        end
    end
    endcase

    if (i_de == 1'b1) begin
        v.mux_ena = {r.mux_ena[2: 0], r.mux_ena[3]};
        if (r.mux_ena[0] == 1'b1) begin
            v_rd_ena = 1'b1;
            v.rd_addr = (r.rd_addr + 1);
            v.rd_col = (r.rd_col + 12'd4);                  // 64-bits contains 4x16-bits pixels
        end
    end else if ((r.de[0] == 1'b1) && (i_de == 1'b0)) begin
        // Back front of the de (end of row)
        v.rd_addr = {(r.rd_addr[7: 6] + 1), 6'd0};
        v.mux_ena = 4'h1;
        v.rd_col = 12'd0;
        v.rd_row = (r.rd_row + 1);
    end
    if ((i_resp_2d_valid == 1'b1) && (v_rd_ena == 1'b0)) begin
        v.difcnt = (r.difcnt + 1);
    end else if ((i_resp_2d_valid == 1'b0) && (v_rd_ena == 1'b1)) begin
        v.difcnt = (r.difcnt - 1);
    end else if ((i_hsync == 1'b0) && (r.h_sync[0] == 1'b1)) begin
        // correction, we can write more than used
        v.difcnt = r.wr_col[11: 2];
    end

    if (r.wr_addr[7: 6] == 2'd0) begin
        w_ring0_wena = i_resp_2d_valid;
        wb_ring0_addr = r.wr_addr[6: 0];
        w_ring1_wena = 1'b0;
        wb_ring1_addr = r.rd_addr[6: 0];
        w_ring2_wena = 1'b0;
        wb_ring2_addr = r.rd_addr[6: 0];
        w_ring3_wena = 1'b0;
        wb_ring3_addr = r.rd_addr[6: 0];
    end else if (r.wr_addr[7: 6] == 2'd1) begin
        w_ring0_wena = 1'b0;
        wb_ring0_addr = r.rd_addr[6: 0];
        w_ring1_wena = i_resp_2d_valid;
        wb_ring1_addr = r.wr_addr[6: 0];
        w_ring2_wena = 1'b0;
        wb_ring2_addr = r.rd_addr[6: 0];
        w_ring3_wena = 1'b0;
        wb_ring3_addr = r.rd_addr[6: 0];
    end else if (r.wr_addr[7: 6] == 2'd2) begin
        w_ring0_wena = 1'b0;
        wb_ring0_addr = r.rd_addr[6: 0];
        w_ring1_wena = 1'b0;
        wb_ring1_addr = r.rd_addr[6: 0];
        w_ring2_wena = i_resp_2d_valid;
        wb_ring2_addr = r.wr_addr[6: 0];
        w_ring3_wena = 1'b0;
        wb_ring3_addr = r.rd_addr[6: 0];
    end else begin
        w_ring0_wena = 1'b0;
        wb_ring0_addr = r.rd_addr[6: 0];
        w_ring1_wena = 1'b0;
        wb_ring1_addr = r.rd_addr[6: 0];
        w_ring2_wena = 1'b0;
        wb_ring2_addr = r.rd_addr[6: 0];
        w_ring3_wena = i_resp_2d_valid;
        wb_ring3_addr = r.wr_addr[6: 0];
    end
    if (r.rd_addr[7: 6] == 2'd0) begin
        v.ring_sel = 4'h1;
    end else if (r.rd_addr[7: 6] == 2'd1) begin
        v.ring_sel = 4'h2;
    end else if (r.rd_addr[7: 6] == 2'd2) begin
        v.ring_sel = 4'h4;
    end else begin
        v.ring_sel = 4'h8;
    end
    v.pix_sel = r.mux_ena;

    if (r.ring_sel[0] == 1'b1) begin
        vb_ring_rdata = wb_ring0_rdata;
    end else if (r.ring_sel[1] == 1'b1) begin
        vb_ring_rdata = wb_ring1_rdata;
    end else if (r.ring_sel[2] == 1'b1) begin
        vb_ring_rdata = wb_ring2_rdata;
    end else begin
        vb_ring_rdata = wb_ring3_rdata;
    end
    if ((|r.de) == 1'b0) begin
        vb_pix = 16'd0;
    end else if (r.pix_sel[0] == 1'b1) begin
        vb_pix = vb_ring_rdata[15: 0];
    end else if (r.pix_sel[1] == 1'b1) begin
        vb_pix = vb_ring_rdata[31: 16];
    end else if (r.pix_sel[2] == 1'b1) begin
        vb_pix = vb_ring_rdata[47: 32];
    end else begin
        vb_pix = vb_ring_rdata[63: 48];
    end
    v.rgb = vb_pix;

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = framebuf_r_reset;
    end

    o_hsync = r.h_sync[1];
    o_vsync = r.v_sync[1];
    o_de = r.de[1];
    o_rgb565 = r.rgb;

    o_req_2d_valid = r.req_valid;
    o_req_2d_bytes = 12'd64;                                // Xilinx MIG is limited to burst beat length 8
    o_req_2d_addr = r.req_addr[23: 0];
    o_resp_2d_ready = r.resp_ready;

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
