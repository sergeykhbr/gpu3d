///////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2010-2015 Xilinx, Inc. All rights reserved.
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

`include "vid_phy_controller_v2_2_2_defs.v"
`timescale 1ns / 1ps

//***********************************Entity Declaration*******************************

module vid_phy_controller_v2_2_2_drp_control_hdmi #
(
  parameter   DRP_ADDR_WIDTH    =   9
)
(
  input  wire        Config_Clk,
  input  wire        Config_Rst,
  input  wire [31:0] DRP_Config,
  output wire [31:0] DRP_Status,
  input  wire        drp_txn_available,
  input  wire        drp_rsp_read,

  input  wire                       DRPCLK,
  input  wire                       DRPBUSY,
  output reg                        DRPEN,       
  output reg                        DRPWE,       
  output reg  [DRP_ADDR_WIDTH-1:0]  DRPADDR,       
  output reg  [15:0]                DRPDI,       
  input  wire [15:0]                DRPDO,       
  input  wire                       DRPRDY       
);

localparam pWAIT_FOR_TXN_REQUEST = 3'b001;
localparam pCHECK_FOR_BUSY       = 3'b010;
localparam pWAIT_FOR_DRP_RDY     = 3'b100;

reg [2:0] drp_state;

  // --------------------------- Async Reset from system -------------------------------------
  wire RST;
  xpm_cdc_async_rst #(
    .RST_ACTIVE_HIGH  ( 1 )
  ) xpm_single_drp_reset_RST_inst (
    .src_arst        ( Config_Rst ),
    .dest_clk        ( DRPCLK ),
    .dest_arst       ( RST )
  );

  // --------------------------- Register DRP Config data with DRPCLK -------------------------------------
reg [31:0]  DRP_Config_Reg; 
wire [31:0] DRP_Config_Reg_sync; 
reg [31:0]  DRP_Status_Reg; 
reg         DRP_Txn_Avail_Toggle = 1'b0; 
wire        DRP_Txn_Avail_Toggle_sync; 
reg         DRP_Txn_Avail_Toggle_q = 1'b0; 
wire        DRP_Txn_Avail_Toggle_pulse; 
reg         drp_txn_available_del;
reg         DRP_Status_sync_rdy_del;
wire [31:0] DRP_Status_sync;
reg         DRP_Status_Rdy;

// Delay TXN available
// The AXI4lite controller sets the txn one cycle before the actual config data is available on the bus. 
// To solve this issue, the txn signal is delayed for one clock.
  always@(posedge Config_Clk)
  begin
    drp_txn_available_del <= drp_txn_available;
  end

// Toggle txn and latch data
  always@(posedge Config_Clk) begin: process_latch_drp_txn
    if(drp_txn_available_del) begin
      DRP_Txn_Avail_Toggle  <= ~DRP_Txn_Avail_Toggle;
      DRP_Config_Reg        <= DRP_Config;
    end
  end

  // --------------------------- Create a DRP Tx Avail pulse in DRPCLK -------------------------------------
/*
  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_DRP_Txn_Avail_Toggle_inst (
    .src_clk         ( Config_Clk ),
    .src_in          ( DRP_Txn_Avail_Toggle ),
    .dest_clk        ( DRPCLK ),
    .dest_out        ( DRP_Txn_Avail_Toggle_sync )
  );
*/

// DRP Config sync
/*
  xpm_cdc_handshake #(
    // Module parameters
    .DEST_EXT_HSK   (0),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SIM_ASYNC_RAND (0),
    .SRC_SYNC_FF    (`XPM_CDC_MTBF_FFS      ),
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .WIDTH          (33)
  ) xpm_handshake_DRP_Config_inst (
    // Module ports
    .src_clk            (Config_Clk),
    .src_in             ({DRP_Txn_Avail_Toggle, DRP_Config_Reg}),
    .src_send           (1'b0),  
    .src_rcv            (),
    
    .dest_clk           (DRPCLK),
    .dest_out           ({DRP_Txn_Avail_Toggle_sync, DRP_Config_Reg_sync}),
    .dest_req           (),
    .dest_ack           (1'b0)
  );
*/

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      ),
    .WIDTH          (33)
  ) xpm_handshake_DRP_Config_inst (
    .src_clk         ( Config_Clk ),
    .src_in          ({DRP_Txn_Avail_Toggle, DRP_Config_Reg}),
    .dest_clk        ( DRPCLK ),
    .dest_out        ({DRP_Txn_Avail_Toggle_sync, DRP_Config_Reg_sync})
  );


  always@(posedge DRPCLK) begin: pulse_drp_txn
    DRP_Txn_Avail_Toggle_q <= DRP_Txn_Avail_Toggle_sync;
  end
  assign DRP_Txn_Avail_Toggle_pulse = (DRP_Txn_Avail_Toggle_sync != DRP_Txn_Avail_Toggle_q);

  // --------------------------- Create a DRP Response Read pulse in DRPCLK -------------------------------------
  reg        DRP_Rsp_Rd_Toggle = 1'b0; 
  wire       DRP_Rsp_Rd_Toggle_sync; 
  reg        DRP_Rsp_Rd_Toggle_q = 1'b0; 
  wire       DRP_Rsp_Rd_Toggle_pulse; 
  reg        DRP_Rsp_Rd_Toggle_pulse_cnt; 

  always@(posedge Config_Clk) begin: process_latch_drp_rsp_rd
    if(drp_rsp_read) begin
      DRP_Rsp_Rd_Toggle <= ~DRP_Rsp_Rd_Toggle;
    end
  end

  xpm_cdc_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      )
  ) xpm_single_DRP_Rsp_Rd_Toggle_inst (
    .src_clk         ( Config_Clk ),
    .src_in          ( DRP_Rsp_Rd_Toggle ),
    .dest_clk        ( DRPCLK ),
    .dest_out        ( DRP_Rsp_Rd_Toggle_sync )
  );

  assign DRP_Rsp_Rd_Toggle_pulse = (DRP_Rsp_Rd_Toggle_sync != DRP_Rsp_Rd_Toggle_q);

  // --------------------------- DRP Statemachine -------------------------------------
  always@(posedge DRPCLK) begin
    if(RST) begin
      drp_state  <= pWAIT_FOR_TXN_REQUEST;
      DRP_Status_Reg <= 32'h0;
      DRPEN      <= 1'b0;
      DRPWE      <= 1'b0;
      DRPDI      <= 'h0;
      DRPADDR    <= 'h0;
      DRP_Rsp_Rd_Toggle_q <= 1'b0;
      DRP_Rsp_Rd_Toggle_pulse_cnt <= 1'b0;
    end else begin
      DRP_Rsp_Rd_Toggle_q <= DRP_Rsp_Rd_Toggle_sync;
      if(DRP_Status_Reg[16]==1'b1 && DRP_Rsp_Rd_Toggle_pulse==1'b1) DRP_Rsp_Rd_Toggle_pulse_cnt <= ~DRP_Rsp_Rd_Toggle_pulse_cnt;

      DRPEN     <= 1'b0;
      DRPWE     <= 1'b0;
      DRPDI     <= 'h0;
      DRPADDR   <= 'h0;

      DRP_Status_Reg[17]   <= DRPBUSY;
      
      // DRP state machine

      // Force the DRP state to busy at the start of a new transmit
      if (DRP_Txn_Avail_Toggle_pulse==1'b1)
      begin 
        DRP_Status_Reg[16]  <= 1'b0; //Clear ready status for new txn
        drp_state       <= pCHECK_FOR_BUSY;
      end

      // Decode state
      else
      begin
        case(drp_state)
          pWAIT_FOR_TXN_REQUEST: begin
            //DRP_Status[16]   <= 1'b0; //Clear ready status for new txn
           // if(DRP_Txn_Avail_Toggle_pulse==1'b1) begin
            //  DRP_Rsp_Rd_Toggle_pulse_cnt <= 1'b0;
            //  drp_state <= pCHECK_FOR_BUSY;
            //end
            drp_state  <= pWAIT_FOR_TXN_REQUEST;    // Endless loop
          end

          pCHECK_FOR_BUSY: begin
//            if(DRPBUSY!=1'b1 && DRPRDY==1'b1) begin
            if(DRPBUSY!=1'b1) begin
              drp_state <= pWAIT_FOR_DRP_RDY;
              DRPEN     <= DRP_Config_Reg_sync[12];
              DRPWE     <= DRP_Config_Reg_sync[13];
              DRPDI     <= DRP_Config_Reg_sync[31:16];
              DRPADDR   <= DRP_Config_Reg_sync[DRP_ADDR_WIDTH-1:0];
            end
          end

          pWAIT_FOR_DRP_RDY: begin
            //Latch DRP response until Host reads it. Set RDY as valid indicator
            if(DRPRDY==1'b1) begin
//              drp_state <= pWAIT_FOR_DRP_RDY;
              DRP_Status_Reg[15:0] <= DRPDO;
              DRP_Status_Reg[16]   <= 1'b1;
              drp_state <= pWAIT_FOR_TXN_REQUEST;
            end

            //Latch the ready and DO for atleast 2 txn time so host can read it
           // end else if (DRP_Status[16]==1'b1 && DRP_Rsp_Rd_Toggle_pulse_cnt==1'b1) begin
          end

          default: begin
          end
        endcase
      end
    end
  end

// DRP Status sync
/*
  xpm_cdc_handshake #(
    // Module parameters
    .DEST_EXT_HSK   (0),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SIM_ASYNC_RAND (0),
    .SRC_SYNC_FF    (`XPM_CDC_MTBF_FFS      ),
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .WIDTH          (32)
  ) xpm_handshake_DRP_Status_inst (
    // Module ports
    .src_clk            (DRPCLK),
    .src_in             (DRP_Status_Reg),
    .src_send           (1'b0),  
    .src_rcv            (),
    
    .dest_clk           (Config_Clk),

    .dest_out           (DRP_Status_sync),
    .dest_req           (),
    .dest_ack           (1'b0)
  );
*/

  xpm_cdc_array_single #(
    .VERSION        (`XPM_CDC_VERSION       ),
    .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
    .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
    .SRC_INPUT_REG  (0                      ),
    .WIDTH          (32)
  ) xpm_handshake_DRP_Status_inst (
    .src_clk         (DRPCLK),
    .src_in          (DRP_Status_Reg),
    .dest_clk        (Config_Clk),
    .dest_out        (DRP_Status_sync)
  );

// DRP status ready delayed
// This is used for the ready rising edge detector. 
  always@ (posedge Config_Clk) 
  begin
    DRP_Status_sync_rdy_del <= DRP_Status_sync[16];
  end

// Config status Ready
  always@ (posedge Config_Clk) 
  begin
    if (Config_Rst)
      DRP_Status_Rdy <= 1'b0;

    else 
    begin
      // Clear at the start of an access
      if (drp_txn_available) 
        DRP_Status_Rdy <= 1'b0;

        // Set at rising edge DRP ready
      else if ((DRP_Status_sync[16] == 1'b1) && (DRP_Status_sync_rdy_del == 1'b0))
        DRP_Status_Rdy <= 1'b1;
    end
  end

  assign DRP_Status = {14'h0, DRP_Status_sync[17], DRP_Status_Rdy, DRP_Status_sync[15:0]};

endmodule


