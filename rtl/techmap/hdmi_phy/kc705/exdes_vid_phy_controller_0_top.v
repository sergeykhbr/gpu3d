
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`include "vid_phy_controller_v2_2_2_defs.v"
`timescale 1ns / 1ps
`define DLY #1

//***********************************Entity Declaration************************
(* DowngradeIPIdentifiedWarnings="yes" *)
module exdes_vid_phy_controller_0_top #
    (
        // 
        parameter         C_COMPONENT_NAME                      = "vid_phy_controller_v",
        parameter         C_FAMILY                              = "kintex7",
        parameter         C_DEVICE                              = "xc7k325t",
        parameter         C_SPEEDGRADE                          = "-3",
        parameter         C_SILICON_REVISION                    = "0",
        // HDMI
        parameter integer C_NIDRU                       = 1,
        parameter integer C_NIDRU_REFCLK_SEL            = 2,
        
        parameter integer C_TX_REFCLK_SEL               = 1,
        parameter integer C_RX_REFCLK_SEL               = 0,
        parameter integer C_SupportLevel                        = 0,
        parameter integer C_TransceiverControl          = "false",
        parameter         c_sub_core_name                       = "subcore",
        // GT Specific Parameters       
        parameter integer C_Tx_No_Of_Channels           =  3,   // baoshan: get from modelparam
        parameter integer C_Rx_No_Of_Channels           =  3,   // baoshan: get from modelparam
        parameter integer C_Tx_Protocol                 =  1,         // baoshan: get from modelparam
        parameter integer C_Rx_Protocol                 =  1,         // baoshan: get from modelparam
        parameter integer C_TX_PLL_SELECTION            =  0,                // baoshan: get from modelparam
        parameter integer C_RX_PLL_SELECTION            =  3,                // baoshan: get from modelparam
        parameter integer C_INPUT_PIXELS_PER_CLOCK      =  4, //Mak, will need to add this parameter in GUI for all device types

        parameter integer Tx_Buffer_Bypass              = 1,
        parameter integer C_Hdmi_Fast_Switch            = 1,
        parameter integer C_Err_Irq_En                  = 0,
        
        parameter integer C_Txrefclk_Rdy_Invert         = 1,
        parameter integer C_Use_GT_CH4_HDMI             = 0,

        // Parameters of Axi Slave Bus Interface vid_phy_axi4lite
        parameter integer C_vid_phy_axi4lite_DATA_WIDTH         = 32,
        parameter integer C_vid_phy_axi4lite_ADDR_WIDTH         = 10,   // baoshan: 1 bit added on addr width for HDMI - review this with Vamsi
        parameter integer C_vid_phy_tx_axi4s_ch_TDATA_WIDTH     = 20,
        parameter integer C_vid_phy_tx_axi4s_ch_INT_TDATA_WIDTH     = 20,
 
        parameter integer C_vid_phy_tx_axi4s_ch_TUSER_WIDTH     = 1,
        parameter integer C_vid_phy_rx_axi4s_ch_TDATA_WIDTH     = 20,
        parameter integer C_vid_phy_rx_axi4s_ch_INT_TDATA_WIDTH     = 20,
 
        parameter integer C_vid_phy_rx_axi4s_ch_TUSER_WIDTH     = 1,
        parameter integer C_vid_phy_control_sb_tx_TDATA_WIDTH   = 32,
        parameter integer C_vid_phy_status_sb_tx_TDATA_WIDTH    = 32,
        parameter integer C_vid_phy_control_sb_rx_TDATA_WIDTH   = 32,
        parameter integer C_vid_phy_status_sb_rx_TDATA_WIDTH    = 32

    )
    (
        // Ports of GT
        input wire  mgtrefclk0_pad_n_in,
        input wire  mgtrefclk0_pad_p_in,
        input wire  mgtrefclk1_pad_n_in,
        input wire  mgtrefclk1_pad_p_in,
        input wire  mgtrefclk0_in,
        input wire  mgtrefclk1_in,

        input wire  drpclk,

        //input wire  gtgrefclk_in,
        input wire  gtnorthrefclk0_in,
        input wire  gtnorthrefclk1_in,
        input wire  gtsouthrefclk0_in,
        input wire  gtsouthrefclk1_in,
        //gtp ports
        input wire  gteastrefclk0_in,
        input wire  gteastrefclk1_in,
        input wire  gtwestrefclk0_in,
        input wire  gtwestrefclk1_in,
        
        // 8-series QPLL clocks (DUMMY)
        //input wire  gtgrefclk0_in,
        //input wire  gtgrefclk1_in,
        input wire  gtnorthrefclk00_in,
        input wire  gtnorthrefclk01_in,
        input wire  gtnorthrefclk10_in,
        input wire  gtnorthrefclk11_in,
        input wire  gtsouthrefclk00_in,
        input wire  gtsouthrefclk01_in,
        input wire  gtsouthrefclk10_in,
        input wire  gtsouthrefclk11_in,

        input wire [C_Rx_No_Of_Channels-1 : 0]  phy_rxn_in,
        input wire [C_Rx_No_Of_Channels-1 : 0]  phy_rxp_in,
        output wire [C_Tx_No_Of_Channels-1 : 0]  phy_txn_out,
        output wire [C_Tx_No_Of_Channels-1 : 0]  phy_txp_out,

        // Ports of Axi Slave Bus Interface vid_phy_axi4lite
        input wire  vid_phy_axi4lite_aclk,
        input wire  vid_phy_axi4lite_aresetn,
        input wire [C_vid_phy_axi4lite_ADDR_WIDTH-1 : 0] vid_phy_axi4lite_awaddr,
        input wire [2 : 0] vid_phy_axi4lite_awprot,
        input wire  vid_phy_axi4lite_awvalid,
        output wire  vid_phy_axi4lite_awready,
        input wire [C_vid_phy_axi4lite_DATA_WIDTH-1 : 0] vid_phy_axi4lite_wdata,
        input wire [(C_vid_phy_axi4lite_DATA_WIDTH/8)-1 : 0] vid_phy_axi4lite_wstrb,
        input wire  vid_phy_axi4lite_wvalid,
        output wire  vid_phy_axi4lite_wready,
        output wire [1 : 0] vid_phy_axi4lite_bresp,
        output wire  vid_phy_axi4lite_bvalid,
        input wire  vid_phy_axi4lite_bready,
        input wire [C_vid_phy_axi4lite_ADDR_WIDTH-1 : 0] vid_phy_axi4lite_araddr,
        input wire [2 : 0] vid_phy_axi4lite_arprot,
        input wire  vid_phy_axi4lite_arvalid,
        output wire  vid_phy_axi4lite_arready,
        output wire [C_vid_phy_axi4lite_DATA_WIDTH-1 : 0] vid_phy_axi4lite_rdata,
        output wire [1 : 0] vid_phy_axi4lite_rresp,
        output wire  vid_phy_axi4lite_rvalid,
        input wire  vid_phy_axi4lite_rready,

        // Ports of Axi Slave Bus Interface vid_phy_tx_axi4s_ch0
        input wire  vid_phy_tx_axi4s_aclk,
        input wire  vid_phy_tx_axi4s_aresetn,

        output wire  vid_phy_tx_axi4s_ch0_tready,
        input wire [C_vid_phy_tx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_tx_axi4s_ch0_tdata,
        input wire [C_vid_phy_tx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_tx_axi4s_ch0_tuser,
        input wire  vid_phy_tx_axi4s_ch0_tvalid,

        // Ports of Axi Slave Bus Interface vid_phy_tx_axi4s_ch1
        output wire  vid_phy_tx_axi4s_ch1_tready,
        input wire [C_vid_phy_tx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_tx_axi4s_ch1_tdata,
        input wire [C_vid_phy_tx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_tx_axi4s_ch1_tuser,
        input wire  vid_phy_tx_axi4s_ch1_tvalid,

        // Ports of Axi Slave Bus Interface vid_phy_tx_axi4s_ch2
        output wire  vid_phy_tx_axi4s_ch2_tready,
        input wire [C_vid_phy_tx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_tx_axi4s_ch2_tdata,
        input wire [C_vid_phy_tx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_tx_axi4s_ch2_tuser,
        input wire  vid_phy_tx_axi4s_ch2_tvalid,

        // Ports of Axi Slave Bus Interface vid_phy_tx_axi4s_ch3
        output wire  vid_phy_tx_axi4s_ch3_tready,
        input wire [C_vid_phy_tx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_tx_axi4s_ch3_tdata,
        input wire [C_vid_phy_tx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_tx_axi4s_ch3_tuser,
        input wire  vid_phy_tx_axi4s_ch3_tvalid,

        // Ports of Axi Master Bus Interface vid_phy_rx_axi4s_ch0
        input wire  vid_phy_rx_axi4s_aclk,
        input wire  vid_phy_rx_axi4s_aresetn,

        output wire  vid_phy_rx_axi4s_ch0_tvalid,
        output wire [C_vid_phy_rx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_rx_axi4s_ch0_tdata,
        output wire [C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_rx_axi4s_ch0_tuser,
        input wire  vid_phy_rx_axi4s_ch0_tready,

        // Ports of Axi Master Bus Interface vid_phy_rx_axi4s_ch1
        output wire  vid_phy_rx_axi4s_ch1_tvalid,
        output wire [C_vid_phy_rx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_rx_axi4s_ch1_tdata,
        output wire [C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_rx_axi4s_ch1_tuser,
        input wire  vid_phy_rx_axi4s_ch1_tready,

        // Ports of Axi Master Bus Interface vid_phy_rx_axi4s_ch2
        output wire  vid_phy_rx_axi4s_ch2_tvalid,
        output wire [C_vid_phy_rx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_rx_axi4s_ch2_tdata,
        output wire [C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_rx_axi4s_ch2_tuser,
        input wire  vid_phy_rx_axi4s_ch2_tready,

        // Ports of Axi Master Bus Interface vid_phy_rx_axi4s_ch3
        output wire  vid_phy_rx_axi4s_ch3_tvalid,
        output wire [C_vid_phy_rx_axi4s_ch_TDATA_WIDTH-1 : 0] vid_phy_rx_axi4s_ch3_tdata,
        output wire [C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0] vid_phy_rx_axi4s_ch3_tuser,
        input wire  vid_phy_rx_axi4s_ch3_tready,

        // Ports of Axi Slave Bus Interface vid_phy_control_sb_tx
        input wire  vid_phy_sb_aclk,
        input wire  vid_phy_sb_aresetn,

        output wire  vid_phy_control_sb_tx_tready,
        input wire [C_vid_phy_control_sb_tx_TDATA_WIDTH-1 : 0] vid_phy_control_sb_tx_tdata,
        input wire  vid_phy_control_sb_tx_tvalid,

        // Ports of Axi Master Bus Interface vid_phy_status_sb_tx
        output wire  vid_phy_status_sb_tx_tvalid,
        output wire [C_vid_phy_status_sb_tx_TDATA_WIDTH-1 : 0] vid_phy_status_sb_tx_tdata,
        input wire  vid_phy_status_sb_tx_tready,

        // Ports of Axi Slave Bus Interface vid_phy_control_sb_rx
        output wire  vid_phy_control_sb_rx_tready,
        input wire [C_vid_phy_control_sb_rx_TDATA_WIDTH-1 : 0] vid_phy_control_sb_rx_tdata,
        input wire  vid_phy_control_sb_rx_tvalid,

        // Ports of Axi Master Bus Interface vid_phy_status_sb_rx
        output wire  vid_phy_status_sb_rx_tvalid,
        output wire [C_vid_phy_status_sb_rx_TDATA_WIDTH-1 : 0] vid_phy_status_sb_rx_tdata,
        input wire  vid_phy_status_sb_rx_tready,

        // HDMI sideband
        input wire   tx_refclk_rdy, 
        output wire  tx_tmds_clk, 
        output wire  tx_video_clk, 
        output wire  rx_tmds_clk,  
        output wire  rx_video_clk, 
        output wire  tx_tmds_clk_p, 
        output wire  tx_tmds_clk_n,         
        output wire  rx_tmds_clk_p, 
        output wire  rx_tmds_clk_n,         
        
        input wire  mgtrefclk0_odiv2_in,
        input wire  mgtrefclk1_odiv2_in,
        input wire  gtnorthrefclk0_odiv2_in,
        input wire  gtnorthrefclk1_odiv2_in,
        input wire  gtsouthrefclk0_odiv2_in,
        input wire  gtsouthrefclk1_odiv2_in,
                
        output wire  txrefclk_ceb, //To Mak: activate only if txrefclk is outside the quad i.e. NORTH, SOUTH, WEST and EAST
        output wire  rxrefclk_ceb, //To Mak: activate only if rxrefclk is outside the quad i.e. NORTH, SOUTH, WEST and EAST
        
                input wire  [C_Tx_No_Of_Channels   -1 : 0] gttxpippmen_in,
                input wire  [C_Tx_No_Of_Channels   -1 : 0] gttxpippmovrden_in,
                input wire  [C_Tx_No_Of_Channels   -1 : 0] gttxpippmpd_in,
                input wire  [C_Tx_No_Of_Channels   -1 : 0] gttxpippmsel_in,
                input wire  [C_Tx_No_Of_Channels*5 -1 : 0] gttxpippmstepsize_in,
        output wire err_irq,
        
        output wire  txoutclk,
        output wire  rxoutclk,
        output wire  irq
    );

    wire            tied_to_ground_i;
    wire    [63:0]  tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [7:0]   tied_to_vcc_vec_i;

    //  Static signal Assigments    
    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 64'h0000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 8'hff;

    wire mgtrefclk0_i;
    wire mgtrefclk1_i;
    wire vid_phy_axi4lite_areset = ~vid_phy_axi4lite_aresetn;
    wire  drp_clk = vid_phy_axi4lite_aclk; 
 
    wire mgtrefclk0_bufg_i;
    wire mgtrefclk1_bufg_i;
    wire txrefclk_from_bufds;
    wire txrefclk_from_buffer;
    wire rxrefclk_from_bufds;
    wire rxrefclk_from_buffer;
    wire vid_phy_rx_axi4s_ch0_tvalid_i;
    wire vid_phy_rx_axi4s_ch1_tvalid_i;
    wire vid_phy_rx_axi4s_ch2_tvalid_i;
    
    wire  ibuf_mgtrefclk1_pad_n_in;
    wire  ibuf_mgtrefclk1_pad_p_in;
    wire  ibuf_mgtrefclk0_pad_n_in;
    wire  ibuf_mgtrefclk0_pad_p_in;

    //Signal Naming Format: b0gt0 -> Bank 0, GT Channel 0
 
    //wire            b0gt0_cplllock_out;
    wire            b0gt0_cplllock_out_sync;
    wire            b0gt0_cplllockdetclk_in;
    wire            b0gt0_cpllpd_in;
    wire            b0gt0_cpllreset_in;
    wire  [3:0]     b0gt0_clkrsvd_in = tied_to_ground_vec_i[3:0];
    
    wire            b0gt0_gtnorthrefclk0_in = gtnorthrefclk0_in;
    wire            b0gt0_gtnorthrefclk1_in = gtnorthrefclk1_in;
    wire            b0gt0_gtsouthrefclk0_in = gtsouthrefclk0_in;
    wire            b0gt0_gtsouthrefclk1_in = gtsouthrefclk1_in;
    wire  [39:0]    b0gt0_dru_data_out; 
    wire            b0gt0_dru_en_out; 
    
    wire  [8:0]     b0gt0_drpaddr_in;
    wire            b0gt0_drpclk_in;
    wire  [15:0]    b0gt0_drpdi_in;
    wire  [15:0]    b0gt0_drpdo_out;
    wire            b0gt0_drpen_in;
    wire            b0gt0_drprdy_out;
    wire            b0gt0_drp_busy_out;
    wire            b0gt0_drpwe_in;
    wire  [1:0]     b0gt0_rxsysclksel_in;
    wire  [1:0]     b0gt0_txsysclksel_in;
    wire  [2:0]     b0gt0_cpllrefclksel_in;
    wire  [7:0]     b0gt0_dmonitorout_out;
    wire  [2:0]     b0gt0_loopback_in;
    wire            b0gt0_phystatus_out;
    wire  [1:0]     b0gt0_txpd_in;
    wire  [1:0]     b0gt0_txpd_in_sync;
    wire  [1:0]     b0gt0_rxpd_in;
    wire            b0gt0_eyescanreset_in;
    wire            b0gt0_rxuserrdy_in;
    wire            b0gt0_eyescantrigger_in = tied_to_ground_i;
    wire            b0gt0_rxcdrhold_in;
    wire  [39:0]    b0gt0_rxdata_out;
    wire            b0gt0_rxprbserr_out;
    reg             b0gt0_rxprbserr_out_latch;
    wire            b0gt0_rxprbserr_out_sync;
    wire  [2:0]     b0gt0_rxprbssel_in;
    wire  [2:0]     b0gt0_rxprbssel_in_sync;
    wire            b0gt0_rxprbscntreset_in;
    wire            b0gt0_rxprbscntreset_in_sync;
    wire            b0gt0_rxbufreset_in;
    wire  [2:0]     b0gt0_rxbufstatus_out;
    wire  [2:0]     b0gt0_rxbufstatus_out_sync;
    wire            b0gt0_rxlpmhfovrden_in;
    wire            b0gt0_rxlpmhfovrden_in_sync;
    wire            b0gt0_rxdfeagchold_in = tied_to_ground_i;
    wire            b0gt0_rxdfelfhold_in = tied_to_ground_i;
    wire            b0gt0_rxdfelpmreset_in = tied_to_ground_i;
    wire  [6:0]     b0gt0_rxmonitorout_out;
    wire            b0gt0_rxlpmlfklovrden_in;
    wire            b0gt0_rxlpmlfklovrden_in_sync;
    wire  [1:0]     b0gt0_rxmonitorsel_in = tied_to_ground_vec_i[1:0];
    wire            b0gt0_rxoutclk_out;
    wire            b0gt0_rxcdrlock_out;
    wire            b0gt0_rxcdrlock_out_sync;
    wire            b0gt0_gtrxreset_in;
    wire            b0gt0_rxpcsreset_in;
    wire            b0gt0_rxpmareset_in;
    wire            b0gt0_rxlpmen_in;
    wire            b0gt0_rxlpmen_in_sync;
    wire            b0gt0_rxpolarity_in;
    wire            b0gt0_rxpolarity_in_sync;
    wire            b0gt0_rxslide_in = tied_to_ground_i;
    wire            b0gt0_rxresetdone_out;
    wire            b0gt0_rxresetdone_out_sync;
    wire  [4:0]     b0gt0_txpostcursor_in;
    wire  [4:0]     b0gt0_txprecursor_in;
    wire            b0gt0_gttxreset_in;
    wire            b0gt0_txuserrdy_in;
    wire            b0gt0_txelecidle_in;
    wire            b0gt0_txprbsforceerr_in;
    wire            b0gt0_txprbsforceerr_in_sync;
    wire  [1:0]     b0gt0_txbufstatus_out;
    wire  [1:0]     b0gt0_txbufstatus_out_sync;
    wire            b0gt0_txphaligndone_out;
    wire            b0gt0_txphaligndone_out_sync;
    wire  [3:0]     b0gt0_txdiffctrl_in;
    wire  [3:0]     b0gt0_txdiffctrl_in_sync;
    wire            b0gt0_txinhibit_in;
    wire            b0gt0_txinhibit_in_sync;
    wire  [39:0]    b0gt0_txdata_in;
    
    wire            b0gt0_txoutclk_out;
    wire            b0gt0_txoutclkfabric_out;
    wire            b0gt0_txoutclkpcs_out;
    wire            b0gt0_txpcsreset_in;
    wire            b0gt0_txpmareset_in;
    wire            b0gt0_txresetdone_out;
    wire            b0gt0_txfsmresetdone_out;
    wire            b0gt0_tx_mmcm_lock_in;
    wire            b0gt0_tx_mmcm_reset_out;
    wire            b0gt0_txfsmresetdone_out_sync;
    wire            b0gt0_txresetdone_out_sync;
    wire            b0gt0_tx8b10ben_in;
    wire            b0gt0_tx8b10ben_in_sync;
    wire            b0gt0_txpolarity_in;
    wire            b0gt0_txpolarity_in_sync;
    wire  [2:0]     b0gt0_txprbssel_in;
    wire  [2:0]     b0gt0_txprbssel_in_sync;
    wire            b0gt0_gtxtxn_out;
    wire            b0gt0_gtxtxp_out;
    wire            b0gt0_gtxrxn_in;
    wire            b0gt0_gtxrxp_in;


    //Signal Naming Format: b0gt0 -> Bank 0, GT Channel 0
 
    //wire            b0gt1_cplllock_out;
    wire            b0gt1_cplllock_out_sync;
    wire            b0gt1_cplllockdetclk_in;
    wire            b0gt1_cpllpd_in;
    wire            b0gt1_cpllreset_in;
    wire  [3:0]     b0gt1_clkrsvd_in = tied_to_ground_vec_i[3:0];
    
    wire            b0gt1_gtnorthrefclk0_in = gtnorthrefclk0_in;
    wire            b0gt1_gtnorthrefclk1_in = gtnorthrefclk1_in;
    wire            b0gt1_gtsouthrefclk0_in = gtsouthrefclk0_in;
    wire            b0gt1_gtsouthrefclk1_in = gtsouthrefclk1_in;
    wire  [39:0]    b0gt1_dru_data_out; 
    wire            b0gt1_dru_en_out; 
    
    wire  [8:0]     b0gt1_drpaddr_in;
    wire            b0gt1_drpclk_in;
    wire  [15:0]    b0gt1_drpdi_in;
    wire  [15:0]    b0gt1_drpdo_out;
    wire            b0gt1_drpen_in;
    wire            b0gt1_drprdy_out;
    wire            b0gt1_drp_busy_out;
    wire            b0gt1_drpwe_in;
    wire  [1:0]     b0gt1_rxsysclksel_in;
    wire  [1:0]     b0gt1_txsysclksel_in;
    wire  [2:0]     b0gt1_cpllrefclksel_in;
    wire  [7:0]     b0gt1_dmonitorout_out;
    wire  [2:0]     b0gt1_loopback_in;
    wire            b0gt1_phystatus_out;
    wire  [1:0]     b0gt1_txpd_in;
    wire  [1:0]     b0gt1_txpd_in_sync;
    wire  [1:0]     b0gt1_rxpd_in;
    wire            b0gt1_eyescanreset_in;
    wire            b0gt1_rxuserrdy_in;
    wire            b0gt1_eyescantrigger_in = tied_to_ground_i;
    wire            b0gt1_rxcdrhold_in;
    wire  [39:0]    b0gt1_rxdata_out;
    wire            b0gt1_rxprbserr_out;
    reg             b0gt1_rxprbserr_out_latch;
    wire            b0gt1_rxprbserr_out_sync;
    wire  [2:0]     b0gt1_rxprbssel_in;
    wire  [2:0]     b0gt1_rxprbssel_in_sync;
    wire            b0gt1_rxprbscntreset_in;
    wire            b0gt1_rxprbscntreset_in_sync;
    wire            b0gt1_rxbufreset_in;
    wire  [2:0]     b0gt1_rxbufstatus_out;
    wire  [2:0]     b0gt1_rxbufstatus_out_sync;
    wire            b0gt1_rxlpmhfovrden_in;
    wire            b0gt1_rxlpmhfovrden_in_sync;
    wire            b0gt1_rxdfeagchold_in = tied_to_ground_i;
    wire            b0gt1_rxdfelfhold_in = tied_to_ground_i;
    wire            b0gt1_rxdfelpmreset_in = tied_to_ground_i;
    wire  [6:0]     b0gt1_rxmonitorout_out;
    wire            b0gt1_rxlpmlfklovrden_in;
    wire            b0gt1_rxlpmlfklovrden_in_sync;
    wire  [1:0]     b0gt1_rxmonitorsel_in = tied_to_ground_vec_i[1:0];
    wire            b0gt1_rxoutclk_out;
    wire            b0gt1_rxcdrlock_out;
    wire            b0gt1_rxcdrlock_out_sync;
    wire            b0gt1_gtrxreset_in;
    wire            b0gt1_rxpcsreset_in;
    wire            b0gt1_rxpmareset_in;
    wire            b0gt1_rxlpmen_in;
    wire            b0gt1_rxlpmen_in_sync;
    wire            b0gt1_rxpolarity_in;
    wire            b0gt1_rxpolarity_in_sync;
    wire            b0gt1_rxslide_in = tied_to_ground_i;
    wire            b0gt1_rxresetdone_out;
    wire            b0gt1_rxresetdone_out_sync;
    wire  [4:0]     b0gt1_txpostcursor_in;
    wire  [4:0]     b0gt1_txprecursor_in;
    wire            b0gt1_gttxreset_in;
    wire            b0gt1_txuserrdy_in;
    wire            b0gt1_txelecidle_in;
    wire            b0gt1_txprbsforceerr_in;
    wire            b0gt1_txprbsforceerr_in_sync;
    wire  [1:0]     b0gt1_txbufstatus_out;
    wire  [1:0]     b0gt1_txbufstatus_out_sync;
    wire            b0gt1_txphaligndone_out;
    wire            b0gt1_txphaligndone_out_sync;
    wire  [3:0]     b0gt1_txdiffctrl_in;
    wire  [3:0]     b0gt1_txdiffctrl_in_sync;
    wire            b0gt1_txinhibit_in;
    wire            b0gt1_txinhibit_in_sync;
    wire  [39:0]    b0gt1_txdata_in;
    
    wire            b0gt1_txoutclk_out;
    wire            b0gt1_txoutclkfabric_out;
    wire            b0gt1_txoutclkpcs_out;
    wire            b0gt1_txpcsreset_in;
    wire            b0gt1_txpmareset_in;
    wire            b0gt1_txresetdone_out;
    wire            b0gt1_txfsmresetdone_out;
    wire            b0gt1_tx_mmcm_lock_in;
    wire            b0gt1_tx_mmcm_reset_out;
    wire            b0gt1_txfsmresetdone_out_sync;
    wire            b0gt1_txresetdone_out_sync;
    wire            b0gt1_tx8b10ben_in;
    wire            b0gt1_tx8b10ben_in_sync;
    wire            b0gt1_txpolarity_in;
    wire            b0gt1_txpolarity_in_sync;
    wire  [2:0]     b0gt1_txprbssel_in;
    wire  [2:0]     b0gt1_txprbssel_in_sync;
    wire            b0gt1_gtxtxn_out;
    wire            b0gt1_gtxtxp_out;
    wire            b0gt1_gtxrxn_in;
    wire            b0gt1_gtxrxp_in;


    //Signal Naming Format: b0gt0 -> Bank 0, GT Channel 0
 
    //wire            b0gt2_cplllock_out;
    wire            b0gt2_cplllock_out_sync;
    wire            b0gt2_cplllockdetclk_in;
    wire            b0gt2_cpllpd_in;
    wire            b0gt2_cpllreset_in;
    wire  [3:0]     b0gt2_clkrsvd_in = tied_to_ground_vec_i[3:0];
    
    wire            b0gt2_gtnorthrefclk0_in = gtnorthrefclk0_in;
    wire            b0gt2_gtnorthrefclk1_in = gtnorthrefclk1_in;
    wire            b0gt2_gtsouthrefclk0_in = gtsouthrefclk0_in;
    wire            b0gt2_gtsouthrefclk1_in = gtsouthrefclk1_in;
    wire  [39:0]    b0gt2_dru_data_out; 
    wire            b0gt2_dru_en_out; 
    
    wire  [8:0]     b0gt2_drpaddr_in;
    wire            b0gt2_drpclk_in;
    wire  [15:0]    b0gt2_drpdi_in;
    wire  [15:0]    b0gt2_drpdo_out;
    wire            b0gt2_drpen_in;
    wire            b0gt2_drprdy_out;
    wire            b0gt2_drp_busy_out;
    wire            b0gt2_drpwe_in;
    wire  [1:0]     b0gt2_rxsysclksel_in;
    wire  [1:0]     b0gt2_txsysclksel_in;
    wire  [2:0]     b0gt2_cpllrefclksel_in;
    wire  [7:0]     b0gt2_dmonitorout_out;
    wire  [2:0]     b0gt2_loopback_in;
    wire            b0gt2_phystatus_out;
    wire  [1:0]     b0gt2_txpd_in;
    wire  [1:0]     b0gt2_txpd_in_sync;
    wire  [1:0]     b0gt2_rxpd_in;
    wire            b0gt2_eyescanreset_in;
    wire            b0gt2_rxuserrdy_in;
    wire            b0gt2_eyescantrigger_in = tied_to_ground_i;
    wire            b0gt2_rxcdrhold_in;
    wire  [39:0]    b0gt2_rxdata_out;
    wire            b0gt2_rxprbserr_out;
    reg             b0gt2_rxprbserr_out_latch;
    wire            b0gt2_rxprbserr_out_sync;
    wire  [2:0]     b0gt2_rxprbssel_in;
    wire  [2:0]     b0gt2_rxprbssel_in_sync;
    wire            b0gt2_rxprbscntreset_in;
    wire            b0gt2_rxprbscntreset_in_sync;
    wire            b0gt2_rxbufreset_in;
    wire  [2:0]     b0gt2_rxbufstatus_out;
    wire  [2:0]     b0gt2_rxbufstatus_out_sync;
    wire            b0gt2_rxlpmhfovrden_in;
    wire            b0gt2_rxlpmhfovrden_in_sync;
    wire            b0gt2_rxdfeagchold_in = tied_to_ground_i;
    wire            b0gt2_rxdfelfhold_in = tied_to_ground_i;
    wire            b0gt2_rxdfelpmreset_in = tied_to_ground_i;
    wire  [6:0]     b0gt2_rxmonitorout_out;
    wire            b0gt2_rxlpmlfklovrden_in;
    wire            b0gt2_rxlpmlfklovrden_in_sync;
    wire  [1:0]     b0gt2_rxmonitorsel_in = tied_to_ground_vec_i[1:0];
    wire            b0gt2_rxoutclk_out;
    wire            b0gt2_rxcdrlock_out;
    wire            b0gt2_rxcdrlock_out_sync;
    wire            b0gt2_gtrxreset_in;
    wire            b0gt2_rxpcsreset_in;
    wire            b0gt2_rxpmareset_in;
    wire            b0gt2_rxlpmen_in;
    wire            b0gt2_rxlpmen_in_sync;
    wire            b0gt2_rxpolarity_in;
    wire            b0gt2_rxpolarity_in_sync;
    wire            b0gt2_rxslide_in = tied_to_ground_i;
    wire            b0gt2_rxresetdone_out;
    wire            b0gt2_rxresetdone_out_sync;
    wire  [4:0]     b0gt2_txpostcursor_in;
    wire  [4:0]     b0gt2_txprecursor_in;
    wire            b0gt2_gttxreset_in;
    wire            b0gt2_txuserrdy_in;
    wire            b0gt2_txelecidle_in;
    wire            b0gt2_txprbsforceerr_in;
    wire            b0gt2_txprbsforceerr_in_sync;
    wire  [1:0]     b0gt2_txbufstatus_out;
    wire  [1:0]     b0gt2_txbufstatus_out_sync;
    wire            b0gt2_txphaligndone_out;
    wire            b0gt2_txphaligndone_out_sync;
    wire  [3:0]     b0gt2_txdiffctrl_in;
    wire  [3:0]     b0gt2_txdiffctrl_in_sync;
    wire            b0gt2_txinhibit_in;
    wire            b0gt2_txinhibit_in_sync;
    wire  [39:0]    b0gt2_txdata_in;
    
    wire            b0gt2_txoutclk_out;
    wire            b0gt2_txoutclkfabric_out;
    wire            b0gt2_txoutclkpcs_out;
    wire            b0gt2_txpcsreset_in;
    wire            b0gt2_txpmareset_in;
    wire            b0gt2_txresetdone_out;
    wire            b0gt2_txfsmresetdone_out;
    wire            b0gt2_tx_mmcm_lock_in;
    wire            b0gt2_tx_mmcm_reset_out;
    wire            b0gt2_txfsmresetdone_out_sync;
    wire            b0gt2_txresetdone_out_sync;
    wire            b0gt2_tx8b10ben_in;
    wire            b0gt2_tx8b10ben_in_sync;
    wire            b0gt2_txpolarity_in;
    wire            b0gt2_txpolarity_in_sync;
    wire  [2:0]     b0gt2_txprbssel_in;
    wire  [2:0]     b0gt2_txprbssel_in_sync;
    wire            b0gt2_gtxtxn_out;
    wire            b0gt2_gtxtxp_out;
    wire            b0gt2_gtxrxn_in;
    wire            b0gt2_gtxrxp_in;

    wire            b0gt0_txusrclk_in;
    wire            b0gt0_txusrclk2_in;
    wire            b0gt0_rxusrclk_in;
    wire            b0gt0_rxusrclk2_in;

    //____________________________COMMON PORTS________________________________
    wire            b0gt0_qplllock_in;
    wire            b0gt0_qplllock_in_sync;
    wire            b0gt0_qpllrefclklost_in;
    wire            b0gt0_qpllrefclklost_in_sync;
    wire            b0gt0_qpllreset_in;
    wire            b0gt0_qpllreset_in_prog;
    wire            b0gt0_qplloutclk_in;
    wire            b0gt0_qplloutrefclk_in;
    wire   [2:0]    b0gt0_qpllrefclksel_in;
    
    wire            b0gt0_qpllpd_in;
    wire   [7:0]    b0gt0_drpaddr_common_in;
    wire   [15:0]   b0gt0_drpdi_common_in;
    wire   [15:0]   b0gt0_drpdo_common_out;
    wire            b0gt0_drpen_common_in;
    wire            b0gt0_drprdy_common_out;
    wire            b0gt0_drpwe_common_in;
    //______________________GTP COMMON PORTS__________________________________
    wire            b0gt0_pll0_lock_in;
    wire            b0gt0_pll0_lock_in_sync;
    wire            b0gt0_pll1_lock_in;
    wire            b0gt0_pll1_lock_in_sync;
    wire            b0gt0_pll0outclk_in;
    wire            b0gt0_pll0outrefclk_in;
    wire            b0gt0_pll1outclk_in;
    wire            b0gt0_pll1outrefclk_in;
    wire            b0gt0_pll0reset_in_prog;
    wire            b0gt0_pll1reset_in_prog;
    wire            b0gt0_pllpd_in;
    wire   [2:0]    b0gt0_pll0refclksel_in;
    wire   [2:0]    b0gt0_pll1refclksel_in;
    wire            b0gt0_pll0reset_out;
    wire            b0gt0_pll1reset_out;
    wire            b0gt0_pll0refclklost_in; 
    wire            b0gt0_pll1refclklost_in; 

    localparam pBANK0 = 5'h00;
    localparam pBANK1 = 5'h01;
    localparam pBANK2 = 5'h02;
    localparam pBANK3 = 5'h03;
    localparam GTREFCLK0 = 0;
    localparam GTREFCLK1 = 1;
    localparam GTNORTHREFCLK0 = 2;
    localparam GTNORTHREFCLK1 = 3;
    localparam GTSOUTHREFCLK0 = 4;
    localparam GTSOUTHREFCLK1 = 5;
    localparam GTEASTREFCLK0  = 6;
    localparam GTEASTREFCLK1  = 7;
    localparam GTWESTREFCLK0  = 8;
    localparam GTWESTREFCLK1  = 9;

    wire `tPHY_MEM_MAP_FIELDS_CONTROL   cfg_phy_mem_map_control;
    wire  `tPHY_MEM_MAP_FIELDS_STATUS    cfg_phy_mem_map_status;  
    wire [6:0] drp_txn_available;
    wire [6:0] drp_rsp_read; 
    wire [3:0] rx_sym_err_cntr_read;    
    
 

    wire `tPHY_MEM_MAP_FIELDS_CONTROL   cfg_phy_mem_map_control_b0;
    wire `tPHY_MEM_MAP_FIELDS_STATUS    cfg_phy_mem_map_status_b0;  

`ifdef SIM_GTRESET_SPEEDUP
    localparam      pSIM_GTRESET_SPEEDUP = "TRUE";
`else
    localparam      pSIM_GTRESET_SPEEDUP = "FALSE";
`endif

    assign txoutclk = b0gt0_txusrclk_in; //Connecting channel0
    assign rxoutclk = b0gt0_rxusrclk_in; //Connecting channel0


    // ---------------------- Bank 0, GT Channel 0 ------------------------------
    assign phy_txp_out[0]                 = b0gt0_gtxtxp_out;
    assign phy_txn_out[0]                 = b0gt0_gtxtxn_out;

    assign b0gt0_gtxrxp_in          = phy_rxp_in[0];
    assign b0gt0_gtxrxn_in          = phy_rxn_in[0];

    assign b0gt0_txdata_in          = {20'b0, vid_phy_tx_axi4s_ch0_tdata};
    assign vid_phy_tx_axi4s_ch0_tready    = 1'b1;

 
    assign vid_phy_rx_axi4s_ch0_tdata        = (C_NIDRU) ? b0gt0_dru_data_out[19:0] : b0gt0_rxdata_out[19:0];
    assign vid_phy_rx_axi4s_ch0_tuser        = tied_to_ground_vec_i[C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0];
    assign vid_phy_rx_axi4s_ch0_tvalid       = (C_NIDRU) ? b0gt0_dru_en_out : 1'b1;
    

    // ---------------------- Bank 0, GT Channel 1 ------------------------------
    assign phy_txp_out[1]                 = b0gt1_gtxtxp_out;
    assign phy_txn_out[1]                 = b0gt1_gtxtxn_out;

    assign b0gt1_gtxrxp_in          = phy_rxp_in[1];
    assign b0gt1_gtxrxn_in          = phy_rxn_in[1];

    assign b0gt1_txdata_in          = {20'b0, vid_phy_tx_axi4s_ch1_tdata};
    assign vid_phy_tx_axi4s_ch1_tready    = 1'b1;

 
    assign vid_phy_rx_axi4s_ch1_tdata        = (C_NIDRU) ? b0gt1_dru_data_out[19:0] : b0gt1_rxdata_out[19:0];
    assign vid_phy_rx_axi4s_ch1_tuser        = tied_to_ground_vec_i[C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0];
    assign vid_phy_rx_axi4s_ch1_tvalid       = (C_NIDRU) ? b0gt1_dru_en_out : 1'b1;
    

    // ---------------------- Bank 0, GT Channel 2 ------------------------------
    assign phy_txp_out[2]                 = b0gt2_gtxtxp_out;
    assign phy_txn_out[2]                 = b0gt2_gtxtxn_out;

    assign b0gt2_gtxrxp_in          = phy_rxp_in[2];
    assign b0gt2_gtxrxn_in          = phy_rxn_in[2];

    assign b0gt2_txdata_in          = {20'b0, vid_phy_tx_axi4s_ch2_tdata};
    assign vid_phy_tx_axi4s_ch2_tready    = 1'b1;

 
    assign vid_phy_rx_axi4s_ch2_tdata        = (C_NIDRU) ? b0gt2_dru_data_out[19:0] : b0gt2_rxdata_out[19:0];
    assign vid_phy_rx_axi4s_ch2_tuser        = tied_to_ground_vec_i[C_vid_phy_rx_axi4s_ch_TUSER_WIDTH-1 : 0];
    assign vid_phy_rx_axi4s_ch2_tvalid       = (C_NIDRU) ? b0gt2_dru_en_out : 1'b1;

wire                        mgtrefclk0_from_bufds;
wire                        mgtrefclk1_from_bufds;
wire                        drurefclk_from_bufds;

// TX Alignment
wire                        str_to_txaln;
wire                        rst_to_txaln;
wire                        done_from_txaln;
wire	[2:0]				txdlyen_from_txaln;
wire	[2:0]				txdlysreset_from_txaln;
wire 	[2:0]	    		txdlysresetdone_from_gt;
wire	[2:0]	    		txphalign_from_txaln;
wire	[2:0]				txphaligndone_from_gt;
wire	[2:0]				txphalignen_from_txaln;
wire	[2:0]	    		txphdlyreset_from_txaln;
wire	[2:0]				txphinit_from_txaln;
wire	[2:0]				txphinitdone_from_gt;

wire	[2:0]				lock_from_cpll;
reg     [23:0]              clk_cpll_lock_cnt;
reg                         clk_cpll_locked;
reg                         clk_cpll_lock_lost;

reg                         clk_cpll_pd;
wire                        rst_to_cpll;
reg                         rst_to_cpll_del;
wire                        rst_to_cpll_re;
wire                        rst_to_cpll_fe;
reg                         clk_cpll_rst;
wire                        rst_to_cpll_from_tx;
wire                        rst_to_cpll_from_rx;
wire    [2:0]               clksel_to_cpll;

reg                         clk_qpll_pd;
wire                        rst_to_qpll_from_tx;
wire                        rst_to_qpll_from_rx;
wire                        rst_to_qpll;
reg                         rst_to_qpll_del;
wire                        rst_to_qpll_re;
wire                        rst_to_qpll_fe;
reg                         clk_qpll_rst;
wire                        lock_from_qpll;
reg     [23:0]              clk_qpll_lock_cnt;
reg                         clk_qpll_locked;
reg                         clk_qpll_lock_lost;


wire                        rxcdrhold_to_gt;
wire                        rxlpmhfovrden_to_gt;
wire                        rxlpmlfklovrden_to_gt;
wire                        rxosovrden_to_gt;

reg                         clk_rxusrrdy;
reg                         clk_txusrrdy;

// TX PLL
wire                        pd_to_txpll;
wire                        rst_to_txpll;
reg                         rst_to_txpll_del;
wire                        rst_to_txpll_re;
wire                        rst_to_txpll_fe;
reg                         clk_txpll_rst;
wire                        lock_from_txpll;
reg     [23:0]              clk_txpll_lock_cnt;
reg                         clk_txpll_locked;
reg                         clk_txpll_lock_lost;
wire    [15:0]              drp_dat_from_txpll;
wire                        drp_rdy_from_txpll;

wire                        clksel_to_txpll;
wire                        fbclk_from_txpll;
wire                        hclk_from_txpll_i;      
wire                        hclk_from_txpll;        // HDMI clock
wire                        lclk_from_txpll;        // Link clock
wire                        vclk_from_txpll;        // Video clock
wire                        vclk_from_txbufg;       // Video clock
wire                        lclk_from_txbufg;       // Link clock

wire    [31:0]              DRP_Config_mmcm_txusrclk;
wire    [31:0]              DRP_Status_mmcm_txusrclk;

// RX PLL
wire                        pd_to_rxpll;
wire                        rst_to_rxpll;
reg                         rst_to_rxpll_del;
wire                        rst_to_rxpll_re;
wire                        rst_to_rxpll_fe;
reg                         clk_rxpll_rst;
wire                        lock_from_rxpll;
reg     [23:0]              clk_rxpll_lock_cnt;
reg                         clk_rxpll_locked;
reg                         clk_rxpll_lock_lost;

wire    [15:0]              drp_dat_from_rxpll;
wire                        drp_rdy_from_rxpll;

wire                        fbclk_from_rxpll;       // Feedback clock
wire                        lclk_from_rxpll;        // Link clock
wire                        vclk_from_rxpll;        // Video clock
wire                        lclk_from_rxbufg;       // Link clock
wire                        vclk_from_rxbufg;       // Video clock
wire                        aclk_from_rxbufg;       // Audio clock

wire    [31:0]              DRP_Config_mmcm_rxusrclk;
wire    [31:0]              DRP_Status_mmcm_rxusrclk;

// DRU
wire                        dru_active;     

wire                        dat_from_oddr_tx;
wire                        dat_from_oddr_rx;

(* async_reg = "true" *)    reg [2:0]   hclk_tx_clk_en;
(* async_reg = "true" *)    reg [2:0]   rxclk_rx_clk_en;

wire   b0_OBUFTDS_TX_EN;
wire   b0_OBUFTDS_TX_EN_sync;
assign b0_OBUFTDS_TX_EN = cfg_phy_mem_map_control_b0[`OBUFTDS_TXUSRCLK_CLKOUT1_EN];
wire   b0_OBUFTDS_RX_EN;
assign b0_OBUFTDS_RX_EN = cfg_phy_mem_map_control_b0[`OBUFTDS_RXUSRCLK_CLKOUT1_EN];

// Transceiver
exdes_vid_phy_controller_0_gtxe2_hdmi_xcvr
    #(
        // Simulation attributes
        .GT_SIM_GTRESET_SPEEDUP     ("TRUE"),       // Set to "TRUE" to speed up sim reset;
        .RX_DFE_KL_CFG2_IN          (32'h301148AC),
        .PMA_RSV_IN                 (32'h00018480),
        .PCS_RSVD_ATTR_IN           (48'h000000000002)          // Bit[1] must be set for the TX buffer bypass to work correctly
    )
    XCVR_CH0_INST
    (
        //------------------------------- CPLL Ports -------------------------------
        .cpllfbclklost_out      (),
        .cplllock_out           (lock_from_cpll[0]), //update channel!
        .cplllockdetclk_in      (vid_phy_axi4lite_aclk),
        .cpllpd_in              (clk_cpll_pd),
        .cpllrefclklost_out     (),
        .cpllreset_in           (clk_cpll_rst),
        .cpllrefclksel_in       (b0gt0_cpllrefclksel_in),//(clksel_to_cpll),
        //------------------------ Channel - Clocking Ports ------------------------
        .gtrefclk0_in           (mgtrefclk0_from_bufds),
        .gtrefclk1_in           (mgtrefclk1_from_bufds),
        .gtnorthrefclk0_in      (gtnorthrefclk0_in),
        .gtnorthrefclk1_in      (gtnorthrefclk1_in),
        .gtsouthrefclk0_in      (gtsouthrefclk0_in),
        .gtsouthrefclk1_in      (gtsouthrefclk1_in),
        //-------------------------- Channel - DRP Ports  --------------------------
        .drpaddr_in             (b0gt0_drpaddr_in), //update channel!
        .drpclk_in              (b0gt0_drpclk_in),  //update channel!
        .drpdi_in               (b0gt0_drpdi_in),   //update channel!
        .drpdo_out              (b0gt0_drpdo_out),  //update channel!
        .drpen_in               (b0gt0_drpen_in),   //update channel!
        .drprdy_out             (b0gt0_drprdy_out), //update channel!
        .drpwe_in               (b0gt0_drpwe_in),   //update channel!
        //----------------------------- Clocking Ports -----------------------------
        .qpllclk_in             (b0gt0_qplloutclk_in),
        .qpllrefclk_in          (b0gt0_qplloutrefclk_in),
        .rxsysclksel_in         (b0gt0_rxsysclksel_in),
        .txsysclksel_in         (b0gt0_txsysclksel_in),
        //----------------------------- Loopback Ports -----------------------------
        .loopback_in            (b0gt0_loopback_in),
        //------------------------- Digital Monitor Ports --------------------------
        .dmonitorout_out        (),
        //------------------- RX Initialization and Reset Ports --------------------
        .eyescanreset_in        (1'b0),
        .rxuserrdy_in           (clk_rxusrrdy),
        //---------------- Receive Ports - RX Margin Analysis ports ----------------
        .rxlpmen_in             (b0gt0_rxlpmen_in),//(rx_dfelpmsel_from_pio),       // 0 - Select DFE mode / 1 - Select LPM mode
        //------------------------ RX Margin Analysis Ports ------------------------
        .eyescandataerror_out   (),
        .eyescantrigger_in      (1'b0),
        //----------------------- Receive Ports - CDR Ports ------------------------
        .rxcdrhold_in           (rxcdrhold_to_gt),
        .rxcdrlock_out          (b0gt0_rxcdrlock_out),
        //---------------- Receive Ports - FPGA RX Interface Ports -----------------
        .rxusrclk_in            (b0gt0_rxusrclk_in),
        .rxusrclk2_in           (b0gt0_rxusrclk2_in),
        //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .rxdata_out             (b0gt0_rxdata_out),   //update channel!
        //------------------------- Receive Ports - RX AFE -------------------------
        .gtxrxp_in              (b0gt0_gtxrxp_in),   //update channel!
        //---------------------- Receive Ports - RX AFE Ports ----------------------
        .gtxrxn_in              (b0gt0_gtxrxn_in),   //update channel!
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        /*
        .rxdlyen_in             (rxdlyen_from_rxaln[i]),
        .rxdlysreset_in         (rxdlysreset_from_rxaln[i]),
        .rxdlysresetdone_out    (rxdlysresetdone_from_gt[i]),
        .rxphalign_in           (rxphalign_from_rxaln[i]),
        .rxphaligndone_out      (rxphaligndone_from_gt[i]),
        .rxphalignen_in         (rxphalignen_from_rxaln[i]),
        .rxphdlyreset_in        (rxphdlyreset_from_rxaln[i]),
        .rxphmonitor_out        (),
        .rxphslipmonitor_out    (),
        */
        //------------------ Receive Ports - RX Equailizer Ports -------------------
        .rxlpmhfhold_in         (1'b0),
        .rxlpmlfhold_in         (1'b0),
        .rxlpmhfovrden_in       (rxlpmhfovrden_to_gt),
        .rxlpmlfklovrden_in     (rxlpmlfklovrden_to_gt),
        .rxosovrden_in          (rxosovrden_to_gt),
        //------------------- Receive Ports - RX Equalizer Ports -------------------
        .rxdfelpmreset_in       (1'b0),
        .rxmonitorout_out       (),
        .rxmonitorsel_in        (2'h0),
        //------------- Receive Ports - RX Fabric Output Control Ports -------------
        .rxoutclk_out           (b0gt0_rxoutclk_out),
        //.rxoutclk_out         (),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .gtrxreset_in           (b0gt0_gtrxreset_in),
        .rxpmareset_in          (1'b0),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .rxpolarity_in          (b0gt0_rxpolarity_in),
        //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .rxresetdone_out        (b0gt0_rxresetdone_out),   //update channel!
        //---------------------- TX Configurable Driver Ports ----------------------
        .txpostcursor_in        (b0gt0_txpostcursor_in),
        .txprecursor_in         (b0gt0_txprecursor_in),
        //------------------- TX Initialization and Reset Ports --------------------
        .gttxreset_in           (b0gt0_gttxreset_in),
        .txuserrdy_in           (clk_txusrrdy),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
        .txusrclk_in            (b0gt0_txusrclk_in),
        .txusrclk2_in           (b0gt0_txusrclk2_in),
        //------------------- Transmit Ports - PCI Express Ports -------------------
        .txelecidle_in          (b0gt0_txelecidle_in),
        //---------------- Transmit Ports - TX Buffer Bypass Ports -----------------
        .txdlyen_in             (txdlyen_from_txaln[0]),      //update channel!
        .txdlysreset_in         (txdlysreset_from_txaln[0]),  //update channel!
        .txdlysresetdone_out    (txdlysresetdone_from_gt[0]), //update channel!
        .txphalign_in           (txphalign_from_txaln[0]),    //update channel!
        .txphaligndone_out      (txphaligndone_from_gt[0]),   //update channel!
        .txphalignen_in         (txphalignen_from_txaln[0]),  //update channel!
        .txphdlyreset_in        (txphdlyreset_from_txaln[0]), //update channel!
        .txphinit_in            (txphinit_from_txaln[0]),     //update channel!
        .txphinitdone_out       (txphinitdone_from_gt[0]),    //update channel!
        //------------- Transmit Ports - TX Configurable Driver Ports --------------
        .txdiffctrl_in          (b0gt0_txdiffctrl_in),
        .txinhibit_in           (b0gt0_txinhibit_in),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .txdata_in              (b0gt0_txdata_in),    //update channel!
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .gtxtxn_out             (b0gt0_gtxtxn_out),    //update channel!
        .gtxtxp_out             (b0gt0_gtxtxp_out),    //update channel!
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .txoutclk_out           (b0gt0_txoutclk_out),    //update channel!
//          .txoutclk_out           (),
        .txoutclkfabric_out     (),
        .txoutclkpcs_out        (),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .txresetdone_out        (b0gt0_txresetdone_out),   //update channel!
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
        .txpolarity_in          (b0gt0_txpolarity_in)
    );

exdes_vid_phy_controller_0_gtxe2_hdmi_xcvr
    #(
        // Simulation attributes
        .GT_SIM_GTRESET_SPEEDUP     ("TRUE"),       // Set to "TRUE" to speed up sim reset;
        .RX_DFE_KL_CFG2_IN          (32'h301148AC),
        .PMA_RSV_IN                 (32'h00018480),
        .PCS_RSVD_ATTR_IN           (48'h000000000002)          // Bit[1] must be set for the TX buffer bypass to work correctly
    )
    XCVR_CH1_INST
    (
        //------------------------------- CPLL Ports -------------------------------
        .cpllfbclklost_out      (),
        .cplllock_out           (lock_from_cpll[1]), //update channel!
        .cplllockdetclk_in      (vid_phy_axi4lite_aclk),
        .cpllpd_in              (clk_cpll_pd),
        .cpllrefclklost_out     (),
        .cpllreset_in           (clk_cpll_rst),
        .cpllrefclksel_in       (b0gt0_cpllrefclksel_in),//(clksel_to_cpll),
        //------------------------ Channel - Clocking Ports ------------------------
        .gtrefclk0_in           (mgtrefclk0_from_bufds),
        .gtrefclk1_in           (mgtrefclk1_from_bufds),
        .gtnorthrefclk0_in      (gtnorthrefclk0_in),
        .gtnorthrefclk1_in      (gtnorthrefclk1_in),
        .gtsouthrefclk0_in      (gtsouthrefclk0_in),
        .gtsouthrefclk1_in      (gtsouthrefclk1_in),
        //-------------------------- Channel - DRP Ports  --------------------------
        .drpaddr_in             (b0gt1_drpaddr_in), //update channel!
        .drpclk_in              (b0gt1_drpclk_in),  //update channel!
        .drpdi_in               (b0gt1_drpdi_in),   //update channel!
        .drpdo_out              (b0gt1_drpdo_out),  //update channel!
        .drpen_in               (b0gt1_drpen_in),   //update channel!
        .drprdy_out             (b0gt1_drprdy_out), //update channel!
        .drpwe_in               (b0gt1_drpwe_in),   //update channel!
        //----------------------------- Clocking Ports -----------------------------
        .qpllclk_in             (b0gt0_qplloutclk_in),
        .qpllrefclk_in          (b0gt0_qplloutrefclk_in),
        .rxsysclksel_in         (b0gt0_rxsysclksel_in),
        .txsysclksel_in         (b0gt0_txsysclksel_in),
        //----------------------------- Loopback Ports -----------------------------
        .loopback_in            (b0gt1_loopback_in),
        //------------------------- Digital Monitor Ports --------------------------
        .dmonitorout_out        (),
        //------------------- RX Initialization and Reset Ports --------------------
        .eyescanreset_in        (1'b0),
        .rxuserrdy_in           (clk_rxusrrdy),
        //---------------- Receive Ports - RX Margin Analysis ports ----------------
        .rxlpmen_in             (b0gt0_rxlpmen_in),//(rx_dfelpmsel_from_pio),       // 0 - Select DFE mode / 1 - Select LPM mode
        //------------------------ RX Margin Analysis Ports ------------------------
        .eyescandataerror_out   (),
        .eyescantrigger_in      (1'b0),
        //----------------------- Receive Ports - CDR Ports ------------------------
        .rxcdrhold_in           (rxcdrhold_to_gt),
        .rxcdrlock_out          (b0gt1_rxcdrlock_out),
        //---------------- Receive Ports - FPGA RX Interface Ports -----------------
        .rxusrclk_in            (b0gt0_rxusrclk_in),
        .rxusrclk2_in           (b0gt0_rxusrclk2_in),
        //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .rxdata_out             (b0gt1_rxdata_out),   //update channel!
        //------------------------- Receive Ports - RX AFE -------------------------
        .gtxrxp_in              (b0gt1_gtxrxp_in),   //update channel!
        //---------------------- Receive Ports - RX AFE Ports ----------------------
        .gtxrxn_in              (b0gt1_gtxrxn_in),   //update channel!
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        /*
        .rxdlyen_in             (rxdlyen_from_rxaln[i]),
        .rxdlysreset_in         (rxdlysreset_from_rxaln[i]),
        .rxdlysresetdone_out    (rxdlysresetdone_from_gt[i]),
        .rxphalign_in           (rxphalign_from_rxaln[i]),
        .rxphaligndone_out      (rxphaligndone_from_gt[i]),
        .rxphalignen_in         (rxphalignen_from_rxaln[i]),
        .rxphdlyreset_in        (rxphdlyreset_from_rxaln[i]),
        .rxphmonitor_out        (),
        .rxphslipmonitor_out    (),
        */
        //------------------ Receive Ports - RX Equailizer Ports -------------------
        .rxlpmhfhold_in         (1'b0),
        .rxlpmlfhold_in         (1'b0),
        .rxlpmhfovrden_in       (rxlpmhfovrden_to_gt),
        .rxlpmlfklovrden_in     (rxlpmlfklovrden_to_gt),
        .rxosovrden_in          (rxosovrden_to_gt),
        //------------------- Receive Ports - RX Equalizer Ports -------------------
        .rxdfelpmreset_in       (1'b0),
        .rxmonitorout_out       (),
        .rxmonitorsel_in        (2'h0),
        //------------- Receive Ports - RX Fabric Output Control Ports -------------
        .rxoutclk_out           (b0gt1_rxoutclk_out),
        //.rxoutclk_out         (),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .gtrxreset_in           (b0gt0_gtrxreset_in),
        .rxpmareset_in          (1'b0),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .rxpolarity_in          (b0gt1_rxpolarity_in),
        //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .rxresetdone_out        (b0gt1_rxresetdone_out),   //update channel!
        //---------------------- TX Configurable Driver Ports ----------------------
        .txpostcursor_in        (b0gt1_txpostcursor_in),
        .txprecursor_in         (b0gt1_txprecursor_in),
        //------------------- TX Initialization and Reset Ports --------------------
        .gttxreset_in           (b0gt0_gttxreset_in),
        .txuserrdy_in           (clk_txusrrdy),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
        .txusrclk_in            (b0gt0_txusrclk_in),
        .txusrclk2_in           (b0gt0_txusrclk2_in),
        //------------------- Transmit Ports - PCI Express Ports -------------------
        .txelecidle_in          (b0gt1_txelecidle_in),
        //---------------- Transmit Ports - TX Buffer Bypass Ports -----------------
        .txdlyen_in             (txdlyen_from_txaln[1]),      //update channel!
        .txdlysreset_in         (txdlysreset_from_txaln[1]),  //update channel!
        .txdlysresetdone_out    (txdlysresetdone_from_gt[1]), //update channel!
        .txphalign_in           (txphalign_from_txaln[1]),    //update channel!
        .txphaligndone_out      (txphaligndone_from_gt[1]),   //update channel!
        .txphalignen_in         (txphalignen_from_txaln[1]),  //update channel!
        .txphdlyreset_in        (txphdlyreset_from_txaln[1]), //update channel!
        .txphinit_in            (txphinit_from_txaln[1]),     //update channel!
        .txphinitdone_out       (txphinitdone_from_gt[1]),    //update channel!
        //------------- Transmit Ports - TX Configurable Driver Ports --------------
        .txdiffctrl_in          (b0gt1_txdiffctrl_in),
        .txinhibit_in           (b0gt1_txinhibit_in),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .txdata_in              (b0gt1_txdata_in),    //update channel!
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .gtxtxn_out             (b0gt1_gtxtxn_out),    //update channel!
        .gtxtxp_out             (b0gt1_gtxtxp_out),    //update channel!
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .txoutclk_out           (b0gt1_txoutclk_out),    //update channel!
//          .txoutclk_out           (),
        .txoutclkfabric_out     (),
        .txoutclkpcs_out        (),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .txresetdone_out        (b0gt1_txresetdone_out),   //update channel!
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
        .txpolarity_in          (b0gt1_txpolarity_in)
    );
    
exdes_vid_phy_controller_0_gtxe2_hdmi_xcvr
    #(
        // Simulation attributes
        .GT_SIM_GTRESET_SPEEDUP     ("TRUE"),       // Set to "TRUE" to speed up sim reset;
        .RX_DFE_KL_CFG2_IN          (32'h301148AC),
        .PMA_RSV_IN                 (32'h00018480),
        .PCS_RSVD_ATTR_IN           (48'h000000000002)          // Bit[1] must be set for the TX buffer bypass to work correctly
    )
    XCVR_CH2_INST
    (
        //------------------------------- CPLL Ports -------------------------------
        .cpllfbclklost_out      (),
        .cplllock_out           (lock_from_cpll[2]), //update channel!
        .cplllockdetclk_in      (vid_phy_axi4lite_aclk),
        .cpllpd_in              (clk_cpll_pd),
        .cpllrefclklost_out     (),
        .cpllreset_in           (clk_cpll_rst),
        .cpllrefclksel_in       (b0gt0_cpllrefclksel_in),//(clksel_to_cpll),
        //------------------------ Channel - Clocking Ports ------------------------
        .gtrefclk0_in           (mgtrefclk0_from_bufds),
        .gtrefclk1_in           (mgtrefclk1_from_bufds),
        .gtnorthrefclk0_in      (gtnorthrefclk0_in),
        .gtnorthrefclk1_in      (gtnorthrefclk1_in),
        .gtsouthrefclk0_in      (gtsouthrefclk0_in),
        .gtsouthrefclk1_in      (gtsouthrefclk1_in),
        //-------------------------- Channel - DRP Ports  --------------------------
        .drpaddr_in             (b0gt2_drpaddr_in), //update channel!
        .drpclk_in              (b0gt2_drpclk_in),  //update channel!
        .drpdi_in               (b0gt2_drpdi_in),   //update channel!
        .drpdo_out              (b0gt2_drpdo_out),  //update channel!
        .drpen_in               (b0gt2_drpen_in),   //update channel!
        .drprdy_out             (b0gt2_drprdy_out), //update channel!
        .drpwe_in               (b0gt2_drpwe_in),   //update channel!
        //----------------------------- Clocking Ports -----------------------------
        .qpllclk_in             (b0gt0_qplloutclk_in),
        .qpllrefclk_in          (b0gt0_qplloutrefclk_in),
        .rxsysclksel_in         (b0gt0_rxsysclksel_in),
        .txsysclksel_in         (b0gt0_txsysclksel_in),
        //----------------------------- Loopback Ports -----------------------------
        .loopback_in            (b0gt2_loopback_in),
        //------------------------- Digital Monitor Ports --------------------------
        .dmonitorout_out        (),
        //------------------- RX Initialization and Reset Ports --------------------
        .eyescanreset_in        (1'b0),
        .rxuserrdy_in           (clk_rxusrrdy),
        //---------------- Receive Ports - RX Margin Analysis ports ----------------
        .rxlpmen_in             (b0gt0_rxlpmen_in),//(rx_dfelpmsel_from_pio),       // 0 - Select DFE mode / 1 - Select LPM mode
        //------------------------ RX Margin Analysis Ports ------------------------
        .eyescandataerror_out   (),
        .eyescantrigger_in      (1'b0),
        //----------------------- Receive Ports - CDR Ports ------------------------
        .rxcdrhold_in           (rxcdrhold_to_gt),
        .rxcdrlock_out          (b0gt2_rxcdrlock_out),
        //---------------- Receive Ports - FPGA RX Interface Ports -----------------
        .rxusrclk_in            (b0gt0_rxusrclk_in),
        .rxusrclk2_in           (b0gt0_rxusrclk2_in),
        //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .rxdata_out             (b0gt2_rxdata_out),   //update channel!
        //------------------------- Receive Ports - RX AFE -------------------------
        .gtxrxp_in              (b0gt2_gtxrxp_in),   //update channel!
        //---------------------- Receive Ports - RX AFE Ports ----------------------
        .gtxrxn_in              (b0gt2_gtxrxn_in),   //update channel!
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        /*
        .rxdlyen_in             (rxdlyen_from_rxaln[i]),
        .rxdlysreset_in         (rxdlysreset_from_rxaln[i]),
        .rxdlysresetdone_out    (rxdlysresetdone_from_gt[i]),
        .rxphalign_in           (rxphalign_from_rxaln[i]),
        .rxphaligndone_out      (rxphaligndone_from_gt[i]),
        .rxphalignen_in         (rxphalignen_from_rxaln[i]),
        .rxphdlyreset_in        (rxphdlyreset_from_rxaln[i]),
        .rxphmonitor_out        (),
        .rxphslipmonitor_out    (),
        */
        //------------------ Receive Ports - RX Equailizer Ports -------------------
        .rxlpmhfhold_in         (1'b0),
        .rxlpmlfhold_in         (1'b0),
        .rxlpmhfovrden_in       (rxlpmhfovrden_to_gt),
        .rxlpmlfklovrden_in     (rxlpmlfklovrden_to_gt),
        .rxosovrden_in          (rxosovrden_to_gt),
        //------------------- Receive Ports - RX Equalizer Ports -------------------
        .rxdfelpmreset_in       (1'b0),
        .rxmonitorout_out       (),
        .rxmonitorsel_in        (2'h0),
        //------------- Receive Ports - RX Fabric Output Control Ports -------------
        .rxoutclk_out           (b0gt2_rxoutclk_out),
        //.rxoutclk_out         (),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .gtrxreset_in           (b0gt0_gtrxreset_in),
        .rxpmareset_in          (1'b0),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .rxpolarity_in          (b0gt2_rxpolarity_in),
        //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .rxresetdone_out        (b0gt2_rxresetdone_out),   //update channel!
        //---------------------- TX Configurable Driver Ports ----------------------
        .txpostcursor_in        (b0gt2_txpostcursor_in),
        .txprecursor_in         (b0gt2_txprecursor_in),
        //------------------- TX Initialization and Reset Ports --------------------
        .gttxreset_in           (b0gt0_gttxreset_in),
        .txuserrdy_in           (clk_txusrrdy),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
        .txusrclk_in            (b0gt0_txusrclk_in),
        .txusrclk2_in           (b0gt0_txusrclk2_in),
        //------------------- Transmit Ports - PCI Express Ports -------------------
        .txelecidle_in          (b0gt2_txelecidle_in),
        //---------------- Transmit Ports - TX Buffer Bypass Ports -----------------
        .txdlyen_in             (txdlyen_from_txaln[2]),      //update channel!
        .txdlysreset_in         (txdlysreset_from_txaln[2]),  //update channel!
        .txdlysresetdone_out    (txdlysresetdone_from_gt[2]), //update channel!
        .txphalign_in           (txphalign_from_txaln[2]),    //update channel!
        .txphaligndone_out      (txphaligndone_from_gt[2]),   //update channel!
        .txphalignen_in         (txphalignen_from_txaln[2]),  //update channel!
        .txphdlyreset_in        (txphdlyreset_from_txaln[2]), //update channel!
        .txphinit_in            (txphinit_from_txaln[2]),     //update channel!
        .txphinitdone_out       (txphinitdone_from_gt[2]),    //update channel!
        //------------- Transmit Ports - TX Configurable Driver Ports --------------
        .txdiffctrl_in          (b0gt2_txdiffctrl_in),
        .txinhibit_in           (b0gt2_txinhibit_in),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .txdata_in              (b0gt2_txdata_in),    //update channel!
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .gtxtxn_out             (b0gt2_gtxtxn_out),    //update channel!
        .gtxtxp_out             (b0gt2_gtxtxp_out),    //update channel!
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .txoutclk_out           (b0gt2_txoutclk_out),    //update channel!
//          .txoutclk_out           (),
        .txoutclkfabric_out     (),
        .txoutclkpcs_out        (),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .txresetdone_out        (b0gt2_txresetdone_out),   //update channel!
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
        .txpolarity_in          (b0gt2_txpolarity_in)
    );
	
    // Resets
    assign rst_to_cpll_from_tx = (b0gt0_txsysclksel_in == 2'b00) ? cfg_phy_mem_map_control[`CH1_TX_PLL_GT_RST]: 1'b0;
    assign rst_to_cpll_from_rx = (b0gt0_rxsysclksel_in == 2'b00) ? cfg_phy_mem_map_control[`CH1_RX_PLL_GT_RST]: 1'b0;
    assign rst_to_cpll = rst_to_cpll_from_tx | rst_to_cpll_from_rx;

    assign rst_to_qpll_from_tx = (b0gt0_txsysclksel_in == 2'b11) ? cfg_phy_mem_map_control[`CH1_TX_PLL_GT_RST]: 1'b0;
    assign rst_to_qpll_from_rx = (b0gt0_rxsysclksel_in == 2'b11) ? cfg_phy_mem_map_control[`CH1_RX_PLL_GT_RST]: 1'b0;
    assign rst_to_qpll = rst_to_qpll_from_tx | rst_to_qpll_from_rx;

    // These signals must be set when the DRU is active
    assign rxcdrhold_to_gt          = (dru_active) ? 1'b1 : 1'b0;
    assign rxlpmhfovrden_to_gt      = (dru_active) ? 1'b1 : 1'b0;
    assign rxlpmlfklovrden_to_gt    = (dru_active) ? 1'b1 : 1'b0;
    assign rxosovrden_to_gt         = (dru_active) ? 1'b1 : 1'b0;

// CPLL powerdown
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_cpll_pd <= 1'b1;        // Active high
        end

        else
        begin
            // Clear
            if (!b0gt0_cpllpd_in)
                clk_cpll_pd <= 1'b0;
        end
    end
// GTXE2 common
    GTXE2_COMMON
    #(
        // Simulation attributes
        .SIM_RESET_SPEEDUP              ("TRUE"),
        .SIM_QPLLREFCLK_SEL             (3'b001),
        .SIM_VERSION                    ("4.0"),

        //----------------COMMON BLOCK Attributes---------------
        .BIAS_CFG                       (64'h0000040000001000),
        .COMMON_CFG                     (32'h00000000),
        .QPLL_CFG                       (27'h06801C1),
        .QPLL_CLKOUT_CFG                (4'b0000),
        .QPLL_COARSE_FREQ_OVRD          (6'b010000),
        .QPLL_COARSE_FREQ_OVRD_EN       (1'b0),
        .QPLL_CP                        (10'b0000011111),
        .QPLL_CP_MONITOR_EN             (1'b0),
        .QPLL_DMONITOR_SEL              (1'b0),
        .QPLL_FBDIV                     (10'b0010000000),
        .QPLL_FBDIV_MONITOR_EN          (1'b0),
        .QPLL_FBDIV_RATIO               (1'b1),
        .QPLL_INIT_CFG                  (24'h000006),
        .QPLL_LOCK_CFG                  (16'h21E8),
        .QPLL_LPF                       (4'b1111),
        .QPLL_REFCLK_DIV                (1)
    )
    GTXE2_COMMON_INST
    (
        //----------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
        .DRPADDR                        (b0gt0_drpaddr_common_in),
        .DRPCLK                         (drp_clk),
        .DRPDI                          (b0gt0_drpdi_common_in),
        .DRPDO                          (b0gt0_drpdo_common_out),
        .DRPEN                          (b0gt0_drpen_common_in),
        .DRPRDY                         (b0gt0_drprdy_common_out),
        .DRPWE                          (b0gt0_drpwe_common_in),
        //-------------------- Common Block  - Ref Clock Ports ---------------------
        .GTGREFCLK                      (1'b0),
        .GTNORTHREFCLK0                 (gtnorthrefclk0_in),
        .GTNORTHREFCLK1                 (gtnorthrefclk1_in),
        .GTREFCLK0                      (mgtrefclk0_from_bufds),
        .GTREFCLK1                      (mgtrefclk1_from_bufds),
        .GTSOUTHREFCLK0                 (gtsouthrefclk0_in),
        .GTSOUTHREFCLK1                 (gtsouthrefclk1_in),
        //----------------------- Common Block -  QPLL Ports -----------------------
        .QPLLDMONITOR                   (),
        //--------------------- Common Block - Clocking Ports ----------------------
        .QPLLOUTCLK                     (b0gt0_qplloutclk_in),
        .QPLLOUTREFCLK                  (b0gt0_qplloutrefclk_in),
        .REFCLKOUTMONITOR               (),
        //----------------------- Common Block - QPLL Ports ------------------------
        .QPLLFBCLKLOST                  (),
        .QPLLLOCK                       (lock_from_qpll),
        .QPLLLOCKDETCLK                 (drp_clk),
        .QPLLLOCKEN                     (1'b1),
        .QPLLOUTRESET                   (1'b1),
        .QPLLPD                         (clk_qpll_pd),
        .QPLLREFCLKLOST                 (),
        .QPLLREFCLKSEL                  (b0gt0_qpllrefclksel_in),
        .QPLLRESET                      (clk_qpll_rst),
        .QPLLRSVD1                      (16'b0000000000000000),
        .QPLLRSVD2                      (5'b11111),
        //------------------------------- QPLL Ports -------------------------------
        .BGBYPASSB                      (1'b1),
        .BGMONITORENB                   (1'b1),
        .BGPDB                          (1'b1),
        .BGRCALOVRD                     (5'b11111),
        .PMARSVD                        (8'b00000000),
        .RCALENB                        (1'b1)
    );

// QPLL powerdown
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_qpll_pd <= 1'b1;        // Active high
        end

        else
        begin
            // Clear
            if (!b0gt0_qpllpd_in)
                clk_qpll_pd <= 1'b0;
        end
    end

// TX buffer alignment controller
exdes_vid_phy_controller_0_gtxe2_hdmi_txaln
    #(
        .NUMBER_OF_LANES        (3),  // Number of lanes that are controlled using this FSM.
        .MASTER_LANE_ID         (0)   // Number of the lane which is considered the master in manual phase-alignment
    )
    TXALN_INST
    (
        .STABLE_CLOCK           (vid_phy_axi4lite_aclk),              //Stable Clock, either a stable clock from the PCB
        .RESET_PHALIGNMENT      (rst_to_txaln),
        .RUN_PHALIGNMENT        (cfg_phy_mem_map_control_b0[`CH1_TXPHALIGN]),
        .PHASE_ALIGNMENT_DONE   (done_from_txaln),       // Manual phase-alignment performed sucessfully
        .TXDLYSRESET            (txdlysreset_from_txaln),
        .TXDLYSRESETDONE        (txdlysresetdone_from_gt),
        .TXPHINIT               (txphinit_from_txaln),
        .TXPHINITDONE           (txphinitdone_from_gt),
        .TXPHALIGN              (txphalign_from_txaln),
        .TXPHALIGNDONE          (txphaligndone_from_gt),
        .TXDLYEN                (txdlyen_from_txaln)
    );
    assign cfg_phy_mem_map_status_b0[`CH1_TXPHALIGNDONE] = done_from_txaln;
    assign cfg_phy_mem_map_status_b0[`CH2_TXPHALIGNDONE] = done_from_txaln;
    assign cfg_phy_mem_map_status_b0[`CH3_TXPHALIGNDONE] = done_from_txaln;

    assign txphalignen_from_txaln = 3'b111;
    assign txphdlyreset_from_txaln = 3'b000;
    assign rst_to_txaln = b0gt0_gttxreset_in;

// QPLL lock counter
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_qpll_lock_cnt   <= 0;
            clk_qpll_locked     <= 0;
        end

        else
        begin
            // QPLL Reset
            if (rst_to_qpll)
            begin
                clk_qpll_lock_cnt   <= 0;
                clk_qpll_locked     <= 0;
            end

            else
            begin
                if (lock_from_qpll)
                begin
                    if (clk_qpll_lock_cnt == 24'd100_000)       // 1 ms @ 100 MHz clock
                        clk_qpll_locked     <= 1;
                    else
                    begin
                        clk_qpll_locked     <= 0;
                        clk_qpll_lock_cnt   <= clk_qpll_lock_cnt + 1;
                    end
                end
                else
                begin
                    clk_qpll_lock_cnt   <= 0;
                    clk_qpll_locked     <= 0;
                end
            end
        end
    end

// QPLL lock lost
// This signal is active when the QPLL lock was lost
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        // Set
        if (clk_qpll_locked && !lock_from_qpll)
            clk_qpll_lock_lost <= 1;
        else
            clk_qpll_lock_lost <= 0;
    end

// QPLL reset edge detector
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        rst_to_qpll_del <= rst_to_qpll;
    end

    assign rst_to_qpll_re = (rst_to_qpll && !rst_to_qpll_del) ? 1'b1 : 1'b0;
    assign rst_to_qpll_fe = (!rst_to_qpll && rst_to_qpll_del) ? 1'b1 : 1'b0;

// QPLL reset
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
            clk_qpll_rst <= 1;

        else
        begin
            // Set
            if (clk_qpll_lock_lost || rst_to_qpll_re)
                clk_qpll_rst <= 1;

            // Clear
            else if (rst_to_qpll_fe)
                clk_qpll_rst <= 0;
        end
    end

// CPLL lock counter
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_cpll_lock_cnt   <= 0;
            clk_cpll_locked     <= 0;
        end

        else
        begin
            // CPLL Reset
            if (rst_to_cpll)
            begin
                clk_cpll_lock_cnt   <= 0;
                clk_cpll_locked     <= 0;
            end

            else
            begin
                if (&lock_from_cpll)
                begin
                    if (clk_cpll_lock_cnt == 24'd100_000)       // 1 ms @ 100 MHz clock
                        clk_cpll_locked     <= 1;
                    else
                    begin
                        clk_cpll_locked     <= 0;
                        clk_cpll_lock_cnt   <= clk_cpll_lock_cnt + 1;
                    end
                end
                else
                begin
                    clk_cpll_lock_cnt   <= 0;
                    clk_cpll_locked     <= 0;
                end
            end
        end
    end

// CPLL lock lost
// This signal is active when the CPLL lock was lost
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        // Set
        if (clk_cpll_locked && !(&lock_from_cpll))
            clk_cpll_lock_lost <= 1;
        else
            clk_cpll_lock_lost <= 0;
    end

// CPLL reset edge detector
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        rst_to_cpll_del <= rst_to_cpll;
    end

    assign rst_to_cpll_re = (rst_to_cpll && !rst_to_cpll_del) ? 1'b1 : 1'b0;
    assign rst_to_cpll_fe = (!rst_to_cpll && rst_to_cpll_del) ? 1'b1 : 1'b0;

// CPLL reset
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
            clk_cpll_rst <= 1;

        else
        begin
            // Set
            if (clk_cpll_lock_lost || rst_to_cpll_re)
                clk_cpll_rst <= 1;

            // Clear
            else if (rst_to_cpll_fe)
                clk_cpll_rst <= 0;
        end
    end

// TXPLL lock counter
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin

        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_txpll_lock_cnt  <= 0;
            clk_txpll_locked    <= 0;
        end

        else
        begin
            // TXPLL Reset
            if (clk_txpll_rst)
            begin
                clk_txpll_lock_cnt  <= 0;
                clk_txpll_locked    <= 0;
            end

            else
            begin
                if (lock_from_txpll)
                begin
                    if (clk_txpll_lock_cnt == 24'd100_000)      // 1 ms @ 100 MHz clock
                        clk_txpll_locked    <= 1 & ~cfg_phy_mem_map_control_b0[`MMCM_TXUSRCLK_LOCK_MASK];
                    else
                    begin
                        clk_txpll_locked    <= 0;
                        clk_txpll_lock_cnt  <= clk_txpll_lock_cnt + 1;
                    end
                end
                else
                begin
                    clk_txpll_lock_cnt  <= 0;
                    clk_txpll_locked    <= 0;
                end
            end
        end
    end
    
wire   b0_MMCM_TX_DRP_LOCKED;   
wire   b0_MMCM_TX_DRP_LOCKED_sync;  
assign b0_MMCM_TX_DRP_LOCKED = clk_txpll_locked;
assign rst_to_txpll = cfg_phy_mem_map_control_b0[`MMCM_TXUSRCLK_CONFIG_RESET];
assign pd_to_txpll = cfg_phy_mem_map_control_b0[`MMCM_TXUSRCLK_POWER_DOWN];

// TXPLL lock lost
// This signal is active when the TXPLL lock was lost
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        // Set
        if (clk_txpll_locked && !lock_from_txpll)
            clk_txpll_lock_lost <= 1;
        else
            clk_txpll_lock_lost <= 0;
    end

// TXPLL reset edge detector
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        rst_to_txpll_del <= rst_to_txpll;
    end

    assign rst_to_txpll_re = (rst_to_txpll && !rst_to_txpll_del) ? 1'b1 : 1'b0;
    assign rst_to_txpll_fe = (!rst_to_txpll && rst_to_txpll_del) ? 1'b1 : 1'b0;

// TXPLL reset
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
            clk_txpll_rst <= 1;

        else
        begin
            // Set
            if (clk_txpll_lock_lost || rst_to_txpll_re)
                clk_txpll_rst <= 1;

            // Clear
            else if (rst_to_txpll_fe)
                clk_txpll_rst <= 0;
        end
    end

// RXPLL lock counter
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
        begin
            clk_rxpll_lock_cnt  <= 0;
            clk_rxpll_locked    <= 0;
        end

        else
        begin
            // RXPLL Reset
            if (clk_rxpll_rst)
            begin
                clk_rxpll_lock_cnt  <= 0;
                clk_rxpll_locked    <= 0;
            end

            else
            begin
                if (lock_from_rxpll)
                begin
                    if (clk_rxpll_lock_cnt == 24'd100_000)      // 1 ms @ 100 MHz clock
                        clk_rxpll_locked    <= 1 & ~cfg_phy_mem_map_control_b0[`MMCM_RXUSRCLK_LOCK_MASK];
                    else
                    begin
                        clk_rxpll_locked    <= 0;
                        clk_rxpll_lock_cnt  <= clk_rxpll_lock_cnt + 1;
                    end
                end
                else
                begin
                    clk_rxpll_lock_cnt  <= 0;
                    clk_rxpll_locked    <= 0;
                end
            end
        end
    end
    
wire   b0_MMCM_RX_DRP_LOCKED;
wire   b0_MMCM_RX_DRP_LOCKED_sync;
assign b0_MMCM_RX_DRP_LOCKED = clk_rxpll_locked;
assign rst_to_rxpll = cfg_phy_mem_map_control_b0[`MMCM_RXUSRCLK_CONFIG_RESET];
assign pd_to_rxpll = cfg_phy_mem_map_control_b0[`MMCM_RXUSRCLK_POWER_DOWN];

// RXPLL lock lost
// This signal is active when the RXPLL lock was lost
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        // Set
        if (clk_rxpll_locked && !lock_from_rxpll)
            clk_rxpll_lock_lost <= 1;
        else
            clk_rxpll_lock_lost <= 0;
    end

// RXPLL reset edge detector
    always @ (posedge vid_phy_axi4lite_aclk)
    begin
        rst_to_rxpll_del <= rst_to_rxpll;
    end

    assign rst_to_rxpll_re = (rst_to_rxpll && !rst_to_rxpll_del) ? 1'b1 : 1'b0;
    assign rst_to_rxpll_fe = (!rst_to_rxpll && rst_to_rxpll_del) ? 1'b1 : 1'b0;

// RXPLL reset
    always @ (negedge vid_phy_axi4lite_aresetn, posedge vid_phy_axi4lite_aclk)
    begin
        // AXI reset
        if (!vid_phy_axi4lite_aresetn)
            clk_rxpll_rst <= 1;

        else
        begin
            // Set
            if (clk_rxpll_lock_lost || rst_to_rxpll_re)
                clk_rxpll_rst <= 1;

            // Clear
            else if (rst_to_rxpll_fe)
                clk_rxpll_rst <= 0;
        end
    end

generate
    if ((C_Tx_Protocol==1 && C_TX_REFCLK_SEL==GTREFCLK0) || (C_Rx_Protocol==1 && (C_RX_REFCLK_SEL==GTREFCLK0 || (C_NIDRU_REFCLK_SEL == GTREFCLK0 && C_NIDRU == 1))))
    begin 
               IBUF #(
                  .IBUF_LOW_PWR("TRUE"),  
                  .IOSTANDARD("DEFAULT")  
               ) IBUF_P_REF0_BUF_INST (
                  .O(ibuf_mgtrefclk0_pad_p_in),
                  .I(mgtrefclk0_pad_p_in)  
               );

               IBUF #(
                  .IBUF_LOW_PWR("TRUE"),  
                  .IOSTANDARD("DEFAULT")  
               ) IBUF_N_REF0_BUF_INST (
                  .O(ibuf_mgtrefclk0_pad_n_in),
                  .I(mgtrefclk0_pad_n_in)     
               );
               
            IBUFDS_GTE2
            REF0_BUFDS_INST
            (
                .I               (ibuf_mgtrefclk0_pad_p_in),
                .IB              (ibuf_mgtrefclk0_pad_n_in),
                .O               (mgtrefclk0_from_bufds),   
                .ODIV2           (),                        
                .CEB             (cfg_phy_mem_map_control_b0[`GTREFCLK0_CEB])       
            );
    end
    else 
    begin
        assign mgtrefclk0_from_bufds = 1'b0;
    end

    if ((C_Tx_Protocol==1 && C_TX_REFCLK_SEL==GTREFCLK1) || (C_Rx_Protocol==1 && (C_RX_REFCLK_SEL==GTREFCLK1 || (C_NIDRU_REFCLK_SEL == GTREFCLK1 && C_NIDRU == 1))))
    begin 
               IBUF #(
                  .IBUF_LOW_PWR("TRUE"),  
                  .IOSTANDARD("DEFAULT")  
               ) IBUF_P_REF1_BUF_INST (
                  .O(ibuf_mgtrefclk1_pad_p_in),
                  .I(mgtrefclk1_pad_p_in)  
               );

               IBUF #(
                  .IBUF_LOW_PWR("TRUE"),  
                  .IOSTANDARD("DEFAULT")  
               ) IBUF_N_REF1_BUF_INST (
                  .O(ibuf_mgtrefclk1_pad_n_in),
                  .I(mgtrefclk1_pad_n_in)     
               );
               
            IBUFDS_GTE2
            REF1_BUFDS_INST
            (
                .I               (ibuf_mgtrefclk1_pad_p_in),
                .IB              (ibuf_mgtrefclk1_pad_n_in),
                .O               (mgtrefclk1_from_bufds),   
                .ODIV2           (),                        
                .CEB             (cfg_phy_mem_map_control_b0[`GTREFCLK1_CEB])       
            );
    end
    else 
    begin
        assign mgtrefclk1_from_bufds = 1'b0;
    end
endgenerate


generate
    if ((C_TX_REFCLK_SEL != GTREFCLK0) && (C_TX_REFCLK_SEL != GTREFCLK1) && (C_Tx_Protocol == 1))
    begin 
        assign txrefclk_ceb  = cfg_phy_mem_map_control_b0[`TX_REFCLK_CEB];
    end
    else 
    begin
        assign txrefclk_ceb  = 1'b0;
    end

    if ((C_RX_REFCLK_SEL != GTREFCLK0) && (C_RX_REFCLK_SEL != GTREFCLK1) && (C_Rx_Protocol == 1))
    begin 
        assign rxrefclk_ceb  = cfg_phy_mem_map_control_b0[`RX_REFCLK_CEB];
    end
    else 
    begin
        assign rxrefclk_ceb  = 1'b0;
    end
endgenerate

if      (C_TX_REFCLK_SEL == GTREFCLK0)      assign txrefclk_from_bufds = mgtrefclk0_from_bufds;
else if (C_TX_REFCLK_SEL == GTREFCLK1)      assign txrefclk_from_bufds = mgtrefclk1_from_bufds;
else if (C_TX_REFCLK_SEL == GTNORTHREFCLK0) assign txrefclk_from_bufds = gtnorthrefclk0_in;
else if (C_TX_REFCLK_SEL == GTNORTHREFCLK1) assign txrefclk_from_bufds = gtnorthrefclk1_in; 
else if (C_TX_REFCLK_SEL == GTSOUTHREFCLK0) assign txrefclk_from_bufds = gtsouthrefclk0_in;
else if (C_TX_REFCLK_SEL == GTSOUTHREFCLK1) assign txrefclk_from_bufds = gtsouthrefclk1_in;
else if (C_TX_REFCLK_SEL == GTEASTREFCLK0)  assign txrefclk_from_bufds = gteastrefclk0_in;
else if (C_TX_REFCLK_SEL == GTEASTREFCLK1)  assign txrefclk_from_bufds = gteastrefclk1_in; 
else if (C_TX_REFCLK_SEL == GTWESTREFCLK0)  assign txrefclk_from_bufds = gtwestrefclk0_in;
else if (C_TX_REFCLK_SEL == GTWESTREFCLK1)  assign txrefclk_from_bufds = gtwestrefclk1_in;
else assign txrefclk_from_bufds = 1'b0;

generate
    if (C_Tx_Protocol == 1)
    begin 
        BUFG
        TX_REFCLK_BUFG_INST
        (
            .I              (txrefclk_from_bufds),
            .O              (txrefclk_from_buffer)
        );
    end
endgenerate

if      (C_RX_REFCLK_SEL == GTREFCLK0)      assign rxrefclk_from_bufds = mgtrefclk0_from_bufds;
else if (C_RX_REFCLK_SEL == GTREFCLK1)      assign rxrefclk_from_bufds = mgtrefclk1_from_bufds;
else if (C_RX_REFCLK_SEL == GTNORTHREFCLK0) assign rxrefclk_from_bufds = gtnorthrefclk0_in;
else if (C_RX_REFCLK_SEL == GTNORTHREFCLK1) assign rxrefclk_from_bufds = gtnorthrefclk1_in; 
else if (C_RX_REFCLK_SEL == GTSOUTHREFCLK0) assign rxrefclk_from_bufds = gtsouthrefclk0_in;
else if (C_RX_REFCLK_SEL == GTSOUTHREFCLK1) assign rxrefclk_from_bufds = gtsouthrefclk1_in;
else if (C_RX_REFCLK_SEL == GTEASTREFCLK0)  assign rxrefclk_from_bufds = gteastrefclk0_in;
else if (C_RX_REFCLK_SEL == GTEASTREFCLK1)  assign rxrefclk_from_bufds = gteastrefclk1_in; 
else if (C_RX_REFCLK_SEL == GTWESTREFCLK0)  assign rxrefclk_from_bufds = gtwestrefclk0_in;
else if (C_RX_REFCLK_SEL == GTWESTREFCLK1)  assign rxrefclk_from_bufds = gtwestrefclk1_in;
else assign rxrefclk_from_bufds = 1'b0;

generate
    if (C_Rx_Protocol == 1)
    begin 
        BUFG
        RX_REFCLK_BUFG_INST
        (
            .I              (rxrefclk_from_bufds),
            .O              (rxrefclk_from_buffer)
        );
    end
endgenerate

generate
if (C_Tx_Protocol == 1)
begin 

    //// TX out clock buffer
    //    BUFG
    //    TXOUTCLK_BUF_INST
    //    (
    //        .I              (b0gt0_txoutclk_out),
    //        .O              (txoutclk_from_bufg)
    //    );
        
    wire[15:0] TX_DO;
    wire       TX_DRDY;     
    wire       TX_DWE;
    wire       TX_DEN;
    wire[6:0]  TX_DADDR;
    wire[15:0] TX_DI;
    wire       TX_DCLK;
    
    // TXPLL DRP CONTROLLER
    assign DRP_Config_mmcm_txusrclk[11:0] = cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPADDR];
    assign DRP_Config_mmcm_txusrclk[12]   = cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPEN];
    assign DRP_Config_mmcm_txusrclk[13]   = cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPWE];
    assign DRP_Config_mmcm_txusrclk[31:16]= cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPDI];
    
    vid_phy_controller_v2_2_2_drp_control_hdmi #  
    (
        .DRP_ADDR_WIDTH (7)
    )
        TXPLL_DRP_INST
        (
        .Config_Clk          (vid_phy_axi4lite_aclk),
        .Config_Rst          (vid_phy_axi4lite_areset),
        .DRP_Config          (DRP_Config_mmcm_txusrclk),
        .DRP_Status          (DRP_Status_mmcm_txusrclk),
        .drp_txn_available   (drp_txn_available[5]),
        .drp_rsp_read        (drp_rsp_read[5]),
        .DRPCLK              (drp_clk),
        .DRPBUSY             (1'b0),
        .DRPEN               (TX_DEN),
        .DRPWE               (TX_DWE),
        .DRPADDR             (TX_DADDR),
        .DRPDI               (TX_DI),
        .DRPDO               (TX_DO),
        .DRPRDY              (TX_DRDY)  
        );
    
    // TXPLL
        PLLE2_ADV
        #(
            .BANDWIDTH            ("OPTIMIZED"),
            .COMPENSATION         ("ZHOLD"),
            .DIVCLK_DIVIDE        (1),
            .CLKFBOUT_MULT        (6),
            .CLKFBOUT_PHASE       (0.000),
            .CLKOUT0_DIVIDE       (6),                  // Link clock (297.0 MHz)
            .CLKOUT0_PHASE        (0.000),
            .CLKOUT0_DUTY_CYCLE   (0.500),
            .CLKOUT1_DIVIDE       (6),                  // TMDS clock 
            .CLKOUT1_PHASE        (0.000),
            .CLKOUT1_DUTY_CYCLE   (0.500),
 
           .CLKOUT2_DIVIDE        (6),
            .CLKOUT2_PHASE        (0.000),
            .CLKOUT2_DUTY_CYCLE   (0.500),
            .CLKIN1_PERIOD        (3.367),              // 297 MHz
            .CLKIN2_PERIOD        (3.367),              // 297 MHz
            .REF_JITTER1          (0.010)
        )
        TXPLL_INST
        (
             // Input clock control
            .CLKFBIN             (fbclk_from_txpll),
            .CLKIN1              (txrefclk_from_buffer),
    //      .CLKIN1              (txoutclk_from_bufg),
            .CLKIN2              (rxrefclk_from_buffer),
    //      .CLKIN2              (1'b0),
    
             // Tied to always select the primary input clock
    //      .CLKINSEL            (1'b1),
            .CLKINSEL            (clksel_to_txpll),
    
            // Output clocks
            .CLKFBOUT            (fbclk_from_txpll),
            .CLKOUT0             (lclk_from_txpll),
            .CLKOUT1             (hclk_from_txpll_i),
            .CLKOUT2             (vclk_from_txpll),
            .CLKOUT3             (),
            .CLKOUT4             (),
            .CLKOUT5             (),
    
            // Ports for dynamic reconfiguration
            .DCLK                (vid_phy_axi4lite_aclk),
            .DADDR               (TX_DADDR),
            .DEN                 (TX_DEN),
            .DI                  (TX_DI),
            .DO                  (TX_DO),
            .DRDY                (TX_DRDY),
            .DWE                 (TX_DWE),
    
            // Other control and status signals
            .LOCKED              (lock_from_txpll),
            .PWRDWN              (pd_to_txpll),
            .RST                 (clk_txpll_rst | cfg_phy_mem_map_control_b0[`MMCM_TXUSRCLK_CONFIG_RESET])
        );
    
    // TXPLL clock select
        assign clksel_to_txpll = (b0gt0_rxsysclksel_in == b0gt0_txsysclksel_in) ? 1'b0 :    // RX reference clock
                                1'b1;                                                               // TX reference clock
    
    // TXPLL link clock buffer
        wire lclk_from_txpll_locked_sync;
        xpm_cdc_single #(
         .VERSION        (`XPM_CDC_VERSION       ),
         .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
         .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
         .SRC_INPUT_REG  (0                      )
        ) TX_LCLK_BUF_INST_XPM 
        (
          .src_clk  (1'b0),
          .src_in   (lock_from_txpll),
          .dest_clk (lclk_from_txpll),
          .dest_out (lclk_from_txpll_locked_sync)
        );
        
        BUFGCE
        TX_LCLK_BUF_INST
        (
            .CE             (lclk_from_txpll_locked_sync),
            .I              (lclk_from_txpll),
            .O              (b0gt0_txusrclk_in)
        );
        assign b0gt0_txusrclk2_in = b0gt0_txusrclk_in;
    
    // TXPLL HDMI clock buffer
        assign hclk_from_txpll = hclk_from_txpll_i;

    // TXPLL video clock buffer
        wire vclk_from_txpll_locked_sync;
        xpm_cdc_single #(
         .VERSION        (`XPM_CDC_VERSION       ),
         .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
         .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
         .SRC_INPUT_REG  (0                      )
        ) TX_VCLK_BUF_INST_XPM 
        (
          .src_clk  (1'b0),
          .src_in   (lock_from_txpll),
          .dest_clk (vclk_from_txpll),
          .dest_out (vclk_from_txpll_locked_sync)
        );
        
        BUFGCE
        TX_VCLK_BUF_INST
        (
            .CE             (vclk_from_txpll_locked_sync),
            .I              (vclk_from_txpll),
            .O              (vclk_from_txbufg)
        );
end else begin

    //assign txoutclk_from_bufg = 1'b0;
    assign lclk_from_txpll    = 1'b0;
    assign hclk_from_txpll    = 1'b0;
    assign vclk_from_txpll    = 1'b0;
    assign lock_from_txpll    = 1'b0;
    assign b0gt0_txusrclk2_in = 1'b0;
    assign b0gt0_txusrclk_in  = 1'b0;
    assign vclk_from_txbufg   = 1'b0;

end
endgenerate

generate
if (C_Rx_Protocol == 1)
begin 

    wire[15:0] RX_DO;
    wire       RX_DRDY;
    wire       RX_DWE;
    wire       RX_DEN;
    wire[6:0]  RX_DADDR;
    wire[15:0] RX_DI;
    wire       RX_DCLK;
    
    // RXPLL DRP CONTROLLER
    assign DRP_Config_mmcm_rxusrclk[11:0] = cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPADDR];
    assign DRP_Config_mmcm_rxusrclk[12]   = cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPEN];
    assign DRP_Config_mmcm_rxusrclk[13]   = cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPWE];
    assign DRP_Config_mmcm_rxusrclk[31:16]= cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPDI];
    
    vid_phy_controller_v2_2_2_drp_control_hdmi #  
    (
        .DRP_ADDR_WIDTH (7)
    )
        RXPLL_DRP_INST
        (
        .Config_Clk          (vid_phy_axi4lite_aclk),
        .Config_Rst          (vid_phy_axi4lite_areset),
        .DRP_Config          (DRP_Config_mmcm_rxusrclk),
        .DRP_Status          (DRP_Status_mmcm_rxusrclk),
        .drp_txn_available   (drp_txn_available[6]),
        .drp_rsp_read        (drp_rsp_read[6]),
        .DRPCLK              (drp_clk),
        .DRPBUSY             (1'b0),
        .DRPEN               (RX_DEN),
        .DRPWE               (RX_DWE),
        .DRPADDR             (RX_DADDR),
        .DRPDI               (RX_DI),
        .DRPDO               (RX_DO),
        .DRPRDY              (RX_DRDY)  
        );
    
    // RXPLL
    // The RXPLL input clock is the HMDI RX reference
        MMCME2_ADV
        #(
            .BANDWIDTH            ("OPTIMIZED"),
            .CLKOUT4_CASCADE      ("FALSE"),
            .COMPENSATION         ("ZHOLD"),
            .STARTUP_WAIT         ("FALSE"),
            .DIVCLK_DIVIDE        (1),
            .CLKFBOUT_MULT_F      (4),
            .CLKFBOUT_PHASE       (0.000),
            .CLKFBOUT_USE_FINE_PS ("FALSE"),
            .CLKOUT0_DIVIDE_F     (4),                      // Link clock (297.0 MHz)
            .CLKOUT0_PHASE        (0.000),
            .CLKOUT0_DUTY_CYCLE   (0.500),
            .CLKOUT0_USE_FINE_PS  ("FALSE"),
            .CLKOUT1_DIVIDE       (4),                     // TMDS
            .CLKOUT1_PHASE        (0.000),
            .CLKOUT1_DUTY_CYCLE   (0.500),
            .CLKOUT1_USE_FINE_PS  ("FALSE"),
 
            .CLKOUT2_DIVIDE       (4),
            .CLKOUT2_PHASE        (0.000),
            .CLKOUT2_DUTY_CYCLE   (0.500),
            .CLKOUT2_USE_FINE_PS  ("FALSE"),
            .CLKIN1_PERIOD        (3.367),                  // 297 MHz
            .CLKIN2_PERIOD        (3.367)                   // 297 MHz
        )
        RXPLL_INST
        (
            // Input clock control
            .CLKFBIN             (fbclk_from_rxpll),
            .CLKIN1              (rxrefclk_from_buffer),        // RX reference clock
            .CLKIN2              (1'b0),
    
            // Tied to always select the primary input clock
            .CLKINSEL            (1'b1),                    // 1-RX reference clock
    
            // Output clocks
            .CLKFBOUT            (fbclk_from_rxpll),        // Feedback clock
            .CLKFBOUTB           (),
            .CLKOUT0             (lclk_from_rxpll),         // Link clock
            .CLKOUT0B            (),
            .CLKOUT1             (),            
            .CLKOUT1B            (),
            .CLKOUT2             (vclk_from_rxpll),         // Video clock
            .CLKOUT2B            (),
            .CLKOUT3             (),
            .CLKOUT3B            (),
            .CLKOUT4             (),
            .CLKOUT5             (),
            .CLKOUT6             (),
    
            // Ports for dynamic phase shift
            .PSCLK               (1'b0),
            .PSEN                (1'b0),
            .PSINCDEC            (1'b0),
            .PSDONE              (),
    
            // Ports for dynamic reconfiguration
            .DCLK                (vid_phy_axi4lite_aclk),
            .DADDR               (RX_DADDR),
            .DEN                 (RX_DEN),
            .DI                  (RX_DI),
            .DO                  (RX_DO),
            .DRDY                (RX_DRDY),
            .DWE                 (RX_DWE),
    
            // Other control and status signals
            .LOCKED              (lock_from_rxpll),
            .PWRDWN              (pd_to_rxpll),
            .RST                 (clk_rxpll_rst | cfg_phy_mem_map_control_b0[`MMCM_RXUSRCLK_CONFIG_RESET]),
            .CLKINSTOPPED        (),
            .CLKFBSTOPPED        ()
        );
    
    // RXPLL link clock buffer
    /*
        BUFGMUX_CTRL
        RXPLL_LCLK_BUF_INST
        (
            .S              (act_from_dru),
            .I0             (lclk_from_rxpll),
            .I1             (rxoutclk_from_gt[0]),
            .O              (b0gt0_rxusrclk_in)
        );
    */
        BUFG
        RX_LCLK_BUF_INST
        (
            .I              (b0gt0_rxoutclk_out),
            .O              (b0gt0_rxusrclk_in)
        );
        assign b0gt0_rxusrclk2_in = b0gt0_rxusrclk_in;
    
    
    // RXPLL video clock buffer
        wire vclk_from_rxpll_locked_sync;
        xpm_cdc_single #(
         .VERSION        (`XPM_CDC_VERSION       ),
         .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
         .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
         .SRC_INPUT_REG  (0                      )
        ) RX_VCLK_BUF_INST_XPM 
        (
          .src_clk  (1'b0),
          .src_in   (lock_from_rxpll),
          .dest_clk (vclk_from_rxpll),
          .dest_out (vclk_from_rxpll_locked_sync)
        );
        
        BUFGCE
        RX_VCLK_BUF_INST
        (
            .CE             (vclk_from_rxpll_locked_sync),
            .I              (vclk_from_rxpll),
            .O              (vclk_from_rxbufg)
        );
end else begin

    assign lclk_from_rxpll      = 1'b0;
    assign vclk_from_rxpll      = 1'b0;
    assign lock_from_rxpll      = 1'b0;
    assign b0gt0_rxusrclk_in    = 1'b0;
    assign b0gt0_rxusrclk2_in   = 1'b0;
    assign vclk_from_rxbufg     = 1'b0;

end
endgenerate

// RX user ready
// The RX user ready is asserted when only the GTPLL is locked
    always @ (posedge vid_phy_axi4lite_aclk)
    begin

        if ((b0gt0_rxsysclksel_in == 2'b11) && clk_qpll_locked)
            clk_rxusrrdy <= 1;

        else if ((b0gt0_rxsysclksel_in == 2'b00) && clk_cpll_locked)
            clk_rxusrrdy <= 1;

        else
            clk_rxusrrdy <= 0;
    end

// TX user ready
// The TX user ready is asserted when both the GTPLL and TXPLL are in lock
    always @ (posedge vid_phy_axi4lite_aclk)
    begin

        if ((b0gt0_txsysclksel_in == 2'b00) && clk_cpll_locked && clk_txpll_locked)
            clk_txusrrdy <= 1;

        else if ((b0gt0_txsysclksel_in == 2'b11) && clk_qpll_locked && clk_txpll_locked)
            clk_txusrrdy <= 1;

        else
            clk_txusrrdy <= 0;
    end


generate
if (C_Tx_Protocol == 1)
begin 
// TX TMDS clock driver
    ODDR
    #(
        .DDR_CLK_EDGE   ("OPPOSITE_EDGE"),  // "OPPOSITE_EDGE" or "SAME_EDGE"
        .INIT           (1'b0),             // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE         ("SYNC")            // Set/Reset type: "SYNC" or "ASYNC"
    )
    ODDR_TX_INST
    (
        .Q              (dat_from_oddr_tx),     // 1-bit DDR output
        .C              (hclk_from_txpll),  // 1-bit clock input
        .CE             (1'b1),             // 1-bit clock enable input
        .D1             (1'b1),             // 1-bit data input (positive edge)
        .D2             (1'b0),             // 1-bit data input (negative edge)
        .R              (1'b0),             // 1-bit reset
        .S              (1'b0)              // 1-bit set
    );

// TX TMDS clock buffer
    OBUFTDS
    #(
        .IOSTANDARD     ("DEFAULT"),    // Specify the output I/O standard
        .SLEW           ("FAST")        // Specify the output slew rate
    )
    HDMI_TX_CLK_OBUFDS_INST
    (
        .I              (dat_from_oddr_tx),             // Buffer input
        .T              (~hclk_tx_clk_en[2]),       // 3-state enable input (high disables output buffer)
        .O              (tx_tmds_clk_p),                // Diff_p output (connect directly to top-level port)
        .OB             (tx_tmds_clk_n)                 // Diff_n output (connect directly to top-level port)
    );

// TX clock enable
// This signal drives the enable input of the TMDS clock buffer.
// It is cleared when the TX enable is disabled.
// It is asserted on the failing edge of the TMDS clock after the TX enable is enabled
// This assures a glitch free clock start.
    always @ (negedge b0_OBUFTDS_TX_EN, negedge hclk_from_txpll)
    begin
        // Reset
        if (!b0_OBUFTDS_TX_EN)
        begin
            hclk_tx_clk_en <= 3'b000;
        end

        else
        begin
            hclk_tx_clk_en <= {hclk_tx_clk_en[1:0], 1'b1};
        end
    end
end
endgenerate

generate
if (C_Rx_Protocol == 1)
begin 
// RX reference clock driver
    ODDR
    #(
        .DDR_CLK_EDGE   ("OPPOSITE_EDGE"),      // "OPPOSITE_EDGE" or "SAME_EDGE"
        .INIT           (1'b0),                 // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE         ("SYNC")                // Set/Reset type: "SYNC" or "ASYNC"
    )
    ODDR_RX_INST
    (
        .Q              (dat_from_oddr_rx),     // 1-bit DDR output
        .C              (rxrefclk_from_buffer), // 1-bit clock input
        .CE             (1'b1),                 // 1-bit clock enable input
        .D1             (1'b1),                 // 1-bit data input (positive edge)
        .D2             (1'b0),                 // 1-bit data input (negative edge)
        .R              (1'b0),                 // 1-bit reset
        .S              (1'b0)                  // 1-bit set
    );

// RX clock out differential buffer
// This buffer is used to drive the reference clock off-chip to a clock cleaner
   OBUFTDS
   #(
        .IOSTANDARD     ("DEFAULT"),                // Specify the output I/O standard
        .SLEW           ("SLOW")                    // Specify the output slew rate
   )
   RX_CLKOUT_OBUFTDS_INST
   (
        .I              (dat_from_oddr_rx),         // Buffer input
        .T              (~rxclk_rx_clk_en[2]),      // 3-state enable input (high disables output buffer)
        .O              (rx_tmds_clk_p),                // Diff_p output (connect directly to top-level port)
        .OB             (rx_tmds_clk_n)             // Diff_n output (connect directly to top-level port)
   );

// RX clock enable
// This signal drives the enable input of the RX clock buffer.
// It is cleared when the RX enable is disabled.
// It is asserted on the failing edge of the RX clock after the RX enable is enabled
// This assures a glitch free clock start.
    always @ (negedge b0_OBUFTDS_RX_EN, negedge rxrefclk_from_buffer)
    begin
        // Reset
        if (!b0_OBUFTDS_RX_EN)
        begin
            rxclk_rx_clk_en <= 3'b000;
        end

        else
        begin
            rxclk_rx_clk_en <= {rxclk_rx_clk_en[1:0], 1'b1};
        end
    end
end
endgenerate

// Outputs
    assign tx_tmds_clk      = hclk_from_txpll;      // tmds clock
    assign tx_video_clk     = vclk_from_txbufg;     // video clock
    assign rx_tmds_clk      = rxrefclk_from_buffer; // tmds clock
    assign rx_video_clk     = vclk_from_rxbufg;     // video clock

    //------------------------------------------------------------------------
    // Instantiation of Axi Bus Interface vid_phy_axi4lite
    //------------------------------------------------------------------------

//        assign irq = 1'b0;

    vid_phy_controller_v2_2_2_axi4lite # ( 
        .C_S_AXI_DATA_WIDTH(C_vid_phy_axi4lite_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_vid_phy_axi4lite_ADDR_WIDTH),
        .C_Tx_No_Of_Channels(C_Tx_No_Of_Channels),
        .C_Rx_No_Of_Channels(C_Rx_No_Of_Channels),
        .C_TX_PLL_SELECTION(C_TX_PLL_SELECTION),
        .C_RX_PLL_SELECTION(C_RX_PLL_SELECTION),
        .C_Err_Irq_En(0),
        .C_Use_GT_CH4_HDMI(0)
    ) vid_phy_controller_v2_2_2_vid_phy_axi4lite_inst (
        .S_AXI_ACLK(vid_phy_axi4lite_aclk),
        .S_AXI_ARESETN(vid_phy_axi4lite_aresetn),
        .S_AXI_AWADDR(vid_phy_axi4lite_awaddr),
        .S_AXI_AWPROT(vid_phy_axi4lite_awprot),
        .S_AXI_AWVALID(vid_phy_axi4lite_awvalid),
        .S_AXI_AWREADY(vid_phy_axi4lite_awready),
        .S_AXI_WDATA(vid_phy_axi4lite_wdata),
        .S_AXI_WSTRB(vid_phy_axi4lite_wstrb),
        .S_AXI_WVALID(vid_phy_axi4lite_wvalid),
        .S_AXI_WREADY(vid_phy_axi4lite_wready),
        .S_AXI_BRESP(vid_phy_axi4lite_bresp),
        .S_AXI_BVALID(vid_phy_axi4lite_bvalid),
        .S_AXI_BREADY(vid_phy_axi4lite_bready),
        .S_AXI_ARADDR(vid_phy_axi4lite_araddr),
        .S_AXI_ARPROT(vid_phy_axi4lite_arprot),
        .S_AXI_ARVALID(vid_phy_axi4lite_arvalid),
        .S_AXI_ARREADY(vid_phy_axi4lite_arready),
        .S_AXI_RDATA(vid_phy_axi4lite_rdata),
        .S_AXI_RRESP(vid_phy_axi4lite_rresp),
        .S_AXI_RVALID(vid_phy_axi4lite_rvalid),
        .S_AXI_RREADY(vid_phy_axi4lite_rready),
        .irq(irq),
        .err_irq(err_irq),
        .drp_txn_available(drp_txn_available),
        .drp_rsp_read(drp_rsp_read),
        .rx_sym_err_cntr_read(rx_sym_err_cntr_read),
        .cfg_phy_mem_map_control(cfg_phy_mem_map_control),
        .cfg_phy_mem_map_status(cfg_phy_mem_map_status) 
    );


    assign cfg_phy_mem_map_control_b0 = cfg_phy_mem_map_control;
    assign cfg_phy_mem_map_status     = cfg_phy_mem_map_status_b0;  
 

  //----------------- DRP Control, Bank 0, GT 0 ----------------

  wire [31:0] DRP_Config_b0gt0; 
  wire [31:0] DRP_Status_b0gt0; 

  assign DRP_Config_b0gt0[11:0] = cfg_phy_mem_map_control_b0[`CH1_DRPADDR];
  assign DRP_Config_b0gt0[12]   = cfg_phy_mem_map_control_b0[`CH1_DRPEN];
  assign DRP_Config_b0gt0[13]   = cfg_phy_mem_map_control_b0[`CH1_DRPWE];
  assign DRP_Config_b0gt0[31:16]= cfg_phy_mem_map_control_b0[`CH1_DRPDI];

   vid_phy_controller_v2_2_2_drp_control_hdmi #  
   (
    .DRP_ADDR_WIDTH (9)
   )
   drp_control_b0gt0_inst
   (
     .Config_Clk          (vid_phy_axi4lite_aclk),
     .Config_Rst          (vid_phy_axi4lite_areset),
     .DRP_Config          (DRP_Config_b0gt0),
     .DRP_Status          (DRP_Status_b0gt0),
     .drp_txn_available   (drp_txn_available[0]),
     .drp_rsp_read        (drp_rsp_read[0]),
     .DRPCLK              (drp_clk),
     .DRPBUSY             (1'b0),
     .DRPEN               (b0gt0_drpen_in),
     .DRPWE               (b0gt0_drpwe_in),
     .DRPADDR             (b0gt0_drpaddr_in),
     .DRPDI               (b0gt0_drpdi_in),
     .DRPDO               (b0gt0_drpdo_out),
     .DRPRDY              (b0gt0_drprdy_out)  
   );

  //----------------- DRP Control, Bank 0, GT 1 ----------------

  wire [31:0] DRP_Config_b0gt1; 
  wire [31:0] DRP_Status_b0gt1; 

  assign DRP_Config_b0gt1[11:0] = cfg_phy_mem_map_control_b0[`CH2_DRPADDR];
  assign DRP_Config_b0gt1[12]   = cfg_phy_mem_map_control_b0[`CH2_DRPEN];
  assign DRP_Config_b0gt1[13]   = cfg_phy_mem_map_control_b0[`CH2_DRPWE];
  assign DRP_Config_b0gt1[31:16]= cfg_phy_mem_map_control_b0[`CH2_DRPDI];

   vid_phy_controller_v2_2_2_drp_control_hdmi #  
   (
    .DRP_ADDR_WIDTH (9)
   )
   drp_control_b0gt1_inst
   (
     .Config_Clk          (vid_phy_axi4lite_aclk),
     .Config_Rst          (vid_phy_axi4lite_areset),
     .DRP_Config          (DRP_Config_b0gt1),
     .DRP_Status          (DRP_Status_b0gt1),
     .drp_txn_available   (drp_txn_available[1]),
     .drp_rsp_read        (drp_rsp_read[1]),
     .DRPCLK              (drp_clk),
     .DRPBUSY             (1'b0),
     .DRPEN               (b0gt1_drpen_in),
     .DRPWE               (b0gt1_drpwe_in),
     .DRPADDR             (b0gt1_drpaddr_in),
     .DRPDI               (b0gt1_drpdi_in),
     .DRPDO               (b0gt1_drpdo_out),
     .DRPRDY              (b0gt1_drprdy_out)  
   );

  //----------------- DRP Control, Bank 0, GT 2 ----------------

  wire [31:0] DRP_Config_b0gt2; 
  wire [31:0] DRP_Status_b0gt2; 

  assign DRP_Config_b0gt2[11:0] = cfg_phy_mem_map_control_b0[`CH3_DRPADDR];
  assign DRP_Config_b0gt2[12]   = cfg_phy_mem_map_control_b0[`CH3_DRPEN];
  assign DRP_Config_b0gt2[13]   = cfg_phy_mem_map_control_b0[`CH3_DRPWE];
  assign DRP_Config_b0gt2[31:16]= cfg_phy_mem_map_control_b0[`CH3_DRPDI];

   vid_phy_controller_v2_2_2_drp_control_hdmi #  
   (
    .DRP_ADDR_WIDTH (9)
   )
   drp_control_b0gt2_inst
   (
     .Config_Clk          (vid_phy_axi4lite_aclk),
     .Config_Rst          (vid_phy_axi4lite_areset),
     .DRP_Config          (DRP_Config_b0gt2),
     .DRP_Status          (DRP_Status_b0gt2),
     .drp_txn_available   (drp_txn_available[2]),
     .drp_rsp_read        (drp_rsp_read[2]),
     .DRPCLK              (drp_clk),
     .DRPBUSY             (1'b0),
     .DRPEN               (b0gt2_drpen_in),
     .DRPWE               (b0gt2_drpwe_in),
     .DRPADDR             (b0gt2_drpaddr_in),
     .DRPDI               (b0gt2_drpdi_in),
     .DRPDO               (b0gt2_drpdo_out),
     .DRPRDY              (b0gt2_drprdy_out)  
   );

  //--------------------------- DRP Control, Common ----------------------------

  wire [31:0] DRP_Config_common; 
  wire [31:0] DRP_Status_common; 

  assign DRP_Config_common[11:0] = cfg_phy_mem_map_control[`COMMON_DRPADDR];
  assign DRP_Config_common[12]   = cfg_phy_mem_map_control[`COMMON_DRPEN];
  assign DRP_Config_common[13]   = cfg_phy_mem_map_control[`COMMON_DRPWE];
  assign DRP_Config_common[31:16]= cfg_phy_mem_map_control[`COMMON_DRPDI];

   vid_phy_controller_v2_2_2_drp_control_hdmi #  
   (
    .DRP_ADDR_WIDTH (8)
   )
   drp_control_b0gtcommon_inst
   (
     .Config_Clk          (vid_phy_axi4lite_aclk),
     .Config_Rst          (vid_phy_axi4lite_areset),
     .DRP_Config          (DRP_Config_common),
     .DRP_Status          (DRP_Status_common),
     .drp_txn_available   (drp_txn_available[4]),
     .drp_rsp_read        (drp_rsp_read[4]),
     .DRPCLK              (drp_clk),
     .DRPBUSY             (1'b0),
     .DRPEN               (b0gt0_drpen_common_in),
     .DRPWE               (b0gt0_drpwe_common_in),
     .DRPADDR             (b0gt0_drpaddr_common_in),
     .DRPDI               (b0gt0_drpdi_common_in),
     .DRPDO               (b0gt0_drpdo_common_out),
     .DRPRDY              (b0gt0_drprdy_common_out)  
   );


 
    //--------------------------- Clock Detector ----------------------------
    wire        b0_clkdet_dru_refclk_bufds;
    wire        b0_clkdet_dru_refclk;
    
    wire        b0_clkdet_ctrl_run;
    wire        b0_clkdet_ctrl_tx_tmr_clr;
    wire        b0_clkdet_ctrl_rx_tmr_clr;
    wire        b0_clkdet_ctrl_tx_freq_rst;
    wire        b0_clkdet_ctrl_rx_freq_rst;
    wire  [7:0] b0_clkdet_ctrl_lock_cntr_threshold;
    wire [31:0] b0_clkdet_freq_cntr_timeout;
    wire [31:0] b0_clkdet_tx_tmr;
    wire [31:0] b0_clkdet_rx_tmr;
    wire        b0_clkdet_tx_tmr_ld;
    wire        b0_clkdet_rx_tmr_ld;
    wire        b0_clkdet_tx_tmr_evt_clr;
    wire        b0_clkdet_tx_freq_evt_clr;
    wire        b0_clkdet_rx_tmr_evt_clr;
    wire        b0_clkdet_rx_freq_evt_clr;
    wire        b0_clkdet_stat_tx_freq_zero;      
    wire        b0_clkdet_stat_rx_freq_zero;      
    wire        b0_clkdet_stat_tx_refclk_locked;  
    wire        b0_clkdet_stat_tx_refclk_lock_cap;
    wire [31:0] b0_clkdet_tx_freq; 
    wire [31:0] b0_clkdet_rx_freq; 
    wire [31:0] b0_clkdet_dru_freq;

    wire        b0_clkdet_tx_tmr_evt;
    wire        b0_clkdet_tx_freq_evt;
    wire        b0_clkdet_rx_tmr_evt;
    wire        b0_clkdet_rx_freq_evt;
    wire        b0_clkdet_ctrl_tx_en;
    wire        b0_clkdet_ctrl_rx_en;   

    if      (C_NIDRU_REFCLK_SEL == GTREFCLK0)      assign b0_clkdet_dru_refclk_bufds = mgtrefclk0_from_bufds;
    else if (C_NIDRU_REFCLK_SEL == GTREFCLK1)      assign b0_clkdet_dru_refclk_bufds = mgtrefclk1_from_bufds;
    else if (C_NIDRU_REFCLK_SEL == GTNORTHREFCLK0) assign b0_clkdet_dru_refclk_bufds = gtnorthrefclk0_in;
    else if (C_NIDRU_REFCLK_SEL == GTNORTHREFCLK1) assign b0_clkdet_dru_refclk_bufds = gtnorthrefclk1_in; 
    else if (C_NIDRU_REFCLK_SEL == GTSOUTHREFCLK0) assign b0_clkdet_dru_refclk_bufds = gtsouthrefclk0_in;
    else if (C_NIDRU_REFCLK_SEL == GTSOUTHREFCLK1) assign b0_clkdet_dru_refclk_bufds = gtsouthrefclk1_in;
    else if (C_NIDRU_REFCLK_SEL == GTEASTREFCLK0)  assign b0_clkdet_dru_refclk_bufds = gteastrefclk0_in;
    else if (C_NIDRU_REFCLK_SEL == GTEASTREFCLK1)  assign b0_clkdet_dru_refclk_bufds = gteastrefclk1_in; 
    else if (C_NIDRU_REFCLK_SEL == GTWESTREFCLK0)  assign b0_clkdet_dru_refclk_bufds = gtwestrefclk0_in;
    else if (C_NIDRU_REFCLK_SEL == GTWESTREFCLK1)  assign b0_clkdet_dru_refclk_bufds = gtwestrefclk1_in;
    else assign b0_clkdet_dru_refclk_bufds = 1'b0;
    
    assign b0_clkdet_dru_refclk = b0_clkdet_dru_refclk_bufds;

    assign b0_clkdet_ctrl_run                  = cfg_phy_mem_map_control[`CLKDET_RUN];
    assign b0_clkdet_ctrl_tx_tmr_clr           = cfg_phy_mem_map_control[`CLKDET_TX_TMR_CLR];
    assign b0_clkdet_ctrl_rx_tmr_clr           = cfg_phy_mem_map_control[`CLKDET_RX_TMR_CLR];
    assign b0_clkdet_ctrl_tx_freq_rst          = cfg_phy_mem_map_control[`CLKDET_TX_FREQ_RST];
    assign b0_clkdet_ctrl_rx_freq_rst          = cfg_phy_mem_map_control[`CLKDET_RX_FREQ_RST];
    assign b0_clkdet_ctrl_lock_cntr_threshold  = cfg_phy_mem_map_control[`CLKDET_FREQ_LOCK_CNTR_TRSHLD];
    assign b0_clkdet_freq_cntr_timeout         = cfg_phy_mem_map_control[`CLKDET_FREQ_CNTR_TMOUT];
    assign b0_clkdet_tx_tmr                    = cfg_phy_mem_map_control[`CLKDET_TX_TMR_TMOUT_CNT];
    assign b0_clkdet_rx_tmr                    = cfg_phy_mem_map_control[`CLKDET_RX_TMR_TMOUT_CNT];
    assign b0_clkdet_tx_tmr_ld                 = cfg_phy_mem_map_control[`CLKDET_TX_TMR_LOAD];
    assign b0_clkdet_rx_tmr_ld                 = cfg_phy_mem_map_control[`CLKDET_RX_TMR_LOAD];
    assign b0_clkdet_tx_tmr_evt_clr            = cfg_phy_mem_map_control[`CLKDET_TX_TMR_EVENT_CLR];
    assign b0_clkdet_tx_freq_evt_clr           = cfg_phy_mem_map_control[`CLKDET_TX_FREQ_EVENT_CLR];
    assign b0_clkdet_rx_tmr_evt_clr            = cfg_phy_mem_map_control[`CLKDET_RX_TMR_EVENT_CLR];
    assign b0_clkdet_rx_freq_evt_clr           = cfg_phy_mem_map_control[`CLKDET_RX_FREQ_EVENT_CLR];

    // Clock detector TX enable
    if      (C_TX_REFCLK_SEL == GTREFCLK0)      
        assign b0_clkdet_ctrl_tx_en  = ~cfg_phy_mem_map_control_b0[`GTREFCLK0_CEB];
    else if (C_TX_REFCLK_SEL == GTREFCLK1)      
        assign b0_clkdet_ctrl_tx_en  = ~cfg_phy_mem_map_control_b0[`GTREFCLK1_CEB];
    else
        assign b0_clkdet_ctrl_tx_en  = ~cfg_phy_mem_map_control_b0[`TX_REFCLK_CEB];

    // Clock detector RX enable
    if      (C_RX_REFCLK_SEL == GTREFCLK0)      
        assign b0_clkdet_ctrl_rx_en  = ~cfg_phy_mem_map_control_b0[`GTREFCLK0_CEB];
    else if (C_RX_REFCLK_SEL == GTREFCLK1)      
        assign b0_clkdet_ctrl_rx_en  = ~cfg_phy_mem_map_control_b0[`GTREFCLK1_CEB];
    else
        assign b0_clkdet_ctrl_rx_en  = ~cfg_phy_mem_map_control_b0[`RX_REFCLK_CEB];
    exdes_vid_phy_controller_0_clkdet
    clock_detector_inst
    (
      .CLK_IN                           (vid_phy_axi4lite_aclk),
      .TX_REFCLK_IN                     (txrefclk_from_buffer),
      .TX_REFCLK_LOCK_IN                (tx_refclk_rdy),
      .RX_REFCLK_IN                     (rxrefclk_from_buffer),
      .DRU_REFCLK_IN                    (b0_clkdet_dru_refclk),

      .clkdet_ctrl_run                  (b0_clkdet_ctrl_run),
      .clkdet_ctrl_tx_tmr_clr           (b0_clkdet_ctrl_tx_tmr_clr),
      .clkdet_ctrl_rx_tmr_clr           (b0_clkdet_ctrl_rx_tmr_clr),
      .clkdet_ctrl_tx_freq_rst          (b0_clkdet_ctrl_tx_freq_rst),
      .clkdet_ctrl_rx_freq_rst          (b0_clkdet_ctrl_rx_freq_rst),
      .clkdet_ctrl_lock_cntr_threshold  (b0_clkdet_ctrl_lock_cntr_threshold),
      .clkdet_ctrl_tx_en                (b0_clkdet_ctrl_tx_en),
      .clkdet_ctrl_rx_en                (b0_clkdet_ctrl_rx_en),

      .clkdet_stat_tx_freq_zero         (b0_clkdet_stat_tx_freq_zero),      
      .clkdet_stat_rx_freq_zero         (b0_clkdet_stat_rx_freq_zero),      
      .clkdet_stat_tx_refclk_locked     (b0_clkdet_stat_tx_refclk_locked),  
      .clkdet_stat_tx_refclk_lock_cap   (b0_clkdet_stat_tx_refclk_lock_cap),

      .clkdet_freq_cntr_timeout         (b0_clkdet_freq_cntr_timeout),
      .clkdet_tx_freq                   (b0_clkdet_tx_freq), 
      .clkdet_rx_freq                   (b0_clkdet_rx_freq), 
      .clkdet_dru_freq                  (b0_clkdet_dru_freq),
      .clkdet_tx_tmr                    (b0_clkdet_tx_tmr),
      .clkdet_tx_tmr_ld                 (b0_clkdet_tx_tmr_ld),
      .clkdet_rx_tmr                    (b0_clkdet_rx_tmr),
      .clkdet_rx_tmr_ld                 (b0_clkdet_rx_tmr_ld),

      .clkdet_tx_tmr_evt                (b0_clkdet_tx_tmr_evt),
      .clkdet_tx_freq_evt               (b0_clkdet_tx_freq_evt),
      .clkdet_rx_tmr_evt                (b0_clkdet_rx_tmr_evt), 
      .clkdet_rx_freq_evt               (b0_clkdet_rx_freq_evt),

      .clkdet_tx_tmr_evt_clr            (b0_clkdet_tx_tmr_evt_clr), 
      .clkdet_tx_freq_evt_clr           (b0_clkdet_tx_freq_evt_clr),
      .clkdet_rx_tmr_evt_clr            (b0_clkdet_rx_tmr_evt_clr), 
      .clkdet_rx_freq_evt_clr           (b0_clkdet_rx_freq_evt_clr)
    );

    
    (* dont_touch = "true" *) wire [36:0] dru_ctrl_center_freq_i;
    (* dont_touch = "true" *) wire        dru_ctrl_enable_i;
    (* dont_touch = "true" *) wire        dru_ctrl_reset_i;

    xpm_cdc_array_single #(
      .VERSION        (`XPM_CDC_VERSION       ),
      .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
      .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
      .WIDTH          (39                      ),
      .SRC_INPUT_REG  (0                      )
    ) xpm_array_single_DRU_CTRL_in_sync_inst (
      .src_clk         (vid_phy_axi4lite_aclk        ),
      .src_in          ({
                         cfg_phy_mem_map_control[`DRU_CENTER_FREQ],
                         cfg_phy_mem_map_control[`DRU_ENABLE],
                         cfg_phy_mem_map_control[`DRU_RESET]
                        }),
      .dest_clk        (b0gt0_rxusrclk2_in      ),
      .dest_out        ({
                         dru_ctrl_center_freq_i,
                         dru_ctrl_enable_i,
                         dru_ctrl_reset_i
                        })
    );
    //----------------- DRU, Bank 0, GT 0 ----------------  b0gt0
    
    wire        b0gt0_dru_stat_act; 
    wire        b0gt0_dru_stat_act_sync; 
    wire  [7:0] b0gt0_dru_stat_version; 
    wire  [7:0] b0gt0_dru_stat_version_sync; 
    
    

    vid_phy_controller_v2_2_2_dru #(
      .WIDTH_OUT            (20)
    ) dru_b0gt0_inst (
      .DRU_CLK_IN           (b0gt0_rxusrclk2_in),
      .DRU_ACT_OUT          (b0gt0_dru_stat_act),
      .DRU_DATA_IN          (b0gt0_rxdata_out),
      .DRU_DATA_OUT         (b0gt0_dru_data_out),
      .DRU_DATA_EN_OUT      (b0gt0_dru_en_out),
      
      .dru_ctrl_rst         (dru_ctrl_reset_i),
      .dru_ctrl_enable      (dru_ctrl_enable_i),
      .dru_ctrl_ph_est_dis  (1'b0),
      
      .dru_center_freq      (dru_ctrl_center_freq_i),
      .dru_gain_g1          (5'd9),
      .dru_gain_g1_p        (5'd16),
      .dru_gain_g2          (5'd5),
      
      .dru_version          (b0gt0_dru_stat_version)
    );
    
    //----------------- DRU, Bank 0, GT 1 ----------------  b0gt1
    
    wire        b0gt1_dru_stat_act; 
    wire        b0gt1_dru_stat_act_sync; 
    wire  [7:0] b0gt1_dru_stat_version; 
    wire  [7:0] b0gt1_dru_stat_version_sync; 
	

    vid_phy_controller_v2_2_2_dru #(
      .WIDTH_OUT            (20)
    ) dru_b0gt1_inst (
      .DRU_CLK_IN           (b0gt0_rxusrclk2_in),
      .DRU_ACT_OUT          (b0gt1_dru_stat_act),
      .DRU_DATA_IN          (b0gt1_rxdata_out),
      .DRU_DATA_OUT         (b0gt1_dru_data_out),
      .DRU_DATA_EN_OUT      (b0gt1_dru_en_out),
      
      .dru_ctrl_rst         (dru_ctrl_reset_i),
      .dru_ctrl_enable      (dru_ctrl_enable_i),
      .dru_ctrl_ph_est_dis  (1'b0),
      
      .dru_center_freq      (dru_ctrl_center_freq_i),
      .dru_gain_g1          (5'd9),
      .dru_gain_g1_p        (5'd16),
      .dru_gain_g2          (5'd5),
      
      .dru_version          (b0gt1_dru_stat_version)
    );
    
    //----------------- DRU, Bank 0, GT 2 ----------------  b0gt2
    
    wire        b0gt2_dru_stat_act; 
    wire        b0gt2_dru_stat_act_sync; 
    wire  [7:0] b0gt2_dru_stat_version; 
    wire  [7:0] b0gt2_dru_stat_version_sync; 
	

    vid_phy_controller_v2_2_2_dru #(
      .WIDTH_OUT            (20)
    ) dru_b0gt2_inst (
      .DRU_CLK_IN           (b0gt0_rxusrclk2_in),
      .DRU_ACT_OUT          (b0gt2_dru_stat_act),
      .DRU_DATA_IN          (b0gt2_rxdata_out),
      .DRU_DATA_OUT         (b0gt2_dru_data_out),
      .DRU_DATA_EN_OUT      (b0gt2_dru_en_out),
      
      .dru_ctrl_rst         (dru_ctrl_reset_i),
      .dru_ctrl_enable      (dru_ctrl_enable_i),
      .dru_ctrl_ph_est_dis  (1'b0),
      
      .dru_center_freq      (dru_ctrl_center_freq_i),
      .dru_gain_g1          (5'd9),
      .dru_gain_g1_p        (5'd16),
      .dru_gain_g2          (5'd5),
      
      .dru_version          (b0gt2_dru_stat_version)
    );
    
    assign cfg_phy_mem_map_status_b0[`DRU_GAIN_G1]   = 5'd9;
    assign cfg_phy_mem_map_status_b0[`DRU_GAIN_G1_P] = 5'd16;
    assign cfg_phy_mem_map_status_b0[`DRU_GAIN_G2]   = 5'd5;
    


    // ----------------------------------- AXI4LIte Control ---------------------------------

    // ----------------------------------- GT COMMON - QPLL ---------------------------------
    assign b0gt0_qpllreset_in_prog = cfg_phy_mem_map_control[`QPLL0RESET];// | b0gt0_qpllreset_in;
    assign b0gt0_qpllpd_in         = cfg_phy_mem_map_control[`CH1_QPLL0PD];
    assign b0gt0_qpllrefclksel_in  = cfg_phy_mem_map_control[`QPLL0REFCLKSEL];
    //----------------------------------- GTP COMMON - PLL0, PLL1---------------------------
    assign b0gt0_pll0reset_in_prog = cfg_phy_mem_map_control[`QPLL0RESET] | b0gt0_pll0reset_out;
    //assign b0gt0_pll1reset_in_prog = cfg_phy_mem_map_control[`QPLL0RESET] | b0gt0_pll1reset_out;
    assign b0gt0_pllpd_in          = cfg_phy_mem_map_control[`CH1_QPLL0PD];
    assign b0gt0_pll0refclksel_in  = cfg_phy_mem_map_control[`QPLL0REFCLKSEL];
    assign b0gt0_pll1refclksel_in  = cfg_phy_mem_map_control_b0[`QPLL1REFCLKSEL];



    // ---------------------- Bank 0, GT Channel 0 ------------------------------
    // Control Assignments
    // All are ASYNC inputs to GT unless exception is clearly added in comment next to assignment - Reference GT Userguide
// 
//    assign b0gt0_tx_mmcm_lock_in   = b0_MMCM_TX_DRP_LOCKED;
//  
    assign b0gt0_cplllockdetclk_in = vid_phy_axi4lite_aclk;
    assign b0gt0_rxsysclksel_in    = cfg_phy_mem_map_control_b0[`RXSYSCLKSEL];
    assign b0gt0_txsysclksel_in    = cfg_phy_mem_map_control_b0[`TXSYSCLKSEL];
    assign b0gt0_cpllrefclksel_in  = cfg_phy_mem_map_control_b0[`CPLLREFCLKSEL];
    assign b0gt0_cpllpd_in         = cfg_phy_mem_map_control_b0[`CH1_CPLLPD];
    assign b0gt0_cpllreset_in      = cfg_phy_mem_map_control_b0[`CPLLRESET];
    assign b0gt0_drpclk_in         = drp_clk;
    assign b0gt0_loopback_in       = cfg_phy_mem_map_control_b0[`CH1_LOOPBACK];
    assign b0gt0_txpd_in           = b0gt0_txpd_in_sync;  //Sync to TXUSRCLK2
    assign b0gt0_rxpd_in           = cfg_phy_mem_map_control_b0[`CH1_RXPD];  //Async
    assign b0gt0_eyescanreset_in   = cfg_phy_mem_map_control_b0[`CH1_EYESCANRESET];
    assign b0gt0_rxcdrhold_in      = cfg_phy_mem_map_control_b0[`CH1_RXCDRHOLD];
    assign b0gt0_rxprbssel_in      = b0gt0_rxprbssel_in_sync; //Sync to RXUSRCLK2
    assign b0gt0_rxprbscntreset_in = b0gt0_rxprbscntreset_in_sync; //Sync to RXUSRCLK2
    assign b0gt0_rxbufreset_in     = cfg_phy_mem_map_control_b0[`CH1_RXBUFRESET];
    assign b0gt0_rxlpmhfovrden_in  = b0gt0_rxlpmhfovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt0_rxlpmlfklovrden_in= b0gt0_rxlpmlfklovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt0_gtrxreset_in      = cfg_phy_mem_map_control_b0[`CH1_GTRXRESET];
 
    assign cfg_phy_mem_map_status_b0[`CH1_DRU_ACTIVE] =  b0gt0_dru_stat_act_sync;
    assign dru_active              = cfg_phy_mem_map_control_b0[`DRU_ENABLE];
 
    assign b0gt0_rxpcsreset_in     = cfg_phy_mem_map_control_b0[`CH1_RXPCSRESET];
    assign b0gt0_rxpmareset_in     = cfg_phy_mem_map_control_b0[`CH1_RXPMARESET];
    assign b0gt0_rxlpmen_in        = cfg_phy_mem_map_control_b0[`CH1_RXLPMEN];//b0gt0_rxlpmen_in_sync; //Sync to RXUSRCLK2
    assign b0gt0_rxpolarity_in     = b0gt0_rxpolarity_in_sync; //Sync to RXUSRCLK2
    assign b0gt0_txpostcursor_in   = cfg_phy_mem_map_control_b0[`CH1_TXPOSTCURSOR];
    assign b0gt0_txprecursor_in    = cfg_phy_mem_map_control_b0[`CH1_TXPRECURSOR];
    assign b0gt0_gttxreset_in      = cfg_phy_mem_map_control_b0[`CH1_GTTXRESET];
    assign b0gt0_txelecidle_in     = cfg_phy_mem_map_control_b0[`CH1_TXELECIDLE]; //Not Connected, If connected then sync to TXUSRCLK2
    assign b0gt0_txprbssel_in      = b0gt0_txprbssel_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_txprbsforceerr_in = b0gt0_txprbsforceerr_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_txdiffctrl_in     = b0gt0_txdiffctrl_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_txinhibit_in      = b0gt0_txinhibit_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_txpcsreset_in     = cfg_phy_mem_map_control_b0[`CH1_TXPCSRESET];
    assign b0gt0_txpmareset_in     = cfg_phy_mem_map_control_b0[`CH1_TXPMARESET];
    assign b0gt0_txpolarity_in     = b0gt0_txpolarity_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_tx8b10ben_in      = b0gt0_tx8b10ben_in_sync; //Sync to TXUSRCLK2
    assign b0gt0_rxuserrdy_in      = cfg_phy_mem_map_control_b0[`CH1_RXUSERRDY];
    assign b0gt0_txuserrdy_in      = cfg_phy_mem_map_control_b0[`CH1_TXUSERRDY];

    //Status Assignments
    assign cfg_phy_mem_map_status_b0[`CH1_TXRESETDONE]        =  b0gt0_txresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_TXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH1_TXGTPOWERGOOD]      =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH1_RXRESETDONE]        =  b0gt0_rxresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_RXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH1_DRPDO]              =  DRP_Status_b0gt0[15:0];
    assign cfg_phy_mem_map_status_b0[`CH1_DRPRDY]             =  DRP_Status_b0gt0[16];
 
    assign cfg_phy_mem_map_status_b0[`CH1_DRPBUSY]            =  DRP_Status_b0gt0[17];
//    assign cfg_phy_mem_map_status_b0[`CH1_TXPHALIGNDONE]      =  b0gt0_txfsmresetdone_out_sync;//_txphaligndone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_TXPHINITDONE]       =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH1_TXDLYRESETDONE]     =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH1_TXBUFSTATUS]        =  b0gt0_txbufstatus_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_RXCDRLOCK]          =  b0gt0_rxcdrlock_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_RXPRBSERR]          =  b0gt0_rxprbserr_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH1_RXBUFSTATUS]        =  b0gt0_rxbufstatus_out_sync;
    //Common - For coding simplicity, assigned to all quads.
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPBUSY]             =  DRP_Status_common[17];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPRDY]              =  DRP_Status_common[16];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPDO]               =  DRP_Status_common[15:0];
    assign cfg_phy_mem_map_status_b0[`QPLLLOCK]                   =  b0gt0_qplllock_in_sync;
    assign cfg_phy_mem_map_status_b0[`QPLL1LOCK]                  =  1'b0; //used in US device
 
//    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_CONFIG_DONE]  =  b0_MMCM_TX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_LOCKED]       =  b0_MMCM_TX_DRP_LOCKED_sync;
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_DRPBUSY]      =  DRP_Status_mmcm_txusrclk[17];
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_DRPRDY]       =  DRP_Status_mmcm_txusrclk[16];
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_DRPDO]        =  DRP_Status_mmcm_txusrclk[15:0];

//    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_CONFIG_DONE]  =  b0_MMCM_RX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_LOCKED]       =  b0_MMCM_RX_DRP_LOCKED_sync;
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_DRPBUSY]      =  DRP_Status_mmcm_rxusrclk[17];
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_DRPRDY]       =  DRP_Status_mmcm_rxusrclk[16];
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_DRPDO]        =  DRP_Status_mmcm_rxusrclk[15:0];

    assign cfg_phy_mem_map_status_b0[`CH1_SYM_ERR_COUNT]          =  1'b0; // not used in HDMI
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_ZERO]        =  b0_clkdet_stat_tx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_ZERO]        =  b0_clkdet_stat_rx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK]      =  b0_clkdet_stat_tx_refclk_locked;  
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK_CAP]  =  b0_clkdet_stat_tx_refclk_lock_cap;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ]             =  b0_clkdet_tx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ]             =  b0_clkdet_rx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_DRU_FREQ]            =  b0_clkdet_dru_freq;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_TMR_EVENT]        =  b0_clkdet_tx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_EVENT]       =  b0_clkdet_tx_freq_evt;
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_TMR_EVENT]        =  b0_clkdet_rx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_EVENT]       =  b0_clkdet_rx_freq_evt;
    

    // ---------------------- Bank 0, GT Channel 1 ------------------------------
    // Control Assignments
    // All are ASYNC inputs to GT unless exception is clearly added in comment next to assignment - Reference GT Userguide
// 
//    assign b0gt1_tx_mmcm_lock_in   = b0_MMCM_TX_DRP_LOCKED;
//  
    assign b0gt1_cplllockdetclk_in = vid_phy_axi4lite_aclk;
    assign b0gt1_rxsysclksel_in    = cfg_phy_mem_map_control_b0[`RXSYSCLKSEL];
    assign b0gt1_txsysclksel_in    = cfg_phy_mem_map_control_b0[`TXSYSCLKSEL];
    assign b0gt1_cpllrefclksel_in  = cfg_phy_mem_map_control_b0[`CPLLREFCLKSEL];
    assign b0gt1_cpllpd_in         = cfg_phy_mem_map_control_b0[`CH2_CPLLPD];
    assign b0gt1_cpllreset_in      = cfg_phy_mem_map_control_b0[`CPLLRESET];
    assign b0gt1_drpclk_in         = drp_clk;
    assign b0gt1_loopback_in       = cfg_phy_mem_map_control_b0[`CH2_LOOPBACK];
    assign b0gt1_txpd_in           = b0gt1_txpd_in_sync;  //Sync to TXUSRCLK2
    assign b0gt1_rxpd_in           = cfg_phy_mem_map_control_b0[`CH2_RXPD];  //Async
    assign b0gt1_eyescanreset_in   = cfg_phy_mem_map_control_b0[`CH2_EYESCANRESET];
    assign b0gt1_rxcdrhold_in      = cfg_phy_mem_map_control_b0[`CH2_RXCDRHOLD];
    assign b0gt1_rxprbssel_in      = b0gt1_rxprbssel_in_sync; //Sync to RXUSRCLK2
    assign b0gt1_rxprbscntreset_in = b0gt1_rxprbscntreset_in_sync; //Sync to RXUSRCLK2
    assign b0gt1_rxbufreset_in     = cfg_phy_mem_map_control_b0[`CH2_RXBUFRESET];
    assign b0gt1_rxlpmhfovrden_in  = b0gt1_rxlpmhfovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt1_rxlpmlfklovrden_in= b0gt1_rxlpmlfklovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt1_gtrxreset_in      = cfg_phy_mem_map_control_b0[`CH2_GTRXRESET];
 
    assign cfg_phy_mem_map_status_b0[`CH2_DRU_ACTIVE] =  b0gt1_dru_stat_act_sync;
 
    assign b0gt1_rxpcsreset_in     = cfg_phy_mem_map_control_b0[`CH2_RXPCSRESET];
    assign b0gt1_rxpmareset_in     = cfg_phy_mem_map_control_b0[`CH2_RXPMARESET];
    assign b0gt1_rxlpmen_in        = cfg_phy_mem_map_control_b0[`CH2_RXLPMEN];//b0gt1_rxlpmen_in_sync; //Sync to RXUSRCLK2
    assign b0gt1_rxpolarity_in     = b0gt1_rxpolarity_in_sync; //Sync to RXUSRCLK2
    assign b0gt1_txpostcursor_in   = cfg_phy_mem_map_control_b0[`CH2_TXPOSTCURSOR];
    assign b0gt1_txprecursor_in    = cfg_phy_mem_map_control_b0[`CH2_TXPRECURSOR];
    assign b0gt1_gttxreset_in      = cfg_phy_mem_map_control_b0[`CH2_GTTXRESET];
    assign b0gt1_txelecidle_in     = cfg_phy_mem_map_control_b0[`CH2_TXELECIDLE]; //Not Connected, If connected then sync to TXUSRCLK2
    assign b0gt1_txprbssel_in      = b0gt1_txprbssel_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_txprbsforceerr_in = b0gt1_txprbsforceerr_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_txdiffctrl_in     = b0gt1_txdiffctrl_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_txinhibit_in      = b0gt1_txinhibit_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_txpcsreset_in     = cfg_phy_mem_map_control_b0[`CH2_TXPCSRESET];
    assign b0gt1_txpmareset_in     = cfg_phy_mem_map_control_b0[`CH2_TXPMARESET];
    assign b0gt1_txpolarity_in     = b0gt1_txpolarity_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_tx8b10ben_in      = b0gt1_tx8b10ben_in_sync; //Sync to TXUSRCLK2
    assign b0gt1_rxuserrdy_in      = cfg_phy_mem_map_control_b0[`CH2_RXUSERRDY];
    assign b0gt1_txuserrdy_in      = cfg_phy_mem_map_control_b0[`CH2_TXUSERRDY];

    //Status Assignments
    assign cfg_phy_mem_map_status_b0[`CH2_TXRESETDONE]        =  b0gt1_txresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_TXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH2_TXGTPOWERGOOD]      =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH2_RXRESETDONE]        =  b0gt1_rxresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_RXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH2_DRPDO]              =  DRP_Status_b0gt1[15:0];
    assign cfg_phy_mem_map_status_b0[`CH2_DRPRDY]             =  DRP_Status_b0gt1[16];
 
    assign cfg_phy_mem_map_status_b0[`CH2_DRPBUSY]            =  DRP_Status_b0gt1[17];
//    assign cfg_phy_mem_map_status_b0[`CH2_TXPHALIGNDONE]      =  b0gt1_txfsmresetdone_out_sync;//_txphaligndone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_TXPHINITDONE]       =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH2_TXDLYRESETDONE]     =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH2_TXBUFSTATUS]        =  b0gt1_txbufstatus_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_RXCDRLOCK]          =  b0gt1_rxcdrlock_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_RXPRBSERR]          =  b0gt1_rxprbserr_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_RXBUFSTATUS]        =  b0gt1_rxbufstatus_out_sync;
    //Common - For coding simplicity, assigned to all quads.
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPBUSY]             =  DRP_Status_common[17];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPRDY]              =  DRP_Status_common[16];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPDO]               =  DRP_Status_common[15:0];
    assign cfg_phy_mem_map_status_b0[`QPLLLOCK]                   =  b0gt0_qplllock_in_sync;
    assign cfg_phy_mem_map_status_b0[`QPLL1LOCK]                  =  1'b0; //used in US device
 
//    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_CONFIG_DONE]  =  b0_MMCM_TX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_LOCKED]       =  b0_MMCM_TX_DRP_LOCKED_sync;
//    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_CONFIG_DONE]  =  b0_MMCM_RX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_LOCKED]       =  b0_MMCM_RX_DRP_LOCKED_sync;
    assign cfg_phy_mem_map_status_b0[`CH2_SYM_ERR_COUNT]          =  1'b0; // not used in HDMI
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_ZERO]        =  b0_clkdet_stat_tx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_ZERO]        =  b0_clkdet_stat_rx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK]      =  b0_clkdet_stat_tx_refclk_locked;  
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK_CAP]  =  b0_clkdet_stat_tx_refclk_lock_cap;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ]             =  b0_clkdet_tx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ]             =  b0_clkdet_rx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_DRU_FREQ]            =  b0_clkdet_dru_freq;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_TMR_EVENT]        =  b0_clkdet_tx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_EVENT]       =  b0_clkdet_tx_freq_evt;
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_TMR_EVENT]        =  b0_clkdet_rx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_EVENT]       =  b0_clkdet_rx_freq_evt;
    

    // ---------------------- Bank 0, GT Channel 2 ------------------------------
    // Control Assignments
    // All are ASYNC inputs to GT unless exception is clearly added in comment next to assignment - Reference GT Userguide
// 
//    assign b0gt2_tx_mmcm_lock_in   = b0_MMCM_TX_DRP_LOCKED;
//  
    assign b0gt2_cplllockdetclk_in = vid_phy_axi4lite_aclk;
    assign b0gt2_rxsysclksel_in    = cfg_phy_mem_map_control_b0[`RXSYSCLKSEL];
    assign b0gt2_txsysclksel_in    = cfg_phy_mem_map_control_b0[`TXSYSCLKSEL];
    assign b0gt2_cpllrefclksel_in  = cfg_phy_mem_map_control_b0[`CPLLREFCLKSEL];
    assign b0gt2_cpllpd_in         = cfg_phy_mem_map_control_b0[`CH3_CPLLPD];
    assign b0gt2_cpllreset_in      = cfg_phy_mem_map_control_b0[`CPLLRESET];
    assign b0gt2_drpclk_in         = drp_clk;
    assign b0gt2_loopback_in       = cfg_phy_mem_map_control_b0[`CH3_LOOPBACK];
    assign b0gt2_txpd_in           = b0gt2_txpd_in_sync;  //Sync to TXUSRCLK2
    assign b0gt2_rxpd_in           = cfg_phy_mem_map_control_b0[`CH3_RXPD];  //Async
    assign b0gt2_eyescanreset_in   = cfg_phy_mem_map_control_b0[`CH3_EYESCANRESET];
    assign b0gt2_rxcdrhold_in      = cfg_phy_mem_map_control_b0[`CH3_RXCDRHOLD];
    assign b0gt2_rxprbssel_in      = b0gt2_rxprbssel_in_sync; //Sync to RXUSRCLK2
    assign b0gt2_rxprbscntreset_in = b0gt2_rxprbscntreset_in_sync; //Sync to RXUSRCLK2
    assign b0gt2_rxbufreset_in     = cfg_phy_mem_map_control_b0[`CH3_RXBUFRESET];
    assign b0gt2_rxlpmhfovrden_in  = b0gt2_rxlpmhfovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt2_rxlpmlfklovrden_in= b0gt2_rxlpmlfklovrden_in_sync; // Sync to RXUSRCLK2
    assign b0gt2_gtrxreset_in      = cfg_phy_mem_map_control_b0[`CH3_GTRXRESET];
 
    assign cfg_phy_mem_map_status_b0[`CH3_DRU_ACTIVE] =  b0gt2_dru_stat_act_sync;
 
    assign b0gt2_rxpcsreset_in     = cfg_phy_mem_map_control_b0[`CH3_RXPCSRESET];
    assign b0gt2_rxpmareset_in     = cfg_phy_mem_map_control_b0[`CH3_RXPMARESET];
    assign b0gt2_rxlpmen_in        = cfg_phy_mem_map_control_b0[`CH3_RXLPMEN];//b0gt2_rxlpmen_in_sync; //Sync to RXUSRCLK2
    assign b0gt2_rxpolarity_in     = b0gt2_rxpolarity_in_sync; //Sync to RXUSRCLK2
    assign b0gt2_txpostcursor_in   = cfg_phy_mem_map_control_b0[`CH3_TXPOSTCURSOR];
    assign b0gt2_txprecursor_in    = cfg_phy_mem_map_control_b0[`CH3_TXPRECURSOR];
    assign b0gt2_gttxreset_in      = cfg_phy_mem_map_control_b0[`CH3_GTTXRESET];
    assign b0gt2_txelecidle_in     = cfg_phy_mem_map_control_b0[`CH3_TXELECIDLE]; //Not Connected, If connected then sync to TXUSRCLK2
    assign b0gt2_txprbssel_in      = b0gt2_txprbssel_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_txprbsforceerr_in = b0gt2_txprbsforceerr_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_txdiffctrl_in     = b0gt2_txdiffctrl_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_txinhibit_in      = b0gt2_txinhibit_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_txpcsreset_in     = cfg_phy_mem_map_control_b0[`CH3_TXPCSRESET];
    assign b0gt2_txpmareset_in     = cfg_phy_mem_map_control_b0[`CH3_TXPMARESET];
    assign b0gt2_txpolarity_in     = b0gt2_txpolarity_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_tx8b10ben_in      = b0gt2_tx8b10ben_in_sync; //Sync to TXUSRCLK2
    assign b0gt2_rxuserrdy_in      = cfg_phy_mem_map_control_b0[`CH3_RXUSERRDY];
    assign b0gt2_txuserrdy_in      = cfg_phy_mem_map_control_b0[`CH3_TXUSERRDY];

    //Status Assignments
    assign cfg_phy_mem_map_status_b0[`CH3_TXRESETDONE]        =  b0gt2_txresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_TXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH3_TXGTPOWERGOOD]      =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH3_RXRESETDONE]        =  b0gt2_rxresetdone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_RXPMARESETDONE]     =  1'b1; //Not Available
    assign cfg_phy_mem_map_status_b0[`CH3_DRPDO]              =  DRP_Status_b0gt2[15:0];
    assign cfg_phy_mem_map_status_b0[`CH3_DRPRDY]             =  DRP_Status_b0gt2[16];
 
    assign cfg_phy_mem_map_status_b0[`CH3_DRPBUSY]            =  DRP_Status_b0gt2[17];
//    assign cfg_phy_mem_map_status_b0[`CH3_TXPHALIGNDONE]      =  b0gt2_txfsmresetdone_out_sync;//_txphaligndone_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_TXPHINITDONE]       =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH3_TXDLYRESETDONE]     =  1'b0; // Not Available
    assign cfg_phy_mem_map_status_b0[`CH3_TXBUFSTATUS]        =  b0gt2_txbufstatus_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_RXCDRLOCK]          =  b0gt2_rxcdrlock_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_RXPRBSERR]          =  b0gt2_rxprbserr_out_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_RXBUFSTATUS]        =  b0gt2_rxbufstatus_out_sync;
    //Common - For coding simplicity, assigned to all quads.
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPBUSY]             =  DRP_Status_common[17];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPRDY]              =  DRP_Status_common[16];
    assign cfg_phy_mem_map_status_b0[`COMMON_DRPDO]               =  DRP_Status_common[15:0];
    assign cfg_phy_mem_map_status_b0[`QPLLLOCK]                   =  b0gt0_qplllock_in_sync;
    assign cfg_phy_mem_map_status_b0[`QPLL1LOCK]                  =  1'b0; //used in US device
 
//    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_CONFIG_DONE]  =  b0_MMCM_TX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_TXUSRCLK_LOCKED]       =  b0_MMCM_TX_DRP_LOCKED_sync;
//    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_CONFIG_DONE]  =  b0_MMCM_RX_DRP_SRDY;
    assign cfg_phy_mem_map_status_b0[`MMCM_RXUSRCLK_LOCKED]       =  b0_MMCM_RX_DRP_LOCKED_sync;
    assign cfg_phy_mem_map_status_b0[`CH3_SYM_ERR_COUNT]          =  1'b0; // not used in HDMI
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_ZERO]        =  b0_clkdet_stat_tx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_ZERO]        =  b0_clkdet_stat_rx_freq_zero;      
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK]      =  b0_clkdet_stat_tx_refclk_locked;  
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_REFCLK_LOCK_CAP]  =  b0_clkdet_stat_tx_refclk_lock_cap;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ]             =  b0_clkdet_tx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ]             =  b0_clkdet_rx_freq; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_DRU_FREQ]            =  b0_clkdet_dru_freq;
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_TMR_EVENT]        =  b0_clkdet_tx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_TX_FREQ_EVENT]       =  b0_clkdet_tx_freq_evt;
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_TMR_EVENT]        =  b0_clkdet_rx_tmr_evt; 
    assign cfg_phy_mem_map_status_b0[`CLKDET_RX_FREQ_EVENT]       =  b0_clkdet_rx_freq_evt;
	
 
    assign cfg_phy_mem_map_status_b0[`DRU_VERSION]                =  b0gt0_dru_stat_version_sync;

  // ------------------------------------------- Synchronizers ------------------------------------------

  // ---------------------- Synchronizer: Bank 0, GT Channel 0 ------------------------------
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_tx_reset_done_b0gt0inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt0_txresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt0_txresetdone_out_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_reset_done_b0gt0inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt0_rxresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt0_rxresetdone_out_sync)
  );
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_cdrlock_b0gt0inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt0_rxcdrlock_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt0_rxcdrlock_out_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_txbufstatus_out_b0gt0inst (
    .src_clk         (b0gt0_txusrclk2_in        ),
    .src_in          (b0gt0_txbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_txbufstatus_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_txphaligndone_b0gt0inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt0_txphaligndone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt0_txphaligndone_out_sync)
  );
  
//  xpm_cdc_single #(
//    .VERSION        (`XPM_CDC_VERSION       ),
//    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
//    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
//    .SRC_INPUT_REG  (0                      )
//  ) xpm_single_txfsmresetdone_out_b0gt0inst (
//    .src_clk         ( b0gt0_txusrclk2_in    ),
//    .src_in          ( b0gt0_txfsmresetdone_out ),
//    .dest_clk        ( vid_phy_axi4lite_aclk      ),
//    .dest_out        ( b0gt0_txfsmresetdone_out_sync)
//  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_rxbufstatus_out_b0gt0inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt0_rxbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_rxbufstatus_out_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_txpd_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXPD]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txpd_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbssel_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXPRBSSEL]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt0_rxprbssel_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbscntrreset_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXPRBSCNTRESET]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt0_rxprbscntreset_in_sync)
  );

  //Latch the PRBS error after tolerance window is lapsed
  //User has to read PRBS Error Counter value using DRP access from GT (through SW)
  reg [3:0] b0gt0_rxprbserr_out_cntr;
  always@(posedge b0gt0_rxusrclk2_in) begin
    if(b0gt0_rxprbscntreset_in_sync) begin
      b0gt0_rxprbserr_out_latch <= 1'b0;
      b0gt0_rxprbserr_out_cntr  <= 'h0;
    end else begin
      if(b0gt0_rxprbserr_out) begin
        b0gt0_rxprbserr_out_cntr <= b0gt0_rxprbserr_out_cntr + 1'b1;  
      end
      if(&b0gt0_rxprbserr_out_cntr) begin
        b0gt0_rxprbserr_out_latch <= 1'b1;
      end
    end
  end

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_prbserr_out_sync_b0gt0inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt0_rxprbserr_out_latch),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_rxprbserr_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMHFOVRDEN_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXLPMHFOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt0_rxlpmhfovrden_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMLFKLOVRDEN_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXLPMLFKLOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt0_rxlpmlfklovrden_in_sync)
  );

  //xpm_cdc_single #(
  //  .VERSION        (`XPM_CDC_VERSION       ),
  //  .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
  //  .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
  //  .SRC_INPUT_REG  (1                      )
  //) xpm_array_single_RXLPMEN_in_sync_b0gt0inst (
  //  .src_clk         (vid_phy_axi4lite_aclk        ),
  //  .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXLPMEN]),
  //  .dest_clk        (b0gt0_rxusrclk2_in       ),
  //  .dest_out        (b0gt0_rxlpmen_in_sync)
  //);

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXPOLARITY_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_RXPOLARITY]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt0_rxpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSFORCEERR_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXPRBSFORCEERR]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txprbsforceerr_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSSEL_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXPRBSSEL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txprbssel_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (4                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXDIFFCTRL_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXDIFFCTRL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txdiffctrl_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXINHIBIT_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXINHIBIT]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txinhibit_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPOLARITY_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TXPOLARITY]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_txpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TX8B10B_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH1_TX8B10B]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt0_tx8b10ben_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_CPLLLOCK_in_sync_b0gt0inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (lock_from_cpll[0]),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_cplllock_out_sync)
  );

 

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_DRU_ACT_in_sync_b0gt0inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt0_dru_stat_act),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_dru_stat_act_sync)
  );
 
  


  // ---------------------- Synchronizer: Bank 0, GT Channel 1 ------------------------------
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_tx_reset_done_b0gt1inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt1_txresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt1_txresetdone_out_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_reset_done_b0gt1inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt1_rxresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt1_rxresetdone_out_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_cdrlock_b0gt1inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt1_rxcdrlock_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt1_rxcdrlock_out_sync)
  );
  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_txbufstatus_out_b0gt1inst (
    .src_clk         (b0gt0_txusrclk2_in        ),
    .src_in          (b0gt1_txbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt1_txbufstatus_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_txphaligndone_b0gt1inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt1_txphaligndone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt1_txphaligndone_out_sync)
  );
  
//  xpm_cdc_single #(
//    .VERSION        (`XPM_CDC_VERSION       ),
//    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
//    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
//    .SRC_INPUT_REG  (0                      )
//  ) xpm_single_txfsmresetdone_out_b0gt1inst (
//    .src_clk         ( b0gt0_txusrclk2_in    ),
//    .src_in          ( b0gt1_txfsmresetdone_out ),
//    .dest_clk        ( vid_phy_axi4lite_aclk      ),
//    .dest_out        ( b0gt1_txfsmresetdone_out_sync)
//  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_rxbufstatus_out_b0gt1inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt1_rxbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt1_rxbufstatus_out_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_txpd_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXPD]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txpd_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbssel_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXPRBSSEL]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt1_rxprbssel_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbscntrreset_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXPRBSCNTRESET]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt1_rxprbscntreset_in_sync)
  );

  //Latch the PRBS error after tolerance window is lapsed
  //User has to read PRBS Error Counter value using DRP access from GT (through SW)
  reg [3:0] b0gt1_rxprbserr_out_cntr;
  always@(posedge b0gt0_rxusrclk2_in) begin
    if(b0gt1_rxprbscntreset_in_sync) begin
      b0gt1_rxprbserr_out_latch <= 1'b0;
      b0gt1_rxprbserr_out_cntr  <= 'h0;
    end else begin
      if(b0gt1_rxprbserr_out) begin
        b0gt1_rxprbserr_out_cntr <= b0gt1_rxprbserr_out_cntr + 1'b1;  
      end
      if(&b0gt1_rxprbserr_out_cntr) begin
        b0gt1_rxprbserr_out_latch <= 1'b1;
      end
    end
  end

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_prbserr_out_sync_b0gt1inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt1_rxprbserr_out_latch),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt1_rxprbserr_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMHFOVRDEN_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXLPMHFOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt1_rxlpmhfovrden_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMLFKLOVRDEN_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXLPMLFKLOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt1_rxlpmlfklovrden_in_sync)
  );

  //xpm_cdc_single #(
  //  .VERSION        (`XPM_CDC_VERSION       ),
  //  .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
  //  .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
  //  .SRC_INPUT_REG  (1                      )
  //) xpm_array_single_RXLPMEN_in_sync_b0gt1inst (
  //  .src_clk         (vid_phy_axi4lite_aclk        ),
  //  .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXLPMEN]),
  //  .dest_clk        (b0gt0_rxusrclk2_in       ),
  //  .dest_out        (b0gt1_rxlpmen_in_sync)
  //);

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXPOLARITY_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_RXPOLARITY]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt1_rxpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSFORCEERR_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXPRBSFORCEERR]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txprbsforceerr_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSSEL_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXPRBSSEL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txprbssel_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (4                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXDIFFCTRL_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXDIFFCTRL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txdiffctrl_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXINHIBIT_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXINHIBIT]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txinhibit_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPOLARITY_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TXPOLARITY]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_txpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TX8B10B_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH2_TX8B10B]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt1_tx8b10ben_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_CPLLLOCK_in_sync_b0gt1inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (lock_from_cpll[1]),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt1_cplllock_out_sync)
  );

 

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_DRU_ACT_in_sync_b0gt1inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt1_dru_stat_act),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt1_dru_stat_act_sync)
  );
  


  // ---------------------- Synchronizer: Bank 0, GT Channel 2 ------------------------------
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_tx_reset_done_b0gt2inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt2_txresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt2_txresetdone_out_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_reset_done_b0gt2inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt2_rxresetdone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt2_rxresetdone_out_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_cdrlock_b0gt2inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0gt2_rxcdrlock_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt2_rxcdrlock_out_sync)
  );
  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_txbufstatus_out_b0gt2inst (
    .src_clk         (b0gt0_txusrclk2_in        ),
    .src_in          (b0gt2_txbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt2_txbufstatus_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_txphaligndone_b0gt2inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0gt2_txphaligndone_out ),
    .dest_clk        ( vid_phy_axi4lite_aclk      ),
    .dest_out        ( b0gt2_txphaligndone_out_sync)
  );
  
//  xpm_cdc_single #(
//    .VERSION        (`XPM_CDC_VERSION       ),
//    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
//    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
//    .SRC_INPUT_REG  (0                      )
//  ) xpm_single_txfsmresetdone_out_b0gt2inst (
//    .src_clk         ( b0gt0_txusrclk2_in    ),
//    .src_in          ( b0gt2_txfsmresetdone_out ),
//    .dest_clk        ( vid_phy_axi4lite_aclk      ),
//    .dest_out        ( b0gt2_txfsmresetdone_out_sync)
//  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_rxbufstatus_out_b0gt2inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt2_rxbufstatus_out),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt2_rxbufstatus_out_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (2                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_txpd_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXPD]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txpd_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbssel_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXPRBSSEL]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt2_rxprbssel_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_prbscntrreset_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXPRBSCNTRESET]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt2_rxprbscntreset_in_sync)
  );

  //Latch the PRBS error after tolerance window is lapsed
  //User has to read PRBS Error Counter value using DRP access from GT (through SW)
  reg [3:0] b0gt2_rxprbserr_out_cntr;
  always@(posedge b0gt0_rxusrclk2_in) begin
    if(b0gt2_rxprbscntreset_in_sync) begin
      b0gt2_rxprbserr_out_latch <= 1'b0;
      b0gt2_rxprbserr_out_cntr  <= 'h0;
    end else begin
      if(b0gt2_rxprbserr_out) begin
        b0gt2_rxprbserr_out_cntr <= b0gt2_rxprbserr_out_cntr + 1'b1;  
      end
      if(&b0gt2_rxprbserr_out_cntr) begin
        b0gt2_rxprbserr_out_latch <= 1'b1;
      end
    end
  end

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_prbserr_out_sync_b0gt2inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt2_rxprbserr_out_latch),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt2_rxprbserr_out_sync)
  );


  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMHFOVRDEN_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXLPMHFOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt2_rxlpmhfovrden_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXLPMLFKLOVRDEN_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXLPMLFKLOVRDEN]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt2_rxlpmlfklovrden_in_sync)
  );

  //xpm_cdc_single #(
  //  .VERSION        (`XPM_CDC_VERSION       ),
  //  .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
  //  .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
  //  .SRC_INPUT_REG  (1                      )
  //) xpm_array_single_RXLPMEN_in_sync_b0gt2inst (
  //  .src_clk         (vid_phy_axi4lite_aclk        ),
  //  .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXLPMEN]),
  //  .dest_clk        (b0gt0_rxusrclk2_in       ),
  //  .dest_out        (b0gt2_rxlpmen_in_sync)
  //);

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_RXPOLARITY_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_RXPOLARITY]),
    .dest_clk        (b0gt0_rxusrclk2_in       ),
    .dest_out        (b0gt2_rxpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSFORCEERR_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXPRBSFORCEERR]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txprbsforceerr_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (3                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPRBSSEL_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXPRBSSEL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txprbssel_in_sync)
  );

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          (4                      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXDIFFCTRL_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXDIFFCTRL]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txdiffctrl_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXINHIBIT_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXINHIBIT]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txinhibit_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TXPOLARITY_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TXPOLARITY]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_txpolarity_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (1                      )
  ) xpm_array_single_TX8B10B_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (cfg_phy_mem_map_control_b0[`CH3_TX8B10B]),
    .dest_clk        (b0gt0_txusrclk2_in       ),
    .dest_out        (b0gt2_tx8b10ben_in_sync)
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_CPLLLOCK_in_sync_b0gt2inst (
    .src_clk         (vid_phy_axi4lite_aclk        ),
    .src_in          (lock_from_cpll[2]),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt2_cplllock_out_sync)
  );

 
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_DRU_ACT_in_sync_b0gt2inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt2_dru_stat_act),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt2_dru_stat_act_sync)
  );
 
  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .WIDTH          ( 8      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_DRU_VERSION_in_sync_b0gt0inst (
    .src_clk         (b0gt0_rxusrclk2_in        ),
    .src_in          (b0gt0_dru_stat_version),
    .dest_clk        (vid_phy_axi4lite_aclk       ),
    .dest_out        (b0gt0_dru_stat_version_sync)
  );  

  // ---------------------- Synchronizer: User Clocking ----------------------------
  assign b0gt0_qplllock_in = clk_qpll_locked;
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_array_single_QPLLLOCK_in_sync_inst (
    .src_clk         (vid_phy_axi4lite_aclk ),
    .src_in          (b0gt0_qplllock_in     ),
    .dest_clk        (vid_phy_axi4lite_aclk ),
    .dest_out        (b0gt0_qplllock_in_sync)
  );
  // for HDMI
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_tx_mmcm_drp_locked_b0_inst (
    .src_clk         ( b0gt0_txusrclk2_in    ),
    .src_in          ( b0_MMCM_TX_DRP_LOCKED ),
    .dest_clk        ( vid_phy_axi4lite_aclk ),
    .dest_out        ( b0_MMCM_TX_DRP_LOCKED_sync )
  );

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_rx_mmcm_drp_locked_b0_inst (
    .src_clk         ( b0gt0_rxusrclk2_in    ),
    .src_in          ( b0_MMCM_RX_DRP_LOCKED ),
    .dest_clk        ( vid_phy_axi4lite_aclk ),
    .dest_out        ( b0_MMCM_RX_DRP_LOCKED_sync )
  );
  
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_obuftds_tx_en_b0_inst (
    .src_clk         ( vid_phy_axi4lite_aclk    ),
    .src_in          ( b0_OBUFTDS_TX_EN ),
    .dest_clk        ( b0gt0_txusrclk2_in ),
    .dest_out        ( b0_OBUFTDS_TX_EN_sync )
  );
  
  
  assign cfg_phy_mem_map_status_b0[`CH1_CPLLLOCK] =  b0gt0_cplllock_out_sync;
  assign cfg_phy_mem_map_status_b0[`CH2_CPLLLOCK] =  b0gt1_cplllock_out_sync;
  assign cfg_phy_mem_map_status_b0[`CH3_CPLLLOCK] =  b0gt2_cplllock_out_sync;


  // ----------------------------------- Tx Sideband Connections (Uses AXI4Lite Clock) -----------------------------

 

   
  // Control Inputs - Tx DP does not use any link layer driven control
  assign vid_phy_control_sb_tx_tready  = 1'b1;

  // Status Outputs - Will be used by link layer
  assign vid_phy_status_sb_tx_tvalid   = 1'b1;

//  assign vid_phy_status_sb_tx_tdata[0] = b0gt0_txfsmresetdone_out_sync & b0gt1_txfsmresetdone_out_sync & b0gt2_txfsmresetdone_out_sync;
  assign vid_phy_status_sb_tx_tdata[0] = done_from_txaln & b0gt0_txresetdone_out_sync & b0gt1_txresetdone_out_sync & b0gt2_txresetdone_out_sync;


  assign vid_phy_status_sb_tx_tdata[1] = b0_MMCM_TX_DRP_LOCKED_sync; 
 


  // ----------------------------------- Rx Sideband Connections (Uses AXI4Lite Clock) -----------------------------

  
  
  
  // Control Inputs - Driven from Link Layer to add protocol specific control
  assign vid_phy_control_sb_rx_tready   = 1'b1;
//  assign i_dp_train_itr_reset           = vid_phy_control_sb_rx_tdata[0] & vid_phy_control_sb_rx_tvalid; //resets for every TP lane set access
//  assign i_dp_start_of_tp1_reset        = vid_phy_control_sb_rx_tdata[1] & vid_phy_control_sb_rx_tvalid; //resets GT for every start of TP1 event

  // Status Outputs - Will be used by link layer
  assign vid_phy_status_sb_rx_tvalid    = 1'b1;

  assign vid_phy_status_sb_rx_tdata[0]  = b0gt0_rxresetdone_out_sync & b0gt1_rxresetdone_out_sync & b0gt2_rxresetdone_out_sync;


  assign vid_phy_status_sb_rx_tdata[1]  = b0_MMCM_RX_DRP_LOCKED_sync;  
  
  

endmodule
