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

namespace debugger {

SC_MODULE(video_sync) {
 public:
    sc_in<bool> i_nrst;                                     // Reset: active LOW
    sc_in<bool> i_clk;                                      // CPU clock
    sc_out<bool> o_hsync;                                   // Horisontal sync pulse
    sc_out<bool> o_vsync;                                   // Vertical sync pulse
    sc_out<bool> o_de;                                      // Data enable, HIGH in active zone 1366x768 screen resolution

    void comb();
    void registers();

    video_sync(sc_module_name name,
               bool async_reset,
               int H_ACTIVE,
               int H_FRONT,
               int H_SYNC,
               int H_BACK,
               int V_ACTIVE,
               int V_FRONT,
               int V_SYNC,
               int V_BACK);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;
    int H_ACTIVE_;
    int H_FRONT_;
    int H_SYNC_;
    int H_BACK_;
    int V_ACTIVE_;
    int V_FRONT_;
    int V_SYNC_;
    int V_BACK_;
    int H_TOTAL;
    int V_TOTAL;

    struct video_sync_registers {
        sc_signal<sc_uint<11>> h_count;
        sc_signal<sc_uint<10>> v_count;
        sc_signal<bool> h_sync;
        sc_signal<bool> v_sync;
        sc_signal<bool> de;
        sc_signal<sc_uint<11>> x_pix;
        sc_signal<sc_uint<10>> y_pix;
    };

    void video_sync_r_reset(video_sync_registers& iv) {
        iv.h_count = 0;
        iv.v_count = 0;
        iv.h_sync = 0;
        iv.v_sync = 0;
        iv.de = 0;
        iv.x_pix = 0;
        iv.y_pix = 0;
    }

    video_sync_registers v;
    video_sync_registers r;

};

}  // namespace debugger

