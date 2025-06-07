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
#pragma once

#include <systemc.h>
#include "../ambalib/types_pnp.h"
#include "../ambalib/types_amba.h"
#include "video_sync.h"
#include "framebuf.h"
#include "../ambalib/axi_dma.h"

namespace debugger {

SC_MODULE(hdmi_top) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_in<bool> i_hdmi_clk;                                 // HDMI clock depends on resolution for 1366x768@60Hz ~83MHz
    sc_out<bool> o_hsync;                                   // Horizontal sync strob
    sc_out<bool> o_vsync;                                   // Vertical sync. strob
    sc_out<bool> o_de;                                      // Data enable strob
    sc_out<sc_uint<18>> o_data;                             // Output data in YCbCr format
    sc_out<bool> o_spdif;                                   // Sound channel
    sc_in<bool> i_spdif_out;                                // Reverse sound
    sc_in<bool> i_irq;                                      // Interrupt request from HDMI transmitter
    // DMA engine interface - System on Chip interface
    sc_out<dev_config_type> o_xmst_cfg;                     // HDMI DMA master interface descriptor
    sc_in<axi4_master_in_type> i_xmsti;
    sc_out<axi4_master_out_type> o_xmsto;

    void comb();

    hdmi_top(sc_module_name name,
             bool async_reset);
    virtual ~hdmi_top();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;

    sc_signal<bool> w_sync_hsync;
    sc_signal<bool> w_sync_vsync;
    sc_signal<bool> w_sync_de;
    sc_signal<sc_uint<11>> wb_sync_x;
    sc_signal<sc_uint<10>> wb_sync_y;
    sc_signal<sc_uint<24>> wb_sync_xy_total;
    sc_signal<bool> w_req_mem_ready;
    sc_signal<bool> w_req_mem_valid;
    sc_signal<bool> w_req_mem_write;                        // 0=read; 1=write operation
    sc_signal<sc_uint<12>> wb_req_mem_bytes;                // 0=4096 Bytes; 4=DWORD; 8=QWORD; ...
    sc_signal<sc_uint<24>> wb_req_mem_addr;                 // 16 MB allocated for framebuffer
    sc_signal<sc_uint<8>> wb_req_mem_strob;
    sc_signal<sc_uint<64>> wb_req_mem_data;
    sc_signal<bool> w_req_mem_last;
    sc_signal<bool> w_resp_mem_valid;
    sc_signal<bool> w_resp_mem_last;
    sc_signal<bool> w_resp_mem_fault_unused;
    sc_signal<sc_uint<24>> wb_resp_mem_addr;                // 16 MB allocated for framebuffer
    sc_signal<sc_uint<64>> wb_resp_mem_data;
    sc_signal<bool> w_resp_mem_ready;
    sc_signal<bool> w_dbg_valid_unused;
    sc_signal<sc_uint<64>> wb_dbg_payload_unused;

    video_sync *sync0;
    framebuf *fb0;
    axi_dma<24> *xdma0;

};

}  // namespace debugger

