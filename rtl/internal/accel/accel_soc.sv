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

module accel_soc #(
    parameter logic async_reset = 1'b0,
    parameter int sim_uart_speedup_rate = 0                 // simulation UART speed-up: 0=no speed up, 1=2x, 2=4x, etc
)
(
    input logic i_sys_nrst,                                 // Power-on system reset active LOW
    input logic i_sys_clk,                                  // System Bus (AXI) clock
    input logic i_cpu_nrst,                                 // CPUs/Groups reset active LOW
    input logic i_cpu_clk,                                  // CPUs/Groups clock
    input logic i_apb_nrst,                                 // APB sub-system reset: active LOW
    input logic i_apb_clk,                                  // APB Bus clock
    input logic i_dbg_nrst,                                 // Reset from Debug interface (DMI). Reset everything except DMI
    input logic i_ddr_nrst,                                 // DDR related logic reset (AXI clock transformator)
    input logic i_ddr_clk,                                  // DDR memoru clock
    // GPIO signals:
    input logic [11:0] i_gpio,
    output logic [11:0] o_gpio,
    output logic [11:0] o_gpio_dir,
    // JTAG signals:
    input logic i_jtag_trst,
    input logic i_jtag_tck,
    input logic i_jtag_tms,
    input logic i_jtag_tdi,
    output logic o_jtag_tdo,
    output logic o_jtag_vref,
    // UART1 signals
    input logic i_uart1_rd,
    output logic o_uart1_td,
    // I2C master interface for HDMI transmitter
    output logic o_i2c0_scl,                                // Clock up to 400 KHz. Default 100 KHz
    output logic o_i2c0_sda,                                // I2C output data
    output logic o_i2c0_sda_dir,                            // output data tri-stte buffer control
    input logic i_i2c0_sda,                                 // I2C input data
    output logic o_i2c0_nreset,                             // I2C slave reset. PCA9548 I2C mux must be de-asserted.
    input logic i_hdmi_nrst,                                // Reset: active LOW. Must be HIGH only after DDR 
    input logic i_hdmi_clk,                                 // HDMI Clock depends on resolution: for 1366x768@60Hz is ~83 MHz
    output logic o_hdmi_hsync,                              // Horizontal sync. strob
    output logic o_hdmi_vsync,                              // Vertical sync. strob
    output logic o_hdmi_de,                                 // Data enable strob
    output logic [17:0] o_hdmi_d,                           // Data in format YCbCr 16-bits
    output logic o_hdmi_spdif,                              // Sound channel output
    input logic i_hdmi_spdif_out,                           // Reverse sound channel
    input logic i_hdmi_int,                                 // External interrupt from HDMI transmitter
    // PLL and Reset interfaces:
    output logic o_dmreset,                                 // Debug reset request. Everything except DMI.
    output types_amba_pkg::mapinfo_type o_prci_pmapinfo,    // PRCI mapping information
    input types_pnp_pkg::dev_config_type i_prci_pdevcfg,    // PRCI device descriptor
    output types_amba_pkg::apb_in_type o_prci_apbi,         // APB: PLL and Reset configuration interface
    input types_amba_pkg::apb_out_type i_prci_apbo,         // APB: PLL and Reset configuration interface
    // DDR interfaces:
    output logic [types_amba_pkg::CFG_SYSBUS_ID_BITS-1:0] o_ddr_aw_id,
    output logic [29:0] o_ddr_aw_addr,                      // 1 GB by default
    output logic [7:0] o_ddr_aw_len,
    output logic [2:0] o_ddr_aw_size,
    output logic [1:0] o_ddr_aw_burst,
    output logic o_ddr_aw_lock,
    output logic [3:0] o_ddr_aw_cache,
    output logic [2:0] o_ddr_aw_prot,
    output logic [3:0] o_ddr_aw_qos,
    output logic o_ddr_aw_valid,
    input logic i_ddr_aw_ready,
    output logic [63:0] o_ddr_w_data,
    output logic [7:0] o_ddr_w_strb,
    output logic o_ddr_w_last,
    output logic o_ddr_w_valid,
    input logic i_ddr_w_ready,
    output logic o_ddr_b_ready,
    input logic [types_amba_pkg::CFG_SYSBUS_ID_BITS-1:0] i_ddr_b_id,
    input logic [1:0] i_ddr_b_resp,
    input logic i_ddr_b_valid,
    output logic [types_amba_pkg::CFG_SYSBUS_ID_BITS-1:0] o_ddr_ar_id,
    output logic [29:0] o_ddr_ar_addr,                      // 1 GB by default
    output logic [7:0] o_ddr_ar_len,
    output logic [2:0] o_ddr_ar_size,
    output logic [1:0] o_ddr_ar_burst,
    output logic o_ddr_ar_lock,
    output logic [3:0] o_ddr_ar_cache,
    output logic [2:0] o_ddr_ar_prot,
    output logic [3:0] o_ddr_ar_qos,
    output logic o_ddr_ar_valid,
    input logic i_ddr_ar_ready,
    output logic o_ddr_r_ready,
    input logic [types_amba_pkg::CFG_SYSBUS_ID_BITS-1:0] i_ddr_r_id,
    input logic [63:0] i_ddr_r_data,
    input logic [1:0] i_ddr_r_resp,
    input logic i_ddr_r_last,
    input logic i_ddr_r_valid,
    input logic i_ddr_app_init_calib_done,                  // DDR initital calibration done
    input logic [11:0] i_ddr_app_temp,                      // Device temperature
    output logic o_ddr_app_sr_req,                          // Self-refresh request (low-power mode)
    output logic o_ddr_app_ref_req,                         // Periodic refresh request ~7.8 us
    output logic o_ddr_app_zq_req,                          // ZQ calibration request. Startup and runtime maintenance
    input logic i_ddr_app_sr_active,                        // Self-resfresh is active (low-power mode or sleep)
    input logic i_ddr_app_ref_ack,                          // Refresh request acknowledged
    input logic i_ddr_app_zq_ack,                           // ZQ calibration request acknowledged
    // PCIE endpoint interface:
    input logic i_pcie_clk,                                 // PCIE clock generated by end-point
    input logic i_pcie_nrst,                                // PCIE reset active LOW generated inside of PRCI
    input logic [15:0] i_pcie_completer_id,                 // Bus, Device, Function
    output types_pcie_dma_pkg::pcie_dma64_out_type o_pcie_dmao,// PCIE DMA enging interface
    input types_pcie_dma_pkg::pcie_dma64_in_type i_pcie_dmai// PCIE DMA enging interface
);

import types_accel_bus0_pkg::*;
import types_accel_bus1_pkg::*;
import types_amba_pkg::*;
import types_pnp_pkg::*;
import types_pcie_dma_pkg::*;
import river_cfg_pkg::*;
import target_cfg_pkg::*;
import accel_soc_pkg::*;

axi4_master_out_type acpo;
axi4_master_in_type acpi;
bus0_mapinfo_vector bus0_mapinfo;
bus0_xmst_in_vector aximi;
bus0_xmst_out_vector aximo;
bus0_xslv_in_vector axisi;
bus0_xslv_out_vector axiso;
bus1_mapinfo_vector bus1_mapinfo;
bus1_apb_in_vector apbi;
bus1_apb_out_vector apbo;
soc_pnp_vector dev_pnp;
axi4_master_out_type wb_group0_xmsto;                       // CPU clock domain
axi4_master_in_type wb_group0_xmsti;                        // CPU clock domain
axi4_slave_in_type wb_ddr_xslvi;                            // DDR clock domain
axi4_slave_out_type wb_ddr_xslvo;                           // DDR clock domain
axi4_slave_in_type wb_pbridge_xslvi;                        // APB clock domain
axi4_slave_out_type wb_pbridge_xslvo;                       // APB clock domain
logic [63:0] wb_clint_mtimer;
logic [CFG_CPU_MAX-1:0] wb_clint_msip;
logic [CFG_CPU_MAX-1:0] wb_clint_mtip;
logic [SOC_PLIC_CONTEXT_TOTAL-1:0] wb_plic_xeip;
logic [CFG_CPU_MAX-1:0] wb_plic_meip;
logic [CFG_CPU_MAX-1:0] wb_plic_seip;
logic w_irq_uart1;
logic [SOC_GPIO0_WIDTH-1:0] wb_irq_gpio;
logic w_irq_pnp;
logic [SOC_PLIC_IRQ_TOTAL-1:0] wb_ext_irqs;
logic [3:0] wb_pcie_dma_state;
logic w_dbg_valid;
logic [63:0] w_dbg_payload;
logic w_irq_i2c0;

accel_axictrl_bus0 #(
    .async_reset(async_reset)
) bus0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .o_cfg(dev_pnp[SOC_PNP_XCTRL0]),
    .i_xmsto(aximo),
    .o_xmsti(aximi),
    .i_xslvo(axiso),
    .o_xslvi(axisi),
    .o_mapinfo(bus0_mapinfo)
);

accel_axi2apb_bus1 #(
    .async_reset(async_reset)
) bus1 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_PBRIDGE]),
    .o_cfg(dev_pnp[SOC_PNP_PBRIDGE0]),
    .i_xslvi(wb_pbridge_xslvi),
    .o_xslvo(wb_pbridge_xslvo),
    .i_apbo(apbo),
    .o_apbi(apbi),
    .o_mapinfo(bus1_mapinfo)
);

afifo_xmst #(
    .abits_depth(2),
    .dbits_depth(3)
) afifo_group0 (
    .i_xmst_nrst(i_cpu_nrst),
    .i_xmst_clk(i_cpu_clk),
    .i_xmsto(wb_group0_xmsto),
    .o_xmsti(wb_group0_xmsti),
    .i_xslv_nrst(i_sys_nrst),
    .i_xslv_clk(i_sys_clk),
    .o_xslvi(aximo[CFG_BUS0_XMST_GROUP0]),
    .i_xslvo(aximi[CFG_BUS0_XMST_GROUP0])
);

afifo_xslv #(
    .abits_depth(2),
    .dbits_depth(2)
) afifo_apb0 (
    .i_xslv_nrst(i_sys_nrst),
    .i_xslv_clk(i_sys_clk),
    .i_xslvi(axisi[CFG_BUS0_XSLV_PBRIDGE]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_PBRIDGE]),
    .i_xmst_nrst(i_apb_nrst),
    .i_xmst_clk(i_apb_clk),
    .o_xmsto(wb_pbridge_xslvi),
    .i_xmsti(wb_pbridge_xslvo)
);

afifo_xslv #(
    .abits_depth(2),
    .dbits_depth(9)
) afifo_ddr0 (
    .i_xslv_nrst(i_sys_nrst),
    .i_xslv_clk(i_sys_clk),
    .i_xslvi(axisi[CFG_BUS0_XSLV_DDR]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_DDR]),
    .i_xmst_nrst(i_ddr_nrst),
    .i_xmst_clk(i_ddr_clk),
    .o_xmsto(wb_ddr_xslvi),
    .i_xmsti(wb_ddr_xslvo)
);

Workgroup #(
    .async_reset(async_reset),
    .cpu_num(CFG_CPU_NUM),
    .l2cache_ena(CFG_L2CACHE_ENA)
) group0 (
    .i_cores_nrst(i_cpu_nrst),
    .i_dmi_nrst(i_dbg_nrst),
    .i_clk(i_cpu_clk),
    .i_trst(i_jtag_trst),
    .i_tck(i_jtag_tck),
    .i_tms(i_jtag_tms),
    .i_tdi(i_jtag_tdi),
    .o_tdo(o_jtag_tdo),
    .i_msip(wb_clint_msip),
    .i_mtip(wb_clint_mtip),
    .i_meip(wb_plic_meip),
    .i_seip(wb_plic_seip),
    .i_mtimer(wb_clint_mtimer),
    .i_acpo(acpo),
    .o_acpi(acpi),
    .o_xmst_cfg(dev_pnp[SOC_PNP_GROUP0]),
    .i_msti(wb_group0_xmsti),
    .o_msto(wb_group0_xmsto),
    .i_dmi_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_DMI]),
    .o_dmi_cfg(dev_pnp[SOC_PNP_DMI]),
    .i_dmi_apbi(apbi[CFG_BUS1_PSLV_DMI]),
    .o_dmi_apbo(apbo[CFG_BUS1_PSLV_DMI]),
    .o_dmreset(o_dmreset)
);

axi_rom #(
    .abits(CFG_BOOTROM_LOG2_SIZE),
    .async_reset(async_reset),
    .filename(CFG_BOOTROM_FILE_HEX)
) rom0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_BOOTROM]),
    .o_cfg(dev_pnp[SOC_PNP_BOOTROM]),
    .i_xslvi(axisi[CFG_BUS0_XSLV_BOOTROM]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_BOOTROM])
);

axi_sram #(
    .abits(CFG_SRAM_LOG2_SIZE),
    .async_reset(async_reset)
) sram0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_SRAM]),
    .o_cfg(dev_pnp[SOC_PNP_SRAM]),
    .i_xslvi(axisi[CFG_BUS0_XSLV_SRAM]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_SRAM])
);

clint #(
    .cpu_total(CFG_CPU_MAX),
    .async_reset(async_reset)
) clint0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_CLINT]),
    .o_cfg(dev_pnp[SOC_PNP_CLINT]),
    .i_xslvi(axisi[CFG_BUS0_XSLV_CLINT]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_CLINT]),
    .o_mtimer(wb_clint_mtimer),
    .o_msip(wb_clint_msip),
    .o_mtip(wb_clint_mtip)
);

plic #(
    .ctxmax(SOC_PLIC_CONTEXT_TOTAL),
    .irqmax(SOC_PLIC_IRQ_TOTAL),
    .async_reset(async_reset)
) plic0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .i_mapinfo(bus0_mapinfo[CFG_BUS0_XSLV_PLIC]),
    .o_cfg(dev_pnp[SOC_PNP_PLIC]),
    .i_xslvi(axisi[CFG_BUS0_XSLV_PLIC]),
    .o_xslvo(axiso[CFG_BUS0_XSLV_PLIC]),
    .i_irq_request(wb_ext_irqs),
    .o_ip(wb_plic_xeip)
);

apb_uart #(
    .log2_fifosz(SOC_UART1_LOG2_FIFOSZ),
    .async_reset(async_reset),
    .sim_speedup_rate(sim_uart_speedup_rate)
) uart1 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_UART1]),
    .o_cfg(dev_pnp[SOC_PNP_UART1]),
    .i_apbi(apbi[CFG_BUS1_PSLV_UART1]),
    .o_apbo(apbo[CFG_BUS1_PSLV_UART1]),
    .i_rd(i_uart1_rd),
    .o_td(o_uart1_td),
    .o_irq(w_irq_uart1)
);

apb_gpio #(
    .width(SOC_GPIO0_WIDTH),
    .async_reset(async_reset)
) gpio0 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_GPIO]),
    .o_cfg(dev_pnp[SOC_PNP_GPIO]),
    .i_apbi(apbi[CFG_BUS1_PSLV_GPIO]),
    .o_apbo(apbo[CFG_BUS1_PSLV_GPIO]),
    .i_gpio(i_gpio),
    .o_gpio_dir(o_gpio_dir),
    .o_gpio(o_gpio),
    .o_irq(wb_irq_gpio)
);

apb_ddr #(
    .async_reset(async_reset)
) pddr0 (
    .i_apb_nrst(i_apb_nrst),
    .i_apb_clk(i_apb_clk),
    .i_ddr_nrst(i_ddr_nrst),
    .i_ddr_clk(i_ddr_clk),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_DDR]),
    .o_cfg(dev_pnp[SOC_PNP_DDR_APB]),
    .i_apbi(apbi[CFG_BUS1_PSLV_DDR]),
    .o_apbo(apbo[CFG_BUS1_PSLV_DDR]),
    .i_init_calib_done(i_ddr_app_init_calib_done),
    .i_device_temp(i_ddr_app_temp),
    .o_sr_req(o_ddr_app_sr_req),
    .o_ref_req(o_ddr_app_ref_req),
    .o_zq_req(o_ddr_app_zq_req),
    .i_sr_active(i_ddr_app_sr_active),
    .i_ref_ack(i_ddr_app_ref_ack),
    .i_zq_ack(i_ddr_app_zq_ack)
);

apb_i2c #(
    .async_reset(async_reset)
) i2c0 (
    .i_clk(i_sys_clk),
    .i_nrst(i_sys_nrst),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_I2C0]),
    .o_cfg(dev_pnp[SOC_PNP_I2C]),
    .i_apbi(apbi[CFG_BUS1_PSLV_I2C0]),
    .o_apbo(apbo[CFG_BUS1_PSLV_I2C0]),
    .o_scl(o_i2c0_scl),
    .o_sda(o_i2c0_sda),
    .o_sda_dir(o_i2c0_sda_dir),
    .i_sda(i_i2c0_sda),
    .o_irq(w_irq_i2c0),
    .o_nreset(o_i2c0_nreset)
);

hdmi_top #(
    .async_reset(async_reset),
    .WIDTH(12'd1366),
    .HEIGHT(12'd768)
) hdmi0 (
    .i_nrst(i_sys_nrst),
    .i_clk(i_sys_clk),
    .i_hdmi_nrst(i_hdmi_nrst),
    .i_hdmi_clk(i_hdmi_clk),
    .o_hsync(o_hdmi_hsync),
    .o_vsync(o_hdmi_vsync),
    .o_de(o_hdmi_de),
    .o_data(o_hdmi_d),
    .o_spdif(o_hdmi_spdif),
    .i_spdif_out(i_hdmi_spdif_out),
    .i_irq(i_hdmi_int),
    .o_xmst_cfg(dev_pnp[SOC_PNP_HDMI_DMA]),
    .i_xmsti(aximi[CFG_BUS0_XMST_HDMI]),
    .o_xmsto(aximo[CFG_BUS0_XMST_HDMI])
);

// See reference: pg054-7series-pcie.pdf
pcie_dma #(
    .async_reset(async_reset)
) pcidma0 (
    .i_nrst(i_pcie_nrst),
    .i_clk(i_sys_clk),
    .i_pcie_phy_clk(i_pcie_clk),
    .i_pcie_completer_id(i_pcie_completer_id),
    .o_dma_state(wb_pcie_dma_state),
    .i_pcie_dmai(i_pcie_dmai),
    .o_pcie_dmao(o_pcie_dmao),
    .o_xmst_cfg(dev_pnp[SOC_PNP_PCIE_DMA]),
    .i_xmsti(aximi[CFG_BUS0_XMST_PCIE]),
    .o_xmsto(aximo[CFG_BUS0_XMST_PCIE]),
    .o_dbg_valid(w_dbg_valid),
    .o_dbg_payload(w_dbg_payload)
);

apb_pcie #(
    .async_reset(async_reset)
) ppcie0 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_PCIE]),
    .o_cfg(dev_pnp[SOC_PNP_PCIE_APB]),
    .i_apbi(apbi[CFG_BUS1_PSLV_PCIE]),
    .o_apbo(apbo[CFG_BUS1_PSLV_PCIE]),
    .i_pcie_completer_id(i_pcie_completer_id),
    .i_dma_state(wb_pcie_dma_state),
    .i_dbg_valid(w_dbg_valid),
    .i_dbg_payload(w_dbg_payload)
);

apb_pnp #(
    .cfg_slots(SOC_PNP_TOTAL),
    .async_reset(async_reset),
    .hwid(SOC_HW_ID),
    .cpu_max(CFG_CPU_NUM),
    .l2cache_ena(CFG_L2CACHE_ENA),
    .plic_irq_max(SOC_PLIC_IRQ_TOTAL)
) pnp0 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(bus1_mapinfo[CFG_BUS1_PSLV_PNP]),
    .i_cfg(dev_pnp),
    .o_cfg(dev_pnp[SOC_PNP_PNP]),
    .i_apbi(apbi[CFG_BUS1_PSLV_PNP]),
    .o_apbo(apbo[CFG_BUS1_PSLV_PNP]),
    .o_irq(w_irq_pnp)
);

always_comb
begin: comb_proc
    logic v_gnd1;
    logic [SOC_PLIC_IRQ_TOTAL-1:0] vb_ext_irqs;
    dev_config_type vb_ddr_xcfg;
    mapinfo_type vb_ddr_mapinfo;
    axi4_slave_out_type vb_ddr_xslvo;                       // systemc compatibility

    v_gnd1 = 1'b0;
    vb_ext_irqs = '0;


    // assign interrupts:
    vb_ext_irqs[22: 0] = '0;
    vb_ext_irqs[((23 + SOC_GPIO0_WIDTH) - 1): 23] = wb_irq_gpio;// FU740: 16 bits, current 12-bits
    vb_ext_irqs[39] = w_irq_uart1;
    vb_ext_irqs[40] = w_irq_i2c0;
    vb_ext_irqs[69: 41] = '0;
    vb_ext_irqs[70] = w_irq_pnp;
    vb_ext_irqs[(SOC_PLIC_IRQ_TOTAL - 1): 71] = '0;
    wb_ext_irqs = vb_ext_irqs;

    // FU740 implements 5 cores (we implement only 4):
    //     Hart0 - M-mode only (S7 Core RV64IMAC)
    //     Hart1..4 - M+S modes (U74 Cores RV64GC)
    // Hart4 ignored
    wb_plic_meip = {wb_plic_xeip[5],
            wb_plic_xeip[3],
            wb_plic_xeip[1],
            wb_plic_xeip[0]};
    wb_plic_seip = {wb_plic_xeip[6],
            wb_plic_xeip[4],
            wb_plic_xeip[2],
            v_gnd1};

    o_jtag_vref = 1'b1;

    // Nullify emty AXI-slots:
    acpo = axi4_master_out_none;

    // PRCI:
    o_prci_apbi = apbi[CFG_BUS1_PSLV_PRCI];
    apbo[CFG_BUS1_PSLV_PRCI] = i_prci_apbo;
    dev_pnp[SOC_PNP_PRCI] = i_prci_pdevcfg;

    // DDR:
    o_ddr_aw_id = wb_ddr_xslvi.aw_id;
    // Warning: we should do (addr - start_addr)[29:0], but BAR is 0x80000000
    o_ddr_aw_addr = wb_ddr_xslvi.aw_bits.addr[29: 0];
    o_ddr_aw_len = wb_ddr_xslvi.aw_bits.len;
    o_ddr_aw_size = wb_ddr_xslvi.aw_bits.size;
    o_ddr_aw_burst = wb_ddr_xslvi.aw_bits.burst;
    o_ddr_aw_lock = wb_ddr_xslvi.aw_bits.lock;
    o_ddr_aw_cache = wb_ddr_xslvi.aw_bits.cache;
    o_ddr_aw_prot = wb_ddr_xslvi.aw_bits.prot;
    o_ddr_aw_qos = wb_ddr_xslvi.aw_bits.qos;
    o_ddr_aw_valid = wb_ddr_xslvi.aw_valid;
    vb_ddr_xslvo.aw_ready = i_ddr_aw_ready;
    o_ddr_w_data = wb_ddr_xslvi.w_data;
    o_ddr_w_strb = wb_ddr_xslvi.w_strb;
    o_ddr_w_last = wb_ddr_xslvi.w_last;
    o_ddr_w_valid = wb_ddr_xslvi.w_valid;
    vb_ddr_xslvo.w_ready = i_ddr_w_ready;
    o_ddr_b_ready = wb_ddr_xslvi.b_ready;
    vb_ddr_xslvo.b_id = i_ddr_b_id;
    vb_ddr_xslvo.b_resp = i_ddr_b_resp;
    vb_ddr_xslvo.b_valid = i_ddr_b_valid;
    vb_ddr_xslvo.b_user = 3'd0;
    o_ddr_ar_id = wb_ddr_xslvi.ar_id;
    // Warning: we should do (addr - start_addr)[29:0], but BAR is 0x80000000
    o_ddr_ar_addr = wb_ddr_xslvi.ar_bits.addr[29: 0];
    o_ddr_ar_len = wb_ddr_xslvi.ar_bits.len;
    o_ddr_ar_size = wb_ddr_xslvi.ar_bits.size;
    o_ddr_ar_burst = wb_ddr_xslvi.ar_bits.burst;
    o_ddr_ar_lock = wb_ddr_xslvi.ar_bits.lock;
    o_ddr_ar_cache = wb_ddr_xslvi.ar_bits.cache;
    o_ddr_ar_prot = wb_ddr_xslvi.ar_bits.prot;
    o_ddr_ar_qos = wb_ddr_xslvi.ar_bits.qos;
    o_ddr_ar_valid = wb_ddr_xslvi.ar_valid;
    vb_ddr_xslvo.ar_ready = i_ddr_ar_ready;
    o_ddr_r_ready = wb_ddr_xslvi.r_ready;
    vb_ddr_xslvo.r_id = i_ddr_r_id;
    vb_ddr_xslvo.r_user = 3'd0;
    vb_ddr_xslvo.r_data = i_ddr_r_data;
    vb_ddr_xslvo.r_resp = i_ddr_r_resp;
    vb_ddr_xslvo.r_last = i_ddr_r_last;
    vb_ddr_xslvo.r_valid = i_ddr_r_valid;
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
end: comb_proc

endmodule: accel_soc
