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
    parameter int ROW_BITS = 14,                            // Row address width
    parameter int BA_BITS = 3,                              // Bank address width
    parameter int LANE_TOTAL = 8,                           // Lane is: 8 dq (byte) + 1 dm (mask) + 1 dqs_n/dqs_p (strob)
    parameter int DUAL_RANK = 0,                            // 1=Enable dual DDR; 0=disable.
    parameter int AXI_SIZE_LOG2 = 30,                       // 30 = 1GB (default). Bus address width
    parameter int AXI_ID_BITS = 5,                          // Custom ID field width
    parameter SYSCLK_TYPE           = "DIFFERENTIAL",
    parameter SIM_BYPASS_INIT_CAL   = "OFF",
    parameter SIMULATION            = "FALSE"
)
(
    input logic i_nrst,                                     // DDR reset active LOW. Connected to IODELAY
    input logic i_ctrl_clk,                                 // DDR Controller clock: MIG 200 MHz, UberDDR 1:4 PHY clock
    input logic i_phy_clk,                                  // PHY clock default for DDR3 800 MHz
    input logic i_ref_clk200,                               // Reference clock for internal mmcm
    // 
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
    output logic o_init_calib_done,                         // DDR calibration done, active HIGH
    output logic [11:0] o_temperature,                      // Device temperature
    input logic i_sr_req,                                   // Self-refresh request (low-power mode)
    input logic i_ref_req,                                  // Periodic refresh request ~7.8 us
    input logic i_zq_req,                                   // ZQ calibration request. Startup and runtime maintenance
    output logic o_sr_active,                               // Self-resfresh is active (low-power mode or sleep)
    output logic o_ref_ack,                                 // Refresh request acknoledged
    output logic o_zq_ack,                                  // ZQ calibration request acknowledged
    // AXI slave interface:
    input logic [AXI_ID_BITS-1:0] i_aw_id,
    input logic [AXI_SIZE_LOG2-1:0] i_aw_addr,
    input logic [7:0] i_aw_len,
    input logic [2:0] i_aw_size,
    input logic [1:0] i_aw_burst,
    input logic i_aw_lock,
    input logic [3:0] i_aw_cache,
    input logic [2:0] i_aw_prot,
    input logic [3:0] i_aw_qos,
    input logic i_aw_valid,
    output logic o_aw_ready,
    input logic [63:0] i_w_data,
    input logic [7:0] i_w_strb,
    input logic i_w_last,
    input logic i_w_valid,
    output logic o_w_ready,
    input logic i_b_ready,
    output logic [AXI_ID_BITS-1:0] o_b_id,
    output logic [1:0] o_b_resp,
    output logic o_b_valid,
    input logic [AXI_ID_BITS-1:0] i_ar_id,
    input logic [AXI_SIZE_LOG2-1:0] i_ar_addr,
    input logic [7:0] i_ar_len,
    input logic [2:0] i_ar_size,
    input logic [1:0] i_ar_burst,
    input logic i_ar_lock,
    input logic [3:0] i_ar_cache,
    input logic [2:0] i_ar_prot,
    input logic [3:0] i_ar_qos,
    input logic i_ar_valid,
    output logic o_ar_ready,
    input logic i_r_ready,
    output logic [AXI_ID_BITS-1:0] o_r_id,
    output logic [63:0] o_r_data,
    output logic [1:0] o_r_resp,
    output logic o_r_last,
    output logic o_r_valid
);

bit w_ddr_mmcm_locked;
bit w_ui_rst;

assign o_ui_nrst = ~w_ui_rst;

mig_ddr3 #(
    .SYSCLK_TYPE(SYSCLK_TYPE), // "NO_BUFFER,"DIFFERENTIAL"
    .SIM_BYPASS_INIT_CAL(SIM_BYPASS_INIT_CAL),  // "FAST"-for simulation true; "OFF"
    .SIMULATION(SIMULATION)
) mig0 (
    .ddr3_dq(io_ddr3_dq),
    .ddr3_dqs_n(io_ddr3_dqs_n),
    .ddr3_dqs_p(io_ddr3_dqs_p),
    .ddr3_addr(o_ddr3_addr),
    .ddr3_ba(o_ddr3_ba),
    .ddr3_ras_n(o_ddr3_ras_n),
    .ddr3_cas_n(o_ddr3_cas_n),
    .ddr3_we_n(o_ddr3_we_n),
    .ddr3_reset_n(o_ddr3_reset_n),
    .ddr3_ck_p(o_ddr3_ck_p),
    .ddr3_ck_n(o_ddr3_ck_n),
    .ddr3_cke(o_ddr3_cke),
    .ddr3_cs_n(o_ddr3_cs_n),
    .ddr3_dm(o_ddr3_dm),
    .ddr3_odt(o_ddr3_odt),
    .sys_clk_p(1'b0),
    .sys_clk_n(1'b0),
    .sys_clk_i(i_ctrl_clk),//i_xslv_clk),
    .ui_clk(o_ui_clk),
    .ui_clk_sync_rst(w_ui_rst),
    .mmcm_locked(w_ddr_mmcm_locked),
    .aresetn(i_nrst),
    .app_sr_req(i_sr_req),
    .app_ref_req(i_ref_req),
    .app_zq_req(i_zq_req),
    .app_sr_active(o_sr_active),
    .app_ref_ack(o_ref_ack),
    .app_zq_ack(o_zq_ack),
    .s_axi_awid(i_aw_id),
    .s_axi_awaddr(i_aw_addr),
    .s_axi_awlen(i_aw_len),
    .s_axi_awsize(i_aw_size),
    .s_axi_awburst(i_aw_burst),
    .s_axi_awlock(i_aw_lock),
    .s_axi_awcache(i_aw_cache),
    .s_axi_awprot(i_aw_prot),
    .s_axi_awqos(i_aw_qos),
    .s_axi_awvalid(i_aw_valid),
    .s_axi_awready(o_aw_ready),
    .s_axi_wdata(i_w_data),
    .s_axi_wstrb(i_w_strb),
    .s_axi_wlast(i_w_last),
    .s_axi_wvalid(i_w_valid),
    .s_axi_wready(o_w_ready),
    .s_axi_bready(i_b_ready),
    .s_axi_bid(o_b_id),
    .s_axi_bresp(o_b_resp),
    .s_axi_bvalid(o_b_valid),
    .s_axi_arid(i_ar_id),
    .s_axi_araddr(i_ar_addr),
    .s_axi_arlen(i_ar_len),
    .s_axi_arsize(i_ar_size),
    .s_axi_arburst(i_ar_burst),
    .s_axi_arlock(i_ar_lock),
    .s_axi_arcache(i_ar_cache),
    .s_axi_arprot(i_ar_prot),
    .s_axi_arqos(i_ar_qos),
    .s_axi_arvalid(i_ar_valid),
    .s_axi_arready(o_ar_ready),
    .s_axi_rready(i_r_ready),
    .s_axi_rid(o_r_id),
    .s_axi_rdata(o_r_data),
    .s_axi_rresp(o_r_resp),
    .s_axi_rlast(o_r_last),
    .s_axi_rvalid(o_r_valid),
    .init_calib_complete(o_init_calib_done),
    .device_temp(o_temperature),
    .sys_rst(i_nrst)  // active LOW. Connected to IODELAY
  );


endmodule
