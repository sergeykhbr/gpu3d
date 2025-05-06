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
#include "../../../rtl/sim/io/ids_tech.h"
#include "../../../rtl/sim/pll/SysPLL_tech.h"
#include "../../../rtl/internal/misclib/apb_prci.h"
#include "../../../rtl/internal/accel/accel_soc.h"
#include "sv_func.h"

namespace debugger {

SC_MODULE(asic_top) {
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


    asic_top(sc_module_name name,
             bool async_reset,
             int sim_uart_speedup_rate);
    virtual ~asic_top();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    bool async_reset_;
    int sim_uart_speedup_rate_;

    sc_signal<bool> ib_clk_tcxo;
    sc_signal<sc_uint<12>> ib_gpio_ipins;
    sc_signal<sc_uint<12>> ob_gpio_opins;
    sc_signal<sc_uint<12>> ob_gpio_direction;
    sc_signal<bool> w_sys_rst;
    sc_signal<bool> w_sys_nrst;
    sc_signal<bool> w_dbg_nrst;
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
    SysPLL_tech *pll0;
    apb_prci *prci0;
    accel_soc *soc0;

};

}  // namespace debugger

