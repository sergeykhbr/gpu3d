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
    output o_ddr3_init_calib_complete,
    // PCI-Express Interface
    input [0:0] i_pcie_rxn,
    input [0:0] i_pcie_rxp,
    output [0:0] o_pcie_txn,
    output [0:0] o_pcie_txp

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
  logic             w_pcie_clk;
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
    .o_clk_pcie(w_pcie_clk),   // 100 MHz (default), 125, 250
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


  localparam PL_FAST_TRAIN       = "FALSE"; // Simulation Speedup
  localparam EXT_PIPE_SIM        = "FALSE";  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.	
  localparam PCIE_EXT_CLK        = "TRUE";    // Use External Clocking Module
  localparam PCIE_EXT_GT_COMMON  = "FALSE";
  localparam REF_CLK_FREQ        = 0;     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
  localparam C_DATA_WIDTH        = 64; // RX/TX interface data width
  localparam KEEP_WIDTH          = C_DATA_WIDTH / 8; // TSTRB width

  localparam TCQ               = 1;
  localparam USER_CLK_FREQ     = 1;
  localparam USER_CLK2_DIV2    = "FALSE";
  localparam USERCLK2_FREQ     = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 
                                                                                   : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ
                                                            : USER_CLK_FREQ;

  wire                                        pipe_mmcm_rst_n;
  wire                                        w_pcie_user_clk;
  wire                                        w_user_reset;
  wire                                        w_user_lnk_up;
  // Tx
  wire                                        s_axis_tx_tready;
  wire [3:0]                                  s_axis_tx_tuser;
  wire [C_DATA_WIDTH-1:0]                     s_axis_tx_tdata;
  wire [KEEP_WIDTH-1:0]                       s_axis_tx_tkeep;
  wire                                        s_axis_tx_tlast;
  wire                                        s_axis_tx_tvalid;
  // Rx
  wire [C_DATA_WIDTH-1:0]                     m_axis_rx_tdata;
  wire [KEEP_WIDTH-1:0]                       m_axis_rx_tkeep;
  wire                                        m_axis_rx_tlast;
  wire                                        m_axis_rx_tvalid;
  wire                                        m_axis_rx_tready;
  wire  [21:0]                                m_axis_rx_tuser;
  wire                                        tx_cfg_gnt;
  wire                                        rx_np_ok;
  wire                                        rx_np_req;
  wire                                        cfg_turnoff_ok;
  wire                                        cfg_trn_pending;
  wire                                        cfg_pm_halt_aspm_l0s;
  wire                                        cfg_pm_halt_aspm_l1;
  wire                                        cfg_pm_force_state_en;
  wire   [1:0]                                cfg_pm_force_state;
  wire                                        cfg_pm_wake;
  wire  [63:0]                                cfg_dsn;
  // Flow Control
  wire [2:0]                                  fc_sel;
  //-------------------------------------------------------
  // Configuration (CFG) Interface
  //-------------------------------------------------------
  wire                                        cfg_err_ecrc;
  wire                                        cfg_err_cor;
  wire                                        cfg_err_atomic_egress_blocked;
  wire                                        cfg_err_internal_cor;
  wire                                        cfg_err_malformed;
  wire                                        cfg_err_mc_blocked;
  wire                                        cfg_err_poisoned;
  wire                                        cfg_err_norecovery;
  wire                                        cfg_err_acs;
  wire                                        cfg_err_internal_uncor;
  wire                                        cfg_err_ur;
  wire                                        cfg_err_cpl_timeout;
  wire                                        cfg_err_cpl_abort;
  wire                                        cfg_err_cpl_unexpect;
  wire                                        cfg_err_posted;
  wire                                        cfg_err_locked;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire [127:0]                                cfg_err_aer_headerlog;
  wire   [4:0]                                cfg_aer_interrupt_msgnum;
  wire                                        cfg_interrupt;
  wire                                        cfg_interrupt_assert;
  wire   [7:0]                                cfg_interrupt_di;
  wire                                        cfg_interrupt_stat;
  wire   [4:0]                                cfg_pciecap_interrupt_msgnum;
  wire                                        cfg_to_turnoff;
  wire   [7:0]                                cfg_bus_number;
  wire   [4:0]                                cfg_device_number;
  wire   [2:0]                                cfg_function_number;
  wire  [31:0]                                cfg_mgmt_di;
  wire   [3:0]                                cfg_mgmt_byte_en;
  wire   [9:0]                                cfg_mgmt_dwaddr;
  wire                                        cfg_mgmt_wr_en;
  wire                                        cfg_mgmt_rd_en;
  wire                                        cfg_mgmt_wr_readonly;
  //-------------------------------------------------------
  // Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------
  wire                                        pl_directed_link_auton;
  wire [1:0]                                  pl_directed_link_change;
  wire                                        pl_directed_link_speed;
  wire [1:0]                                  pl_directed_link_width;
  wire                                        pl_upstream_prefer_deemph;
  // Register Declaration
  reg                                         r_user_reset;
  reg                                         r_user_lnk_up;

  always @(posedge w_pcie_user_clk) begin
    r_user_reset  <= w_user_reset;
    r_user_lnk_up <= w_user_lnk_up;
  end

  assign pipe_mmcm_rst_n                        = 1'b1;


  pcie_7x_1line_5gts_64bits_support #
   (	 
    .LINK_CAP_MAX_LINK_WIDTH        ( 1 ),      // PCIe Lane Width
    .C_DATA_WIDTH                   ( C_DATA_WIDTH ),     // RX/TX interface data width
    .KEEP_WIDTH                     ( KEEP_WIDTH ),   // TSTRB width
    .PCIE_REFCLK_FREQ               ( 0 ),      // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
    .PCIE_USERCLK1_FREQ             ( 1 +1 ),                   // PCIe user clock 1 frequency
    .PCIE_USERCLK2_FREQ             ( 1 +1 ),                   // PCIe user clock 2 frequency             
    .PCIE_USE_MODE                  ("3.0"),           // PCIe use mode
    .PCIE_GT_DEVICE                 ("GTX")              // PCIe GT device
   ) 
  pcie_ep0
  (
    //----------------------------------------------------------------------------------------------------------------//
    // PCI Express (pci_exp) Interface                                                                                //
    //----------------------------------------------------------------------------------------------------------------//
    // Tx
    .pci_exp_txn(o_pcie_txn),
    .pci_exp_txp(o_pcie_txp),
    // Rx
    .pci_exp_rxn(i_pcie_rxn),
    .pci_exp_rxp(i_pcie_rxp),
  //----------------------------------------------------------------------------------------------------------------//
  // Clocking Sharing Interface                                                                                     //
  //----------------------------------------------------------------------------------------------------------------//
  .pipe_pclk_out_slave                        ( ),
  .pipe_rxusrclk_out                          ( ),
  .pipe_rxoutclk_out                          ( ),
  .pipe_dclk_out                              ( ),
  .pipe_userclk1_out                          ( ),
  .pipe_oobclk_out                            ( ),
  .pipe_userclk2_out                          ( ),
  .pipe_mmcm_lock_out                         ( ),
  .pipe_pclk_sel_slave                        ( 1'b0),
  .pipe_mmcm_rst_n                            ( pipe_mmcm_rst_n ),        // Async      | Async
  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Common
  .user_clk_out                              ( w_pcie_user_clk ),
  .user_reset_out                            ( w_user_reset ),
  .user_lnk_up                               ( w_user_lnk_up ),
  .user_app_rdy                              ( ),
  // TX
  .s_axis_tx_tready                          ( s_axis_tx_tready ),
  .s_axis_tx_tdata                           ( s_axis_tx_tdata ),
  .s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
  .s_axis_tx_tuser                           ( s_axis_tx_tuser ),
  .s_axis_tx_tlast                           ( s_axis_tx_tlast ),
  .s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),
  // Rx
  .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
  .m_axis_rx_tready                          ( m_axis_rx_tready ),
  .m_axis_rx_tuser                           ( m_axis_rx_tuser ),
  // Flow Control
  .fc_cpld                                   ( ),
  .fc_cplh                                   ( ),
  .fc_npd                                    ( ),
  .fc_nph                                    ( ),
  .fc_pd                                     ( ),
  .fc_ph                                     ( ),
  .fc_sel                                    ( fc_sel ),
  // Management Interface
  .cfg_mgmt_di                               ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en                          ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                           ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                            ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                            ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly                      ( cfg_mgmt_wr_readonly ),
  //------------------------------------------------//
  // EP and RP                                      //
  //------------------------------------------------//
  .cfg_mgmt_do                               ( ),
  .cfg_mgmt_rd_wr_done                       ( ),
  .cfg_mgmt_wr_rw1c_as_rw                    ( 1'b0 ),
  // Error Reporting Interface
  .cfg_err_ecrc                              ( cfg_err_ecrc ),
  .cfg_err_ur                                ( cfg_err_ur ),
  .cfg_err_cpl_timeout                       ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_unexpect                      ( cfg_err_cpl_unexpect ),
  .cfg_err_cpl_abort                         ( cfg_err_cpl_abort ),
  .cfg_err_posted                            ( cfg_err_posted ),
  .cfg_err_cor                               ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked             ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor                      ( cfg_err_internal_cor ),
  .cfg_err_malformed                         ( cfg_err_malformed ),
  .cfg_err_mc_blocked                        ( cfg_err_mc_blocked ),
  .cfg_err_poisoned                          ( cfg_err_poisoned ),
  .cfg_err_norecovery                        ( cfg_err_norecovery ),
  .cfg_err_tlp_cpl_header                    ( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy                           ( ),
  .cfg_err_locked                            ( cfg_err_locked ),
  .cfg_err_acs                               ( cfg_err_acs ),
  .cfg_err_internal_uncor                    ( cfg_err_internal_uncor ),
  //----------------------------------------------------------------------------------------------------------------//
  // AER Interface                                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog                     ( cfg_err_aer_headerlog ),
  .cfg_err_aer_headerlog_set                 ( ),
  .cfg_aer_ecrc_check_en                     ( ),
  .cfg_aer_ecrc_gen_en                       ( ),
  .cfg_aer_interrupt_msgnum                  ( cfg_aer_interrupt_msgnum ),
  .tx_cfg_gnt                                ( tx_cfg_gnt ),
  .rx_np_ok                                  ( rx_np_ok ),
  .rx_np_req                                 ( rx_np_req ),
  .cfg_trn_pending                           ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en                     ( cfg_pm_force_state_en ),
  .cfg_pm_force_state                        ( cfg_pm_force_state ),
  .cfg_dsn                                   ( cfg_dsn ),
  .cfg_turnoff_ok                            ( cfg_turnoff_ok ),
  .cfg_pm_wake                               ( cfg_pm_wake ),
  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .cfg_pm_send_pme_to                        ( 1'b0 ),
  .cfg_ds_bus_number                         ( 8'b0 ),
  .cfg_ds_device_number                      ( 5'b0 ),
  .cfg_ds_function_number                    ( 3'b0 ),
  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .cfg_interrupt                             ( cfg_interrupt ),
  .cfg_interrupt_rdy                         ( ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( cfg_interrupt_di ),
  .cfg_interrupt_do                          ( ),
  .cfg_interrupt_mmenable                    ( ),
  .cfg_interrupt_msienable                   ( ),
  .cfg_interrupt_msixenable                  ( ),
  .cfg_interrupt_msixfm                      ( ),
  .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),
  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_status                                ( ),
  .cfg_command                               ( ),
  .cfg_dstatus                               ( ),
  .cfg_lstatus                               ( ),
  .cfg_pcie_link_state                       ( ),
  .cfg_dcommand                              ( ),
  .cfg_lcommand                              ( ),
  .cfg_dcommand2                             ( ),
  .cfg_pmcsr_pme_en                          ( ),
  .cfg_pmcsr_powerstate                      ( ),
  .cfg_pmcsr_pme_status                      ( ),
  .cfg_received_func_lvl_rst                 ( ),
  .tx_buf_av                                 ( ),
  .tx_err_drop                               ( ),
  .tx_cfg_req                                ( ),
  .cfg_to_turnoff                            ( cfg_to_turnoff ),
  .cfg_bus_number                            ( cfg_bus_number ),
  .cfg_device_number                         ( cfg_device_number ),
  .cfg_function_number                       ( cfg_function_number ),
  .cfg_bridge_serr_en                        ( ),
  .cfg_slot_control_electromech_il_ctl_pulse ( ),
  .cfg_root_control_syserr_corr_err_en       ( ),
  .cfg_root_control_syserr_non_fatal_err_en  ( ),
  .cfg_root_control_syserr_fatal_err_en      ( ),
  .cfg_root_control_pme_int_en               ( ),
  .cfg_aer_rooterr_corr_err_reporting_en     ( ),
  .cfg_aer_rooterr_non_fatal_err_reporting_en( ),
  .cfg_aer_rooterr_fatal_err_reporting_en    ( ),
  .cfg_aer_rooterr_corr_err_received         ( ),
  .cfg_aer_rooterr_non_fatal_err_received    ( ),
  .cfg_aer_rooterr_fatal_err_received        ( ),
  //----------------------------------------------------------------------------------------------------------------//
  // VC interface                                                                                                  //
  //---------------------------------------------------------------------------------------------------------------//
  .cfg_vc_tcvc_map                           ( ),
  .cfg_msg_received                          ( ),
  .cfg_msg_data                              ( ),
  .cfg_msg_received_err_cor                  ( ),
  .cfg_msg_received_err_non_fatal            ( ),
  .cfg_msg_received_err_fatal                ( ),
  .cfg_msg_received_pm_as_nak                ( ),
  .cfg_msg_received_pme_to_ack               ( ),
  .cfg_msg_received_assert_int_a             ( ),
  .cfg_msg_received_assert_int_b             ( ),
  .cfg_msg_received_assert_int_c             ( ),
  .cfg_msg_received_assert_int_d             ( ),
  .cfg_msg_received_deassert_int_a           ( ),
  .cfg_msg_received_deassert_int_b           ( ),
  .cfg_msg_received_deassert_int_c           ( ),
  .cfg_msg_received_deassert_int_d           ( ),
  .cfg_msg_received_pm_pme                  ( ),
  .cfg_msg_received_setslotpowerlimit       ( ),
  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_change                   ( pl_directed_link_change ),
  .pl_directed_link_width                    ( pl_directed_link_width ),
  .pl_directed_link_speed                    ( pl_directed_link_speed ),
  .pl_directed_link_auton                    ( pl_directed_link_auton ),
  .pl_upstream_prefer_deemph                 ( pl_upstream_prefer_deemph ),
  .pl_sel_lnk_rate                           ( ),
  .pl_sel_lnk_width                          ( ),
  .pl_ltssm_state                            ( ),
  .pl_lane_reversal_mode                     ( ),
  .pl_phy_lnk_up                             ( ),
  .pl_tx_pm_state                            ( ),
  .pl_rx_pm_state                            ( ),
  .pl_link_upcfg_cap                         ( ),
  .pl_link_gen2_cap                          ( ),
  .pl_link_partner_gen2_supported            ( ),
  .pl_initial_link_width                     ( ),
  .pl_directed_change_done                   ( ),
  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .pl_received_hot_rst                       ( ),
  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .pl_transmit_hot_rst                       ( 1'b0 ),
  .pl_downstream_deemph_source               ( 1'b0 ),
  //----------------------------------------------------------------------------------------------------------------//
  // PCIe DRP (PCIe DRP) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .pcie_drp_clk                               ( 1'b1 ),
  .pcie_drp_en                                ( 1'b0 ),
  .pcie_drp_we                                ( 1'b0 ),
  .pcie_drp_addr                              ( 9'h0 ),
  .pcie_drp_di                                ( 16'h0 ),
  .pcie_drp_rdy                               ( ),
  .pcie_drp_do                                ( ),
  //----------------------------------------------------------------------------------------------------------------//
  // System  (SYS) Interface                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//
  .sys_clk(w_pcie_clk),
  .sys_rst_n(w_sys_nrst)
);


pcie_app_7x  #(
  .C_DATA_WIDTH( C_DATA_WIDTH ),   // 64
  .TCQ( TCQ )                      // 1
) app (
  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Common
  .user_clk                       ( w_pcie_user_clk ),
  .user_reset                     ( r_user_reset ),
  .user_lnk_up                    ( r_user_lnk_up ),
  // Tx
  .s_axis_tx_tready               ( s_axis_tx_tready ),
  .s_axis_tx_tdata                ( s_axis_tx_tdata ),
  .s_axis_tx_tkeep                ( s_axis_tx_tkeep ),
  .s_axis_tx_tuser                ( s_axis_tx_tuser ),
  .s_axis_tx_tlast                ( s_axis_tx_tlast ),
  .s_axis_tx_tvalid               ( s_axis_tx_tvalid ),
  // Rx
  .m_axis_rx_tdata                ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid               ( m_axis_rx_tvalid ),
  .m_axis_rx_tready               ( m_axis_rx_tready ),
  .m_axis_rx_tuser                ( m_axis_rx_tuser ),
  .tx_cfg_gnt                     ( tx_cfg_gnt ),
  .rx_np_ok                       ( rx_np_ok ),
  .rx_np_req                      ( rx_np_req ),
  .cfg_turnoff_ok                 ( cfg_turnoff_ok ),
  .cfg_trn_pending                ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s           ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1            ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en          ( cfg_pm_force_state_en ),
  .cfg_pm_force_state             ( cfg_pm_force_state ),
  .cfg_pm_wake                    ( cfg_pm_wake ),
  .cfg_dsn                        ( cfg_dsn ),
  // Flow Control
  .fc_sel                         ( fc_sel ),
  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_cor                    ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked  ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor           ( cfg_err_internal_cor ),
  .cfg_err_malformed              ( cfg_err_malformed ),
  .cfg_err_mc_blocked             ( cfg_err_mc_blocked ),
  .cfg_err_poisoned               ( cfg_err_poisoned ),
  .cfg_err_norecovery             ( cfg_err_norecovery ),
  .cfg_err_ur                     ( cfg_err_ur ),
  .cfg_err_ecrc                   ( cfg_err_ecrc ),
  .cfg_err_cpl_timeout            ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_abort              ( cfg_err_cpl_abort ),
  .cfg_err_cpl_unexpect           ( cfg_err_cpl_unexpect ),
  .cfg_err_posted                 ( cfg_err_posted ),
  .cfg_err_locked                 ( cfg_err_locked ),
  .cfg_err_acs                    ( cfg_err_acs ), //1'b0 ),
  .cfg_err_internal_uncor         ( cfg_err_internal_uncor ), //1'b0 ),
  .cfg_err_tlp_cpl_header         ( cfg_err_tlp_cpl_header ),
  //----------------------------------------------------------------------------------------------------------------//
  // Advanced Error Reporting (AER) Interface                                                                       //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog          ( cfg_err_aer_headerlog ),
  .cfg_aer_interrupt_msgnum       ( cfg_aer_interrupt_msgnum ),
  .cfg_to_turnoff                 ( cfg_to_turnoff ),
  .cfg_bus_number                 ( cfg_bus_number ),
  .cfg_device_number              ( cfg_device_number ),
  .cfg_function_number            ( cfg_function_number ),

  //----------------------------------------------------------------------------------------------------------------//
  // Management (MGMT) Interface                                                                                    //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_mgmt_di                    ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en               ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                 ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                 ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly           ( cfg_mgmt_wr_readonly ),
  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_auton         ( pl_directed_link_auton ),
  .pl_directed_link_change        ( pl_directed_link_change ),
  .pl_directed_link_speed         ( pl_directed_link_speed ),
  .pl_directed_link_width         ( pl_directed_link_width ),
  .pl_upstream_prefer_deemph      ( pl_upstream_prefer_deemph ),
  .cfg_interrupt                  ( cfg_interrupt ),
  .cfg_interrupt_assert           ( cfg_interrupt_assert ),
  .cfg_interrupt_di               ( cfg_interrupt_di ),
  .cfg_interrupt_stat             ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum   ( cfg_pciecap_interrupt_msgnum )

);


  
endmodule