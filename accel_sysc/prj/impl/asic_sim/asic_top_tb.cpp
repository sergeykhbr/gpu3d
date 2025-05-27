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

#include "asic_top_tb.h"
#include "api_core.h"

namespace debugger {

asic_top_tb::asic_top_tb(sc_module_name name)
    : sc_module(name) {

    clk0 = 0;
    uart1 = 0;
    iosda0 = 0;
    i2c0 = 0;
    tt = 0;

    clk0 = new vip_clk("clk0",
                        25.0);
    clk0->o_clk(w_sclk_p);

    iosda0 = new iobuf_tech("iosda0");
    iosda0->io(w_i2c_sda);
    iosda0->o(w_bufo_i2c0_sda);
    iosda0->i(w_vipo_i2c0_sda);
    iosda0->t(w_vipo_i2c0_sda_dir);

    i2c0 = new vip_i2c_s("i2c0",
                          0);
    i2c0->i_clk(w_sclk_p);
    i2c0->i_nrst(w_nrst);
    i2c0->i_scl(w_i2c_scl);
    i2c0->i_sda(w_bufo_i2c0_sda);
    i2c0->o_sda(w_vipo_i2c0_sda);
    i2c0->o_sda_dir(w_vipo_i2c0_sda_dir);

    uart1 = new vip_uart_top("uart1",
                              1,
                              0,
                              sim_uart_baudrate,
                              8,
                              "uart1");
    uart1->i_nrst(w_nrst);
    uart1->i_rx(w_uart1_td);
    uart1->o_tx(w_uart1_rd);
    uart1->i_loopback_ena(w_uart1_loopback_ena);

    tt = new asic_top("tt",
                       CFG_ASYNC_RESET,
                       sim_uart_speedup_rate);
    tt->i_rst(w_rst);
    tt->i_sclk_p(w_sclk_p);
    tt->i_sclk_n(w_sclk_n);
    tt->io_gpio(wb_gpio);
    tt->i_jtag_trst(w_jtag_trst);
    tt->i_jtag_tck(w_jtag_tck);
    tt->i_jtag_tms(w_jtag_tms);
    tt->i_jtag_tdi(w_jtag_tdi);
    tt->o_jtag_tdo(w_jtag_tdo);
    tt->o_jtag_vref(w_jtag_vref);
    tt->i_uart1_rd(w_uart1_rd);
    tt->o_uart1_td(w_uart1_td);
    tt->o_i2c0_scl(w_i2c_scl);
    tt->io_i2c0_sda(w_i2c_sda);
    tt->o_i2c0_nreset(w_i2c_nreset);
    tt->o_hdmi_clk(w_hdmi_clk);
    tt->o_hdmi_hsync(w_hdmi_hsync);
    tt->o_hdmi_vsync(w_hdmi_vsync);
    tt->o_hdmi_de(w_hdmi_de);
    tt->o_hdmi_d(wb_hdmi_d);
    tt->o_hdmi_spdif(w_hdmi_spdif);
    tt->i_hdmi_spdif_out(w_hdmi_spdif_out);
    tt->i_hdmi_int(w_hdmi_int);

    SC_METHOD(test);
    sensitive << w_sclk_p.posedge_event();
}

asic_top_tb::~asic_top_tb() {
    if (clk0) {
        delete clk0;
    }
    if (uart1) {
        delete uart1;
    }
    if (iosda0) {
        delete iosda0;
    }
    if (i2c0) {
        delete i2c0;
    }
    if (tt) {
        delete tt;
    }
}

void asic_top_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
    if (uart1) {
        uart1->generateVCD(i_vcd, o_vcd);
    }
    if (iosda0) {
        iosda0->generateVCD(i_vcd, o_vcd);
    }
    if (i2c0) {
        i2c0->generateVCD(i_vcd, o_vcd);
    }
    if (tt) {
        tt->generateVCD(i_vcd, o_vcd);
    }
}

void asic_top_tb::test() {
    wb_clk_cnt = (wb_clk_cnt + 1);
    if (wb_clk_cnt < 10) {
        w_rst = 1;
    } else {
        w_rst = 0;
    }

    w_nrst = (!w_rst.read());
    w_sclk_n = (!w_sclk_p.read());
    w_hdmi_spdif_out = 0;
    w_hdmi_int = 0;
}

}  // namespace debugger

