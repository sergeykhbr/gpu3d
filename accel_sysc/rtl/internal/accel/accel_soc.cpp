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

#include "accel_soc.h"
#include "api_core.h"

namespace debugger {

accel_soc::accel_soc(sc_module_name name,
                     bool async_reset,
                     int sim_uart_speedup_rate)
    : sc_module(name),
    i_sys_nrst("i_sys_nrst"),
    i_sys_clk("i_sys_clk"),
    i_cpu_nrst("i_cpu_nrst"),
    i_cpu_clk("i_cpu_clk"),
    i_apb_nrst("i_apb_nrst"),
    i_apb_clk("i_apb_clk"),
    i_dbg_nrst("i_dbg_nrst"),
    i_ddr_nrst("i_ddr_nrst"),
    i_ddr_clk("i_ddr_clk"),
    i_gpio("i_gpio"),
    o_gpio("o_gpio"),
    o_gpio_dir("o_gpio_dir"),
    i_jtag_trst("i_jtag_trst"),
    i_jtag_tck("i_jtag_tck"),
    i_jtag_tms("i_jtag_tms"),
    i_jtag_tdi("i_jtag_tdi"),
    o_jtag_tdo("o_jtag_tdo"),
    o_jtag_vref("o_jtag_vref"),
    i_uart1_rd("i_uart1_rd"),
    o_uart1_td("o_uart1_td"),
    o_i2c0_scl("o_i2c0_scl"),
    o_i2c0_sda("o_i2c0_sda"),
    o_i2c0_sda_dir("o_i2c0_sda_dir"),
    i_i2c0_sda("i_i2c0_sda"),
    o_i2c0_nreset("o_i2c0_nreset"),
    i_hdmi_nrst("i_hdmi_nrst"),
    i_hdmi_clk("i_hdmi_clk"),
    o_hdmi_hsync("o_hdmi_hsync"),
    o_hdmi_vsync("o_hdmi_vsync"),
    o_hdmi_de("o_hdmi_de"),
    o_hdmi_d("o_hdmi_d"),
    o_hdmi_spdif("o_hdmi_spdif"),
    i_hdmi_spdif_out("i_hdmi_spdif_out"),
    i_hdmi_int("i_hdmi_int"),
    o_dmreset("o_dmreset"),
    o_prci_pmapinfo("o_prci_pmapinfo"),
    i_prci_pdevcfg("i_prci_pdevcfg"),
    o_prci_apbi("o_prci_apbi"),
    i_prci_apbo("i_prci_apbo"),
    o_ddr_aw_id("o_ddr_aw_id"),
    o_ddr_aw_addr("o_ddr_aw_addr"),
    o_ddr_aw_len("o_ddr_aw_len"),
    o_ddr_aw_size("o_ddr_aw_size"),
    o_ddr_aw_burst("o_ddr_aw_burst"),
    o_ddr_aw_lock("o_ddr_aw_lock"),
    o_ddr_aw_cache("o_ddr_aw_cache"),
    o_ddr_aw_prot("o_ddr_aw_prot"),
    o_ddr_aw_qos("o_ddr_aw_qos"),
    o_ddr_aw_valid("o_ddr_aw_valid"),
    i_ddr_aw_ready("i_ddr_aw_ready"),
    o_ddr_w_data("o_ddr_w_data"),
    o_ddr_w_strb("o_ddr_w_strb"),
    o_ddr_w_last("o_ddr_w_last"),
    o_ddr_w_valid("o_ddr_w_valid"),
    i_ddr_w_ready("i_ddr_w_ready"),
    o_ddr_b_ready("o_ddr_b_ready"),
    i_ddr_b_id("i_ddr_b_id"),
    i_ddr_b_resp("i_ddr_b_resp"),
    i_ddr_b_valid("i_ddr_b_valid"),
    o_ddr_ar_id("o_ddr_ar_id"),
    o_ddr_ar_addr("o_ddr_ar_addr"),
    o_ddr_ar_len("o_ddr_ar_len"),
    o_ddr_ar_size("o_ddr_ar_size"),
    o_ddr_ar_burst("o_ddr_ar_burst"),
    o_ddr_ar_lock("o_ddr_ar_lock"),
    o_ddr_ar_cache("o_ddr_ar_cache"),
    o_ddr_ar_prot("o_ddr_ar_prot"),
    o_ddr_ar_qos("o_ddr_ar_qos"),
    o_ddr_ar_valid("o_ddr_ar_valid"),
    i_ddr_ar_ready("i_ddr_ar_ready"),
    o_ddr_r_ready("o_ddr_r_ready"),
    i_ddr_r_id("i_ddr_r_id"),
    i_ddr_r_data("i_ddr_r_data"),
    i_ddr_r_resp("i_ddr_r_resp"),
    i_ddr_r_last("i_ddr_r_last"),
    i_ddr_r_valid("i_ddr_r_valid"),
    i_ddr_app_init_calib_done("i_ddr_app_init_calib_done"),
    i_ddr_app_temp("i_ddr_app_temp"),
    o_ddr_app_sr_req("o_ddr_app_sr_req"),
    o_ddr_app_ref_req("o_ddr_app_ref_req"),
    o_ddr_app_zq_req("o_ddr_app_zq_req"),
    i_ddr_app_sr_active("i_ddr_app_sr_active"),
    i_ddr_app_ref_ack("i_ddr_app_ref_ack"),
    i_ddr_app_zq_ack("i_ddr_app_zq_ack"),
    i_pcie_clk("i_pcie_clk"),
    i_pcie_nrst("i_pcie_nrst"),
    i_pcie_completer_id("i_pcie_completer_id"),
    o_pcie_dmao("o_pcie_dmao"),
    i_pcie_dmai("i_pcie_dmai"),
    bus0_mapinfo("bus0_mapinfo", CFG_BUS0_XSLV_TOTAL),
    aximi("aximi", CFG_BUS0_XMST_TOTAL),
    aximo("aximo", CFG_BUS0_XMST_TOTAL),
    axisi("axisi", CFG_BUS0_XSLV_TOTAL),
    axiso("axiso", CFG_BUS0_XSLV_TOTAL),
    bus1_mapinfo("bus1_mapinfo", CFG_BUS1_PSLV_TOTAL),
    apbi("apbi", CFG_BUS1_PSLV_TOTAL),
    apbo("apbo", CFG_BUS1_PSLV_TOTAL),
    dev_pnp("dev_pnp", SOC_PNP_TOTAL) {

    async_reset_ = async_reset;
    sim_uart_speedup_rate_ = sim_uart_speedup_rate;
    bus0 = 0;
    bus1 = 0;
    rom0 = 0;
    sram0 = 0;
    clint0 = 0;
    plic0 = 0;
    uart1 = 0;
    gpio0 = 0;
    pddr0 = 0;
    i2c0 = 0;
    hdmi0 = 0;
    pcidma0 = 0;
    ppcie0 = 0;
    pnp0 = 0;
    group0 = 0;
    afifo_ddr0 = 0;
    afifo_apb0 = 0;
    afifo_group0 = 0;

    bus0 = new accel_axictrl_bus0("bus0",
                                   async_reset);
    bus0->i_clk(i_sys_clk);
    bus0->i_nrst(i_sys_nrst);
    bus0->o_cfg(dev_pnp[SOC_PNP_XCTRL0]);
    bus0->i_xmsto(aximo);
    bus0->o_xmsti(aximi);
    bus0->i_xslvo(axiso);
    bus0->o_xslvi(axisi);
    bus0->o_mapinfo(bus0_mapinfo);

    bus1 = new accel_axi2apb_bus1("bus1",
                                   async_reset);
    bus1->i_clk(i_apb_clk);
    bus1->i_nrst(i_apb_nrst);
    bus1->i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_PBRIDGE]);
    bus1->o_cfg(dev_pnp[SOC_PNP_PBRIDGE0]);
    bus1->i_xslvi(wb_pbridge_xslvi);
    bus1->o_xslvo(wb_pbridge_xslvo);
    bus1->i_apbo(apbo);
    bus1->o_apbi(apbi);
    bus1->o_mapinfo(bus1_mapinfo);

    afifo_group0 = new afifo_xmst<2,
                                  3>("afifo_group0");
    afifo_group0->i_xmst_nrst(i_cpu_nrst);
    afifo_group0->i_xmst_clk(i_cpu_clk);
    afifo_group0->i_xmsto(wb_group0_xmsto);
    afifo_group0->o_xmsti(wb_group0_xmsti);
    afifo_group0->i_xslv_nrst(i_sys_nrst);
    afifo_group0->i_xslv_clk(i_sys_clk);
    afifo_group0->o_xslvi(aximo[CFG_BUS0_XMST_GROUP0]);
    afifo_group0->i_xslvo(aximi[CFG_BUS0_XMST_GROUP0]);

    afifo_apb0 = new afifo_xslv<2,
                                2>("afifo_apb0");
    afifo_apb0->i_xslv_nrst(i_sys_nrst);
    afifo_apb0->i_xslv_clk(i_sys_clk);
    afifo_apb0->i_xslvi(axisi[CFG_BUS0_XSLV_PBRIDGE]);
    afifo_apb0->o_xslvo(axiso[CFG_BUS0_XSLV_PBRIDGE]);
    afifo_apb0->i_xmst_nrst(i_apb_nrst);
    afifo_apb0->i_xmst_clk(i_apb_clk);
    afifo_apb0->o_xmsto(wb_pbridge_xslvi);
    afifo_apb0->i_xmsti(wb_pbridge_xslvo);

    afifo_ddr0 = new afifo_xslv<2,
                                9>("afifo_ddr0");
    afifo_ddr0->i_xslv_nrst(i_sys_nrst);
    afifo_ddr0->i_xslv_clk(i_sys_clk);
    afifo_ddr0->i_xslvi(axisi[CFG_BUS0_XSLV_DDR]);
    afifo_ddr0->o_xslvo(axiso[CFG_BUS0_XSLV_DDR]);
    afifo_ddr0->i_xmst_nrst(i_ddr_nrst);
    afifo_ddr0->i_xmst_clk(i_ddr_clk);
    afifo_ddr0->o_xmsto(wb_ddr_xslvi);
    afifo_ddr0->i_xmsti(wb_ddr_xslvo);

    group0 = new Workgroup("group0",
                            async_reset,
                            CFG_CPU_NUM,
                            CFG_L2CACHE_ENA);
    group0->i_cores_nrst(i_cpu_nrst);
    group0->i_dmi_nrst(i_dbg_nrst);
    group0->i_clk(i_cpu_clk);
    group0->i_trst(i_jtag_trst);
    group0->i_tck(i_jtag_tck);
    group0->i_tms(i_jtag_tms);
    group0->i_tdi(i_jtag_tdi);
    group0->o_tdo(o_jtag_tdo);
    group0->i_msip(wb_clint_msip);
    group0->i_mtip(wb_clint_mtip);
    group0->i_meip(wb_plic_meip);
    group0->i_seip(wb_plic_seip);
    group0->i_mtimer(wb_clint_mtimer);
    group0->i_acpo(acpo);
    group0->o_acpi(acpi);
    group0->o_xmst_cfg(dev_pnp[SOC_PNP_GROUP0]);
    group0->i_msti(wb_group0_xmsti);
    group0->o_msto(wb_group0_xmsto);
    group0->i_dmi_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_DMI]);
    group0->o_dmi_cfg(dev_pnp[SOC_PNP_DMI]);
    group0->i_dmi_apbi(apbi[CFG_BUS1_PSLV_DMI]);
    group0->o_dmi_apbo(apbo[CFG_BUS1_PSLV_DMI]);
    group0->o_dmreset(o_dmreset);

    rom0 = new axi_rom<CFG_BOOTROM_LOG2_SIZE>("rom0",
                                              async_reset,
                                              CFG_BOOTROM_FILE_HEX);
    rom0->i_clk(i_sys_clk);
    rom0->i_nrst(i_sys_nrst);
    rom0->i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_BOOTROM]);
    rom0->o_cfg(dev_pnp[SOC_PNP_BOOTROM]);
    rom0->i_xslvi(axisi[CFG_BUS0_XSLV_BOOTROM]);
    rom0->o_xslvo(axiso[CFG_BUS0_XSLV_BOOTROM]);

    sram0 = new axi_sram<CFG_SRAM_LOG2_SIZE>("sram0",
                                             async_reset);
    sram0->i_clk(i_sys_clk);
    sram0->i_nrst(i_sys_nrst);
    sram0->i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_SRAM]);
    sram0->o_cfg(dev_pnp[SOC_PNP_SRAM]);
    sram0->i_xslvi(axisi[CFG_BUS0_XSLV_SRAM]);
    sram0->o_xslvo(axiso[CFG_BUS0_XSLV_SRAM]);

    clint0 = new clint<CFG_CPU_MAX>("clint0",
                                    async_reset);
    clint0->i_clk(i_sys_clk);
    clint0->i_nrst(i_sys_nrst);
    clint0->i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_CLINT]);
    clint0->o_cfg(dev_pnp[SOC_PNP_CLINT]);
    clint0->i_xslvi(axisi[CFG_BUS0_XSLV_CLINT]);
    clint0->o_xslvo(axiso[CFG_BUS0_XSLV_CLINT]);
    clint0->o_mtimer(wb_clint_mtimer);
    clint0->o_msip(wb_clint_msip);
    clint0->o_mtip(wb_clint_mtip);

    plic0 = new plic<SOC_PLIC_CONTEXT_TOTAL,
                     SOC_PLIC_IRQ_TOTAL>("plic0",
                                         async_reset);
    plic0->i_clk(i_sys_clk);
    plic0->i_nrst(i_sys_nrst);
    plic0->i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_PLIC]);
    plic0->o_cfg(dev_pnp[SOC_PNP_PLIC]);
    plic0->i_xslvi(axisi[CFG_BUS0_XSLV_PLIC]);
    plic0->o_xslvo(axiso[CFG_BUS0_XSLV_PLIC]);
    plic0->i_irq_request(wb_ext_irqs);
    plic0->o_ip(wb_plic_xeip);

    uart1 = new apb_uart<SOC_UART1_LOG2_FIFOSZ>("uart1",
                                                async_reset,
                                                sim_uart_speedup_rate);
    uart1->i_clk(i_apb_clk);
    uart1->i_nrst(i_apb_nrst);
    uart1->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_UART1]);
    uart1->o_cfg(dev_pnp[SOC_PNP_UART1]);
    uart1->i_apbi(apbi[CFG_BUS1_PSLV_UART1]);
    uart1->o_apbo(apbo[CFG_BUS1_PSLV_UART1]);
    uart1->i_rd(i_uart1_rd);
    uart1->o_td(o_uart1_td);
    uart1->o_irq(w_irq_uart1);

    gpio0 = new apb_gpio<SOC_GPIO0_WIDTH>("gpio0",
                                          async_reset);
    gpio0->i_clk(i_apb_clk);
    gpio0->i_nrst(i_apb_nrst);
    gpio0->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_GPIO]);
    gpio0->o_cfg(dev_pnp[SOC_PNP_GPIO]);
    gpio0->i_apbi(apbi[CFG_BUS1_PSLV_GPIO]);
    gpio0->o_apbo(apbo[CFG_BUS1_PSLV_GPIO]);
    gpio0->i_gpio(i_gpio);
    gpio0->o_gpio_dir(o_gpio_dir);
    gpio0->o_gpio(o_gpio);
    gpio0->o_irq(wb_irq_gpio);

    pddr0 = new apb_ddr("pddr0",
                         async_reset);
    pddr0->i_apb_nrst(i_apb_nrst);
    pddr0->i_apb_clk(i_apb_clk);
    pddr0->i_ddr_nrst(i_ddr_nrst);
    pddr0->i_ddr_clk(i_ddr_clk);
    pddr0->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_DDR]);
    pddr0->o_cfg(dev_pnp[SOC_PNP_DDR_APB]);
    pddr0->i_apbi(apbi[CFG_BUS1_PSLV_DDR]);
    pddr0->o_apbo(apbo[CFG_BUS1_PSLV_DDR]);
    pddr0->i_init_calib_done(i_ddr_app_init_calib_done);
    pddr0->i_device_temp(i_ddr_app_temp);
    pddr0->o_sr_req(o_ddr_app_sr_req);
    pddr0->o_ref_req(o_ddr_app_ref_req);
    pddr0->o_zq_req(o_ddr_app_zq_req);
    pddr0->i_sr_active(i_ddr_app_sr_active);
    pddr0->i_ref_ack(i_ddr_app_ref_ack);
    pddr0->i_zq_ack(i_ddr_app_zq_ack);

    i2c0 = new apb_i2c("i2c0",
                        async_reset);
    i2c0->i_clk(i_sys_clk);
    i2c0->i_nrst(i_sys_nrst);
    i2c0->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_I2C0]);
    i2c0->o_cfg(dev_pnp[SOC_PNP_I2C]);
    i2c0->i_apbi(apbi[CFG_BUS1_PSLV_I2C0]);
    i2c0->o_apbo(apbo[CFG_BUS1_PSLV_I2C0]);
    i2c0->o_scl(o_i2c0_scl);
    i2c0->o_sda(o_i2c0_sda);
    i2c0->o_sda_dir(o_i2c0_sda_dir);
    i2c0->i_sda(i_i2c0_sda);
    i2c0->o_irq(w_irq_i2c0);
    i2c0->o_nreset(o_i2c0_nreset);

    hdmi0 = new hdmi_top("hdmi0",
                          async_reset,
                          1366,
                          768);
    hdmi0->i_nrst(i_sys_nrst);
    hdmi0->i_clk(i_sys_clk);
    hdmi0->i_hdmi_nrst(i_hdmi_nrst);
    hdmi0->i_hdmi_clk(i_hdmi_clk);
    hdmi0->o_hsync(o_hdmi_hsync);
    hdmi0->o_vsync(o_hdmi_vsync);
    hdmi0->o_de(o_hdmi_de);
    hdmi0->o_data(o_hdmi_d);
    hdmi0->o_spdif(o_hdmi_spdif);
    hdmi0->i_spdif_out(i_hdmi_spdif_out);
    hdmi0->i_irq(i_hdmi_int);
    hdmi0->o_xmst_cfg(dev_pnp[SOC_PNP_HDMI_DMA]);
    hdmi0->i_xmsti(aximi[CFG_BUS0_XMST_HDMI]);
    hdmi0->o_xmsto(aximo[CFG_BUS0_XMST_HDMI]);

    // See reference: pg054-7series-pcie.pdf
    pcidma0 = new pcie_dma("pcidma0",
                            async_reset);
    pcidma0->i_nrst(i_pcie_nrst);
    pcidma0->i_clk(i_sys_clk);
    pcidma0->i_pcie_phy_clk(i_pcie_clk);
    pcidma0->i_pcie_completer_id(i_pcie_completer_id);
    pcidma0->o_dma_state(wb_pcie_dma_state);
    pcidma0->i_pcie_dmai(i_pcie_dmai);
    pcidma0->o_pcie_dmao(o_pcie_dmao);
    pcidma0->o_xmst_cfg(dev_pnp[SOC_PNP_PCIE_DMA]);
    pcidma0->i_xmsti(aximi[CFG_BUS0_XMST_PCIE]);
    pcidma0->o_xmsto(aximo[CFG_BUS0_XMST_PCIE]);
    pcidma0->o_dbg_valid(w_dbg_valid);
    pcidma0->o_dbg_payload(w_dbg_payload);

    ppcie0 = new apb_pcie("ppcie0",
                           async_reset);
    ppcie0->i_clk(i_apb_clk);
    ppcie0->i_nrst(i_apb_nrst);
    ppcie0->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_PCIE]);
    ppcie0->o_cfg(dev_pnp[SOC_PNP_PCIE_APB]);
    ppcie0->i_apbi(apbi[CFG_BUS1_PSLV_PCIE]);
    ppcie0->o_apbo(apbo[CFG_BUS1_PSLV_PCIE]);
    ppcie0->i_pcie_completer_id(i_pcie_completer_id);
    ppcie0->i_dma_state(wb_pcie_dma_state);
    ppcie0->i_dbg_valid(w_dbg_valid);
    ppcie0->i_dbg_payload(w_dbg_payload);

    pnp0 = new apb_pnp<SOC_PNP_TOTAL>("pnp0",
                                      async_reset,
                                      SOC_HW_ID,
                                      CFG_CPU_NUM,
                                      CFG_L2CACHE_ENA,
                                      SOC_PLIC_IRQ_TOTAL);
    pnp0->i_clk(i_apb_clk);
    pnp0->i_nrst(i_apb_nrst);
    pnp0->i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_PNP]);
    pnp0->i_cfg(dev_pnp);
    pnp0->o_cfg(dev_pnp[SOC_PNP_PNP]);
    pnp0->i_apbi(apbi[CFG_BUS1_PSLV_PNP]);
    pnp0->o_apbo(apbo[CFG_BUS1_PSLV_PNP]);
    pnp0->o_irq(w_irq_pnp);

    SC_METHOD(comb);
    sensitive << i_sys_nrst;
    sensitive << i_sys_clk;
    sensitive << i_cpu_nrst;
    sensitive << i_cpu_clk;
    sensitive << i_apb_nrst;
    sensitive << i_apb_clk;
    sensitive << i_dbg_nrst;
    sensitive << i_ddr_nrst;
    sensitive << i_ddr_clk;
    sensitive << i_gpio;
    sensitive << i_jtag_trst;
    sensitive << i_jtag_tck;
    sensitive << i_jtag_tms;
    sensitive << i_jtag_tdi;
    sensitive << i_uart1_rd;
    sensitive << i_i2c0_sda;
    sensitive << i_hdmi_nrst;
    sensitive << i_hdmi_clk;
    sensitive << i_hdmi_spdif_out;
    sensitive << i_hdmi_int;
    sensitive << i_prci_pdevcfg;
    sensitive << i_prci_apbo;
    sensitive << i_ddr_aw_ready;
    sensitive << i_ddr_w_ready;
    sensitive << i_ddr_b_id;
    sensitive << i_ddr_b_resp;
    sensitive << i_ddr_b_valid;
    sensitive << i_ddr_ar_ready;
    sensitive << i_ddr_r_id;
    sensitive << i_ddr_r_data;
    sensitive << i_ddr_r_resp;
    sensitive << i_ddr_r_last;
    sensitive << i_ddr_r_valid;
    sensitive << i_ddr_app_init_calib_done;
    sensitive << i_ddr_app_temp;
    sensitive << i_ddr_app_sr_active;
    sensitive << i_ddr_app_ref_ack;
    sensitive << i_ddr_app_zq_ack;
    sensitive << i_pcie_clk;
    sensitive << i_pcie_nrst;
    sensitive << i_pcie_completer_id;
    sensitive << i_pcie_dmai;
    sensitive << acpo;
    sensitive << acpi;
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << bus0_mapinfo[i];
    }
    for (int i = 0; i < CFG_BUS0_XMST_TOTAL; i++) {
        sensitive << aximi[i];
    }
    for (int i = 0; i < CFG_BUS0_XMST_TOTAL; i++) {
        sensitive << aximo[i];
    }
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << axisi[i];
    }
    for (int i = 0; i < CFG_BUS0_XSLV_TOTAL; i++) {
        sensitive << axiso[i];
    }
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << bus1_mapinfo[i];
    }
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << apbi[i];
    }
    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) {
        sensitive << apbo[i];
    }
    for (int i = 0; i < SOC_PNP_TOTAL; i++) {
        sensitive << dev_pnp[i];
    }
    sensitive << wb_group0_xmsto;
    sensitive << wb_group0_xmsti;
    sensitive << wb_ddr_xslvi;
    sensitive << wb_ddr_xslvo;
    sensitive << wb_pbridge_xslvi;
    sensitive << wb_pbridge_xslvo;
    sensitive << wb_clint_mtimer;
    sensitive << wb_clint_msip;
    sensitive << wb_clint_mtip;
    sensitive << wb_plic_xeip;
    sensitive << wb_plic_meip;
    sensitive << wb_plic_seip;
    sensitive << w_irq_uart1;
    sensitive << wb_irq_gpio;
    sensitive << w_irq_pnp;
    sensitive << wb_ext_irqs;
    sensitive << wb_pcie_dma_state;
    sensitive << w_dbg_valid;
    sensitive << w_dbg_payload;
    sensitive << w_irq_i2c0;
}

accel_soc::~accel_soc() {
    if (bus0) {
        delete bus0;
    }
    if (bus1) {
        delete bus1;
    }
    if (rom0) {
        delete rom0;
    }
    if (sram0) {
        delete sram0;
    }
    if (clint0) {
        delete clint0;
    }
    if (plic0) {
        delete plic0;
    }
    if (uart1) {
        delete uart1;
    }
    if (gpio0) {
        delete gpio0;
    }
    if (pddr0) {
        delete pddr0;
    }
    if (i2c0) {
        delete i2c0;
    }
    if (hdmi0) {
        delete hdmi0;
    }
    if (pcidma0) {
        delete pcidma0;
    }
    if (ppcie0) {
        delete ppcie0;
    }
    if (pnp0) {
        delete pnp0;
    }
    if (group0) {
        delete group0;
    }
    if (afifo_ddr0) {
        delete afifo_ddr0;
    }
    if (afifo_apb0) {
        delete afifo_apb0;
    }
    if (afifo_group0) {
        delete afifo_group0;
    }
}

void accel_soc::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_sys_nrst, i_sys_nrst.name());
        sc_trace(o_vcd, i_sys_clk, i_sys_clk.name());
        sc_trace(o_vcd, i_cpu_nrst, i_cpu_nrst.name());
        sc_trace(o_vcd, i_cpu_clk, i_cpu_clk.name());
        sc_trace(o_vcd, i_apb_nrst, i_apb_nrst.name());
        sc_trace(o_vcd, i_apb_clk, i_apb_clk.name());
        sc_trace(o_vcd, i_dbg_nrst, i_dbg_nrst.name());
        sc_trace(o_vcd, i_ddr_nrst, i_ddr_nrst.name());
        sc_trace(o_vcd, i_ddr_clk, i_ddr_clk.name());
        sc_trace(o_vcd, i_gpio, i_gpio.name());
        sc_trace(o_vcd, o_gpio, o_gpio.name());
        sc_trace(o_vcd, o_gpio_dir, o_gpio_dir.name());
        sc_trace(o_vcd, i_jtag_trst, i_jtag_trst.name());
        sc_trace(o_vcd, i_jtag_tck, i_jtag_tck.name());
        sc_trace(o_vcd, i_jtag_tms, i_jtag_tms.name());
        sc_trace(o_vcd, i_jtag_tdi, i_jtag_tdi.name());
        sc_trace(o_vcd, o_jtag_tdo, o_jtag_tdo.name());
        sc_trace(o_vcd, o_jtag_vref, o_jtag_vref.name());
        sc_trace(o_vcd, i_uart1_rd, i_uart1_rd.name());
        sc_trace(o_vcd, o_uart1_td, o_uart1_td.name());
        sc_trace(o_vcd, o_i2c0_scl, o_i2c0_scl.name());
        sc_trace(o_vcd, o_i2c0_sda, o_i2c0_sda.name());
        sc_trace(o_vcd, o_i2c0_sda_dir, o_i2c0_sda_dir.name());
        sc_trace(o_vcd, i_i2c0_sda, i_i2c0_sda.name());
        sc_trace(o_vcd, o_i2c0_nreset, o_i2c0_nreset.name());
        sc_trace(o_vcd, i_hdmi_nrst, i_hdmi_nrst.name());
        sc_trace(o_vcd, i_hdmi_clk, i_hdmi_clk.name());
        sc_trace(o_vcd, o_hdmi_hsync, o_hdmi_hsync.name());
        sc_trace(o_vcd, o_hdmi_vsync, o_hdmi_vsync.name());
        sc_trace(o_vcd, o_hdmi_de, o_hdmi_de.name());
        sc_trace(o_vcd, o_hdmi_d, o_hdmi_d.name());
        sc_trace(o_vcd, o_hdmi_spdif, o_hdmi_spdif.name());
        sc_trace(o_vcd, i_hdmi_spdif_out, i_hdmi_spdif_out.name());
        sc_trace(o_vcd, i_hdmi_int, i_hdmi_int.name());
        sc_trace(o_vcd, o_dmreset, o_dmreset.name());
        sc_trace(o_vcd, o_prci_apbi, o_prci_apbi.name());
        sc_trace(o_vcd, i_prci_apbo, i_prci_apbo.name());
        sc_trace(o_vcd, o_ddr_aw_id, o_ddr_aw_id.name());
        sc_trace(o_vcd, o_ddr_aw_addr, o_ddr_aw_addr.name());
        sc_trace(o_vcd, o_ddr_aw_len, o_ddr_aw_len.name());
        sc_trace(o_vcd, o_ddr_aw_size, o_ddr_aw_size.name());
        sc_trace(o_vcd, o_ddr_aw_burst, o_ddr_aw_burst.name());
        sc_trace(o_vcd, o_ddr_aw_lock, o_ddr_aw_lock.name());
        sc_trace(o_vcd, o_ddr_aw_cache, o_ddr_aw_cache.name());
        sc_trace(o_vcd, o_ddr_aw_prot, o_ddr_aw_prot.name());
        sc_trace(o_vcd, o_ddr_aw_qos, o_ddr_aw_qos.name());
        sc_trace(o_vcd, o_ddr_aw_valid, o_ddr_aw_valid.name());
        sc_trace(o_vcd, i_ddr_aw_ready, i_ddr_aw_ready.name());
        sc_trace(o_vcd, o_ddr_w_data, o_ddr_w_data.name());
        sc_trace(o_vcd, o_ddr_w_strb, o_ddr_w_strb.name());
        sc_trace(o_vcd, o_ddr_w_last, o_ddr_w_last.name());
        sc_trace(o_vcd, o_ddr_w_valid, o_ddr_w_valid.name());
        sc_trace(o_vcd, i_ddr_w_ready, i_ddr_w_ready.name());
        sc_trace(o_vcd, o_ddr_b_ready, o_ddr_b_ready.name());
        sc_trace(o_vcd, i_ddr_b_id, i_ddr_b_id.name());
        sc_trace(o_vcd, i_ddr_b_resp, i_ddr_b_resp.name());
        sc_trace(o_vcd, i_ddr_b_valid, i_ddr_b_valid.name());
        sc_trace(o_vcd, o_ddr_ar_id, o_ddr_ar_id.name());
        sc_trace(o_vcd, o_ddr_ar_addr, o_ddr_ar_addr.name());
        sc_trace(o_vcd, o_ddr_ar_len, o_ddr_ar_len.name());
        sc_trace(o_vcd, o_ddr_ar_size, o_ddr_ar_size.name());
        sc_trace(o_vcd, o_ddr_ar_burst, o_ddr_ar_burst.name());
        sc_trace(o_vcd, o_ddr_ar_lock, o_ddr_ar_lock.name());
        sc_trace(o_vcd, o_ddr_ar_cache, o_ddr_ar_cache.name());
        sc_trace(o_vcd, o_ddr_ar_prot, o_ddr_ar_prot.name());
        sc_trace(o_vcd, o_ddr_ar_qos, o_ddr_ar_qos.name());
        sc_trace(o_vcd, o_ddr_ar_valid, o_ddr_ar_valid.name());
        sc_trace(o_vcd, i_ddr_ar_ready, i_ddr_ar_ready.name());
        sc_trace(o_vcd, o_ddr_r_ready, o_ddr_r_ready.name());
        sc_trace(o_vcd, i_ddr_r_id, i_ddr_r_id.name());
        sc_trace(o_vcd, i_ddr_r_data, i_ddr_r_data.name());
        sc_trace(o_vcd, i_ddr_r_resp, i_ddr_r_resp.name());
        sc_trace(o_vcd, i_ddr_r_last, i_ddr_r_last.name());
        sc_trace(o_vcd, i_ddr_r_valid, i_ddr_r_valid.name());
        sc_trace(o_vcd, i_ddr_app_init_calib_done, i_ddr_app_init_calib_done.name());
        sc_trace(o_vcd, i_ddr_app_temp, i_ddr_app_temp.name());
        sc_trace(o_vcd, o_ddr_app_sr_req, o_ddr_app_sr_req.name());
        sc_trace(o_vcd, o_ddr_app_ref_req, o_ddr_app_ref_req.name());
        sc_trace(o_vcd, o_ddr_app_zq_req, o_ddr_app_zq_req.name());
        sc_trace(o_vcd, i_ddr_app_sr_active, i_ddr_app_sr_active.name());
        sc_trace(o_vcd, i_ddr_app_ref_ack, i_ddr_app_ref_ack.name());
        sc_trace(o_vcd, i_ddr_app_zq_ack, i_ddr_app_zq_ack.name());
        sc_trace(o_vcd, i_pcie_clk, i_pcie_clk.name());
        sc_trace(o_vcd, i_pcie_nrst, i_pcie_nrst.name());
        sc_trace(o_vcd, i_pcie_completer_id, i_pcie_completer_id.name());
        sc_trace(o_vcd, o_pcie_dmao, o_pcie_dmao.name());
        sc_trace(o_vcd, i_pcie_dmai, i_pcie_dmai.name());
    }

    if (bus0) {
        bus0->generateVCD(i_vcd, o_vcd);
    }
    if (bus1) {
        bus1->generateVCD(i_vcd, o_vcd);
    }
    if (rom0) {
        rom0->generateVCD(i_vcd, o_vcd);
    }
    if (sram0) {
        sram0->generateVCD(i_vcd, o_vcd);
    }
    if (clint0) {
        clint0->generateVCD(i_vcd, o_vcd);
    }
    if (plic0) {
        plic0->generateVCD(i_vcd, o_vcd);
    }
    if (uart1) {
        uart1->generateVCD(i_vcd, o_vcd);
    }
    if (gpio0) {
        gpio0->generateVCD(i_vcd, o_vcd);
    }
    if (pddr0) {
        pddr0->generateVCD(i_vcd, o_vcd);
    }
    if (i2c0) {
        i2c0->generateVCD(i_vcd, o_vcd);
    }
    if (hdmi0) {
        hdmi0->generateVCD(i_vcd, o_vcd);
    }
    if (pcidma0) {
        pcidma0->generateVCD(i_vcd, o_vcd);
    }
    if (ppcie0) {
        ppcie0->generateVCD(i_vcd, o_vcd);
    }
    if (pnp0) {
        pnp0->generateVCD(i_vcd, o_vcd);
    }
    if (group0) {
        group0->generateVCD(i_vcd, o_vcd);
    }
    if (afifo_ddr0) {
        afifo_ddr0->generateVCD(i_vcd, o_vcd);
    }
    if (afifo_apb0) {
        afifo_apb0->generateVCD(i_vcd, o_vcd);
    }
    if (afifo_group0) {
        afifo_group0->generateVCD(i_vcd, o_vcd);
    }
}

void accel_soc::comb() {
    sc_uint<1> v_gnd1;
    sc_biguint<SOC_PLIC_IRQ_TOTAL> vb_ext_irqs;
    dev_config_type vb_ddr_xcfg;
    mapinfo_type vb_ddr_mapinfo;
    axi4_slave_out_type vb_ddr_xslvo;                       // systemc compatibility

    v_gnd1 = 0;
    vb_ext_irqs = 0;


    // assign interrupts:
    vb_ext_irqs(22, 0) = 0;
    vb_ext_irqs(((23 + SOC_GPIO0_WIDTH) - 1), 23) = wb_irq_gpio.read();// FU740: 16 bits, current 12-bits
    vb_ext_irqs[39] = w_irq_uart1.read();
    vb_ext_irqs[40] = w_irq_i2c0.read();
    vb_ext_irqs(69, 41) = 0;
    vb_ext_irqs[70] = w_irq_pnp.read();
    vb_ext_irqs((SOC_PLIC_IRQ_TOTAL - 1), 71) = 0;
    wb_ext_irqs = vb_ext_irqs;

    // FU740 implements 5 cores (we implement only 4):
    //     Hart0 - M-mode only (S7 Core RV64IMAC)
    //     Hart1..4 - M+S modes (U74 Cores RV64GC)
    // Hart4 ignored
    wb_plic_meip = (wb_plic_xeip.read()[5],
            wb_plic_xeip.read()[3],
            wb_plic_xeip.read()[1],
            wb_plic_xeip.read()[0]);
    wb_plic_seip = (wb_plic_xeip.read()[6],
            wb_plic_xeip.read()[4],
            wb_plic_xeip.read()[2],
            v_gnd1);

    o_jtag_vref = 1;

    // Nullify emty AXI-slots:
    acpo = axi4_master_out_none;

    // PRCI:
    o_prci_apbi = apbi[CFG_BUS1_PSLV_PRCI];
    apbo[CFG_BUS1_PSLV_PRCI] = i_prci_apbo.read();
    dev_pnp[SOC_PNP_PRCI] = i_prci_pdevcfg.read();

    // DDR:
    o_ddr_aw_id = wb_ddr_xslvi.read().aw_id;
    // Warning: we should do (addr - start_addr)[29:0], but BAR is 0x80000000
    o_ddr_aw_addr = wb_ddr_xslvi.read().aw_bits.addr(29, 0);
    o_ddr_aw_len = wb_ddr_xslvi.read().aw_bits.len;
    o_ddr_aw_size = wb_ddr_xslvi.read().aw_bits.size;
    o_ddr_aw_burst = wb_ddr_xslvi.read().aw_bits.burst;
    o_ddr_aw_lock = wb_ddr_xslvi.read().aw_bits.lock;
    o_ddr_aw_cache = wb_ddr_xslvi.read().aw_bits.cache;
    o_ddr_aw_prot = wb_ddr_xslvi.read().aw_bits.prot;
    o_ddr_aw_qos = wb_ddr_xslvi.read().aw_bits.qos;
    o_ddr_aw_valid = wb_ddr_xslvi.read().aw_valid;
    vb_ddr_xslvo.aw_ready = i_ddr_aw_ready.read();
    o_ddr_w_data = wb_ddr_xslvi.read().w_data;
    o_ddr_w_strb = wb_ddr_xslvi.read().w_strb;
    o_ddr_w_last = wb_ddr_xslvi.read().w_last;
    o_ddr_w_valid = wb_ddr_xslvi.read().w_valid;
    vb_ddr_xslvo.w_ready = i_ddr_w_ready.read();
    o_ddr_b_ready = wb_ddr_xslvi.read().b_ready;
    vb_ddr_xslvo.b_id = i_ddr_b_id.read();
    vb_ddr_xslvo.b_resp = i_ddr_b_resp.read();
    vb_ddr_xslvo.b_valid = i_ddr_b_valid.read();
    vb_ddr_xslvo.b_user = 0;
    o_ddr_ar_id = wb_ddr_xslvi.read().ar_id;
    // Warning: we should do (addr - start_addr)[29:0], but BAR is 0x80000000
    o_ddr_ar_addr = wb_ddr_xslvi.read().ar_bits.addr(29, 0);
    o_ddr_ar_len = wb_ddr_xslvi.read().ar_bits.len;
    o_ddr_ar_size = wb_ddr_xslvi.read().ar_bits.size;
    o_ddr_ar_burst = wb_ddr_xslvi.read().ar_bits.burst;
    o_ddr_ar_lock = wb_ddr_xslvi.read().ar_bits.lock;
    o_ddr_ar_cache = wb_ddr_xslvi.read().ar_bits.cache;
    o_ddr_ar_prot = wb_ddr_xslvi.read().ar_bits.prot;
    o_ddr_ar_qos = wb_ddr_xslvi.read().ar_bits.qos;
    o_ddr_ar_valid = wb_ddr_xslvi.read().ar_valid;
    vb_ddr_xslvo.ar_ready = i_ddr_ar_ready.read();
    o_ddr_r_ready = wb_ddr_xslvi.read().r_ready;
    vb_ddr_xslvo.r_id = i_ddr_r_id.read();
    vb_ddr_xslvo.r_user = 0;
    vb_ddr_xslvo.r_data = i_ddr_r_data.read();
    vb_ddr_xslvo.r_resp = i_ddr_r_resp.read();
    vb_ddr_xslvo.r_last = i_ddr_r_last.read();
    vb_ddr_xslvo.r_valid = i_ddr_r_valid.read();
    wb_ddr_xslvo = vb_ddr_xslvo;                            // SystemC compatibility
    vb_ddr_mapinfo = bus0_mapinfo[CFG_BUS0_XSLV_DDR];
    vb_ddr_xcfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
    vb_ddr_xcfg.descrtype = PNP_CFG_TYPE_SLAVE;
    vb_ddr_xcfg.addr_start = vb_ddr_mapinfo.addr_start;
    vb_ddr_xcfg.addr_end = vb_ddr_mapinfo.addr_end;
    vb_ddr_xcfg.vid = VENDOR_OPTIMITECH;
    vb_ddr_xcfg.did = OPTIMITECH_SRAM;
    dev_pnp[SOC_PNP_DDR_AXI] = vb_ddr_xcfg;
    // SD-controlled disabled:
    dev_pnp[SOC_PNP_SDCTRL_REG] = dev_config_none;
    dev_pnp[SOC_PNP_SDCTRL_MEM] = dev_config_none;
}

}  // namespace debugger

