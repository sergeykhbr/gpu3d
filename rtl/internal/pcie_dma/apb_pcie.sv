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

module apb_pcie #(
    parameter bit async_reset = 1'b0
)
(
    input logic i_clk,                                      // APB clock
    input logic i_nrst,                                     // Reset: active LOW
    input types_amba_pkg::mapinfo_type i_mapinfo,           // interconnect slot information
    output types_pnp_pkg::dev_config_type o_cfg,            // Device descriptor
    input types_amba_pkg::apb_in_type i_apbi,               // APB input interface
    output types_amba_pkg::apb_out_type o_apbo,             // APB output interface
    input logic [15:0] i_pcie_completer_id,                 // Bus, Device, Function
    input logic [3:0] i_dma_state,                          // DMA engine brief state
    input types_dma_pkg::pcie_dma64_in_type i_dbg_pcie_dmai // Debugging request from async fifo
);

import types_amba_pkg::*;
import types_pnp_pkg::*;
import types_dma_pkg::*;
import apb_pcie_pkg::*;

logic w_req_valid;
logic [31:0] wb_req_addr;
logic w_req_write;
logic [31:0] wb_req_wdata;
apb_pcie_registers r, rin;
apb_pcie_rxegisters rx, rxin;

apb_slv #(
    .async_reset(async_reset),
    .vid(VENDOR_OPTIMITECH),
    .did(OPTIMITECH_PCIE_CTRL)
) pslv0 (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_mapinfo(i_mapinfo),
    .o_cfg(o_cfg),
    .i_apbi(i_apbi),
    .o_apbo(o_apbo),
    .o_req_valid(w_req_valid),
    .o_req_addr(wb_req_addr),
    .o_req_write(w_req_write),
    .o_req_wdata(wb_req_wdata),
    .i_resp_valid(r.resp_valid),
    .i_resp_rdata(r.resp_rdata),
    .i_resp_err(r.resp_err)
);

always_comb
begin: comb_proc
    apb_pcie_registers v;
    apb_pcie_rxegisters vx;
    logic [31:0] vb_rdata;

    vb_rdata = '0;

    v = r;
    for (int i = 0; i < 16; i++) begin
        vx.req_data_arr[i] = rx.req_data_arr[i];
    end


    if (i_dbg_pcie_dmai.valid == 1'b1) begin
        v.req_cnt = (r.req_cnt + 1);
        vx.req_data_arr[int'(r.req_cnt)] = i_dbg_pcie_dmai.data;
    end

    v.resp_err = 1'b0;
    // Registers access:
    if (wb_req_addr[11: 2] == 10'd0) begin
        // 0x00: link status
        vb_rdata[3: 0] = i_dma_state;
    end else if (wb_req_addr[11: 2] == 10'd1) begin
        // 0x04: bus, device, function
        vb_rdata[15: 0] = i_pcie_completer_id;
    end else if (wb_req_addr[11: 2] == 10'd2) begin
        // 0x08: request counter
        vb_rdata[3: 0] = r.req_cnt;
    end else if (wb_req_addr[11: 7] == 5'd1) begin
        // 0x040..0x04F: debug buffer
        if (wb_req_addr[2] == 1'b0) begin
            vb_rdata = rx.req_data_arr[int'(wb_req_addr[6: 3])][31: 0];
        end else begin
            vb_rdata = rx.req_data_arr[int'(wb_req_addr[6: 3])][63: 32];
        end
    end

    v.resp_valid = w_req_valid;
    v.resp_rdata = vb_rdata;

    if (~async_reset && i_nrst == 1'b0) begin
        v = apb_pcie_r_reset;
    end

    rin = v;
    for (int i = 0; i < 16; i++) begin
        rxin.req_data_arr[i] = vx.req_data_arr[i];
    end
end: comb_proc


generate
    if (async_reset) begin: async_rst_gen

        always_ff @(posedge i_clk, negedge i_nrst) begin: rg_proc
            if (i_nrst == 1'b0) begin
                r <= apb_pcie_r_reset;
            end else begin
                r <= rin;
            end
        end: rg_proc

        always_ff @(posedge i_clk) begin: rxg_proc
            for (int i = 0; i < 16; i++) begin
                rx.req_data_arr[i] <= rxin.req_data_arr[i];
            end
        end: rxg_proc

    end: async_rst_gen
    else begin: no_rst_gen

        always_ff @(posedge i_clk) begin: rg_proc
            r <= rin;
        end: rg_proc

        always_ff @(posedge i_clk) begin: rxg_proc
            for (int i = 0; i < 16; i++) begin
                rx.req_data_arr[i] <= rxin.req_data_arr[i];
            end
        end: rxg_proc

    end: no_rst_gen
endgenerate

endmodule: apb_pcie
