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
#include "../../common/vips/clk/vip_clk.h"
#include "../../common/vips/uart/vip_uart_top.h"
#include "../../common/vips/jtag/jtag_app.h"
#include "../../../rtl/sim/io/iobuf_tech.h"
#include "../../common/vips/i2c/vip_i2c_s.h"
#include "../asic_accel/asic_accel_top.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(asic_accel_top_tb) {
 public:

    void test();

    asic_accel_top_tb(sc_module_name name);
    virtual ~asic_accel_top_tb();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    static const int sim_uart_speedup_rate = 3;             // 0=no speed-up, 1=2x speed, 2=4x speed, 3=8x speed, 4=16x speed, .. etc
    static const int sim_uart_baudrate = (115200 * (1 << sim_uart_speedup_rate));

    sc_signal<bool> w_rst;                                  // Power-on system reset active HIGH
    sc_signal<bool> w_nrst;
    sc_signal<bool> w_sclk_p;
    sc_signal<bool> w_sclk_n;
    sc_signal<sc_uint<12>> wb_gpio;
    sc_signal<bool> w_jtag_trst;
    sc_signal<bool> w_jtag_tck;
    sc_signal<bool> w_jtag_tms;
    sc_signal<bool> w_jtag_tdi;
    sc_signal<bool> w_jtag_tdo;
    sc_signal<bool> w_jtag_vref;
    sc_signal<bool> w_uart1_rd;
    sc_signal<bool> w_uart1_td;
    sc_signal<bool> w_uart1_loopback_ena;
    sc_signal<bool> w_i2c_scl;
    sc_signal<bool, SC_UNCHECKED_WRITERS> w_i2c_sda;
    sc_signal<bool> w_i2c_nreset;
    sc_signal<bool> w_hdmi_clk;
    sc_signal<bool> w_hdmi_hsync;
    sc_signal<bool> w_hdmi_vsync;
    sc_signal<bool> w_hdmi_de;
    sc_signal<sc_uint<18>> wb_hdmi_d;
    sc_signal<bool> w_hdmi_spdif;
    sc_signal<bool> w_hdmi_spdif_out;
    sc_signal<bool> w_hdmi_int;
    sc_signal<bool> w_bufo_i2c0_sda;
    sc_signal<bool> w_vipo_i2c0_sda;
    sc_signal<bool> w_vipo_i2c0_sda_dir;
    sc_uint<32> wb_clk_cnt;

    vip_clk *clk0;
    vip_uart_top *uart1;
    jtag_app *jtag0;
    iobuf_tech *iosda0;
    vip_i2c_s *i2c0;
    asic_accel_top *tt;

};

}  // namespace debugger

