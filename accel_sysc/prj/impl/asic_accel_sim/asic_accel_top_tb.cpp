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

#include "asic_accel_top_tb.h"
#include "api_core.h"

namespace debugger {

asic_accel_top_tb::asic_accel_top_tb(sc_module_name name)
    : sc_module(name) {

    clk0 = 0;
    uart1 = 0;
    jtag0 = 0;
    iosda0 = 0;
    i2c0 = 0;
    tt = 0;

    clk0 = new pll_generic("clk0",
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

    jtag0 = new jtag_app("jtag0");
    jtag0->o_trst(w_jtag_trst);
    jtag0->o_tck(w_jtag_tck);
    jtag0->o_tms(w_jtag_tms);
    jtag0->o_tdo(w_jtag_tdi);
    jtag0->i_tdi(w_jtag_tdo);

    tt = new asic_accel_top("tt",
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
    tt->o_ddr3_reset_n(w_ddr3_reset_n);
    tt->o_ddr3_ck_n(w_ddr3_ck_n);
    tt->o_ddr3_ck_p(w_ddr3_ck_p);
    tt->o_ddr3_cke(w_ddr3_cke);
    tt->o_ddr3_cs_n(w_ddr3_cs_n);
    tt->o_ddr3_ras_n(w_ddr3_ras_n);
    tt->o_ddr3_cas_n(w_ddr3_cas_n);
    tt->o_ddr3_we_n(w_ddr3_we_n);
    tt->o_ddr3_dm(wb_ddr3_dm);
    tt->o_ddr3_ba(wb_ddr3_ba);
    tt->o_ddr3_addr(wb_ddr3_addr);
    tt->io_ddr3_dq(wb_ddr3_dq);
    tt->io_ddr3_dqs_n(wb_ddr3_dqs_n);
    tt->io_ddr3_dqs_p(wb_ddr3_dqs_p);
    tt->o_ddr3_odt(w_ddr3_odt);

    SC_THREAD(init);

    SC_METHOD(test);
    sensitive << w_sclk_p.posedge_event();
}

asic_accel_top_tb::~asic_accel_top_tb() {
    if (clk0) {
        delete clk0;
    }
    if (uart1) {
        delete uart1;
    }
    if (jtag0) {
        delete jtag0;
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

void asic_accel_top_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
    if (uart1) {
        uart1->generateVCD(i_vcd, o_vcd);
    }
    if (jtag0) {
        jtag0->generateVCD(i_vcd, o_vcd);
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

void asic_accel_top_tb::init() {
    w_nrst = 0;
    wait(static_cast<int>(200.0), SC_NS);
    w_nrst = 1;
}

void asic_accel_top_tb::test() {
    if (w_nrst.read() == 0) {
        wb_clk_cnt = 0;
    } else {
        wb_clk_cnt = (wb_clk_cnt + 1);
    }

    w_sclk_n = (!w_sclk_p.read());
    w_hdmi_spdif_out = 0;
    w_hdmi_int = 0;
}

}  // namespace debugger

