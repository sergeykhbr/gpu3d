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
#include "types_accel_bus0.h"
#include "types_accel_bus1.h"
#include "../ambalib/types_amba.h"
#include "../ambalib/types_pnp.h"
#include "../pcie_dma/types_pcie_dma.h"
#include "../riverlib/river_cfg.h"
#include "../../../prj/impl/asic_accel/target_cfg.h"
#include "accel_axictrl_bus0.h"
#include "accel_axi2apb_bus1.h"
#include "../misclib/axi_rom.h"
#include "../misclib/axi_sram.h"
#include "../misclib/clint.h"
#include "../misclib/plic.h"
#include "../misclib/apb_uart.h"
#include "../misclib/apb_gpio.h"
#include "../misclib/apb_ddr.h"
#include "../misclib/apb_i2c.h"
#include "../hdmilib/hdmi_top.h"
#include "../pcie_dma/pcie_dma.h"
#include "../pcie_dma/apb_pcie.h"
#include "../misclib/apb_pnp.h"
#include "../riverlib/workgroup.h"
#include "../cdc/afifo_xslv.h"
#include "../cdc/afifo_xmst.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(accel_soc) {
 public:
    sc_in<bool> i_sys_nrst;                                 // Power-on system reset active LOW
    sc_in<bool> i_sys_clk;                                  // System Bus (AXI) clock
    sc_in<bool> i_cpu_nrst;                                 // CPUs/Groups reset active LOW
    sc_in<bool> i_cpu_clk;                                  // CPUs/Groups clock
    sc_in<bool> i_apb_nrst;                                 // APB sub-system reset: active LOW
    sc_in<bool> i_apb_clk;                                  // APB Bus clock
    sc_in<bool> i_dbg_nrst;                                 // Reset from Debug interface (DMI). Reset everything except DMI
    sc_in<bool> i_ddr_nrst;                                 // DDR related logic reset (AXI clock transformator)
    sc_in<bool> i_ddr_clk;                                  // DDR memoru clock
    // GPIO signals:
    sc_in<sc_uint<12>> i_gpio;
    sc_out<sc_uint<12>> o_gpio;
    sc_out<sc_uint<12>> o_gpio_dir;
    // JTAG signals:
    sc_in<bool> i_jtag_trst;
    sc_in<bool> i_jtag_tck;
    sc_in<bool> i_jtag_tms;
    sc_in<bool> i_jtag_tdi;
    sc_out<bool> o_jtag_tdo;
    sc_out<bool> o_jtag_vref;
    // UART1 signals
    sc_in<bool> i_uart1_rd;
    sc_out<bool> o_uart1_td;
    // I2C master interface for HDMI transmitter
    sc_out<bool> o_i2c0_scl;                                // Clock up to 400 KHz. Default 100 KHz
    sc_out<bool> o_i2c0_sda;                                // I2C output data
    sc_out<bool> o_i2c0_sda_dir;                            // output data tri-stte buffer control
    sc_in<bool> i_i2c0_sda;                                 // I2C input data
    sc_out<bool> o_i2c0_nreset;                             // I2C slave reset. PCA9548 I2C mux must be de-asserted.
    sc_in<bool> i_hdmi_nrst;                                // Reset: active LOW. Must be HIGH only after DDR 
    sc_in<bool> i_hdmi_clk;                                 // HDMI Clock depends on resolution: for 1366x768@60Hz is ~83 MHz
    sc_out<bool> o_hdmi_hsync;                              // Horizontal sync. strob
    sc_out<bool> o_hdmi_vsync;                              // Vertical sync. strob
    sc_out<bool> o_hdmi_de;                                 // Data enable strob
    sc_out<sc_uint<18>> o_hdmi_d;                           // Data in format YCbCr 16-bits
    sc_out<bool> o_hdmi_spdif;                              // Sound channel output
    sc_in<bool> i_hdmi_spdif_out;                           // Reverse sound channel
    sc_in<bool> i_hdmi_int;                                 // External interrupt from HDMI transmitter
    // PLL and Reset interfaces:
    sc_out<bool> o_dmreset;                                 // Debug reset request. Everything except DMI.
    sc_out<mapinfo_type> o_prci_pmapinfo;                   // PRCI mapping information
    sc_in<dev_config_type> i_prci_pdevcfg;                  // PRCI device descriptor
    sc_out<apb_in_type> o_prci_apbi;                        // APB: PLL and Reset configuration interface
    sc_in<apb_out_type> i_prci_apbo;                        // APB: PLL and Reset configuration interface
    // DDR interfaces:
    sc_out<sc_uint<CFG_SYSBUS_ID_BITS>> o_ddr_aw_id;
    sc_out<sc_uint<30>> o_ddr_aw_addr;                      // 1 GB by default
    sc_out<sc_uint<8>> o_ddr_aw_len;
    sc_out<sc_uint<3>> o_ddr_aw_size;
    sc_out<sc_uint<2>> o_ddr_aw_burst;
    sc_out<bool> o_ddr_aw_lock;
    sc_out<sc_uint<4>> o_ddr_aw_cache;
    sc_out<sc_uint<3>> o_ddr_aw_prot;
    sc_out<sc_uint<4>> o_ddr_aw_qos;
    sc_out<bool> o_ddr_aw_valid;
    sc_in<bool> i_ddr_aw_ready;
    sc_out<sc_uint<64>> o_ddr_w_data;
    sc_out<sc_uint<8>> o_ddr_w_strb;
    sc_out<bool> o_ddr_w_last;
    sc_out<bool> o_ddr_w_valid;
    sc_in<bool> i_ddr_w_ready;
    sc_out<bool> o_ddr_b_ready;
    sc_in<sc_uint<CFG_SYSBUS_ID_BITS>> i_ddr_b_id;
    sc_in<sc_uint<2>> i_ddr_b_resp;
    sc_in<bool> i_ddr_b_valid;
    sc_out<sc_uint<CFG_SYSBUS_ID_BITS>> o_ddr_ar_id;
    sc_out<sc_uint<30>> o_ddr_ar_addr;                      // 1 GB by default
    sc_out<sc_uint<8>> o_ddr_ar_len;
    sc_out<sc_uint<3>> o_ddr_ar_size;
    sc_out<sc_uint<2>> o_ddr_ar_burst;
    sc_out<bool> o_ddr_ar_lock;
    sc_out<sc_uint<4>> o_ddr_ar_cache;
    sc_out<sc_uint<3>> o_ddr_ar_prot;
    sc_out<sc_uint<4>> o_ddr_ar_qos;
    sc_out<bool> o_ddr_ar_valid;
    sc_in<bool> i_ddr_ar_ready;
    sc_out<bool> o_ddr_r_ready;
    sc_in<sc_uint<CFG_SYSBUS_ID_BITS>> i_ddr_r_id;
    sc_in<sc_uint<64>> i_ddr_r_data;
    sc_in<sc_uint<2>> i_ddr_r_resp;
    sc_in<bool> i_ddr_r_last;
    sc_in<bool> i_ddr_r_valid;
    sc_in<bool> i_ddr_app_init_calib_done;                  // DDR initital calibration done
    sc_in<sc_uint<12>> i_ddr_app_temp;                      // Device temperature
    sc_out<bool> o_ddr_app_sr_req;                          // Self-refresh request (low-power mode)
    sc_out<bool> o_ddr_app_ref_req;                         // Periodic refresh request ~7.8 us
    sc_out<bool> o_ddr_app_zq_req;                          // ZQ calibration request. Startup and runtime maintenance
    sc_in<bool> i_ddr_app_sr_active;                        // Self-resfresh is active (low-power mode or sleep)
    sc_in<bool> i_ddr_app_ref_ack;                          // Refresh request acknowledged
    sc_in<bool> i_ddr_app_zq_ack;                           // ZQ calibration request acknowledged
    // PCIE endpoint interface:
    sc_in<bool> i_pcie_clk;                                 // PCIE clock generated by end-point
    sc_in<bool> i_pcie_nrst;                                // PCIE reset active LOW generated inside of PRCI
    sc_in<sc_uint<16>> i_pcie_completer_id;                 // Bus, Device, Function
    sc_out<pcie_dma64_out_type> o_pcie_dmao;                // PCIE DMA enging interface
    sc_in<pcie_dma64_in_type> i_pcie_dmai;                  // PCIE DMA enging interface

    void comb();

    accel_soc(sc_module_name name,
              bool async_reset,
              int sim_uart_speedup_rate);
    virtual ~accel_soc();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;
    int sim_uart_speedup_rate_;


    // Hardware SoC Identificator.
    // Read Only unique platform identificator that could be read by FW
    static const uint32_t SOC_HW_ID = 0x20241103;

    // UARTx fifo log2(size) in bytes:
    static const int SOC_UART1_LOG2_FIFOSZ = 4;

    // Number of available generic IO pins:
    static const int SOC_GPIO0_WIDTH = 12;

    // Number of contexts in PLIC controller.
    // Example FU740: S7 Core0 (M) + 4xU74 Cores (M+S).
    static const int SOC_PLIC_CONTEXT_TOTAL = 9;
    // Any number up to 1024. Zero interrupt must be 0.
    static const int SOC_PLIC_IRQ_TOTAL = 73;

    sc_signal<axi4_master_out_type> acpo;
    sc_signal<axi4_master_in_type> acpi;
    bus0_mapinfo_vector bus0_mapinfo;
    bus0_xmst_in_vector aximi;
    bus0_xmst_out_vector aximo;
    bus0_xslv_in_vector axisi;
    bus0_xslv_out_vector axiso;
    bus1_mapinfo_vector bus1_mapinfo;
    bus1_apb_in_vector apbi;
    bus1_apb_out_vector apbo;
    soc_pnp_vector dev_pnp;
    sc_signal<axi4_master_out_type> wb_group0_xmsto;        // CPU clock domain
    sc_signal<axi4_master_in_type> wb_group0_xmsti;         // CPU clock domain
    sc_signal<axi4_slave_in_type> wb_ddr_xslvi;             // DDR clock domain
    sc_signal<axi4_slave_out_type> wb_ddr_xslvo;            // DDR clock domain
    sc_signal<axi4_slave_in_type> wb_pbridge_xslvi;         // APB clock domain
    sc_signal<axi4_slave_out_type> wb_pbridge_xslvo;        // APB clock domain
    sc_signal<sc_uint<64>> wb_clint_mtimer;
    sc_signal<sc_uint<CFG_CPU_MAX>> wb_clint_msip;
    sc_signal<sc_uint<CFG_CPU_MAX>> wb_clint_mtip;
    sc_signal<sc_uint<SOC_PLIC_CONTEXT_TOTAL>> wb_plic_xeip;
    sc_signal<sc_uint<CFG_CPU_MAX>> wb_plic_meip;
    sc_signal<sc_uint<CFG_CPU_MAX>> wb_plic_seip;
    sc_signal<bool> w_irq_uart1;
    sc_signal<sc_uint<SOC_GPIO0_WIDTH>> wb_irq_gpio;
    sc_signal<bool> w_irq_pnp;
    sc_signal<sc_biguint<SOC_PLIC_IRQ_TOTAL>> wb_ext_irqs;
    sc_signal<sc_uint<4>> wb_pcie_dma_state;
    sc_signal<bool> w_dbg_valid;
    sc_signal<sc_uint<64>> w_dbg_payload;
    sc_signal<bool> w_irq_i2c0;

    accel_axictrl_bus0 *bus0;
    accel_axi2apb_bus1 *bus1;
    axi_rom<CFG_BOOTROM_LOG2_SIZE> *rom0;
    axi_sram<CFG_SRAM_LOG2_SIZE> *sram0;
    clint<CFG_CPU_MAX> *clint0;
    plic<SOC_PLIC_CONTEXT_TOTAL, SOC_PLIC_IRQ_TOTAL> *plic0;
    apb_uart<SOC_UART1_LOG2_FIFOSZ> *uart1;
    apb_gpio<SOC_GPIO0_WIDTH> *gpio0;
    apb_ddr *pddr0;
    apb_i2c *i2c0;
    hdmi_top *hdmi0;
    pcie_dma *pcidma0;
    apb_pcie *ppcie0;
    apb_pnp<SOC_PNP_TOTAL> *pnp0;
    Workgroup *group0;
    afifo_xslv<2, 9> *afifo_ddr0;
    afifo_xslv<2, 2> *afifo_apb0;
    afifo_xmst<2, 3> *afifo_group0;

};

}  // namespace debugger

