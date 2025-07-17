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

#include "asic_accel_top.h"
#include "api_core.h"

namespace debugger {

asic_accel_top::asic_accel_top(sc_module_name name,
                               bool async_reset,
                               int sim_uart_speedup_rate)
    : sc_module(name),
    i_rst("i_rst"),
    i_sclk_p("i_sclk_p"),
    i_sclk_n("i_sclk_n"),
    io_gpio("io_gpio"),
    i_jtag_trst("i_jtag_trst"),
    i_jtag_tck("i_jtag_tck"),
    i_jtag_tms("i_jtag_tms"),
    i_jtag_tdi("i_jtag_tdi"),
    o_jtag_tdo("o_jtag_tdo"),
    o_jtag_vref("o_jtag_vref"),
    i_uart1_rd("i_uart1_rd"),
    o_uart1_td("o_uart1_td"),
    o_i2c0_scl("o_i2c0_scl"),
    io_i2c0_sda("io_i2c0_sda"),
    o_i2c0_nreset("o_i2c0_nreset"),
    o_hdmi_clk("o_hdmi_clk"),
    o_hdmi_hsync("o_hdmi_hsync"),
    o_hdmi_vsync("o_hdmi_vsync"),
    o_hdmi_de("o_hdmi_de"),
    o_hdmi_d("o_hdmi_d"),
    o_hdmi_spdif("o_hdmi_spdif"),
    i_hdmi_spdif_out("i_hdmi_spdif_out"),
    i_hdmi_int("i_hdmi_int"),
    o_ddr3_reset_n("o_ddr3_reset_n"),
    o_ddr3_ck_n("o_ddr3_ck_n"),
    o_ddr3_ck_p("o_ddr3_ck_p"),
    o_ddr3_cke("o_ddr3_cke"),
    o_ddr3_cs_n("o_ddr3_cs_n"),
    o_ddr3_ras_n("o_ddr3_ras_n"),
    o_ddr3_cas_n("o_ddr3_cas_n"),
    o_ddr3_we_n("o_ddr3_we_n"),
    o_ddr3_dm("o_ddr3_dm"),
    o_ddr3_ba("o_ddr3_ba"),
    o_ddr3_addr("o_ddr3_addr"),
    io_ddr3_dq("io_ddr3_dq"),
    io_ddr3_dqs_n("io_ddr3_dqs_n"),
    io_ddr3_dqs_p("io_ddr3_dqs_p"),
    o_ddr3_odt("o_ddr3_odt") {

    async_reset_ = async_reset;
    sim_uart_speedup_rate_ = sim_uart_speedup_rate;
    iclk0 = 0;
    oi2c0scl = 0;
    oi2c0nreset = 0;
    ioi2c0sda = 0;
    ohdmiclk = 0;
    ohdmihsync = 0;
    ohdmivsync = 0;
    ohdmide = 0;
    ohdmid = 0;
    ohdmispdif = 0;
    ihdmispdif = 0;
    ihdmiint = 0;
    pll0 = 0;
    prci0 = 0;
    ddr3 = 0;
    soc0 = 0;

    iclk0 = new ids_tech("iclk0");
    iclk0->i_clk_p(i_sclk_p);
    iclk0->i_clk_n(i_sclk_n);
    iclk0->o_clk(ib_clk_tcxo);

    // ======== HDMI I2C interface ========
    oi2c0scl = new obuf_tech("oi2c0scl");
    oi2c0scl->i(ob_i2c0_scl);
    oi2c0scl->o(o_i2c0_scl);

    oi2c0nreset = new obuf_tech("oi2c0nreset");
    oi2c0nreset->i(ob_i2c0_nreset);
    oi2c0nreset->o(o_i2c0_nreset);

    ioi2c0sda = new iobuf_tech("ioi2c0sda");
    ioi2c0sda->io(io_i2c0_sda);
    ioi2c0sda->o(ib_i2c0_sda);
    ioi2c0sda->i(ob_i2c0_sda);
    ioi2c0sda->t(ob_i2c0_sda_direction);

    // ======== HDMI data buffer ========
    ohdmiclk = new obuf_tech("ohdmiclk");
    ohdmiclk->i(w_sys_clk);
    ohdmiclk->o(o_hdmi_clk);

    ohdmihsync = new obuf_tech("ohdmihsync");
    ohdmihsync->i(ob_hdmi_hsync);
    ohdmihsync->o(o_hdmi_hsync);

    ohdmivsync = new obuf_tech("ohdmivsync");
    ohdmivsync->i(ob_hdmi_vsync);
    ohdmivsync->o(o_hdmi_vsync);

    ohdmide = new obuf_tech("ohdmide");
    ohdmide->i(ob_hdmi_de);
    ohdmide->o(o_hdmi_de);

    ohdmid = new obuf_arr_tech<18>("ohdmid");
    ohdmid->i(ob_hdmi_d);
    ohdmid->o(o_hdmi_d);

    ohdmispdif = new obuf_tech("ohdmispdif");
    ohdmispdif->i(ob_hdmi_spdif);
    ohdmispdif->o(o_hdmi_spdif);

    ihdmispdif = new ibuf_tech("ihdmispdif");
    ihdmispdif->i(i_hdmi_spdif_out);
    ihdmispdif->o(ib_hdmi_spdif_out);

    ihdmiint = new ibuf_tech("ihdmiint");
    ihdmiint->i(i_hdmi_int);
    ihdmiint->o(ib_hdmi_int);

    pll0 = new SysPLL_tech("pll0");
    pll0->i_reset(i_rst);
    pll0->i_clk_tcxo(ib_clk_tcxo);
    pll0->o_clk_sys(w_sys_clk);
    pll0->o_clk_ddr(w_ddr_clk);
    pll0->o_clk_ddr_phy(w_ddr_phy_clk);
    pll0->o_clk_pcie(w_pcie_clk);
    pll0->o_locked(w_pll_lock);

    prci0 = new apb_prci("prci0",
                          async_reset);
    prci0->i_clk(ib_clk_tcxo);
    prci0->i_pwrreset(i_rst);
    prci0->i_dmireset(w_dmreset);
    prci0->i_sys_locked(w_pll_lock);
    prci0->i_ddr_locked(w_ddr3_init_calib_done);
    prci0->i_pcie_phy_rst(w_pcie_user_rst);
    prci0->i_pcie_phy_clk(w_pcie_user_clk);
    prci0->i_pcie_phy_lnk_up(w_pcie_phy_lnk_up);
    prci0->o_sys_rst(w_sys_rst);
    prci0->o_sys_nrst(w_sys_nrst);
    prci0->o_dbg_nrst(w_dbg_nrst);
    prci0->o_pcie_nrst(w_pcie_nrst);
    prci0->o_hdmi_nrst(w_hdmi_nrst);
    prci0->i_mapinfo(prci_pmapinfo);
    prci0->o_cfg(prci_dev_cfg);
    prci0->i_apbi(prci_apbi);
    prci0->o_apbo(prci_apbo);

    soc0 = new accel_soc("soc0",
                          async_reset,
                          sim_uart_speedup_rate);
    soc0->i_sys_nrst(w_sys_nrst);
    soc0->i_sys_clk(w_sys_clk);
    soc0->i_cpu_nrst(w_sys_nrst);
    soc0->i_cpu_clk(w_sys_clk);
    soc0->i_apb_nrst(w_sys_nrst);
    soc0->i_apb_clk(w_sys_clk);
    soc0->i_dbg_nrst(w_dbg_nrst);
    soc0->i_ddr_nrst(w_ddr_ui_nrst);
    soc0->i_ddr_clk(w_ddr_ui_clk);
    soc0->i_gpio(ib_gpio_ipins);
    soc0->o_gpio(ob_gpio_opins);
    soc0->o_gpio_dir(ob_gpio_direction);
    soc0->i_jtag_trst(i_jtag_trst);
    soc0->i_jtag_tck(i_jtag_tck);
    soc0->i_jtag_tms(i_jtag_tms);
    soc0->i_jtag_tdi(i_jtag_tdi);
    soc0->o_jtag_tdo(o_jtag_tdo);
    soc0->o_jtag_vref(o_jtag_vref);
    soc0->i_uart1_rd(i_uart1_rd);
    soc0->o_uart1_td(o_uart1_td);
    soc0->o_i2c0_scl(ob_i2c0_scl);
    soc0->o_i2c0_sda(ob_i2c0_sda);
    soc0->o_i2c0_sda_dir(ob_i2c0_sda_direction);
    soc0->i_i2c0_sda(ib_i2c0_sda);
    soc0->o_i2c0_nreset(ob_i2c0_nreset);
    soc0->i_hdmi_nrst(w_hdmi_nrst);
    soc0->i_hdmi_clk(w_sys_clk);
    soc0->o_hdmi_hsync(ob_hdmi_hsync);
    soc0->o_hdmi_vsync(ob_hdmi_vsync);
    soc0->o_hdmi_de(ob_hdmi_de);
    soc0->o_hdmi_d(ob_hdmi_d);
    soc0->o_hdmi_spdif(ob_hdmi_spdif);
    soc0->i_hdmi_spdif_out(ib_hdmi_spdif_out);
    soc0->i_hdmi_int(ib_hdmi_int);
    soc0->o_dmreset(w_dmreset);
    soc0->o_prci_pmapinfo(prci_pmapinfo);
    soc0->i_prci_pdevcfg(prci_dev_cfg);
    soc0->o_prci_apbi(prci_apbi);
    soc0->i_prci_apbo(prci_apbo);
    soc0->o_ddr_aw_id(wb_ddr_aw_id);
    soc0->o_ddr_aw_addr(wb_ddr_aw_addr);
    soc0->o_ddr_aw_len(wb_ddr_aw_len);
    soc0->o_ddr_aw_size(wb_ddr_aw_size);
    soc0->o_ddr_aw_burst(wb_ddr_aw_burst);
    soc0->o_ddr_aw_lock(w_ddr_aw_lock);
    soc0->o_ddr_aw_cache(wb_ddr_aw_cache);
    soc0->o_ddr_aw_prot(wb_ddr_aw_prot);
    soc0->o_ddr_aw_qos(wb_ddr_aw_qos);
    soc0->o_ddr_aw_valid(w_ddr_aw_valid);
    soc0->i_ddr_aw_ready(w_ddr_aw_ready);
    soc0->o_ddr_w_data(wb_ddr_w_data);
    soc0->o_ddr_w_strb(wb_ddr_w_strb);
    soc0->o_ddr_w_last(w_ddr_w_last);
    soc0->o_ddr_w_valid(w_ddr_w_valid);
    soc0->i_ddr_w_ready(w_ddr_w_ready);
    soc0->o_ddr_b_ready(w_ddr_b_ready);
    soc0->i_ddr_b_id(wb_ddr_b_id);
    soc0->i_ddr_b_resp(wb_ddr_b_resp);
    soc0->i_ddr_b_valid(w_ddr_b_valid);
    soc0->o_ddr_ar_id(wb_ddr_ar_id);
    soc0->o_ddr_ar_addr(wb_ddr_ar_addr);
    soc0->o_ddr_ar_len(wb_ddr_ar_len);
    soc0->o_ddr_ar_size(wb_ddr_ar_size);
    soc0->o_ddr_ar_burst(wb_ddr_ar_burst);
    soc0->o_ddr_ar_lock(w_ddr_ar_lock);
    soc0->o_ddr_ar_cache(wb_ddr_ar_cache);
    soc0->o_ddr_ar_prot(wb_ddr_ar_prot);
    soc0->o_ddr_ar_qos(wb_ddr_ar_qos);
    soc0->o_ddr_ar_valid(w_ddr_ar_valid);
    soc0->i_ddr_ar_ready(w_ddr_ar_ready);
    soc0->o_ddr_r_ready(w_ddr_r_ready);
    soc0->i_ddr_r_id(wb_ddr_r_id);
    soc0->i_ddr_r_data(wb_ddr_r_data);
    soc0->i_ddr_r_resp(wb_ddr_r_resp);
    soc0->i_ddr_r_last(w_ddr_r_last);
    soc0->i_ddr_r_valid(w_ddr_r_valid);
    soc0->i_ddr_app_init_calib_done(w_ddr3_init_calib_done);
    soc0->i_ddr_app_temp(wb_ddr3_temperature);
    soc0->o_ddr_app_sr_req(w_ddr_app_sr_req);
    soc0->o_ddr_app_ref_req(w_ddr_app_ref_req);
    soc0->o_ddr_app_zq_req(w_ddr_app_zq_req);
    soc0->i_ddr_app_sr_active(w_ddr_app_sr_active);
    soc0->i_ddr_app_ref_ack(w_ddr_app_ref_ack);
    soc0->i_ddr_app_zq_ack(w_ddr_app_zq_ack);
    soc0->i_pcie_clk(w_pcie_user_clk);
    soc0->i_pcie_nrst(w_pcie_nrst);
    soc0->i_pcie_completer_id(wb_pcie_completer_id);
    soc0->o_pcie_dmao(pcie_dmao);
    soc0->i_pcie_dmai(pcie_dmai);

    // ----------------------------------------
    // External IPs
    ddr3 = new ddr3_tech<14,
                         3,
                         8,
                         0,
                         30,
                         5>("ddr3");
    ddr3->i_nrst(w_sys_nrst);
    ddr3->i_ctrl_clk(w_ddr_clk);
    ddr3->i_phy_clk(w_ddr_phy_clk);
    ddr3->i_ref_clk200(ib_clk_tcxo);
    ddr3->o_ui_nrst(w_ddr_ui_nrst);
    ddr3->o_ui_clk(w_ddr_ui_clk);
    ddr3->o_ddr3_reset_n(o_ddr3_reset_n);
    ddr3->o_ddr3_ck_n(o_ddr3_ck_n);
    ddr3->o_ddr3_ck_p(o_ddr3_ck_p);
    ddr3->o_ddr3_cke(o_ddr3_cke);
    ddr3->o_ddr3_cs_n(o_ddr3_cs_n);
    ddr3->o_ddr3_ras_n(o_ddr3_ras_n);
    ddr3->o_ddr3_cas_n(o_ddr3_cas_n);
    ddr3->o_ddr3_we_n(o_ddr3_we_n);
    ddr3->o_ddr3_dm(o_ddr3_dm);
    ddr3->o_ddr3_ba(o_ddr3_ba);
    ddr3->o_ddr3_addr(o_ddr3_addr);
    ddr3->io_ddr3_dq(io_ddr3_dq);
    ddr3->io_ddr3_dqs_n(io_ddr3_dqs_n);
    ddr3->io_ddr3_dqs_p(io_ddr3_dqs_p);
    ddr3->o_ddr3_odt(o_ddr3_odt);
    ddr3->o_init_calib_done(w_ddr3_init_calib_done);
    ddr3->o_temperature(wb_ddr3_temperature);
    ddr3->i_sr_req(w_ddr_app_sr_req);
    ddr3->i_ref_req(w_ddr_app_ref_req);
    ddr3->i_zq_req(w_ddr_app_zq_req);
    ddr3->o_sr_active(w_ddr_app_sr_active);
    ddr3->o_ref_ack(w_ddr_app_ref_ack);
    ddr3->o_zq_ack(w_ddr_app_zq_ack);
    ddr3->i_aw_id(wb_ddr_aw_id);
    ddr3->i_aw_addr(wb_ddr_aw_addr);
    ddr3->i_aw_len(wb_ddr_aw_len);
    ddr3->i_aw_size(wb_ddr_aw_size);
    ddr3->i_aw_burst(wb_ddr_aw_burst);
    ddr3->i_aw_lock(w_ddr_aw_lock);
    ddr3->i_aw_cache(wb_ddr_aw_cache);
    ddr3->i_aw_prot(wb_ddr_aw_prot);
    ddr3->i_aw_qos(wb_ddr_aw_qos);
    ddr3->i_aw_valid(w_ddr_aw_valid);
    ddr3->o_aw_ready(w_ddr_aw_ready);
    ddr3->i_w_data(wb_ddr_w_data);
    ddr3->i_w_strb(wb_ddr_w_strb);
    ddr3->i_w_last(w_ddr_w_last);
    ddr3->i_w_valid(w_ddr_w_valid);
    ddr3->o_w_ready(w_ddr_w_ready);
    ddr3->i_b_ready(w_ddr_b_ready);
    ddr3->o_b_id(wb_ddr_b_id);
    ddr3->o_b_resp(wb_ddr_b_resp);
    ddr3->o_b_valid(w_ddr_b_valid);
    ddr3->i_ar_id(wb_ddr_ar_id);
    ddr3->i_ar_addr(wb_ddr_ar_addr);
    ddr3->i_ar_len(wb_ddr_ar_len);
    ddr3->i_ar_size(wb_ddr_ar_size);
    ddr3->i_ar_burst(wb_ddr_ar_burst);
    ddr3->i_ar_lock(w_ddr_ar_lock);
    ddr3->i_ar_cache(wb_ddr_ar_cache);
    ddr3->i_ar_prot(wb_ddr_ar_prot);
    ddr3->i_ar_qos(wb_ddr_ar_qos);
    ddr3->i_ar_valid(w_ddr_ar_valid);
    ddr3->o_ar_ready(w_ddr_ar_ready);
    ddr3->i_r_ready(w_ddr_r_ready);
    ddr3->o_r_id(wb_ddr_r_id);
    ddr3->o_r_data(wb_ddr_r_data);
    ddr3->o_r_resp(wb_ddr_r_resp);
    ddr3->o_r_last(w_ddr_r_last);
    ddr3->o_r_valid(w_ddr_r_valid);
}

asic_accel_top::~asic_accel_top() {
    if (iclk0) {
        delete iclk0;
    }
    if (oi2c0scl) {
        delete oi2c0scl;
    }
    if (oi2c0nreset) {
        delete oi2c0nreset;
    }
    if (ioi2c0sda) {
        delete ioi2c0sda;
    }
    if (ohdmiclk) {
        delete ohdmiclk;
    }
    if (ohdmihsync) {
        delete ohdmihsync;
    }
    if (ohdmivsync) {
        delete ohdmivsync;
    }
    if (ohdmide) {
        delete ohdmide;
    }
    if (ohdmid) {
        delete ohdmid;
    }
    if (ohdmispdif) {
        delete ohdmispdif;
    }
    if (ihdmispdif) {
        delete ihdmispdif;
    }
    if (ihdmiint) {
        delete ihdmiint;
    }
    if (pll0) {
        delete pll0;
    }
    if (prci0) {
        delete prci0;
    }
    if (ddr3) {
        delete ddr3;
    }
    if (soc0) {
        delete soc0;
    }
}

void asic_accel_top::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_rst, i_rst.name());
        sc_trace(o_vcd, i_sclk_p, i_sclk_p.name());
        sc_trace(o_vcd, i_sclk_n, i_sclk_n.name());
        sc_trace(o_vcd, io_gpio, io_gpio.name());
        sc_trace(o_vcd, i_jtag_trst, i_jtag_trst.name());
        sc_trace(o_vcd, i_jtag_tck, i_jtag_tck.name());
        sc_trace(o_vcd, i_jtag_tms, i_jtag_tms.name());
        sc_trace(o_vcd, i_jtag_tdi, i_jtag_tdi.name());
        sc_trace(o_vcd, o_jtag_tdo, o_jtag_tdo.name());
        sc_trace(o_vcd, o_jtag_vref, o_jtag_vref.name());
        sc_trace(o_vcd, i_uart1_rd, i_uart1_rd.name());
        sc_trace(o_vcd, o_uart1_td, o_uart1_td.name());
        sc_trace(o_vcd, o_i2c0_scl, o_i2c0_scl.name());
        sc_trace(o_vcd, io_i2c0_sda, io_i2c0_sda.name());
        sc_trace(o_vcd, o_i2c0_nreset, o_i2c0_nreset.name());
        sc_trace(o_vcd, o_hdmi_clk, o_hdmi_clk.name());
        sc_trace(o_vcd, o_hdmi_hsync, o_hdmi_hsync.name());
        sc_trace(o_vcd, o_hdmi_vsync, o_hdmi_vsync.name());
        sc_trace(o_vcd, o_hdmi_de, o_hdmi_de.name());
        sc_trace(o_vcd, o_hdmi_d, o_hdmi_d.name());
        sc_trace(o_vcd, o_hdmi_spdif, o_hdmi_spdif.name());
        sc_trace(o_vcd, i_hdmi_spdif_out, i_hdmi_spdif_out.name());
        sc_trace(o_vcd, i_hdmi_int, i_hdmi_int.name());
        sc_trace(o_vcd, o_ddr3_reset_n, o_ddr3_reset_n.name());
        sc_trace(o_vcd, o_ddr3_ck_n, o_ddr3_ck_n.name());
        sc_trace(o_vcd, o_ddr3_ck_p, o_ddr3_ck_p.name());
        sc_trace(o_vcd, o_ddr3_cke, o_ddr3_cke.name());
        sc_trace(o_vcd, o_ddr3_cs_n, o_ddr3_cs_n.name());
        sc_trace(o_vcd, o_ddr3_ras_n, o_ddr3_ras_n.name());
        sc_trace(o_vcd, o_ddr3_cas_n, o_ddr3_cas_n.name());
        sc_trace(o_vcd, o_ddr3_we_n, o_ddr3_we_n.name());
        sc_trace(o_vcd, o_ddr3_dm, o_ddr3_dm.name());
        sc_trace(o_vcd, o_ddr3_ba, o_ddr3_ba.name());
        sc_trace(o_vcd, o_ddr3_addr, o_ddr3_addr.name());
        sc_trace(o_vcd, io_ddr3_dq, io_ddr3_dq.name());
        sc_trace(o_vcd, io_ddr3_dqs_n, io_ddr3_dqs_n.name());
        sc_trace(o_vcd, io_ddr3_dqs_p, io_ddr3_dqs_p.name());
        sc_trace(o_vcd, o_ddr3_odt, o_ddr3_odt.name());
    }

    if (iclk0) {
        iclk0->generateVCD(i_vcd, o_vcd);
    }
    if (oi2c0scl) {
        oi2c0scl->generateVCD(i_vcd, o_vcd);
    }
    if (oi2c0nreset) {
        oi2c0nreset->generateVCD(i_vcd, o_vcd);
    }
    if (ioi2c0sda) {
        ioi2c0sda->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmiclk) {
        ohdmiclk->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmihsync) {
        ohdmihsync->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmivsync) {
        ohdmivsync->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmide) {
        ohdmide->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmid) {
        ohdmid->generateVCD(i_vcd, o_vcd);
    }
    if (ohdmispdif) {
        ohdmispdif->generateVCD(i_vcd, o_vcd);
    }
    if (ihdmispdif) {
        ihdmispdif->generateVCD(i_vcd, o_vcd);
    }
    if (ihdmiint) {
        ihdmiint->generateVCD(i_vcd, o_vcd);
    }
    if (pll0) {
        pll0->generateVCD(i_vcd, o_vcd);
    }
    if (prci0) {
        prci0->generateVCD(i_vcd, o_vcd);
    }
    if (ddr3) {
        ddr3->generateVCD(i_vcd, o_vcd);
    }
    if (soc0) {
        soc0->generateVCD(i_vcd, o_vcd);
    }
}

}  // namespace debugger

