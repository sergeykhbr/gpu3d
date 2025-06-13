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

#include "hdmi_top.h"
#include "api_core.h"

namespace debugger {

hdmi_top::hdmi_top(sc_module_name name,
                   bool async_reset,
                   sc_uint<12> WIDTH,
                   sc_uint<12> HEIGHT)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_hdmi_nrst("i_hdmi_nrst"),
    i_hdmi_clk("i_hdmi_clk"),
    o_hsync("o_hsync"),
    o_vsync("o_vsync"),
    o_de("o_de"),
    o_data("o_data"),
    o_spdif("o_spdif"),
    i_spdif_out("i_spdif_out"),
    i_irq("i_irq"),
    o_xmst_cfg("o_xmst_cfg"),
    i_xmsti("i_xmsti"),
    o_xmsto("o_xmsto") {

    async_reset_ = async_reset;
    WIDTH_ = WIDTH;
    HEIGHT_ = HEIGHT;
    sync0 = 0;
    fb0 = 0;
    rgb2y0 = 0;
    xdma0 = 0;

    sync0 = new video_sync("sync0",
                            async_reset,
                            WIDTH,
                            70,
                            143,
                            213,
                            HEIGHT,
                            3,
                            5,
                            24);
    sync0->i_nrst(i_hdmi_nrst);
    sync0->i_clk(i_hdmi_clk);
    sync0->o_hsync(w_sync_hsync);
    sync0->o_vsync(w_sync_vsync);
    sync0->o_de(w_sync_de);

    fb0 = new framebuf("fb0",
                        async_reset);
    fb0->i_nrst(i_hdmi_nrst);
    fb0->i_clk(i_hdmi_clk);
    fb0->i_hsync(w_sync_hsync);
    fb0->i_vsync(w_sync_vsync);
    fb0->i_de(w_sync_de);
    fb0->i_width_m1(wb_width_m1);
    fb0->i_height_m1(wb_height_m1);
    fb0->o_hsync(w_fb_hsync);
    fb0->o_vsync(w_fb_vsync);
    fb0->o_de(w_fb_de);
    fb0->o_rgb565(wb_fb_rgb565);
    fb0->i_req_2d_ready(w_req_mem_ready);
    fb0->o_req_2d_valid(w_req_mem_valid);
    fb0->o_req_2d_bytes(wb_req_mem_bytes);
    fb0->o_req_2d_addr(wb_req_mem_addr);
    fb0->i_resp_2d_valid(w_resp_mem_valid);
    fb0->i_resp_2d_last(w_resp_mem_last);
    fb0->i_resp_2d_addr(wb_resp_mem_addr);
    fb0->i_resp_2d_data(wb_resp_mem_data);
    fb0->o_resp_2d_ready(w_resp_mem_ready);

    rgb2y0 = new rgb2ycbcr("rgb2y0",
                            async_reset);
    rgb2y0->i_nrst(i_hdmi_nrst);
    rgb2y0->i_clk(i_hdmi_clk);
    rgb2y0->i_rgb565(wb_fb_rgb565);
    rgb2y0->i_hsync(w_fb_hsync);
    rgb2y0->i_vsync(w_fb_vsync);
    rgb2y0->i_de(w_fb_de);
    rgb2y0->o_ycbcr422(o_data);
    rgb2y0->o_hsync(o_hsync);
    rgb2y0->o_vsync(o_vsync);
    rgb2y0->o_de(o_de);

    xdma0 = new axi_dma<24>("xdma0",
                            async_reset,
                            1,
                            0x000080000000);
    xdma0->i_nrst(i_nrst);
    xdma0->i_clk(i_clk);
    xdma0->o_req_mem_ready(w_req_mem_ready);
    xdma0->i_req_mem_valid(w_req_mem_valid);
    xdma0->i_req_mem_write(w_req_mem_write);
    xdma0->i_req_mem_bytes(wb_req_mem_bytes);
    xdma0->i_req_mem_addr(wb_req_mem_addr);
    xdma0->i_req_mem_strob(wb_req_mem_strob);
    xdma0->i_req_mem_data(wb_req_mem_data);
    xdma0->i_req_mem_last(w_req_mem_last);
    xdma0->o_resp_mem_valid(w_resp_mem_valid);
    xdma0->o_resp_mem_last(w_resp_mem_last);
    xdma0->o_resp_mem_fault(w_resp_mem_fault_unused);
    xdma0->o_resp_mem_addr(wb_resp_mem_addr);
    xdma0->o_resp_mem_data(wb_resp_mem_data);
    xdma0->i_resp_mem_ready(w_resp_mem_ready);
    xdma0->i_msti(i_xmsti);
    xdma0->o_msto(o_xmsto);
    xdma0->o_dbg_valid(w_dbg_valid_unused);
    xdma0->o_dbg_payload(wb_dbg_payload_unused);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_hdmi_nrst;
    sensitive << i_hdmi_clk;
    sensitive << i_spdif_out;
    sensitive << i_irq;
    sensitive << i_xmsti;
    sensitive << wb_width_m1;
    sensitive << wb_height_m1;
    sensitive << w_sync_hsync;
    sensitive << w_sync_vsync;
    sensitive << w_sync_de;
    sensitive << w_fb_hsync;
    sensitive << w_fb_vsync;
    sensitive << w_fb_de;
    sensitive << wb_fb_rgb565;
    sensitive << w_req_mem_ready;
    sensitive << w_req_mem_valid;
    sensitive << w_req_mem_write;
    sensitive << wb_req_mem_bytes;
    sensitive << wb_req_mem_addr;
    sensitive << wb_req_mem_strob;
    sensitive << wb_req_mem_data;
    sensitive << w_req_mem_last;
    sensitive << w_resp_mem_valid;
    sensitive << w_resp_mem_last;
    sensitive << w_resp_mem_fault_unused;
    sensitive << wb_resp_mem_addr;
    sensitive << wb_resp_mem_data;
    sensitive << w_resp_mem_ready;
    sensitive << w_dbg_valid_unused;
    sensitive << wb_dbg_payload_unused;
}

hdmi_top::~hdmi_top() {
    if (sync0) {
        delete sync0;
    }
    if (fb0) {
        delete fb0;
    }
    if (rgb2y0) {
        delete rgb2y0;
    }
    if (xdma0) {
        delete xdma0;
    }
}

void hdmi_top::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_hdmi_nrst, i_hdmi_nrst.name());
        sc_trace(o_vcd, i_hdmi_clk, i_hdmi_clk.name());
        sc_trace(o_vcd, o_hsync, o_hsync.name());
        sc_trace(o_vcd, o_vsync, o_vsync.name());
        sc_trace(o_vcd, o_de, o_de.name());
        sc_trace(o_vcd, o_data, o_data.name());
        sc_trace(o_vcd, o_spdif, o_spdif.name());
        sc_trace(o_vcd, i_spdif_out, i_spdif_out.name());
        sc_trace(o_vcd, i_irq, i_irq.name());
        sc_trace(o_vcd, i_xmsti, i_xmsti.name());
        sc_trace(o_vcd, o_xmsto, o_xmsto.name());
    }

    if (sync0) {
        sync0->generateVCD(i_vcd, o_vcd);
    }
    if (fb0) {
        fb0->generateVCD(i_vcd, o_vcd);
    }
    if (rgb2y0) {
        rgb2y0->generateVCD(i_vcd, o_vcd);
    }
    if (xdma0) {
        xdma0->generateVCD(i_vcd, o_vcd);
    }
}

void hdmi_top::comb() {
    dev_config_type vb_xmst_cfg;
    axi4_master_out_type vb_xmsto;

    vb_xmst_cfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
    vb_xmst_cfg.descrtype = PNP_CFG_TYPE_MASTER;
    vb_xmst_cfg.vid = VENDOR_OPTIMITECH;
    vb_xmst_cfg.did = OPTIMITECH_HDMI_DMA;
    o_xmst_cfg = vb_xmst_cfg;
    o_spdif = 0;
    w_req_mem_write = 0;                                    // Always read
    wb_req_mem_strob = 0;
    wb_req_mem_data = 0;
    w_req_mem_last = 0;
    wb_width_m1 = (WIDTH_ - 1);
    wb_height_m1 = (HEIGHT_ - 1);
}

}  // namespace debugger

