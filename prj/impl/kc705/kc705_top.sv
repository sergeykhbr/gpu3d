//!
//! Copyright 2022 Sergey Khabarov, sergeykhbr@gmail.com
//!
//! Licensed under the Apache License, Version 2.0 (the "License");
//! you may not use this file except in compliance with the License.
//! You may obtain a copy of the License at
//!
//!     http://www.apache.org/licenses/LICENSE-2.0
//!
//! Unless required by applicable law or agreed to in writing, software
//! distributed under the License is distributed on an "AS IS" BASIS,
//! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//! See the License for the specific language governing permissions and
//! limitations under the License.
//!

module kc705_top #(
    parameter SYSCLK_TYPE           = "NO_BUFFER",
    parameter SIM_BYPASS_INIT_CAL   = "OFF",
    parameter SIMULATION            = "FALSE",
    parameter int sim_uart_speedup_rate = 0                 // simulation UART speed-up: 0=no speed up, 1=2x, 2=4x, etc
)
( 
    //! Input reset. Active HIGH.
    input                     i_rst,
    //! Differential clock (LVDS) positive/negaive signal.
    input                     i_sclk_p,
    input                     i_sclk_n,
    //! GPIO: [11:4] LEDs; [3:0] DIP switch
    inout [11:0]              io_gpio,
    //! JTAG signals:
    input                     i_jtag_tck,
    input                     i_jtag_trst,
    input                     i_jtag_tms,
    input                     i_jtag_tdi,
    output                    o_jtag_tdo,
    output                    o_jtag_vref,
    //! UART1 signals:
    input                     i_uart1_rd,
    output                    o_uart1_td,
    // DDR3 signals:
    output o_ddr3_reset_n,
    output [0:0] o_ddr3_ck_n,
    output [0:0] o_ddr3_ck_p,
    output [0:0] o_ddr3_cke,
    output [0:0] o_ddr3_cs_n,
    output o_ddr3_ras_n,
    output o_ddr3_cas_n,
    output o_ddr3_we_n,
    output [7:0] o_ddr3_dm,
    output [2:0] o_ddr3_ba,
    output [13:0] o_ddr3_addr,
    inout [63:0] io_ddr3_dq,
    inout [7:0] io_ddr3_dqs_n,
    inout [7:0] io_ddr3_dqs_p,
    output [0:0] o_ddr3_odt,
    output o_ddr3_init_calib_complete
);

  import types_amba_pkg::*;
  import types_pnp_pkg::*;
  import kc705_top_pkg::*;

  logic             ib_rst;
  logic             ib_clk_tcxo;
  logic             ib_sclk_n;  

  logic [11:0]      ob_gpio_direction;
  logic [11:0]      ob_gpio_opins;
  logic [11:0]      ib_gpio_ipins;  
  //! JTAG signals:  
  logic             ib_jtag_tck;  
  logic             ib_jtag_trst; 
  logic             ib_jtag_tms; 
  logic             ib_jtag_tdi; 
  logic             ob_jtag_tdo; 
  logic             ob_jtag_vref;   

  logic             w_sys_rst;
  logic             w_sys_nrst;
  logic             w_dbg_nrst;
  logic             w_dmreset;
  logic             w_sys_clk;
  logic             w_ddr_clk;
  logic             w_pll_lock;

  // DDR interface
  mapinfo_type ddr_xmapinfo;
  dev_config_type ddr_xdev_cfg;
  axi4_slave_out_type ddr_xslvo;
  axi4_slave_in_type ddr_xslvi;

  mapinfo_type ddr_pmapinfo;
  dev_config_type ddr_pdev_cfg;
  apb_in_type ddr_apbi;
  apb_out_type ddr_apbo;

  logic w_ddr_ui_nrst;
  logic w_ddr_ui_clk;
  logic w_ddr3_init_calib_complete;

  // PRCI intefrace:
  mapinfo_type prci_pmapinfo;
  dev_config_type prci_dev_cfg;
  apb_in_type prci_apbi;
  apb_out_type prci_apbo;


  ibuf_tech irst0(.o(ib_rst),.i(i_rst));
  
  idsbuf_tech iclk0(.clk_p(i_sclk_p), .clk_n(i_sclk_n), .o_clk(ib_clk_tcxo));
  
  ibuf_tech ird1(.o(ib_uart1_rd),.i(i_uart1_rd));
  obuf_tech otd1(.o(o_uart1_td),.i(ob_uart1_td));

  genvar i;
  generate 
    for(i=0; i<=11; i++) begin: gpiox  
      iobuf_tech iob0(.o(ib_gpio_ipins[i]), .io(io_gpio[i]), .i(ob_gpio_opins[i]), .t(ob_gpio_direction[i])); 
    end
  endgenerate


  ibuf_tech ijtck0(.o(ib_jtag_tck),.i(i_jtag_tck));  
  ibuf_tech ijtrst0(.o(ib_jtag_trst),.i(i_jtag_trst)); 
  ibuf_tech ijtms0(.o(ib_jtag_tms),.i(i_jtag_tms));   
  ibuf_tech ijtdi0(.o(ib_jtag_tdi),.i(i_jtag_tdi)); 
  obuf_tech ojtdo0(.o(o_jtag_tdo),.i(ob_jtag_tdo));   
  obuf_tech ojvrf0(.o(o_jtag_vref),.i(ob_jtag_vref)); 

  assign o_ddr3_init_calib_complete = w_ddr3_init_calib_complete;
  

  SysPLL_tech pll0(
    .i_reset(ib_rst),
    .i_clk_tcxo(ib_clk_tcxo),
    .o_clk_sys(w_sys_clk),
    .o_clk_ddr(w_ddr_clk),
    .o_locked(w_pll_lock)
  );  

  
  // PLL and Reset Control Interface:
  apb_prci #(
    .async_reset(async_reset)
  ) prci0 (
    .i_clk(ib_clk_tcxo),
    .i_pwrreset(ib_rst),
    .i_dmireset(w_dmreset),
    .i_sys_locked(w_pll_lock),
    .i_ddr_locked(w_ddr3_init_calib_complete),
    .o_sys_rst(w_sys_rst),
    .o_sys_nrst(w_sys_nrst),
    .o_dbg_nrst(w_dbg_nrst),
    .i_mapinfo(prci_pmapinfo),
    .o_cfg(prci_dev_cfg),
    .i_apbi(prci_apbi),
    .o_apbo(prci_apbo)
  );

 
  riscv_soc #(
    .async_reset(async_reset),
    .sim_uart_speedup_rate(sim_uart_speedup_rate)
  ) soc0 (
    .i_sys_nrst (w_sys_nrst),
    .i_sys_clk (w_sys_clk),
    .i_dbg_nrst(w_dbg_nrst),
    .i_ddr_nrst (w_ddr_ui_nrst),
    .i_ddr_clk (w_ddr_ui_clk),
    //! GPIO.
    .i_gpio (ib_gpio_ipins),
    .o_gpio (ob_gpio_opins),
    .o_gpio_dir(ob_gpio_direction),
    //! JTAG signals:
    .i_jtag_tck(ib_jtag_tck),
    .i_jtag_trst(ib_jtag_trst),
    .i_jtag_tms(ib_jtag_tms),
    .i_jtag_tdi(ib_jtag_tdi),
    .o_jtag_tdo(ob_jtag_tdo),
    .o_jtag_vref(ob_jtag_vref),
    //! UART1 signals:
    .i_uart1_rd(ib_uart1_rd),
    .o_uart1_td(ob_uart1_td),
    // PRCI:
    .o_dmreset(w_dmreset),
    .o_prci_pmapinfo(prci_pmapinfo),
    .i_prci_pdevcfg(prci_dev_cfg),
    .o_prci_apbi(prci_apbi),
    .i_prci_apbo(prci_apbo),
    // DDR:
    .o_ddr_pmapinfo(ddr_pmapinfo),
    .i_ddr_pdevcfg(ddr_pdev_cfg),
    .o_ddr_apbi(ddr_apbi),
    .i_ddr_apbo(ddr_apbo),
    .o_ddr_xmapinfo(ddr_xmapinfo),
    .i_ddr_xdevcfg(ddr_xdev_cfg),
    .o_ddr_xslvi(ddr_xslvi),
    .i_ddr_xslvo(ddr_xslvo)
  );

ddr_tech #(
    .async_reset(async_reset),
    .SYSCLK_TYPE(SYSCLK_TYPE), // "NO_BUFFER,"DIFFERENTIAL"
    .SIM_BYPASS_INIT_CAL(SIM_BYPASS_INIT_CAL),  // "FAST"-for simulation true; "OFF"
    .SIMULATION(SIMULATION)
) ddr0 (
     // AXI memory access (ddr clock)
    .i_xslv_nrst(w_sys_nrst),
    .i_xslv_clk(ib_clk_tcxo),
    .i_xmapinfo(ddr_xmapinfo),
    .o_xcfg(ddr_xdev_cfg),
    .i_xslvi(ddr_xslvi),
    .o_xslvo(ddr_xslvo),
    // APB control interface (sys clock):
    .i_apb_nrst(w_sys_nrst),
    .i_apb_clk(w_sys_clk),
    .i_pmapinfo(ddr_pmapinfo),
    .o_pcfg(ddr_pdev_cfg),
    .i_apbi(ddr_apbi),
    .o_apbo(ddr_apbo),
    // to SOC:
    .o_ui_nrst(w_ddr_ui_nrst),  // xilinx generte ddr clock inside ddr controller
    .o_ui_clk(w_ddr_ui_clk),  // xilinx generte ddr clock inside ddr controller
    // DDR signals:
    .io_ddr3_dq(io_ddr3_dq),
    .io_ddr3_dqs_n(io_ddr3_dqs_n),
    .io_ddr3_dqs_p(io_ddr3_dqs_p),
    .o_ddr3_addr(o_ddr3_addr),
    .o_ddr3_ba(o_ddr3_ba),
    .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n),
    .o_ddr3_we_n(o_ddr3_we_n),
    .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_ck_p(o_ddr3_ck_p),
    .o_ddr3_ck_n(o_ddr3_ck_n),
    .o_ddr3_cke(o_ddr3_cke),
    .o_ddr3_cs_n(o_ddr3_cs_n),
    .o_ddr3_dm(o_ddr3_dm),
    .o_ddr3_odt(o_ddr3_odt),
    .o_init_calib_done(w_ddr3_init_calib_complete)
);

  
endmodule