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

module hdmi_top #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic i_hdmi_nrst,                                // Reset: active LOW. Must be HIGH only after DDR 
    input logic i_hdmi_clk,                                 // HDMI clock depends on resolution for 1366x768@60Hz ~83MHz
    output logic o_hsync,                                   // Horizontal sync strob
    output logic o_vsync,                                   // Vertical sync. strob
    output logic o_de,                                      // Data enable strob
    output logic [17:0] o_data,                             // Output data in YCbCr format
    output logic o_spdif,                                   // Sound channel
    input logic i_spdif_out,                                // Reverse sound
    input logic i_irq,                                      // Interrupt request from HDMI transmitter
    // DMA engine interface - System on Chip interface
    output types_pnp_pkg::dev_config_type o_xmst_cfg,       // HDMI DMA master interface descriptor
    input types_amba_pkg::axi4_master_in_type i_xmsti,
    output types_amba_pkg::axi4_master_out_type o_xmsto
);

import types_pnp_pkg::*;
import types_amba_pkg::*;
logic w_sync_hsync;
logic w_sync_vsync;
logic w_sync_de;
logic [10:0] wb_sync_x;
logic [9:0] wb_sync_y;
logic [23:0] wb_sync_xy_total;
logic w_fb_hsync;
logic w_fb_vsync;
logic w_fb_de;
logic [15:0] wb_fb_rgb565;
logic w_req_mem_ready;
logic w_req_mem_valid;
logic w_req_mem_write;                                      // 0=read; 1=write operation
logic [11:0] wb_req_mem_bytes;                              // 0=4096 Bytes; 4=DWORD; 8=QWORD; ...
logic [23:0] wb_req_mem_addr;                               // 16 MB allocated for framebuffer
logic [7:0] wb_req_mem_strob;
logic [63:0] wb_req_mem_data;
logic w_req_mem_last;
logic w_resp_mem_valid;
logic w_resp_mem_last;
logic w_resp_mem_fault_unused;
logic [23:0] wb_resp_mem_addr;                              // 16 MB allocated for framebuffer
logic [63:0] wb_resp_mem_data;
logic w_resp_mem_ready;
logic w_dbg_valid_unused;
logic [63:0] wb_dbg_payload_unused;

video_sync #(
    .async_reset(async_reset),
    .H_ACTIVE(1366),
    .H_FRONT(70),
    .H_SYNC(143),
    .H_BACK(213),
    .V_ACTIVE(768),
    .V_FRONT(3),
    .V_SYNC(5),
    .V_BACK(24)
) sync0 (
    .i_nrst(i_hdmi_nrst),
    .i_clk(i_hdmi_clk),
    .o_hsync(w_sync_hsync),
    .o_vsync(w_sync_vsync),
    .o_de(w_sync_de),
    .o_x(wb_sync_x),
    .o_y(wb_sync_y),
    .o_xy_total(wb_sync_xy_total)
);

framebuf #(
    .async_reset(async_reset)
) fb0 (
    .i_nrst(i_hdmi_nrst),
    .i_clk(i_hdmi_clk),
    .i_hsync(w_sync_hsync),
    .i_vsync(w_sync_vsync),
    .i_de(w_sync_de),
    .i_x(wb_sync_x),
    .i_y(wb_sync_y),
    .i_xy_total(wb_sync_xy_total),
    .o_hsync(w_fb_hsync),
    .o_vsync(w_fb_vsync),
    .o_de(w_fb_de),
    .o_rgb565(wb_fb_rgb565),
    .i_req_2d_ready(w_req_mem_ready),
    .o_req_2d_valid(w_req_mem_valid),
    .o_req_2d_bytes(wb_req_mem_bytes),
    .o_req_2d_addr(wb_req_mem_addr),
    .i_resp_2d_valid(w_resp_mem_valid),
    .i_resp_2d_last(w_resp_mem_last),
    .i_resp_2d_addr(wb_resp_mem_addr),
    .i_resp_2d_data(wb_resp_mem_data),
    .o_resp_2d_ready(w_resp_mem_ready)
);

rgb2ycbcr #(
    .async_reset(async_reset)
) rgb2y0 (
    .i_nrst(i_hdmi_nrst),
    .i_clk(i_hdmi_clk),
    .i_rgb565(wb_fb_rgb565),
    .i_hsync(w_fb_hsync),
    .i_vsync(w_fb_vsync),
    .i_de(w_fb_de),
    .o_ycbcr422(o_data),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_de(o_de)
);

axi_dma #(
    .abits(24),
    .async_reset(async_reset),
    .userbits(1),
    .base_offset(48'h000080000000)
) xdma0 (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .o_req_mem_ready(w_req_mem_ready),
    .i_req_mem_valid(w_req_mem_valid),
    .i_req_mem_write(w_req_mem_write),
    .i_req_mem_bytes(wb_req_mem_bytes),
    .i_req_mem_addr(wb_req_mem_addr),
    .i_req_mem_strob(wb_req_mem_strob),
    .i_req_mem_data(wb_req_mem_data),
    .i_req_mem_last(w_req_mem_last),
    .o_resp_mem_valid(w_resp_mem_valid),
    .o_resp_mem_last(w_resp_mem_last),
    .o_resp_mem_fault(w_resp_mem_fault_unused),
    .o_resp_mem_addr(wb_resp_mem_addr),
    .o_resp_mem_data(wb_resp_mem_data),
    .i_resp_mem_ready(w_resp_mem_ready),
    .i_msti(i_xmsti),
    .o_msto(o_xmsto),
    .o_dbg_valid(w_dbg_valid_unused),
    .o_dbg_payload(wb_dbg_payload_unused)
);

always_comb
begin: comb_proc
    dev_config_type vb_xmst_cfg;
    axi4_master_out_type vb_xmsto;

    vb_xmst_cfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
    vb_xmst_cfg.descrtype = PNP_CFG_TYPE_MASTER;
    vb_xmst_cfg.vid = VENDOR_OPTIMITECH;
    vb_xmst_cfg.did = OPTIMITECH_HDMI_DMA;
    o_xmst_cfg = vb_xmst_cfg;
end: comb_proc

assign o_spdif = 1'b0;
assign w_req_mem_write = 1'b0;                              // Always read
assign wb_req_mem_strob = 8'd0;
assign wb_req_mem_data = '0;
assign w_req_mem_last = 1'b0;

endmodule: hdmi_top
