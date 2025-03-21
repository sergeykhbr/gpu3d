///////////////////////////////////////////////////////////////////////////////
// file: clk_wiz_v2_1.v
// 
// (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
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
// 
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
// Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
// Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// CLK_OUT1   100.000      0.000    50.000      130.958     98.575
//
//----------------------------------------------------------------------------
// Input Clock   Input Freq (MHz)   Input Jitter (UI)
//----------------------------------------------------------------------------
// primary         100.000            0.010

`include "vid_phy_controller_v2_2_2_defs.v"
`timescale 1ps/1ps
module exdes_vid_phy_controller_0_CLOCK_MODULE_8series #
(
    parameter   MULT            =   2,
    parameter   DIVIDE          =   2,
    parameter   CLK_PERIOD      =   6.4,
    parameter   OUT0_DIVIDE     =   2,
    parameter   OUT1_DIVIDE     =   2,
    parameter   OUT2_DIVIDE     =   2,
 
    parameter   OUT3_DIVIDE     =   2,    
    parameter   INST_DIRECTION  =   0  //Instance Direction TX:0 RX:1    
)
 (// Clock in ports
  input         CLK_IN,
  // Clock out ports
  output        CLK0_OUT,
  output        CLK1_OUT,
  output        CLK2_OUT,
  output        CLK3_OUT,
  //DRP
  input         DCLK,
  input         DWE,
  input         DEN,
  input [6:0]   DADDR,
  input [15:0]  DI,
  output        DRDY,
  output [15:0] DO,
  // Status and control signals
  input         MMCM_RESET_IN,
  input         MMCM_PWRDN_IN,
  output        MMCM_LOCKED_OUT
 );

  // Input buffering
  //------------------------------------
  BUFG clkin1_buf
  (.O (clkin1),
   .I (CLK_IN));

  // Clocking primitive
  //------------------------------------
  // Instantiation of the MMCM primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        clkfbout;
  wire        clkfbout_buf;
  wire        clkfboutb_unused;
  wire        clkout0b_unused;
  wire        clkout1;
  wire        clkout1b_unused;
  wire        clkout2;
  wire        clkout2b_unused;
  wire        clkout3;
  wire        clkout3b_unused;
  wire        clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        mmcm_locked;

  MMCME3_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (DIVIDE),
    .CLKFBOUT_MULT_F      (MULT),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (OUT0_DIVIDE),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (CLK_PERIOD),
    .CLKOUT1_DIVIDE       (OUT1_DIVIDE),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKOUT2_DIVIDE       (OUT2_DIVIDE),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  ("FALSE"),
    .CLKOUT3_DIVIDE       (OUT3_DIVIDE),
    .CLKOUT3_PHASE        (0.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKOUT3_USE_FINE_PS  ("FALSE"),
    .REF_JITTER1          (0.010))
  mmcm_adv_inst
    // Output clocks
   (.CLKFBOUT            (clkfbout),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clkout0),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clkout1),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout),
    .CLKIN1              (clkin1),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (DADDR),
    .DCLK                (DCLK),
    .DEN                 (DEN),
    .DI                  (DI),
    .DO                  (DO),
    .DRDY                (DRDY),
    .DWE                 (DWE),
    .CDDCDONE            (),
    .CDDCREQ             (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (mmcm_locked),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (MMCM_PWRDN_IN),
    .RST                 (MMCM_RESET_IN));

    assign MMCM_LOCKED_OUT = mmcm_locked;

  // Output buffering
  //-----BUFG in feedback not necessary as a known phase relationship is not needed between the outclk and the usrclk------
  //BUFG clkf_buf
  // (.O (clkfbout_buf),
  //  .I (clkfbout));


 
generate
    assign CLK0_OUT = 1'b0;
    assign CLK3_OUT = 1'b0;
	if (INST_DIRECTION == 0) //TX
        begin 
    wire tx_mmcm_clkout2_bufg_i;
    wire tx_mmcm_locked_sync;
    
    BUFG tx_clkout2_bufg
    (
        .O  (tx_mmcm_clkout2_bufg_i),
        .I  (clkout2)
    );

    xpm_cdc_single #(
     .VERSION        (`XPM_CDC_VERSION       ),
     .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
     .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
     .SRC_INPUT_REG  (0                      )
    ) tx_mmcm_locked_xpm 
    (
      .src_clk  (1'b0),
      .src_in   (mmcm_locked),
      .dest_clk (tx_mmcm_clkout2_bufg_i),
      .dest_out (tx_mmcm_locked_sync)
    );
    
            assign CLK1_OUT = clkout1;
    BUFGCE 
    #(
      .CE_TYPE          ("SYNC"),
      .IS_CE_INVERTED   (1'b0),  
      .IS_I_INVERTED    (1'b0)   
    )
    tx_clkout2_buf 
    (
      .CE   (tx_mmcm_locked_sync),
      .I    (clkout2),       
      .O    (CLK2_OUT)       
    );
        end
    else
        begin
    wire rx_mmcm_clkout2_bufg_i;
    wire rx_mmcm_locked_sync;
    
    BUFG rx_clkout2_bufg
    (
        .O  (rx_mmcm_clkout2_bufg_i),
        .I  (clkout2)
    );

    xpm_cdc_single #(
     .VERSION        (`XPM_CDC_VERSION       ),
     .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
     .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
     .SRC_INPUT_REG  (0                      )
    ) rx_mmcm_locked_xpm 
    (
      .src_clk  (1'b0),
      .src_in   (mmcm_locked),
      .dest_clk (rx_mmcm_clkout2_bufg_i),
      .dest_out (rx_mmcm_locked_sync)
    );
    
    BUFGCE 
    #(
      .CE_TYPE          ("SYNC"),
      .IS_CE_INVERTED   (1'b0),  
      .IS_I_INVERTED    (1'b0)   
    )
    rx_clkout1_buf 
    (
      .CE   (rx_mmcm_locked_sync),
      .I    (clkout1),       
      .O    (CLK1_OUT)       
    );
    BUFGCE 
    #(
      .CE_TYPE          ("SYNC"),
      .IS_CE_INVERTED   (1'b0),  
      .IS_I_INVERTED    (1'b0)   
    )
    rx_clkout2_buf 
    (
      .CE   (rx_mmcm_locked_sync),
      .I    (clkout2),       
      .O    (CLK2_OUT)       
    );
        end
endgenerate 
endmodule

