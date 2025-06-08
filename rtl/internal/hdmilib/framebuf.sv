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
    input logic [23:0] i_xy_total,                          // x*y resolution, up to 16MB
    output logic o_hsync,                                   // delayed horizontal sync
    output logic o_vsync,                                   // delayed vertical sync
    output logic o_de,                                      // delayed data enable
    output logic [17:0] o_YCbCr,                            // YCbCr multiplexed odd/even pixels
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

logic [7:0] wb_ping_addr;
logic w_ping_wena;
logic [63:0] wb_ping_rdata;
logic [7:0] wb_pong_addr;
logic w_pong_wena;
logic [63:0] wb_pong_rdata;
framebuf_registers r;
framebuf_registers rin;

ram_tech #(
    .abits(8),
    .dbits(64)
) ping (
    .i_clk(i_clk),
    .i_addr(wb_ping_addr),
    .i_wena(w_ping_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_ping_rdata)
);

ram_tech #(
    .abits(8),
    .dbits(64)
) pong (
    .i_clk(i_clk),
    .i_addr(wb_pong_addr),
    .i_wena(w_pong_wena),
    .i_wdata(i_resp_2d_data),
    .o_rdata(wb_pong_rdata)
);

always_comb
begin: comb_proc
    framebuf_registers v;
    logic [10:0] vb_raddr_next;

    v = r;
    vb_raddr_next = 11'd0;

    // delayed signals:
    v.de = {r.de[2: 0], i_de};
    v.h_sync = {r.h_sync[2: 0], i_hsync};
    v.v_sync = {r.v_sync[2: 0], i_vsync};
    v.pix_x0 = i_x[0];

    vb_raddr_next = (r.raddr + 1);
    if ((r.req_valid == 1'b1) && (i_req_2d_ready == 1'b1)) begin
        v.req_valid = 1'b0;
    end
    if (i_de == 1'b1) begin
        v.raddr = vb_raddr_next;
        v.raddr_z = r.raddr;
    end

    case (r.state)
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
            if (i_resp_2d_last == 1'b1) begin
                v.resp_ready = 1'b0;
                if ((&i_resp_2d_addr[10: 3]) == 1'b1) begin
                    v.state = STATE_Idle;
                end else begin
                    v.req_valid = 1'b1;
                    v.req_addr = (r.req_addr + 1);
                    v.state = STATE_Request;
                end
            end
        end
    end
    STATE_Idle: begin
        if (r.raddr[10] != vb_raddr_next[10]) begin
            v.pingpong = (~r.pingpong);
            if ((r.req_addr + 1) >= i_xy_total[22: 5]) begin// 2048 B = 1024 pixel (16 bits each)
                // request first data while processing the last one:
                v.req_addr = 18'd0;
            end else begin
                v.req_addr = (r.req_addr + 1);
            end
            v.req_valid = 1'b1;
            v.state = STATE_Request;
        end
    end
    default: begin
    end
    endcase

    if ((i_vsync == 1'b1) && (r.v_sync[0] == 1'b0)) begin
        // Update the second memory bank, so that ping & pong were updated
        v.pingpong = (~r.pingpong);
        v.raddr = 11'd0;
        v.req_addr = 18'd32;                                // 32-burst transactions 64B each => 2048 B
        v.req_valid = 1'b1;
        v.state = STATE_Request;
    end

    if (r.pingpong == 1'b1) begin
        wb_ping_addr = r.raddr[9: 2];
        wb_pong_addr = i_resp_2d_addr[10: 3];
        if ((|r.de) == 1'b1) begin
            if (r.raddr_z[1: 0] == 2'd0) begin
                v.YCbCr = wb_ping_rdata[15: 0];
            end else if (r.raddr_z[1: 0] == 2'd1) begin
                v.YCbCr = wb_ping_rdata[31: 16];
            end else if (r.raddr_z[1: 0] == 2'd2) begin
                v.YCbCr = wb_ping_rdata[47: 32];
            end else begin
                v.YCbCr = wb_ping_rdata[63: 48];
            end
        end else begin
            v.YCbCr = 16'd0;
        end
    end else begin
        wb_ping_addr = i_resp_2d_addr[10: 3];
        wb_pong_addr = r.raddr[9: 2];
        if ((|r.de) == 1'b1) begin
            if (r.raddr_z[1: 0] == 2'd0) begin
                v.YCbCr = wb_pong_rdata[15: 0];
            end else if (r.raddr_z[1: 0] == 2'd1) begin
                v.YCbCr = wb_pong_rdata[31: 16];
            end else if (r.raddr_z[1: 0] == 2'd2) begin
                v.YCbCr = wb_pong_rdata[47: 32];
            end else begin
                v.YCbCr = wb_pong_rdata[63: 48];
            end
        end else begin
            v.YCbCr = 16'd0;
        end
    end
    w_ping_wena = (i_resp_2d_valid & (~r.pingpong));
    w_pong_wena = (i_resp_2d_valid & r.pingpong);

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = framebuf_r_reset;
    end

    o_hsync = r.h_sync[1];
    o_vsync = r.v_sync[1];
    o_de = r.de[1];
    o_YCbCr = {2'd0, r.YCbCr};

    o_req_2d_valid = r.req_valid;
    o_req_2d_bytes = 12'd64;                                // Xilinx MIG is limited to burst beat length 8
    o_req_2d_addr = {r.req_addr, 6'd0};
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
