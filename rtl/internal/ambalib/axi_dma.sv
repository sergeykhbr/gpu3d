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

module axi_dma #(
    parameter logic async_reset = 1'b0,
    parameter int abits = 48,
    parameter int userbits = 1
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    output logic o_req_mem_ready,                           // Ready to accept next data
    input logic i_req_mem_valid,                            // Request data is ready to accept
    input logic i_req_mem_64,                               // 0=32-bits; 1=64-bits
    input logic i_req_mem_write,                            // 0=read; 1=write operation
    input logic [9:0] i_req_mem_bytes,                      // 0=1024 B; 4=DWORD; 8=QWORD; ...
    input logic [abits-1:0] i_req_mem_addr,                 // Address to read/write
    input logic [7:0] i_req_mem_strob,                      // Byte enabling write strob
    input logic [63:0] i_req_mem_data,                      // Data to write
    input logic i_req_mem_last,                             // Last data payload in a sequence
    output logic [63:0] o_resp_mem_data,                    // Read data value
    output logic o_resp_mem_valid,                          // Read/Write data is valid. All write transaction with valid response.
    output logic o_resp_mem_fault,                          // Error on memory access
    input logic i_resp_mem_ready,                           // Ready to accept response
    input types_amba_pkg::axi4_master_in_type i_msti,       // AXI master input
    output types_amba_pkg::axi4_master_out_type o_msto      // AXI master output
);

import types_amba_pkg::*;
import axi_dma_pkg::*;

axi_dma_registers r;
axi_dma_registers rin;


always_comb
begin: comb_proc
    axi_dma_registers v;
    logic [9:0] vb_req_mem_bytes_m1;
    logic [CFG_SYSBUS_ADDR_BITS-1:0] vb_req_addr_inc;
    axi4_master_out_type vmsto;

    v = r;
    vb_req_mem_bytes_m1 = '0;
    vb_req_addr_inc = '0;
    vmsto = axi4_master_out_none;

    vb_req_mem_bytes_m1 = (i_req_mem_bytes - 1);
    vb_req_addr_inc = r.req_addr;
    if (i_req_mem_64 == 1'b1) begin
        vb_req_addr_inc[9: 0] = (r.req_addr[9: 0] + 10'h008);
    end else begin
        vb_req_addr_inc[9: 0] = (r.req_addr[9: 0] + 10'h004);
    end

    case (r.state)
    state_idle: begin
        v.req_ready = 1'b1;
        v.resp_valid = 1'b0;
        if (i_req_mem_valid == 1'b1) begin
            v.req_ready = 1'b0;
            v.req_addr = (48'h000008000000 | {'0, i_req_mem_addr});
            v.req_last = i_req_mem_last;
            if (i_req_mem_64 == 1'b1) begin
                v.req_size = 3'd6;
                v.req_len = {1'b0, vb_req_mem_bytes_m1[9: 3]};
            end else begin
                v.req_size = 3'd5;
                v.req_len = vb_req_mem_bytes_m1[9: 2];
            end
            if (i_req_mem_write == 1'b0) begin
                v.ar_valid = 1'b1;
                v.state = state_ar;
                v.req_wdata = 64'd0;
                v.req_wstrb = 8'd0;
            end else begin
                v.aw_valid = 1'b1;
                v.w_valid = i_req_mem_last;                 // Try to use AXI Lite
                v.req_wdata = i_req_mem_data;
                v.req_wstrb = i_req_mem_strob;
                v.state = state_aw;
            end
        end
    end
    state_ar: begin
        if (i_msti.ar_ready == 1'b1) begin
            v.ar_valid = 1'b0;
            v.r_ready = 1'b1;
            v.state = state_r;
        end
    end
    state_r: begin
        if (i_msti.r_valid == 1'b1) begin
            v.resp_valid = 1'b1;
            v.resp_data = i_msti.r_data;
            v.req_last = i_msti.r_last;
            v.resp_error = i_msti.r_resp[1];
            v.req_addr = vb_req_addr_inc;

            if ((i_resp_mem_ready == 1'b0) || (i_msti.r_last == 1'b1)) begin
                v.r_ready = 1'b0;
                v.state = state_r_wait_accept;
            end
        end
    end
    state_r_wait_accept: begin
        if (i_resp_mem_ready == 1'b1) begin
            v.resp_valid = 1'b0;

            if (r.req_last == 1'b1) begin
                v.req_last = 1'b0;
                v.user_count = (r.user_count + 1);
                v.req_ready = 1'b1;
                v.state = state_idle;
            end else begin
                v.r_ready = 1'b1;
                v.state = state_r;
            end
        end
    end

    state_aw: begin
        if (i_msti.aw_ready == 1'b1) begin
            v.aw_valid = 1'b0;
            v.state = state_w;

            if (r.w_valid && (i_msti.w_ready == 1'b1)) begin
                // AXI Lite accepted
                v.w_valid = 1'b0;
                v.b_ready = i_resp_mem_ready;
                v.state = state_b;
            end else begin
                v.w_valid = 1'b1;
                v.req_ready = (~r.req_last);
                v.state = state_w;
            end
        end
    end
    state_w: begin
        if (i_msti.w_ready == 1'b1) begin
            // Burst write:
            v.w_valid = i_req_mem_valid;
            v.req_last = i_req_mem_last;
            v.req_wstrb = i_req_mem_strob;
            v.req_wdata = i_req_mem_data;
            v.req_addr = vb_req_addr_inc;
            if (r.req_last == 1'b1) begin
                v.req_last = 1'b0;
                v.w_valid = 1'b0;
                v.b_ready = i_resp_mem_ready;
                v.req_ready = 1'b0;
                v.state = state_b;
            end
        end else if (r.w_valid == 1'b1) begin
            v.req_ready = 1'b0;
            v.state = state_w_wait_accept;
        end
    end
    state_w_wait_accept: begin
        if (i_msti.w_ready == 1'b1) begin
            v.w_valid = 1'b0;
            if (r.req_last == 1'b1) begin
                v.req_last = 1'b0;
                v.b_ready = i_resp_mem_ready;
                v.state = state_b;
            end else begin
                v.req_ready = 1'b1;
                v.state = state_w;
            end
        end
    end
    state_b: begin
        v.b_ready = i_resp_mem_ready;
        if ((r.b_ready == 1'b1) && (i_msti.b_valid == 1'b1)) begin
            v.b_ready = 1'b0;
            v.state = state_idle;
            v.user_count = (r.user_count + 1);
            v.resp_error = i_msti.b_resp[1];
            v.resp_valid = 1'b1;
        end
    end
    endcase

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = axi_dma_r_reset;
    end

    o_req_mem_ready = r.req_ready;
    o_resp_mem_valid = r.resp_valid;
    o_resp_mem_data = r.resp_data;
    o_resp_mem_fault = r.resp_error;

    vmsto.ar_valid = r.ar_valid;
    vmsto.ar_bits.addr = r.req_addr;
    vmsto.ar_bits.size = r.req_size;
    vmsto.ar_bits.len = r.req_len;
    vmsto.ar_user = r.user_count;
    vmsto.ar_bits.burst = AXI_BURST_INCR;
    vmsto.r_ready = r.r_ready;

    vmsto.aw_valid = r.aw_valid;
    vmsto.aw_bits.addr = r.req_addr;
    vmsto.aw_bits.size = r.req_size;
    vmsto.aw_bits.len = r.req_len;
    vmsto.aw_user = r.user_count;
    vmsto.aw_bits.burst = AXI_BURST_INCR;
    vmsto.w_valid = r.w_valid;
    vmsto.w_last = r.req_last;
    vmsto.w_data = r.req_wdata;
    vmsto.w_strb = r.req_wstrb;
    vmsto.w_user = r.user_count;
    vmsto.b_ready = r.b_ready;

    o_msto = vmsto;

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= axi_dma_r_reset;
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

endmodule: axi_dma
