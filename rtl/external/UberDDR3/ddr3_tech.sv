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

module ddr3_tech
#(
    parameter int async_reset = 0,
    parameter SYSCLK_TYPE           = "DIFFERENTIAL",
    parameter SIM_BYPASS_INIT_CAL   = "OFF",
    parameter SIMULATION            = "FALSE"
)
(
    input i_ctrl_clk,      // CONTROLLER_CLK_PERIOD
    input i_phy_clk,       // DDR3_CLK_PERIOD must be 4:1 CONTROLLER_CLK_PERIOD
    input i_ref_clk200,    // 200MHz
    input i_apb_nrst,
    input i_apb_clk,
    input i_xslv_nrst,
    input i_xslv_clk,
    // AXI memory access (ddr clock)
    input types_amba_pkg::mapinfo_type i_xmapinfo,
    output types_pnp_pkg::dev_config_type o_xcfg,
    input types_amba_pkg::axi4_slave_in_type i_xslvi,
    output types_amba_pkg::axi4_slave_out_type o_xslvo,
    // APB control interface (sys clock):
    input types_amba_pkg::mapinfo_type i_pmapinfo,
    output types_pnp_pkg::dev_config_type o_pcfg,
    input types_amba_pkg::apb_in_type i_apbi,
    output types_amba_pkg::apb_out_type o_apbo,
    // to SOC:
    output o_ui_nrst,  // xilinx generte ddr clock inside ddr controller
    output o_ui_clk,  // xilinx generte ddr clock inside ddr controller
    // DDR signals:
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
    output logic o_init_calib_done
);

import types_amba_pkg::*;
import types_pnp_pkg::*;

bit w_ddr_mmcm_locked;
bit w_ddr_app_sr_active;
bit w_ddr_app_ref_ack;
bit w_ddr_app_zq_ack;
bit w_ddr_user_self_refresh;
bit w_ddr_init_calib_complete;
bit [11:0] wb_ddr_device_temp;
bit w_ui_rst;

  apb_ddr #(
    .async_reset(async_reset)
  ) apb0 (
    .i_clk(i_apb_clk),
    .i_nrst(i_apb_nrst),
    .i_mapinfo(i_pmapinfo),
    .o_cfg(o_pcfg),
    .i_apbi(i_apbi),
    .o_apbo(o_apbo),
    .i_pll_locked(w_ddr_mmcm_locked),
    .i_init_calib_done(w_ddr_init_calib_complete),
    .i_device_temp(wb_ddr_device_temp),
    .i_sr_active(w_ddr_app_sr_active),
    .i_ref_ack(w_ddr_app_ref_ack),
    .i_zq_ack(w_ddr_app_zq_ack)
  );

  assign o_ui_nrst = ~w_ui_rst;
  assign o_init_calib_done = w_ddr_init_calib_complete;
  // User enabled self-refresh
  assign w_ddr_user_self_refresh = 1'b0;

ddr3_top_axi #(
    .CONTROLLER_CLK_PERIOD(5_000), //ps, clock period of the controller interface
    .DDR3_CLK_PERIOD(1_250), //ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD) 
    .ROW_BITS(14),   //width of row address
    .COL_BITS(10), //width of column address
    .BA_BITS(3), //width of bank address
    .BYTE_LANES(1), //number of byte lanes of DDR3 RAM (axiw_data=64-bits)
    .AXI_ID_WIDTH(1), // The AXI id width used for R&W, an int between 1-16
    .WB2_ADDR_BITS(7), //width of 2nd wishbone address bus 
    .WB2_DATA_BITS(32), //width of 2nd wishbone data bus 
    .MICRON_SIM(1), //!!! FIXME !!!! enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
    .ODELAY_SUPPORTED(1), //set to 1 when ODELAYE2 is supported
    .SECOND_WISHBONE(0), //set to 1 if 2nd wishbone for debugging is needed 
    .WB_ERROR(0), // set to 1 to support Wishbone error (asserts at ECC double bit error)
    .BIST_MODE(0), // 0 = No BIST, 1 = run through all address space ONCE , 2 = run through all address space for every test (burst w/r, random w/r, alternating r/w)
    .ECC_ENABLE(0), // set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC ) 
    .DIC(2'b00), //Output Driver Impedance Control (2'b00 = RZQ/6, 2'b01 = RZQ/7, RZQ = 240ohms) (only change when you know what you are doing)
    .RTT_NOM(3'b011), //RTT Nominal (3'b000 = disabled, 3'b001 = RZQ/4, 3'b010 = RZQ/2 , 3'b011 = RZQ/6, RZQ = 240ohms)  (only change when you know what you are doing)
    .SELF_REFRESH(2'b00) // 0 = use i_user_self_refresh input, 1 = Self-refresh mode is enabled after 64 controller clock cycles of no requests, 2 = 128 cycles, 3 = 256 cycles
) (
    .i_controller_clk(i_ctrl_clk), // CONTROLLER_CLK_PERIOD
    .i_ddr3_clk(i_phy_clk),       // DDR3_CLK_PERIOD
    .i_ref_clk(i_ref_clk200),        // 200MHz
    .i_ddr3_clk_90(0), //required only when ODELAY_SUPPORTED is zero
    .i_rst_n(i_xslv_nrst),
    // AXI write address channel signals
    .s_axi_awvalid(i_xslvi.aw_valid),
    .s_axi_awready(o_xslvo.aw_ready),
    .s_axi_awid(i_xslvi.aw_id),
    .s_axi_awaddr(i_xslvi.aw_bits.addr[29:0]),
    .s_axi_awlen(i_xslvi.aw_bits.len),
    .s_axi_awsize(i_xslvi.aw_bits.size),
    .s_axi_awburst(i_xslvi.aw_bits.burst),
    .s_axi_awlock(i_xslvi.aw_bits.lock),
    .s_axi_awcache(i_xslvi.aw_bits.cache),
    .s_axi_awprot(i_xslvi.aw_bits.prot),
    .s_axi_awqos(i_xslvi.aw_bits.qos),
    // AXI write data channel signals
    .s_axi_wvalid(i_xslvi.w_valid),
    .s_axi_wready(o_xslvo.w_ready),
    .s_axi_wdata(i_xslvi.w_data),
    .s_axi_wstrb(i_xslvi.w_strb),
    .s_axi_wlast(i_xslvi.w_last),
    // AXI write response channel signals
    .s_axi_bvalid(o_xslvo.b_valid),
    .s_axi_bready(i_xslvi.b_ready),
    .s_axi_bid(o_xslvo.b_id),
    .s_axi_bresp(o_xslvo.b_resp),
    // AXI read address channel signals
    .s_axi_arvalid(i_xslvi.ar_valid),
    .s_axi_arready(o_xslvo.ar_ready),
    .s_axi_arid(i_xslvi.ar_id),
    .s_axi_araddr(i_xslvi.ar_bits.addr[29:0]),
    .s_axi_arlen(i_xslvi.ar_bits.len),
    .s_axi_arsize(i_xslvi.ar_bits.size),
    .s_axi_arburst(i_xslvi.ar_bits.burst),
    .s_axi_arlock(i_xslvi.ar_bits.lock),
    .s_axi_arcache(i_xslvi.ar_bits.cache),
    .s_axi_arprot(i_xslvi.ar_bits.prot),
    .s_axi_arqos(i_xslvi.ar_bits.qos),
    // AXI read data channel signals
    .s_axi_rvalid(o_xslvo.r_valid),
    .s_axi_rready(i_xslvi.r_ready),
    .s_axi_rid(o_xslvo.r_id),
    .s_axi_rdata(o_xslvo.r_data),
    .s_axi_rlast(o_xslvo.r_last),
    .s_axi_rresp(o_xslvo.r_resp),
    // DDR3 I/O Interface
    .o_ddr3_clk_p(o_ddr3_ck_p),
    .o_ddr3_clk_n(o_ddr3_ck_n),
    .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_cke(o_ddr3_cke),
    .o_ddr3_cs_n(o_ddr3_cs_n),
    .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n),
    .o_ddr3_we_n(o_ddr3_we_n),
    .o_ddr3_addr(o_ddr3_addr),
    .o_ddr3_ba_addr(o_ddr3_ba),
    .io_ddr3_dq(io_ddr3_dq),
    .io_ddr3_dqs(io_ddr3_dqs_p),
    .io_ddr3_dqs_n(io_ddr3_dqs_n),
    .o_ddr3_dm(o_ddr3_dm),
    .o_ddr3_odt(o_ddr3_odt),
    // Done Calibration pin
    .o_calib_complete(w_ddr_init_calib_complete),
    // Debug outputs
    .o_debug1(),
    // User enabled self-refresh
    .i_user_self_refresh(w_ddr_user_self_refresh)
);


  // TODO: fix me with registers
  assign o_xslvo.r_user = '0;
  assign o_xslvo.b_user = '0;


  assign o_xcfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
  assign o_xcfg.descrtype = PNP_CFG_TYPE_SLAVE;
  assign o_xcfg.addr_start = i_xmapinfo.addr_start;
  assign o_xcfg.addr_end = i_xmapinfo.addr_end;
  assign o_xcfg.vid = VENDOR_OPTIMITECH;
  assign o_xcfg.did = OPTIMITECH_SRAM;

endmodule
