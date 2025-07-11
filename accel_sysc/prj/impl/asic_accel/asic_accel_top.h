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
#include "../../../rtl/internal/ambalib/types_amba.h"
#include "../../../rtl/internal/ambalib/types_pnp.h"
#include "../../../rtl/internal/ambalib/types_dma.h"
#include "target_cfg.h"
#include "../../../rtl/sim/io/ids_tech.h"
#include "../../../rtl/sim/io/obuf_tech.h"
#include "../../../rtl/sim/io/iobuf_tech.h"
#include "../../../rtl/sim/io/obuf_arr_tech.h"
#include "../../../rtl/sim/io/ibuf_tech.h"
#include "../../../rtl/sim/pll/SysPLL_tech.h"
#include "../../../rtl/internal/misclib/apb_prci.h"
#include "../../../rtl/external/ddr3_phy/ddr3_tech.h"
#include "../../../rtl/internal/accel/accel_soc.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(asic_accel_top) {
 public:
    sc_in<bool> i_rst;                                      // Power-on system reset active HIGH
    // Differential clock (LVDS) positive/negaive signal.
    sc_in<bool> i_sclk_p;
    sc_in<bool> i_sclk_n;
    // GPIO: [11:4] LEDs; [3:0] DIP switch
    sc_inout<sc_uint<12>> io_gpio;
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
    // I2C master inerface to HDMI transmitter:
    sc_out<bool> o_i2c0_scl;                                // I2C clock upto 400 kHz (default 100 kHz)
    sc_inout<bool> io_i2c0_sda;                             // I2C bi-directional data
    sc_out<bool> o_i2c0_nreset;                             // I2C slave reset. PCA9548 I2C mux must be de-asserted.
    // Data interface to HDMI transmitter:
    sc_out<bool> o_hdmi_clk;                                // HDMI clock depends on resolution for 1366x768@60Hz is ~83MHz
    sc_out<bool> o_hdmi_hsync;                              // Horizontal sync. strob
    sc_out<bool> o_hdmi_vsync;                              // Vertical sync. strob
    sc_out<bool> o_hdmi_de;                                 // Data enable strob
    sc_out<sc_uint<18>> o_hdmi_d;                           // Data in format YCbCr 16-bits
    sc_out<bool> o_hdmi_spdif;                              // Sound channel output
    sc_in<bool> i_hdmi_spdif_out;                           // Reverse sound channel
    sc_in<bool> i_hdmi_int;                                 // External interrupt from HDMI transmitter


    asic_accel_top(sc_module_name name,
                   bool async_reset,
                   int sim_uart_speedup_rate);
    virtual ~asic_accel_top();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;
    int sim_uart_speedup_rate_;

    sc_signal<bool> ib_clk_tcxo;
    sc_signal<sc_uint<12>> ib_gpio_ipins;
    sc_signal<sc_uint<12>> ob_gpio_opins;
    sc_signal<sc_uint<12>> ob_gpio_direction;
    sc_signal<bool> ob_i2c0_scl;
    sc_signal<bool> ob_i2c0_sda;
    sc_signal<bool> ob_i2c0_sda_direction;
    sc_signal<bool> ib_i2c0_sda;
    sc_signal<bool> ob_i2c0_nreset;
    sc_signal<bool> ob_hdmi_hsync;
    sc_signal<bool> ob_hdmi_vsync;
    sc_signal<bool> ob_hdmi_de;
    sc_signal<sc_uint<18>> ob_hdmi_d;
    sc_signal<bool> ob_hdmi_spdif;
    sc_signal<bool> ib_hdmi_spdif_out;
    sc_signal<bool> ib_hdmi_int;
    sc_signal<bool> w_sys_rst;
    sc_signal<bool> w_sys_nrst;
    sc_signal<bool> w_dbg_nrst;
    sc_signal<bool> w_hdmi_nrst;
    sc_signal<bool> w_dmreset;
    sc_signal<bool> w_sys_clk;
    sc_signal<bool> w_ddr_clk;
    sc_signal<bool> w_pcie_clk;
    sc_signal<bool> w_pll_lock;
    sc_signal<mapinfo_type> ddr_xmapinfo;
    sc_signal<dev_config_type> ddr_xdev_cfg;
    sc_signal<axi4_slave_out_type> ddr_xslvo;
    sc_signal<axi4_slave_in_type> ddr_xslvi;
    sc_signal<mapinfo_type> ddr_pmapinfo;
    sc_signal<dev_config_type> ddr_pdev_cfg;
    sc_signal<apb_in_type> ddr_apbi;
    sc_signal<apb_out_type> ddr_apbo;
    sc_signal<bool> w_ddr_ui_nrst;
    sc_signal<bool> w_ddr_ui_clk;
    sc_signal<bool> w_ddr3_init_calib_complete;
    sc_signal<bool> w_pcie_phy_lnk_up;
    sc_signal<mapinfo_type> prci_pmapinfo;
    sc_signal<dev_config_type> prci_dev_cfg;
    sc_signal<apb_in_type> prci_apbi;
    sc_signal<apb_out_type> prci_apbo;
    sc_signal<bool> w_pcie_user_clk;
    sc_signal<bool> w_pcie_user_rst;
    sc_signal<bool> w_pcie_nrst;
    sc_signal<sc_uint<16>> wb_pcie_completer_id;
    sc_signal<pcie_dma64_out_type> pcie_dmao;
    sc_signal<pcie_dma64_in_type> pcie_dmai;

    ids_tech *iclk0;
    obuf_tech *oi2c0scl;
    obuf_tech *oi2c0nreset;
    iobuf_tech *ioi2c0sda;
    obuf_tech *ohdmiclk;
    obuf_tech *ohdmihsync;
    obuf_tech *ohdmivsync;
    obuf_tech *ohdmide;
    obuf_arr_tech<18> *ohdmid;
    obuf_tech *ohdmispdif;
    ibuf_tech *ihdmispdif;
    ibuf_tech *ihdmiint;
    SysPLL_tech *pll0;
    apb_prci *prci0;
    ddr3_tech *ddr3;
    accel_soc *soc0;

};

}  // namespace debugger

