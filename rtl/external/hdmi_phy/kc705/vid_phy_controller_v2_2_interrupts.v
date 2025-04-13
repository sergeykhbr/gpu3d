///////////////////////////////////////////////////////////////////////////////
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


`timescale 1ns / 1ps

//***********************************Entity Declaration*******************************

module vid_phy_controller_v2_2_2_interrupts
(
  input  wire        clk,
  input  wire        rst_n,
  //ISR
  input  wire        wr_en_2_isr,
  input  wire        wr_en_2_ier,
  input  wire        wr_en_2_idr,
  input  wire [31:0] isr_write, 
  output wire [31:0] isr_read, 
  input  wire [31:0] ier, 
  input  wire [31:0] idr, 
  output wire [31:0] imr, 
  //Events
  input  wire        gt_status_tx_resetdone_updated,
  input  wire        gt_status_rx_resetdone_updated,
  input  wire        gt_status_cpll_lock_updated,
  input  wire        gt_status_qpll_lock_updated,
  input  wire        gt_status_tx_alignment_updated,
  input  wire        gt_status_qpll1_lock_updated,
  input  wire        mmcm_tx_usrclk_lock_event_updated,
  input  wire        mmcm_rx_usrclk_lock_event_updated,

  // HDMI
  input  wire        clkdet_tx_timer_event_updated,
  input  wire        clkdet_tx_freq_event_updated,
  input  wire        clkdet_rx_timer_event_updated,
  input  wire        clkdet_rx_freq_event_updated,

  output reg         irq
);

reg r_gt_mask_tx_resetdone_updated;
reg r_gt_mask_rx_resetdone_updated;
reg r_gt_mask_cpll_lock_updated;
reg r_gt_mask_qpll_lock_updated;
reg r_gt_mask_tx_alignment_updated;
reg r_gt_mask_qpll1_lock_updated;
reg r_mmcm_mask_tx_usrclk_lock_updated;
reg r_mmcm_mask_rx_usrclk_lock_updated;

	// HDMI
reg r_clkdet_mask_tx_timer_event_updated;
reg r_clkdet_mask_tx_freq_event_updated;
reg r_clkdet_mask_rx_timer_event_updated;
reg r_clkdet_mask_rx_freq_event_updated;


reg r_gt_status_tx_resetdone_updated_sticky;
reg r_gt_status_rx_resetdone_updated_sticky;
reg r_gt_status_cpll_lock_updated_sticky;
reg r_gt_status_qpll_lock_updated_sticky;
reg r_gt_status_tx_alignment_updated_sticky;
reg r_gt_status_qpll1_lock_updated_sticky;
reg r_mmcm_status_tx_usrclk_lock_updated_sticky;
reg r_mmcm_status_rx_usrclk_lock_updated_sticky;

	// HDMI
reg r_clkdet_status_tx_timer_event_updated_sticky;
reg r_clkdet_status_tx_freq_event_updated_sticky;
reg r_clkdet_status_rx_timer_event_updated_sticky;
reg r_clkdet_status_rx_freq_event_updated_sticky;


/**
 * IRQ Timing Registers
 **/
always@(posedge clk) begin
    if (!rst_n)
        irq <= 1'b0;
    else
        irq <= (
            (~r_gt_mask_tx_resetdone_updated & r_gt_status_tx_resetdone_updated_sticky) |
            (~r_gt_mask_rx_resetdone_updated & r_gt_status_rx_resetdone_updated_sticky) |
            (~r_gt_mask_cpll_lock_updated & r_gt_status_cpll_lock_updated_sticky) |
            (~r_gt_mask_qpll_lock_updated & r_gt_status_qpll_lock_updated_sticky) |
            (~r_gt_mask_tx_alignment_updated & r_gt_status_tx_alignment_updated_sticky) |
            (~r_mmcm_mask_tx_usrclk_lock_updated & r_mmcm_status_tx_usrclk_lock_updated_sticky) |
            (~r_mmcm_mask_rx_usrclk_lock_updated & r_mmcm_status_rx_usrclk_lock_updated_sticky) |
	    (~r_clkdet_mask_tx_timer_event_updated & r_clkdet_status_tx_timer_event_updated_sticky) |
	    (~r_clkdet_mask_tx_freq_event_updated & r_clkdet_status_tx_freq_event_updated_sticky) |
	    (~r_clkdet_mask_rx_timer_event_updated & r_clkdet_status_rx_timer_event_updated_sticky) |
	    (~r_clkdet_mask_rx_freq_event_updated & r_clkdet_status_rx_freq_event_updated_sticky) |
            (~r_gt_mask_qpll1_lock_updated & r_gt_status_qpll1_lock_updated_sticky)
        );
end

assign imr = { 
               r_clkdet_mask_rx_timer_event_updated,
               r_clkdet_mask_tx_timer_event_updated,
               19'b0,
               r_mmcm_mask_rx_usrclk_lock_updated, 
               r_mmcm_mask_tx_usrclk_lock_updated, 
               1'b0,
	       r_clkdet_mask_rx_freq_event_updated,
               r_clkdet_mask_tx_freq_event_updated,
               r_gt_mask_qpll1_lock_updated, 
               r_gt_mask_tx_alignment_updated, 
               r_gt_mask_qpll_lock_updated, 
               r_gt_mask_cpll_lock_updated, 
               r_gt_mask_rx_resetdone_updated, 
               r_gt_mask_tx_resetdone_updated
             };

assign isr_read = { 
               r_clkdet_status_rx_timer_event_updated_sticky,
               r_clkdet_status_tx_timer_event_updated_sticky,
               19'b0,
               r_mmcm_status_rx_usrclk_lock_updated_sticky, 
               r_mmcm_status_tx_usrclk_lock_updated_sticky, 
               1'b0,
	       r_clkdet_status_rx_freq_event_updated_sticky,
               r_clkdet_status_tx_freq_event_updated_sticky,
               r_gt_status_qpll1_lock_updated_sticky, 
               r_gt_status_tx_alignment_updated_sticky, 
               r_gt_status_qpll_lock_updated_sticky, 
               r_gt_status_cpll_lock_updated_sticky, 
               r_gt_status_rx_resetdone_updated_sticky, 
               r_gt_status_tx_resetdone_updated_sticky
             };

//--------------------------------------------- GT Tx Reset Done Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_tx_resetdone_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_tx_resetdone_updated_sticky <= (r_gt_status_tx_resetdone_updated_sticky & ~isr_write[0]) | gt_status_tx_resetdone_updated;
  end else begin
    r_gt_status_tx_resetdone_updated_sticky <= r_gt_status_tx_resetdone_updated_sticky | gt_status_tx_resetdone_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_tx_resetdone_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[0]) begin
    r_gt_mask_tx_resetdone_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[0]) begin
    r_gt_mask_tx_resetdone_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


//--------------------------------------------- GT Rx Reset Done Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_rx_resetdone_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_rx_resetdone_updated_sticky <= (r_gt_status_rx_resetdone_updated_sticky & ~isr_write[1]) | gt_status_rx_resetdone_updated;
  end else begin
    r_gt_status_rx_resetdone_updated_sticky <= r_gt_status_rx_resetdone_updated_sticky | gt_status_rx_resetdone_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_rx_resetdone_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[1]) begin
    r_gt_mask_rx_resetdone_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[1]) begin
    r_gt_mask_rx_resetdone_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


//----------------------------------------------------- CPLL/PLL0 Lock Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_cpll_lock_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_cpll_lock_updated_sticky <= (r_gt_status_cpll_lock_updated_sticky & ~isr_write[2]) | gt_status_cpll_lock_updated;
  end else begin
    r_gt_status_cpll_lock_updated_sticky <= r_gt_status_cpll_lock_updated_sticky | gt_status_cpll_lock_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_cpll_lock_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[2]) begin
    r_gt_mask_cpll_lock_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[2]) begin
    r_gt_mask_cpll_lock_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


//----------------------------------------------------- QPLL0 Lock Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_qpll_lock_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_qpll_lock_updated_sticky <= (r_gt_status_qpll_lock_updated_sticky & ~isr_write[3]) | gt_status_qpll_lock_updated;
  end else begin
    r_gt_status_qpll_lock_updated_sticky <= r_gt_status_qpll_lock_updated_sticky | gt_status_qpll_lock_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_qpll_lock_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[3]) begin
    r_gt_mask_qpll_lock_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[3]) begin
    r_gt_mask_qpll_lock_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end

//----------------------------------------------------- Tx Alignment Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_tx_alignment_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_tx_alignment_updated_sticky <= (r_gt_status_tx_alignment_updated_sticky & ~isr_write[4]) | gt_status_tx_alignment_updated;
  end else begin
    r_gt_status_tx_alignment_updated_sticky <= r_gt_status_tx_alignment_updated_sticky | gt_status_tx_alignment_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_tx_alignment_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[4]) begin
    r_gt_mask_tx_alignment_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[4]) begin
    r_gt_mask_tx_alignment_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end

//----------------------------------------------------- QPLL1 Lock Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_status_qpll1_lock_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_gt_status_qpll1_lock_updated_sticky <= (r_gt_status_qpll1_lock_updated_sticky & ~isr_write[5]) | gt_status_qpll1_lock_updated;
  end else begin
    r_gt_status_qpll1_lock_updated_sticky <= r_gt_status_qpll1_lock_updated_sticky | gt_status_qpll1_lock_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_gt_mask_qpll1_lock_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[5]) begin
    r_gt_mask_qpll1_lock_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[5]) begin
    r_gt_mask_qpll1_lock_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


// HDMI
//--------------------------------------------- CLKDET TX Frequency Event Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_status_tx_freq_event_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_clkdet_status_tx_freq_event_updated_sticky <= (r_clkdet_status_tx_freq_event_updated_sticky & ~isr_write[6]) | clkdet_tx_freq_event_updated;
  end else begin
    r_clkdet_status_tx_freq_event_updated_sticky <= r_clkdet_status_tx_freq_event_updated_sticky | clkdet_tx_freq_event_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_mask_tx_freq_event_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[6]) begin
    r_clkdet_mask_tx_freq_event_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[6]) begin
    r_clkdet_mask_tx_freq_event_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


//--------------------------------------------- CLKDET RX Frequency Event Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_status_rx_freq_event_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_clkdet_status_rx_freq_event_updated_sticky <= (r_clkdet_status_rx_freq_event_updated_sticky & ~isr_write[7]) | clkdet_rx_freq_event_updated;
  end else begin
    r_clkdet_status_rx_freq_event_updated_sticky <= r_clkdet_status_rx_freq_event_updated_sticky | clkdet_rx_freq_event_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_mask_rx_freq_event_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[7]) begin
    r_clkdet_mask_rx_freq_event_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[7]) begin
    r_clkdet_mask_rx_freq_event_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end

//----------------------------------------------------- TX MMCM USRCLK Lock Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_mmcm_status_tx_usrclk_lock_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_mmcm_status_tx_usrclk_lock_updated_sticky <= (r_mmcm_status_tx_usrclk_lock_updated_sticky & ~isr_write[9]) | mmcm_tx_usrclk_lock_event_updated;
  end else begin
    r_mmcm_status_tx_usrclk_lock_updated_sticky <= r_mmcm_status_tx_usrclk_lock_updated_sticky | mmcm_tx_usrclk_lock_event_updated;
  end
end
always@(posedge clk) begin
  if(!rst_n) begin
    r_mmcm_mask_tx_usrclk_lock_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[9]) begin
    r_mmcm_mask_tx_usrclk_lock_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[9]) begin
    r_mmcm_mask_tx_usrclk_lock_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end
//----------------------------------------------------- RX MMCM USRCLK Lock Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_mmcm_status_rx_usrclk_lock_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_mmcm_status_rx_usrclk_lock_updated_sticky <= (r_mmcm_status_rx_usrclk_lock_updated_sticky & ~isr_write[10]) | mmcm_rx_usrclk_lock_event_updated;
  end else begin
    r_mmcm_status_rx_usrclk_lock_updated_sticky <= r_mmcm_status_rx_usrclk_lock_updated_sticky | mmcm_rx_usrclk_lock_event_updated;
  end
end
always@(posedge clk) begin
  if(!rst_n) begin
    r_mmcm_mask_rx_usrclk_lock_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[10]) begin
    r_mmcm_mask_rx_usrclk_lock_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[10]) begin
    r_mmcm_mask_rx_usrclk_lock_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end

//--------------------------------------------- CLKDET TX Timer Event Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_status_tx_timer_event_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_clkdet_status_tx_timer_event_updated_sticky <= (r_clkdet_status_tx_timer_event_updated_sticky & ~isr_write[30]) | clkdet_tx_timer_event_updated;
  end else begin
    r_clkdet_status_tx_timer_event_updated_sticky <= r_clkdet_status_tx_timer_event_updated_sticky | clkdet_tx_timer_event_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_mask_tx_timer_event_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[30]) begin
    r_clkdet_mask_tx_timer_event_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[30]) begin
    r_clkdet_mask_tx_timer_event_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


//--------------------------------------------- CLKDET RX Timer Event Updated -------------------------------------------------------
always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_status_rx_timer_event_updated_sticky <= 1'b0;
  end else if(wr_en_2_isr) begin
    r_clkdet_status_rx_timer_event_updated_sticky <= (r_clkdet_status_rx_timer_event_updated_sticky & ~isr_write[31]) | clkdet_rx_timer_event_updated;
  end else begin
    r_clkdet_status_rx_timer_event_updated_sticky <= r_clkdet_status_rx_timer_event_updated_sticky | clkdet_rx_timer_event_updated;
  end
end

always@(posedge clk) begin
  if(!rst_n) begin
    r_clkdet_mask_rx_timer_event_updated <= {1{1'b1}}; //Masked on Reset
  end else if (wr_en_2_ier & ier[31]) begin
    r_clkdet_mask_rx_timer_event_updated <= {1{1'b0}}; //To Enable is to Unmask
  end else if (wr_en_2_idr & idr[31]) begin
    r_clkdet_mask_rx_timer_event_updated <= {1{1'b1}}; //To Disable is to Unmask
  end
end


endmodule



