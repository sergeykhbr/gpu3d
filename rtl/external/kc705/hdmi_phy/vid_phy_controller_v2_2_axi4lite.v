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


`timescale 1 ns / 1 ps
`include "vid_phy_controller_v2_2_2_defs.v"

(* DowngradeIPIdentifiedWarnings="yes" *)
module vid_phy_controller_v2_2_2_axi4lite #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 9,
		// Number of TX Active Channels
		parameter integer C_Tx_No_Of_Channels   = 3,
		// Number of RX Active Channels
		parameter integer C_Rx_No_Of_Channels   = 3,
		// TX PLL Selection
		parameter integer C_TX_PLL_SELECTION    = 6,
		// RX PLL Selection
		parameter integer C_RX_PLL_SELECTION    = 0,
                // ERR IRQ
		parameter integer C_Err_Irq_En          = 0,
                // Use GT as TX TMDS Clock 
		parameter integer C_Use_GT_CH4_HDMI     = 0
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY,

                output wire irq,
                output wire err_irq,

                // PHY Control
                output  wire [6:0]                          drp_txn_available,  
                output  reg  [6:0]                          drp_rsp_read,       
                output  reg  [3:0]                          rx_sym_err_cntr_read,       
                output  wire `tPHY_MEM_MAP_FIELDS_CONTROL   cfg_phy_mem_map_control,   
                input   wire `tPHY_MEM_MAP_FIELDS_STATUS    cfg_phy_mem_map_status   
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 7;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 33
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0xC;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x10;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x14;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x18;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x1C;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x20;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x24;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x28;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x2C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x30;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x38;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x3C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x40;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x44;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x48;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4C;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x50;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x54;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x58;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x5C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x60;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x64;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x68;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x6C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x70;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x74;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x78;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x7C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x80;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x84;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x88;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x100;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x104;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x108;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x10C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x110;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x114;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x118;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x11C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x120;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x124;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x128;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x134;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x138;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x140;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x144;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x148;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x154;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x158;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x200;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x204;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x208;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x20C;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x210;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x214;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x218;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x21C;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x300;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x304;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x308;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x30C;
	wire[C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x310;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x340;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

        reg  [6:0]                      drp_txn_available_q;
        reg aw_en;
        reg wr_en_2_isr;
        reg wr_en_2_ier;
        reg wr_en_2_idr;

        wire i_mmcm_txusrclk_locked = cfg_phy_mem_map_status[`MMCM_TXUSRCLK_LOCKED];
        wire i_mmcm_rxusrclk_locked = cfg_phy_mem_map_status[`MMCM_RXUSRCLK_LOCKED];
	
        reg i_reg_clkdet_run;
        reg i_reg_clkdet_tx_tmr_clr;
        reg i_reg_clkdet_rx_tmr_clr;
        reg i_reg_clkdet_tx_freq_rst;
        reg i_reg_clkdet_rx_freq_rst;

        reg i_reg_clkdet_tx_tmr_ld;
        reg i_reg_clkdet_rx_tmr_ld;

        // Interrupt Registers
        wire [31:0] isr_write;
        wire [31:0] isr_read;
        wire [31:0] ier;
        wire [31:0] idr;
        wire [31:0] imr;
        reg  [31:0] imr_reg;
		
        wire gt_status_tx_resetdone_updated;
        wire gt_status_rx_resetdone_updated;
        wire gt_status_cpll_lock_updated;
        wire gt_status_qpll_lock_updated;
        wire gt_status_qpll1_lock_updated;
        wire gt_status_tx_alignment_updated;
        wire mmcm_tx_usrclk_lock_event_re;
        wire mmcm_rx_usrclk_lock_event_re;
        wire clkdet_tx_timer_event_updated_re; 
        wire clkdet_tx_freq_event_updated_re;  		
        wire clkdet_rx_timer_event_updated_re; 		
        wire clkdet_rx_freq_event_updated_re;  		
      
        wire gt_status_tx_resetdone_updated_w;
        wire gt_status_rx_resetdone_updated_w;
      
        reg gt_status_tx_resetdone_updated_q;
        reg gt_status_rx_resetdone_updated_q;
        reg gt_status_cpll_lock_updated_q;
        reg gt_status_qpll_lock_updated_q;
        reg gt_status_qpll1_lock_updated_q;
        reg gt_status_tx_alignment_updated_q;
        reg mmcm_tx_usrclk_lock_event_updated_q;
        reg mmcm_rx_usrclk_lock_event_updated_q;
        reg clkdet_tx_timer_event_updated_q; 
        reg clkdet_tx_freq_event_updated_q;  		
        reg clkdet_rx_timer_event_updated_q; 		
        reg clkdet_rx_freq_event_updated_q;  		

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
          aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en )
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
              aw_en <= 1'b0;
	        end
          else if (S_AXI_BREADY && axi_bvalid)
            begin
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

        
        assign drp_txn_available = drp_txn_available_q; 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
              slv_reg_0x0   <= 32'h02_02_0_0_00;
	      slv_reg_0xC   <= 0;
	      slv_reg_0x10  <= 0;
	      slv_reg_0x14  <= 0;
	      slv_reg_0x1C  <= 0;
	      slv_reg_0x24  <= 0;
	      slv_reg_0x2C  <= 0;
	      slv_reg_0x30  <= 0;
	      slv_reg_0x38  <= 0;
	      slv_reg_0x3C  <= 0;
	      slv_reg_0x40  <= 0;
	      slv_reg_0x44  <= 0;
	      slv_reg_0x48  <= 0;
	      slv_reg_0x4C  <= 0;
	      slv_reg_0x60  <= 0;
	      slv_reg_0x68  <= 0;
	      slv_reg_0x6C  <= 0;
	      slv_reg_0x70  <= 0;
	      slv_reg_0x74  <= 0;
	      slv_reg_0x7C  <= 0;
	      slv_reg_0x80  <= 0;
	      slv_reg_0x100 <= 0;
	      slv_reg_0x108 <= 0;
	      slv_reg_0x10C <= 0;
	      slv_reg_0x110 <= 0;
	      slv_reg_0x114 <= 0;
	      slv_reg_0x11C <= 0;
	      slv_reg_0x120 <= 0;
	      slv_reg_0x124 <= 0;
	      slv_reg_0x134 <= 0;
	      slv_reg_0x138 <= 0;
	      slv_reg_0x140 <= 0;
	      slv_reg_0x144 <= 0;
	      slv_reg_0x154 <= 0;
	      slv_reg_0x158 <= 0;
	      slv_reg_0x200 <= 0;
	      slv_reg_0x208 <= 0;
	      slv_reg_0x214 <= 0;
	      slv_reg_0x218 <= 0;
	      slv_reg_0x300 <= 0;
	      slv_reg_0x308 <= 0;
	      slv_reg_0x30C <= 0;
	      slv_reg_0x340 <= 0;
              drp_txn_available_q <= 0;
              wr_en_2_isr <= 1'b0;
              wr_en_2_ier <= 1'b0;
              wr_en_2_idr <= 1'b0;
              i_reg_clkdet_run <= 1'b0;
              i_reg_clkdet_tx_tmr_clr <= 1'b0;
              i_reg_clkdet_rx_tmr_clr <= 1'b0;
              i_reg_clkdet_tx_freq_rst <= 1'b0;
              i_reg_clkdet_rx_freq_rst <= 1'b0;
              i_reg_clkdet_tx_tmr_ld <= 1'b0;
              i_reg_clkdet_rx_tmr_ld <= 1'b0;
	    end 
	  else begin
            drp_txn_available_q <= 0; // pulse gen
            wr_en_2_isr <= 1'b0;
            wr_en_2_ier <= 1'b0;
            wr_en_2_idr <= 1'b0;
            i_reg_clkdet_tx_tmr_clr <= 1'b0;
            i_reg_clkdet_rx_tmr_clr <= 1'b0;
	    i_reg_clkdet_tx_freq_rst<= (cfg_phy_mem_map_status[`CLKDET_TX_FREQ_ZERO] ? 1'b0 : i_reg_clkdet_tx_freq_rst);
	    i_reg_clkdet_rx_freq_rst<= (cfg_phy_mem_map_status[`CLKDET_RX_FREQ_ZERO] ? 1'b0 : i_reg_clkdet_rx_freq_rst);
	    i_reg_clkdet_tx_tmr_ld  <= 1'b0;
	    i_reg_clkdet_rx_tmr_ld  <= 1'b0;
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          8'h03:  slv_reg_0xC   <= S_AXI_WDATA;
	          8'h04:  slv_reg_0x10  <= S_AXI_WDATA;
	          8'h05:  slv_reg_0x14  <= S_AXI_WDATA;
	          8'h07:  slv_reg_0x1C  <= S_AXI_WDATA;
	          8'h09:  slv_reg_0x24  <= S_AXI_WDATA;
	          8'h0B:  slv_reg_0x2C  <= S_AXI_WDATA;
	          8'h0C:  slv_reg_0x30  <= S_AXI_WDATA;
	          8'h0E:  slv_reg_0x38  <= S_AXI_WDATA;
	          8'h0F:  slv_reg_0x3C  <= S_AXI_WDATA;
	          8'h10:  begin drp_txn_available_q[0] <= 1'b1; slv_reg_0x40  <=  S_AXI_WDATA; end
	          8'h11:  begin drp_txn_available_q[1] <= 1'b1; slv_reg_0x44  <=  S_AXI_WDATA; end 
	          8'h12:  begin drp_txn_available_q[2] <= 1'b1; slv_reg_0x48  <=  S_AXI_WDATA; end
	          8'h13:  begin drp_txn_available_q[3] <= 1'b1; slv_reg_0x4C  <=  S_AXI_WDATA; end
	          8'h18:  begin drp_txn_available_q[4] <= 1'b1; slv_reg_0x60  <=  S_AXI_WDATA; end
	          8'h1A:  slv_reg_0x68  <= S_AXI_WDATA;
	          8'h1B:  slv_reg_0x6C  <= S_AXI_WDATA;
	          8'h1C:  slv_reg_0x70  <= S_AXI_WDATA;
	          8'h1D:  slv_reg_0x74  <= S_AXI_WDATA;
	          8'h1F:  slv_reg_0x7C  <= S_AXI_WDATA;
	          8'h20:  slv_reg_0x80  <= S_AXI_WDATA;
	          8'h40:  slv_reg_0x100 <= S_AXI_WDATA;
	          8'h42:  slv_reg_0x108 <= S_AXI_WDATA;
	          8'h43:  slv_reg_0x10C <= S_AXI_WDATA;
	          8'h44:  begin wr_en_2_ier <= 1'b1; slv_reg_0x110 <= S_AXI_WDATA; end
	          8'h45:  begin wr_en_2_idr <= 1'b1; slv_reg_0x114 <= S_AXI_WDATA; end
	          8'h47:  begin wr_en_2_isr <= 1'b1; slv_reg_0x11C <= S_AXI_WDATA; end
	          8'h48:  slv_reg_0x120 <= S_AXI_WDATA;
	          8'h49:  begin drp_txn_available_q[5] <= 1'b1; slv_reg_0x124 <= S_AXI_WDATA; end
	          8'h4D:  begin slv_reg_0x134 <= S_AXI_WDATA; end
	          8'h4E:  begin slv_reg_0x138 <= S_AXI_WDATA; end
	          8'h50:  slv_reg_0x140 <= S_AXI_WDATA;
	          8'h51:  begin drp_txn_available_q[6] <= 1'b1; slv_reg_0x144 <= S_AXI_WDATA; end
	          8'h55:  begin slv_reg_0x154 <= S_AXI_WDATA; end
	          8'h56:  begin slv_reg_0x158 <= S_AXI_WDATA; end
	          8'h80:  begin i_reg_clkdet_run <= S_AXI_WDATA[0]; 
			                    i_reg_clkdet_tx_tmr_clr <= S_AXI_WDATA[1]; 
			                    i_reg_clkdet_rx_tmr_clr <= S_AXI_WDATA[2]; 
			                    i_reg_clkdet_tx_freq_rst <= S_AXI_WDATA[3]; 
			                    i_reg_clkdet_rx_freq_rst <= S_AXI_WDATA[4]; 
                                slv_reg_0x200 <= S_AXI_WDATA;  end
	          8'h82:  begin slv_reg_0x208 <= S_AXI_WDATA; end
	          8'h85:  begin slv_reg_0x214 <= S_AXI_WDATA; 
			                    i_reg_clkdet_tx_tmr_ld <= 1'b1; end
	          8'h86:  begin slv_reg_0x218 <= S_AXI_WDATA; 
			                    i_reg_clkdet_rx_tmr_ld <= 1'b1;  end
	          8'hC0:  begin slv_reg_0x300 <= S_AXI_WDATA; end
	          8'hC2:  begin slv_reg_0x308 <= S_AXI_WDATA; end
	          8'hC3:  begin slv_reg_0x30C <= S_AXI_WDATA; end
	          8'hD0:  begin slv_reg_0x340 <= C_Use_GT_CH4_HDMI ? S_AXI_WDATA : 32'b0; end
	          default : begin
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        8'h00   : reg_data_out = slv_reg_0x0  ; 
	        8'h03   : reg_data_out = slv_reg_0xC  ;
	        8'h04   : reg_data_out = slv_reg_0x10 ;
	        8'h05   : reg_data_out = slv_reg_0x14 ;
	        8'h06   : reg_data_out = slv_reg_0x18 ;
	        8'h07   : reg_data_out = slv_reg_0x1C ;
	        8'h08   : reg_data_out = slv_reg_0x20 ;
	        8'h09   : reg_data_out = slv_reg_0x24 ;
	        8'h0A   : reg_data_out = slv_reg_0x28 ;
	        8'h0B   : reg_data_out = slv_reg_0x2C ;
	        8'h0C   : reg_data_out = slv_reg_0x30 ;
	        8'h0E   : reg_data_out = slv_reg_0x38 ;
	        8'h0F   : reg_data_out = slv_reg_0x3C ;
	        8'h10   : reg_data_out = slv_reg_0x40 ;
	        8'h11   : reg_data_out = slv_reg_0x44 ;
	        8'h12   : reg_data_out = slv_reg_0x48 ;
	        8'h13   : reg_data_out = slv_reg_0x4C ;
	        8'h14   : reg_data_out = slv_reg_0x50 ;
	        8'h15   : reg_data_out = slv_reg_0x54 ;
	        8'h16   : reg_data_out = slv_reg_0x58 ;
	        8'h17   : reg_data_out = slv_reg_0x5C ;
	        8'h18   : reg_data_out = slv_reg_0x60 ;
	        8'h19   : reg_data_out = slv_reg_0x64 ;
	        8'h1A   : reg_data_out = slv_reg_0x68 ;
	        8'h1B   : reg_data_out = slv_reg_0x6C ;
	        8'h1C   : reg_data_out = slv_reg_0x70 ;
	        8'h1D   : reg_data_out = slv_reg_0x74 ;
	        8'h1E   : reg_data_out = slv_reg_0x78 ;
	        8'h1F   : reg_data_out = slv_reg_0x7C ;
	        8'h20   : reg_data_out = slv_reg_0x80 ;
	        8'h21   : reg_data_out = slv_reg_0x84 ;
	        8'h22   : reg_data_out = slv_reg_0x88 ;
	        8'h40   : reg_data_out = slv_reg_0x100;
	        8'h41   : reg_data_out = slv_reg_0x104;
	        8'h42   : reg_data_out = slv_reg_0x108;
	        8'h43   : reg_data_out = slv_reg_0x10C;
	        8'h46   : reg_data_out = slv_reg_0x118;
	        8'h47   : reg_data_out = isr_read;
	        8'h48   : reg_data_out = {slv_reg_0x120[31:10], i_mmcm_txusrclk_locked, slv_reg_0x120[8:0]};
	        8'h49   : reg_data_out = slv_reg_0x124;
	        8'h4A   : reg_data_out = slv_reg_0x128;
	        8'h4D   : reg_data_out = slv_reg_0x134;
	        8'h4E   : reg_data_out = slv_reg_0x138;
	        8'h50   : reg_data_out = {slv_reg_0x140[31:10], i_mmcm_rxusrclk_locked, slv_reg_0x140[8:0]};
	        8'h51   : reg_data_out = slv_reg_0x144;
	        8'h52   : reg_data_out = slv_reg_0x148;
	        8'h55   : reg_data_out = slv_reg_0x154;
	        8'h56   : reg_data_out = slv_reg_0x158;
	        8'h80   : reg_data_out = {slv_reg_0x200[31:5], i_reg_clkdet_rx_freq_rst, i_reg_clkdet_tx_freq_rst, i_reg_clkdet_rx_tmr_clr, i_reg_clkdet_tx_tmr_clr, i_reg_clkdet_run};
	        8'h81   : reg_data_out = slv_reg_0x204;
	        8'h82   : reg_data_out = slv_reg_0x208;
	        8'h83   : reg_data_out = slv_reg_0x20C;
	        8'h84   : reg_data_out = slv_reg_0x210;
	        8'h85   : reg_data_out = slv_reg_0x214;
	        8'h86   : reg_data_out = slv_reg_0x218;
	        8'h87   : reg_data_out = slv_reg_0x21C;
	        8'hC0   : reg_data_out = slv_reg_0x300;
	        8'hC1   : reg_data_out = slv_reg_0x304;
	        8'hC2   : reg_data_out = slv_reg_0x308;
	        8'hC3   : reg_data_out = slv_reg_0x30C;
	        8'hC4   : reg_data_out = slv_reg_0x310;
	        8'hD0   : reg_data_out = C_Use_GT_CH4_HDMI ? slv_reg_0x340 : 32'b0;
	        default : reg_data_out = 0;
	      endcase
	end

        //DRP Response Read Trigger
	always @(axi_araddr,slv_reg_rden,axi_rvalid,S_AXI_RREADY,reg_data_out)
        begin
	      drp_rsp_read = 0; 
	      rx_sym_err_cntr_read = 0; 
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        8'h14   : drp_rsp_read[0] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h15   : drp_rsp_read[1] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h16   : drp_rsp_read[2] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h17   : drp_rsp_read[3] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h19   : drp_rsp_read[4] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h21   : rx_sym_err_cntr_read[1:0] = {slv_reg_rden,slv_reg_rden}; 
	        8'h22   : rx_sym_err_cntr_read[3:2] = {slv_reg_rden,slv_reg_rden}; 
	        8'h4A   : drp_rsp_read[5] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        8'h52   : drp_rsp_read[6] = axi_rvalid && S_AXI_RREADY && reg_data_out[16];//slv_reg_rden; 
	        default : begin drp_rsp_read = 0; rx_sym_err_cntr_read = 0; end
	      endcase


        end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

  //-------------------------------------------------------------------------------------
  //                             PROCESSOR WRITE CONTROL                                           
  //-------------------------------------------------------------------------------------

  // Bank Selection
  assign cfg_phy_mem_map_control[`TX_BANK_SEL]    = slv_reg_0xC[4:0];
  assign cfg_phy_mem_map_control[`RX_BANK_SEL]    = slv_reg_0xC[12:8];

  // Shared Features & Resets
  assign cfg_phy_mem_map_control[`QPLL0REFCLKSEL] = slv_reg_0x10[3:0];
  assign cfg_phy_mem_map_control[`CPLLREFCLKSEL]  = slv_reg_0x10[7:4];
  assign cfg_phy_mem_map_control[`QPLL1REFCLKSEL] = slv_reg_0x10[11:8];
  assign cfg_phy_mem_map_control[`TXSYSCLKSEL]    = slv_reg_0x10[27:26];
  assign cfg_phy_mem_map_control[`RXSYSCLKSEL]    = slv_reg_0x10[25:24];
  assign cfg_phy_mem_map_control[`TXPLLCLKSEL]    = slv_reg_0x10[31:30];
  assign cfg_phy_mem_map_control[`RXPLLCLKSEL]    = slv_reg_0x10[29:28];

  assign cfg_phy_mem_map_control[`CPLLRESET]      = slv_reg_0x14[0];
  assign cfg_phy_mem_map_control[`QPLL0RESET]     = slv_reg_0x14[1];
  assign cfg_phy_mem_map_control[`QPLL1RESET]     = slv_reg_0x14[2];

  assign cfg_phy_mem_map_control[`CH1_GTTXRESET]      = slv_reg_0x1C[0];
  assign cfg_phy_mem_map_control[`CH1_TXPMARESET]     = slv_reg_0x1C[1];
  assign cfg_phy_mem_map_control[`CH1_TXPCSRESET]     = slv_reg_0x1C[2];
  assign cfg_phy_mem_map_control[`CH1_TXUSERRDY]      = slv_reg_0x1C[3];
  assign cfg_phy_mem_map_control[`CH1_TX_PLL_GT_RST]  = slv_reg_0x1C[7];

  assign cfg_phy_mem_map_control[`CH2_GTTXRESET]      = slv_reg_0x1C[8];
  assign cfg_phy_mem_map_control[`CH2_TXPMARESET]     = slv_reg_0x1C[9];
  assign cfg_phy_mem_map_control[`CH2_TXPCSRESET]     = slv_reg_0x1C[10];
  assign cfg_phy_mem_map_control[`CH2_TXUSERRDY]      = slv_reg_0x1C[11];
  assign cfg_phy_mem_map_control[`CH2_TX_PLL_GT_RST]  = slv_reg_0x1C[15];

  assign cfg_phy_mem_map_control[`CH3_GTTXRESET]      = slv_reg_0x1C[16];
  assign cfg_phy_mem_map_control[`CH3_TXPMARESET]     = slv_reg_0x1C[17];
  assign cfg_phy_mem_map_control[`CH3_TXPCSRESET]     = slv_reg_0x1C[18];
  assign cfg_phy_mem_map_control[`CH3_TXUSERRDY]      = slv_reg_0x1C[19];
  assign cfg_phy_mem_map_control[`CH3_TX_PLL_GT_RST]  = slv_reg_0x1C[23];

  assign cfg_phy_mem_map_control[`CH4_GTTXRESET]      = slv_reg_0x1C[24];
  assign cfg_phy_mem_map_control[`CH4_TXPMARESET]     = slv_reg_0x1C[25];
  assign cfg_phy_mem_map_control[`CH4_TXPCSRESET]     = slv_reg_0x1C[26];
  assign cfg_phy_mem_map_control[`CH4_TXUSERRDY]      = slv_reg_0x1C[27];
  assign cfg_phy_mem_map_control[`CH4_TX_PLL_GT_RST]  = slv_reg_0x1C[31];

  assign cfg_phy_mem_map_control[`CH1_GTRXRESET]      = slv_reg_0x24[0];
  assign cfg_phy_mem_map_control[`CH1_RXPMARESET]     = slv_reg_0x24[1];
  assign cfg_phy_mem_map_control[`CH1_RXDFELPMRESET]  = slv_reg_0x24[2];
  assign cfg_phy_mem_map_control[`CH1_EYESCANRESET]   = slv_reg_0x24[3];
  assign cfg_phy_mem_map_control[`CH1_RXPCSRESET]     = slv_reg_0x24[4];
  assign cfg_phy_mem_map_control[`CH1_RXBUFRESET]     = slv_reg_0x24[5];
  assign cfg_phy_mem_map_control[`CH1_RXUSERRDY]      = slv_reg_0x24[6];
  assign cfg_phy_mem_map_control[`CH1_RX_PLL_GT_RST]  = slv_reg_0x24[7];

  assign cfg_phy_mem_map_control[`CH2_GTRXRESET]      = slv_reg_0x24[8];
  assign cfg_phy_mem_map_control[`CH2_RXPMARESET]     = slv_reg_0x24[9];
  assign cfg_phy_mem_map_control[`CH2_RXDFELPMRESET]  = slv_reg_0x24[10];
  assign cfg_phy_mem_map_control[`CH2_EYESCANRESET]   = slv_reg_0x24[11];
  assign cfg_phy_mem_map_control[`CH2_RXPCSRESET]     = slv_reg_0x24[12];
  assign cfg_phy_mem_map_control[`CH2_RXBUFRESET]     = slv_reg_0x24[13];
  assign cfg_phy_mem_map_control[`CH2_RXUSERRDY]      = slv_reg_0x24[14];
  assign cfg_phy_mem_map_control[`CH2_RX_PLL_GT_RST]  = slv_reg_0x24[15];

  assign cfg_phy_mem_map_control[`CH3_GTRXRESET]      = slv_reg_0x24[16];
  assign cfg_phy_mem_map_control[`CH3_RXPMARESET]     = slv_reg_0x24[17];
  assign cfg_phy_mem_map_control[`CH3_RXDFELPMRESET]  = slv_reg_0x24[18];
  assign cfg_phy_mem_map_control[`CH3_EYESCANRESET]   = slv_reg_0x24[19];
  assign cfg_phy_mem_map_control[`CH3_RXPCSRESET]     = slv_reg_0x24[20];
  assign cfg_phy_mem_map_control[`CH3_RXBUFRESET]     = slv_reg_0x24[21];
  assign cfg_phy_mem_map_control[`CH3_RXUSERRDY]      = slv_reg_0x24[22];
  assign cfg_phy_mem_map_control[`CH3_RX_PLL_GT_RST]  = slv_reg_0x24[23];

  assign cfg_phy_mem_map_control[`CH4_GTRXRESET]      = slv_reg_0x24[24];
  assign cfg_phy_mem_map_control[`CH4_RXPMARESET]     = slv_reg_0x24[25];
  assign cfg_phy_mem_map_control[`CH4_RXDFELPMRESET]  = slv_reg_0x24[26];
  assign cfg_phy_mem_map_control[`CH4_EYESCANRESET]   = slv_reg_0x24[27];
  assign cfg_phy_mem_map_control[`CH4_RXPCSRESET]     = slv_reg_0x24[28];
  assign cfg_phy_mem_map_control[`CH4_RXBUFRESET]     = slv_reg_0x24[29];
  assign cfg_phy_mem_map_control[`CH4_RXUSERRDY]      = slv_reg_0x24[30];
  assign cfg_phy_mem_map_control[`CH4_RX_PLL_GT_RST]  = slv_reg_0x24[31];

  // IBUFDS GTxx Control
  assign cfg_phy_mem_map_control[`GTREFCLK0_CEB]      = slv_reg_0x2C[0];
  assign cfg_phy_mem_map_control[`GTREFCLK1_CEB]      = slv_reg_0x2C[1];
  
  // CPLL Calibration Block Clock Period
  assign cfg_phy_mem_map_control[`CPLL_CAL_CLK_PERIOD] = slv_reg_0x68[17:0];
  assign cfg_phy_mem_map_control[`CPLL_CAL_CLK_CNT_TOL]= slv_reg_0x6C[17:0];
  // Power Down
  assign cfg_phy_mem_map_control[`CH1_CPLLPD]    = slv_reg_0x30[0];
  assign cfg_phy_mem_map_control[`CH1_QPLL0PD]   = slv_reg_0x30[1];  
  assign cfg_phy_mem_map_control[`CH1_QPLL1PD]   = slv_reg_0x30[2];
  assign cfg_phy_mem_map_control[`CH1_RXPD]      = slv_reg_0x30[4:3];
  assign cfg_phy_mem_map_control[`CH1_TXPD]      = slv_reg_0x30[6:5];

  assign cfg_phy_mem_map_control[`CH2_CPLLPD]    = slv_reg_0x30[8];
  assign cfg_phy_mem_map_control[`CH2_RXPD]      = slv_reg_0x30[12:11];
  assign cfg_phy_mem_map_control[`CH2_TXPD]      = slv_reg_0x30[14:13];

  assign cfg_phy_mem_map_control[`CH3_CPLLPD]    = slv_reg_0x30[16];
  assign cfg_phy_mem_map_control[`CH3_RXPD]      = slv_reg_0x30[20:19];
  assign cfg_phy_mem_map_control[`CH3_TXPD]      = slv_reg_0x30[22:21];

  assign cfg_phy_mem_map_control[`CH4_CPLLPD]    = slv_reg_0x30[24];
  assign cfg_phy_mem_map_control[`CH4_RXPD]      = slv_reg_0x30[28:27];
  assign cfg_phy_mem_map_control[`CH4_TXPD]      = slv_reg_0x30[30:29];

  // Loopback
  assign cfg_phy_mem_map_control[`CH1_LOOPBACK]    = slv_reg_0x38[2:0];
  assign cfg_phy_mem_map_control[`CH2_LOOPBACK]    = slv_reg_0x38[10:8];
  assign cfg_phy_mem_map_control[`CH3_LOOPBACK]    = slv_reg_0x38[18:16];
  assign cfg_phy_mem_map_control[`CH4_LOOPBACK]    = slv_reg_0x38[26:24];

  // DRP
  assign cfg_phy_mem_map_control[`CH1_DRPADDR_US_MSB]= slv_reg_0x40[11:9];
  assign cfg_phy_mem_map_control[`CH1_DRPADDR]    = slv_reg_0x40[8:0];
  assign cfg_phy_mem_map_control[`CH1_DRPEN]      = slv_reg_0x40[12];
  assign cfg_phy_mem_map_control[`CH1_DRPWE]      = slv_reg_0x40[13];
//  assign cfg_phy_mem_map_control[`CH1_DRPRST]     = slv_reg_0x40[14];
  assign cfg_phy_mem_map_control[`CH1_DRPDI]      = slv_reg_0x40[31:16];

  assign cfg_phy_mem_map_control[`CH2_DRPADDR_US_MSB]= slv_reg_0x44[11:9];
  assign cfg_phy_mem_map_control[`CH2_DRPADDR]    = slv_reg_0x44[8:0];
  assign cfg_phy_mem_map_control[`CH2_DRPEN]      = slv_reg_0x44[12];
  assign cfg_phy_mem_map_control[`CH2_DRPWE]      = slv_reg_0x44[13];
//  assign cfg_phy_mem_map_control[`CH2_DRPRST]     = slv_reg_0x44[14];
  assign cfg_phy_mem_map_control[`CH2_DRPDI]      = slv_reg_0x44[31:16];

  assign cfg_phy_mem_map_control[`CH3_DRPADDR_US_MSB]= slv_reg_0x48[11:9];
  assign cfg_phy_mem_map_control[`CH3_DRPADDR]    = slv_reg_0x48[8:0];
  assign cfg_phy_mem_map_control[`CH3_DRPEN]      = slv_reg_0x48[12];
  assign cfg_phy_mem_map_control[`CH3_DRPWE]      = slv_reg_0x48[13];
//  assign cfg_phy_mem_map_control[`CH3_DRPRST]     = slv_reg_0x48[14];
  assign cfg_phy_mem_map_control[`CH3_DRPDI]      = slv_reg_0x48[31:16];

  assign cfg_phy_mem_map_control[`CH4_DRPADDR_US_MSB]= slv_reg_0x4C[11:9];
  assign cfg_phy_mem_map_control[`CH4_DRPADDR]    = slv_reg_0x4C[8:0];
  assign cfg_phy_mem_map_control[`CH4_DRPEN]      = slv_reg_0x4C[12];
  assign cfg_phy_mem_map_control[`CH4_DRPWE]      = slv_reg_0x4C[13];
//  assign cfg_phy_mem_map_control[`CH4_DRPRST]     = slv_reg_0x4C[14];
  assign cfg_phy_mem_map_control[`CH4_DRPDI]      = slv_reg_0x4C[31:16];

  assign cfg_phy_mem_map_control[`COMMON_DRPADDR] = slv_reg_0x60[11:0];
  assign cfg_phy_mem_map_control[`COMMON_DRPEN]   = slv_reg_0x60[12];
  assign cfg_phy_mem_map_control[`COMMON_DRPWE]   = slv_reg_0x60[13];
  assign cfg_phy_mem_map_control[`COMMON_DRPDI]   = slv_reg_0x60[31:16];

  // Transmitter Functions
  assign cfg_phy_mem_map_control[`CH1_TX8B10B]        = slv_reg_0x70[0];
  assign cfg_phy_mem_map_control[`CH1_TXPOLARITY]     = slv_reg_0x70[1];
  assign cfg_phy_mem_map_control[`CH1_TXPRBSSEL]      = slv_reg_0x70[4:2];
  assign cfg_phy_mem_map_control[`CH1_TXPRBSFORCEERR] = slv_reg_0x70[5];
  assign cfg_phy_mem_map_control[`CH1_TXPRBSSEL_US_MSB] = slv_reg_0x70[6];

  assign cfg_phy_mem_map_control[`CH2_TX8B10B]        = slv_reg_0x70[8];
  assign cfg_phy_mem_map_control[`CH2_TXPOLARITY]     = slv_reg_0x70[9];
  assign cfg_phy_mem_map_control[`CH2_TXPRBSSEL]      = slv_reg_0x70[12:10];
  assign cfg_phy_mem_map_control[`CH2_TXPRBSFORCEERR] = slv_reg_0x70[13];
  assign cfg_phy_mem_map_control[`CH2_TXPRBSSEL_US_MSB] = slv_reg_0x70[14];

  assign cfg_phy_mem_map_control[`CH3_TX8B10B]        = slv_reg_0x70[16];
  assign cfg_phy_mem_map_control[`CH3_TXPOLARITY]     = slv_reg_0x70[17];
  assign cfg_phy_mem_map_control[`CH3_TXPRBSSEL]      = slv_reg_0x70[20:18];
  assign cfg_phy_mem_map_control[`CH3_TXPRBSFORCEERR] = slv_reg_0x70[21];
  assign cfg_phy_mem_map_control[`CH3_TXPRBSSEL_US_MSB] = slv_reg_0x70[22];

  assign cfg_phy_mem_map_control[`CH4_TX8B10B]        = slv_reg_0x70[24];
  assign cfg_phy_mem_map_control[`CH4_TXPOLARITY]     = slv_reg_0x70[25];
  assign cfg_phy_mem_map_control[`CH4_TXPRBSSEL]      = slv_reg_0x70[28:26];
  assign cfg_phy_mem_map_control[`CH4_TXPRBSFORCEERR] = slv_reg_0x70[29];
  assign cfg_phy_mem_map_control[`CH4_TXPRBSSEL_US_MSB] = slv_reg_0x70[30];

  assign cfg_phy_mem_map_control[`CH1_TXPHDLYRESET]   = slv_reg_0x74[0];
  assign cfg_phy_mem_map_control[`CH1_TXPHALIGN]      = slv_reg_0x74[1];
  assign cfg_phy_mem_map_control[`CH1_TXPHALIGNEN]    = slv_reg_0x74[2];
  assign cfg_phy_mem_map_control[`CH1_TXPHDLYPD]      = slv_reg_0x74[3];
  assign cfg_phy_mem_map_control[`CH1_TXPHINIT]       = slv_reg_0x74[4];
  assign cfg_phy_mem_map_control[`CH1_TXDLYRESET]     = slv_reg_0x74[5];
  assign cfg_phy_mem_map_control[`CH1_TXDLYBYPASS]    = slv_reg_0x74[6];
  assign cfg_phy_mem_map_control[`CH1_TXDLYEN]        = slv_reg_0x74[7];

  assign cfg_phy_mem_map_control[`CH2_TXPHDLYRESET]   = slv_reg_0x74[8];
  assign cfg_phy_mem_map_control[`CH2_TXPHALIGN]      = slv_reg_0x74[9];
  assign cfg_phy_mem_map_control[`CH2_TXPHALIGNEN]    = slv_reg_0x74[10];
  assign cfg_phy_mem_map_control[`CH2_TXPHDLYPD]      = slv_reg_0x74[11];
  assign cfg_phy_mem_map_control[`CH2_TXPHINIT]       = slv_reg_0x74[12];
  assign cfg_phy_mem_map_control[`CH2_TXDLYRESET]     = slv_reg_0x74[13];
  assign cfg_phy_mem_map_control[`CH2_TXDLYBYPASS]    = slv_reg_0x74[14];
  assign cfg_phy_mem_map_control[`CH2_TXDLYEN]        = slv_reg_0x74[15];

  assign cfg_phy_mem_map_control[`CH3_TXPHDLYRESET]   = slv_reg_0x74[16];
  assign cfg_phy_mem_map_control[`CH3_TXPHALIGN]      = slv_reg_0x74[17];
  assign cfg_phy_mem_map_control[`CH3_TXPHALIGNEN]    = slv_reg_0x74[18];
  assign cfg_phy_mem_map_control[`CH3_TXPHDLYPD]      = slv_reg_0x74[19];
  assign cfg_phy_mem_map_control[`CH3_TXPHINIT]       = slv_reg_0x74[20];
  assign cfg_phy_mem_map_control[`CH3_TXDLYRESET]     = slv_reg_0x74[21];
  assign cfg_phy_mem_map_control[`CH3_TXDLYBYPASS]    = slv_reg_0x74[22];
  assign cfg_phy_mem_map_control[`CH3_TXDLYEN]        = slv_reg_0x74[23];

  assign cfg_phy_mem_map_control[`CH4_TXPHDLYRESET]   = slv_reg_0x74[24];
  assign cfg_phy_mem_map_control[`CH4_TXPHALIGN]      = slv_reg_0x74[25];
  assign cfg_phy_mem_map_control[`CH4_TXPHALIGNEN]    = slv_reg_0x74[26];
  assign cfg_phy_mem_map_control[`CH4_TXPHDLYPD]      = slv_reg_0x74[27];
  assign cfg_phy_mem_map_control[`CH4_TXPHINIT]       = slv_reg_0x74[28];
  assign cfg_phy_mem_map_control[`CH4_TXDLYRESET]     = slv_reg_0x74[29];
  assign cfg_phy_mem_map_control[`CH4_TXDLYBYPASS]    = slv_reg_0x74[30];
  assign cfg_phy_mem_map_control[`CH4_TXDLYEN]        = slv_reg_0x74[31];

  assign cfg_phy_mem_map_control[`CH1_TXDIFFCTRL]    = slv_reg_0x7C[3:0];
  assign cfg_phy_mem_map_control[`CH1_TXELECIDLE]    = slv_reg_0x7C[4];
  assign cfg_phy_mem_map_control[`CH1_TXINHIBIT]     = slv_reg_0x7C[5];
  assign cfg_phy_mem_map_control[`CH1_TXPOSTCURSOR]  = slv_reg_0x7C[10:6];
  assign cfg_phy_mem_map_control[`CH1_TXPRECURSOR]   = slv_reg_0x7C[15:11];

  assign cfg_phy_mem_map_control[`CH2_TXDIFFCTRL]    = slv_reg_0x7C[19:16];
  assign cfg_phy_mem_map_control[`CH2_TXELECIDLE]    = slv_reg_0x7C[20];
  assign cfg_phy_mem_map_control[`CH2_TXINHIBIT]     = slv_reg_0x7C[21];
  assign cfg_phy_mem_map_control[`CH2_TXPOSTCURSOR]  = slv_reg_0x7C[26:22];
  assign cfg_phy_mem_map_control[`CH2_TXPRECURSOR]   = slv_reg_0x7C[31:27];

  assign cfg_phy_mem_map_control[`CH3_TXDIFFCTRL]    = slv_reg_0x80[3:0];
  assign cfg_phy_mem_map_control[`CH3_TXELECIDLE]    = slv_reg_0x80[4];
  assign cfg_phy_mem_map_control[`CH3_TXINHIBIT]     = slv_reg_0x80[5];
  assign cfg_phy_mem_map_control[`CH3_TXPOSTCURSOR]  = slv_reg_0x80[10:6];
  assign cfg_phy_mem_map_control[`CH3_TXPRECURSOR]   = slv_reg_0x80[15:11];

  assign cfg_phy_mem_map_control[`CH4_TXDIFFCTRL]    = slv_reg_0x80[19:16];
  assign cfg_phy_mem_map_control[`CH4_TXELECIDLE]    = slv_reg_0x80[20];
  assign cfg_phy_mem_map_control[`CH4_TXINHIBIT]     = slv_reg_0x80[21];
  assign cfg_phy_mem_map_control[`CH4_TXPOSTCURSOR]  = slv_reg_0x80[26:22];
  assign cfg_phy_mem_map_control[`CH4_TXPRECURSOR]   = slv_reg_0x80[31:27];

  // Receiver Functions
  assign cfg_phy_mem_map_control[`CH1_RX8B10BEN]      = slv_reg_0x100[1];
  assign cfg_phy_mem_map_control[`CH1_RXPOLARITY]     = slv_reg_0x100[2];
  assign cfg_phy_mem_map_control[`CH1_RXPRBSCNTRESET] = slv_reg_0x100[3];
  assign cfg_phy_mem_map_control[`CH1_RXPRBSSEL]      = slv_reg_0x100[6:4];
  assign cfg_phy_mem_map_control[`CH1_RXPRBSSEL_US_MSB] = slv_reg_0x100[7];

  assign cfg_phy_mem_map_control[`CH2_RX8B10BEN]      = slv_reg_0x100[9];
  assign cfg_phy_mem_map_control[`CH2_RXPOLARITY]     = slv_reg_0x100[10];
  assign cfg_phy_mem_map_control[`CH2_RXPRBSCNTRESET] = slv_reg_0x100[11];
  assign cfg_phy_mem_map_control[`CH2_RXPRBSSEL]      = slv_reg_0x100[14:12];
  assign cfg_phy_mem_map_control[`CH2_RXPRBSSEL_US_MSB] = slv_reg_0x100[15];

  assign cfg_phy_mem_map_control[`CH3_RX8B10BEN]      = slv_reg_0x100[17];
  assign cfg_phy_mem_map_control[`CH3_RXPOLARITY]     = slv_reg_0x100[18];
  assign cfg_phy_mem_map_control[`CH3_RXPRBSCNTRESET] = slv_reg_0x100[19];
  assign cfg_phy_mem_map_control[`CH3_RXPRBSSEL]      = slv_reg_0x100[22:20];
  assign cfg_phy_mem_map_control[`CH3_RXPRBSSEL_US_MSB] = slv_reg_0x100[23];

  assign cfg_phy_mem_map_control[`CH4_RX8B10BEN]      = slv_reg_0x100[25];
  assign cfg_phy_mem_map_control[`CH4_RXPOLARITY]     = slv_reg_0x100[26];
  assign cfg_phy_mem_map_control[`CH4_RXPRBSCNTRESET] = slv_reg_0x100[27];
  assign cfg_phy_mem_map_control[`CH4_RXPRBSSEL]      = slv_reg_0x100[30:28];
  assign cfg_phy_mem_map_control[`CH4_RXPRBSSEL_US_MSB] = slv_reg_0x100[31];

  assign cfg_phy_mem_map_control[`CH1_RXLPMEN]        = slv_reg_0x108[0];
  assign cfg_phy_mem_map_control[`CH1_RXCDRHOLD]      = slv_reg_0x108[1];
  assign cfg_phy_mem_map_control[`CH1_RXOSOVRDEN]     = slv_reg_0x108[2];
  assign cfg_phy_mem_map_control[`CH1_RXLPMLFKLOVRDEN]= slv_reg_0x108[3];
  assign cfg_phy_mem_map_control[`CH1_RXLPMHFOVRDEN]  = slv_reg_0x108[4];

  assign cfg_phy_mem_map_control[`CH2_RXLPMEN]        = slv_reg_0x108[8];
  assign cfg_phy_mem_map_control[`CH2_RXCDRHOLD]      = slv_reg_0x108[9];
  assign cfg_phy_mem_map_control[`CH2_RXOSOVRDEN]     = slv_reg_0x108[10];
  assign cfg_phy_mem_map_control[`CH2_RXLPMLFKLOVRDEN]= slv_reg_0x108[11];
  assign cfg_phy_mem_map_control[`CH2_RXLPMHFOVRDEN]  = slv_reg_0x108[12];

  assign cfg_phy_mem_map_control[`CH3_RXLPMEN]        = slv_reg_0x108[16];
  assign cfg_phy_mem_map_control[`CH3_RXCDRHOLD]      = slv_reg_0x108[17];
  assign cfg_phy_mem_map_control[`CH3_RXOSOVRDEN]     = slv_reg_0x108[18];
  assign cfg_phy_mem_map_control[`CH3_RXLPMLFKLOVRDEN]= slv_reg_0x108[19];
  assign cfg_phy_mem_map_control[`CH3_RXLPMHFOVRDEN]  = slv_reg_0x108[20];

  assign cfg_phy_mem_map_control[`CH4_RXLPMEN]        = slv_reg_0x108[24];
  assign cfg_phy_mem_map_control[`CH4_RXCDRHOLD]      = slv_reg_0x108[25];
  assign cfg_phy_mem_map_control[`CH4_RXOSOVRDEN]     = slv_reg_0x108[26];
  assign cfg_phy_mem_map_control[`CH4_RXLPMLFKLOVRDEN]= slv_reg_0x108[27];
  assign cfg_phy_mem_map_control[`CH4_RXLPMHFOVRDEN]  = slv_reg_0x108[28];

  assign cfg_phy_mem_map_control[`RX_TDLOCK_VALUE]    = slv_reg_0x10C[31:0];

  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_LOCK_MASK]     = slv_reg_0x120[11];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_POWER_DOWN]    = slv_reg_0x120[10];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_CONFIG_RESET]  = slv_reg_0x120[1];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPADDR]       = slv_reg_0x124[8:0];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPEN]         = slv_reg_0x124[12];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPWE]         = slv_reg_0x124[13];
  assign cfg_phy_mem_map_control[`MMCM_TXUSRCLK_DRPDI]         = slv_reg_0x124[31:16];
  assign cfg_phy_mem_map_control[`BUFGT_TXUSRCLK_DIV]          = slv_reg_0x134[3:1];
  assign cfg_phy_mem_map_control[`BUFGT_TXUSRCLK_CLEAR]        = slv_reg_0x134[0];
  assign cfg_phy_mem_map_control[`OBUFTDS_TXUSRCLK_CLKOUT1_EN] = slv_reg_0x138[0];
  assign cfg_phy_mem_map_control[`TX_REFCLK_CEB]               = slv_reg_0x138[1];

  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_LOCK_MASK]     = slv_reg_0x140[11];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_POWER_DOWN]    = slv_reg_0x140[10];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_CONFIG_RESET]  = slv_reg_0x140[1];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPADDR]       = slv_reg_0x144[8:0];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPEN]         = slv_reg_0x144[12];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPWE]         = slv_reg_0x144[13];
  assign cfg_phy_mem_map_control[`MMCM_RXUSRCLK_DRPDI]         = slv_reg_0x144[31:16];
  assign cfg_phy_mem_map_control[`BUFGT_RXUSRCLK_DIV]          = slv_reg_0x154[3:1];
  assign cfg_phy_mem_map_control[`BUFGT_RXUSRCLK_CLEAR]        = slv_reg_0x154[0];
  assign cfg_phy_mem_map_control[`OBUFTDS_RXUSRCLK_CLKOUT1_EN] = slv_reg_0x158[0];
  assign cfg_phy_mem_map_control[`RX_REFCLK_CEB]               = slv_reg_0x158[1];
  
  assign cfg_phy_mem_map_control[`CLKDET_RUN]                  = i_reg_clkdet_run;
  assign cfg_phy_mem_map_control[`CLKDET_TX_TMR_CLR]           = i_reg_clkdet_tx_tmr_clr;
  assign cfg_phy_mem_map_control[`CLKDET_RX_TMR_CLR]           = i_reg_clkdet_rx_tmr_clr;
  assign cfg_phy_mem_map_control[`CLKDET_TX_FREQ_RST]          = i_reg_clkdet_tx_freq_rst;
  assign cfg_phy_mem_map_control[`CLKDET_RX_FREQ_RST]          = i_reg_clkdet_rx_freq_rst;
  assign cfg_phy_mem_map_control[`CLKDET_FREQ_LOCK_CNTR_TRSHLD]= slv_reg_0x200[12:5];
  assign cfg_phy_mem_map_control[`CLKDET_FREQ_CNTR_TMOUT]      = slv_reg_0x208;
  assign cfg_phy_mem_map_control[`CLKDET_TX_TMR_TMOUT_CNT]     = slv_reg_0x214;
  assign cfg_phy_mem_map_control[`CLKDET_RX_TMR_TMOUT_CNT]     = slv_reg_0x218;
  assign cfg_phy_mem_map_control[`CLKDET_TX_TMR_LOAD]          = i_reg_clkdet_tx_tmr_ld;
  assign cfg_phy_mem_map_control[`CLKDET_RX_TMR_LOAD]          = i_reg_clkdet_rx_tmr_ld;

  assign cfg_phy_mem_map_control[`DRU_RESET]                   = slv_reg_0x300[0];
  assign cfg_phy_mem_map_control[`DRU_ENABLE]                  = slv_reg_0x300[1];
  assign cfg_phy_mem_map_control[`DRU_CENTER_FREQ]             = {slv_reg_0x30C[4:0], slv_reg_0x308};
  
  assign cfg_phy_mem_map_control[`PATGEN_TX_TMDS_RATIO]        = C_Use_GT_CH4_HDMI ? slv_reg_0x340[2:0] : 3'b0;

  //-------------------------------------------------------------------------------------
  //                       PROCESSOR READ STATUS UPDATES                                           
  //-------------------------------------------------------------------------------------
  assign slv_reg_0x18 = { 
                           26'h0,
                           cfg_phy_mem_map_status[`QPLL1LOCK],
                           cfg_phy_mem_map_status[`QPLLLOCK],
                           cfg_phy_mem_map_status[`CH4_CPLLLOCK],
                           cfg_phy_mem_map_status[`CH3_CPLLLOCK],
                           cfg_phy_mem_map_status[`CH2_CPLLLOCK],
                           cfg_phy_mem_map_status[`CH1_CPLLLOCK]
                        };

  assign slv_reg_0x20 = { 
                           5'h0,
                           cfg_phy_mem_map_status[`CH4_TXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH4_TXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH4_TXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH3_TXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH3_TXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH3_TXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH2_TXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH2_TXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH2_TXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH1_TXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH1_TXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH1_TXRESETDONE]
                        };

  assign slv_reg_0x28 = { 
                           5'h0,
                           cfg_phy_mem_map_status[`CH4_RXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH4_RXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH4_RXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH3_RXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH3_RXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH3_RXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH2_RXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH2_RXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH2_RXRESETDONE],
                           5'h0,
                           cfg_phy_mem_map_status[`CH1_RXGTPOWERGOOD],
                           cfg_phy_mem_map_status[`CH1_RXPMARESETDONE],
                           cfg_phy_mem_map_status[`CH1_RXRESETDONE]
                        };

  assign slv_reg_0x50 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`CH1_DRPBUSY],
                           cfg_phy_mem_map_status[`CH1_DRPRDY],
                           cfg_phy_mem_map_status[`CH1_DRPDO]
                        };

  assign slv_reg_0x54 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`CH2_DRPBUSY],
                           cfg_phy_mem_map_status[`CH2_DRPRDY],
                           cfg_phy_mem_map_status[`CH2_DRPDO]
                        };

  assign slv_reg_0x58 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`CH3_DRPBUSY],
                           cfg_phy_mem_map_status[`CH3_DRPRDY],
                           cfg_phy_mem_map_status[`CH3_DRPDO]
                        };

  assign slv_reg_0x5C = { 
                           14'h0,
                           cfg_phy_mem_map_status[`CH4_DRPBUSY],
                           cfg_phy_mem_map_status[`CH4_DRPRDY],
                           cfg_phy_mem_map_status[`CH4_DRPDO]
                        };

  assign slv_reg_0x64 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`COMMON_DRPBUSY],
                           cfg_phy_mem_map_status[`COMMON_DRPRDY],
                           cfg_phy_mem_map_status[`COMMON_DRPDO]
                        };

  assign slv_reg_0x78 = { 
                           2'h0,
                           cfg_phy_mem_map_status[`CH4_BUFF_BYPASS_TX_ERR],
                           cfg_phy_mem_map_status[`CH4_TXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH4_TXDLYRESETDONE],
                           cfg_phy_mem_map_status[`CH4_TXPHINITDONE],
                           cfg_phy_mem_map_status[`CH4_TXPHALIGNDONE],
                           2'h0,
                           cfg_phy_mem_map_status[`CH3_BUFF_BYPASS_TX_ERR],
                           cfg_phy_mem_map_status[`CH3_TXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH3_TXDLYRESETDONE],
                           cfg_phy_mem_map_status[`CH3_TXPHINITDONE],
                           cfg_phy_mem_map_status[`CH3_TXPHALIGNDONE],
                           2'h0,
                           cfg_phy_mem_map_status[`CH2_BUFF_BYPASS_TX_ERR],
                           cfg_phy_mem_map_status[`CH2_TXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH2_TXDLYRESETDONE],
                           cfg_phy_mem_map_status[`CH2_TXPHINITDONE],
                           cfg_phy_mem_map_status[`CH2_TXPHALIGNDONE],
                           2'h0,
                           cfg_phy_mem_map_status[`CH1_BUFF_BYPASS_TX_ERR],
                           cfg_phy_mem_map_status[`CH1_TXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH1_TXDLYRESETDONE],
                           cfg_phy_mem_map_status[`CH1_TXPHINITDONE],
                           cfg_phy_mem_map_status[`CH1_TXPHALIGNDONE]
                        };

  assign slv_reg_0x84 = {cfg_phy_mem_map_status[`CH2_SYM_ERR_COUNT],cfg_phy_mem_map_status[`CH1_SYM_ERR_COUNT]};
  assign slv_reg_0x88 = {cfg_phy_mem_map_status[`CH4_SYM_ERR_COUNT],cfg_phy_mem_map_status[`CH3_SYM_ERR_COUNT]};

  assign slv_reg_0x104= { 
                           3'b0,
                           cfg_phy_mem_map_status[`CH4_RXPRBSERR],
                           cfg_phy_mem_map_status[`CH4_RXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH4_RXCDRLOCK],
                           3'h0,
                           cfg_phy_mem_map_status[`CH3_RXPRBSERR],
                           cfg_phy_mem_map_status[`CH3_RXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH3_RXCDRLOCK],
                           3'h0,
                           cfg_phy_mem_map_status[`CH2_RXPRBSERR],
                           cfg_phy_mem_map_status[`CH2_RXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH2_RXCDRLOCK],
                           3'h0,
                           cfg_phy_mem_map_status[`CH1_RXPRBSERR],
                           cfg_phy_mem_map_status[`CH1_RXBUFSTATUS],
                           cfg_phy_mem_map_status[`CH1_RXCDRLOCK]
                        };

  assign slv_reg_0x128 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`MMCM_TXUSRCLK_DRPBUSY],
                           cfg_phy_mem_map_status[`MMCM_TXUSRCLK_DRPRDY],
                           cfg_phy_mem_map_status[`MMCM_TXUSRCLK_DRPDO]
                        };
                        
  assign slv_reg_0x148 = { 
                           14'h0,
                           cfg_phy_mem_map_status[`MMCM_RXUSRCLK_DRPBUSY],
                           cfg_phy_mem_map_status[`MMCM_RXUSRCLK_DRPRDY],
                           cfg_phy_mem_map_status[`MMCM_RXUSRCLK_DRPDO]
                        };

  assign slv_reg_0x204 = {
                            27'b0,
                            cfg_phy_mem_map_status[`CLKDET_TX_REFCLK_LOCK_CAP],
                            cfg_phy_mem_map_status[`CLKDET_TX_REFCLK_LOCK], 
                            cfg_phy_mem_map_status[`CLKDET_RX_FREQ_ZERO],
                            cfg_phy_mem_map_status[`CLKDET_TX_FREQ_ZERO]
                          };
						 
  assign slv_reg_0x20C = cfg_phy_mem_map_status[`CLKDET_TX_FREQ];
  
  assign slv_reg_0x210 = cfg_phy_mem_map_status[`CLKDET_RX_FREQ];

  assign slv_reg_0x21C = cfg_phy_mem_map_status[`CLKDET_DRU_FREQ];

  assign slv_reg_0x304 = {
                            cfg_phy_mem_map_status[`DRU_VERSION],
                            20'b0,
                            (C_Rx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_DRU_ACTIVE] : 1'b0,
                            (C_Rx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_DRU_ACTIVE] : 1'b0,
                            (C_Rx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_DRU_ACTIVE] : 1'b0,
                            (C_Rx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_DRU_ACTIVE] : 1'b0
                          };
                          
  assign slv_reg_0x310 = {
                            11'b0,
                            cfg_phy_mem_map_status[`DRU_GAIN_G2],
                            3'b0,
                            cfg_phy_mem_map_status[`DRU_GAIN_G1_P],
                            3'b0,
                            cfg_phy_mem_map_status[`DRU_GAIN_G1]
                          };

// ------------------------------------------- Interrupt Controller ---------------------------------------

  //assign slv_reg_0x118[31:10] = 'h0;
  assign slv_reg_0x118[31:0]   = imr_reg;
  assign ier = slv_reg_0x110[31:0];
  assign idr = slv_reg_0x114[31:0];
  assign isr_write = slv_reg_0x11C[31:0];

  assign gt_status_tx_resetdone_updated_w = ((C_Tx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_TXRESETDONE] : 1'b1) &
                                            ((C_Tx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_TXRESETDONE] : 1'b1) &
                                            ((C_Tx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_TXRESETDONE] : 1'b1) &
                                            ((C_Tx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_TXRESETDONE] : 1'b1);

  assign gt_status_rx_resetdone_updated_w = ((C_Rx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_RXRESETDONE] : 1'b1) &
                                            ((C_Rx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_RXRESETDONE] : 1'b1) &
                                            ((C_Rx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_RXRESETDONE] : 1'b1) &
                                            ((C_Rx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_RXRESETDONE] : 1'b1);

  wire gt_allch_cpll_lock;
  generate
      if ((C_TX_PLL_SELECTION == 4) || (C_TX_PLL_SELECTION == 5) || (C_RX_PLL_SELECTION == 4) || (C_RX_PLL_SELECTION == 5))  begin  // GTP
          assign gt_allch_cpll_lock = 1'b0;
	  end else if (C_TX_PLL_SELECTION == 0) begin  // TX uses CPLL
          assign gt_allch_cpll_lock =  ((C_Tx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_CPLLLOCK] : 1'b1) &
                                       ((C_Tx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_CPLLLOCK] : 1'b1) &
                                       ((C_Tx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_CPLLLOCK] : 1'b1) &
                                       ((C_Tx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_CPLLLOCK] : 1'b1);
	  end else begin // RX uses CPLL
          assign gt_allch_cpll_lock =  ((C_Rx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_CPLLLOCK] : 1'b1) &
                                       ((C_Rx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_CPLLLOCK] : 1'b1) &
                                       ((C_Rx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_CPLLLOCK] : 1'b1) &
                                       ((C_Rx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_CPLLLOCK] : 1'b1);
	  end
  endgenerate
	 
  wire gt_allch_txalign_done =  ((C_Tx_No_Of_Channels >= 4) ? cfg_phy_mem_map_status[`CH4_TXPHALIGNDONE] : 1'b1) &
                                ((C_Tx_No_Of_Channels >= 3) ? cfg_phy_mem_map_status[`CH3_TXPHALIGNDONE] : 1'b1) &
                                ((C_Tx_No_Of_Channels >= 2) ? cfg_phy_mem_map_status[`CH2_TXPHALIGNDONE] : 1'b1) &
                                ((C_Tx_No_Of_Channels >= 1) ? cfg_phy_mem_map_status[`CH1_TXPHALIGNDONE] : 1'b1);
  
  assign cfg_phy_mem_map_control[`CLKDET_TX_FREQ_EVENT_CLR] = isr_write[6] & wr_en_2_isr;
  assign cfg_phy_mem_map_control[`CLKDET_RX_FREQ_EVENT_CLR] = isr_write[7] & wr_en_2_isr;

  assign cfg_phy_mem_map_control[`CLKDET_TX_TMR_EVENT_CLR]  = isr_write[30] & wr_en_2_isr;
  assign cfg_phy_mem_map_control[`CLKDET_RX_TMR_EVENT_CLR]  = isr_write[31] & wr_en_2_isr;


  always@(posedge S_AXI_ACLK) begin
    gt_status_tx_resetdone_updated_q <= gt_status_tx_resetdone_updated_w;

    gt_status_rx_resetdone_updated_q <= gt_status_rx_resetdone_updated_w;

    gt_status_cpll_lock_updated_q    <= gt_allch_cpll_lock;

    gt_status_qpll_lock_updated_q    <= cfg_phy_mem_map_status[`QPLLLOCK];

    gt_status_qpll1_lock_updated_q   <= cfg_phy_mem_map_status[`QPLL1LOCK];

    gt_status_tx_alignment_updated_q <= gt_allch_txalign_done;
	
	imr_reg <= imr;

    mmcm_tx_usrclk_lock_event_updated_q   <=  cfg_phy_mem_map_status[`MMCM_TXUSRCLK_LOCKED];
    mmcm_rx_usrclk_lock_event_updated_q   <=  cfg_phy_mem_map_status[`MMCM_RXUSRCLK_LOCKED];
    clkdet_tx_freq_event_updated_q   <=  cfg_phy_mem_map_status[`CLKDET_TX_FREQ_EVENT];
    
    clkdet_rx_freq_event_updated_q   <=  cfg_phy_mem_map_status[`CLKDET_RX_FREQ_EVENT];
    
    clkdet_tx_timer_event_updated_q  <=  cfg_phy_mem_map_status[`CLKDET_TX_TMR_EVENT];
    
    clkdet_rx_timer_event_updated_q  <=  cfg_phy_mem_map_status[`CLKDET_RX_TMR_EVENT];
  end

  assign gt_status_tx_resetdone_updated    = (gt_status_tx_resetdone_updated_q != gt_status_tx_resetdone_updated_w);
  assign gt_status_rx_resetdone_updated    = (gt_status_rx_resetdone_updated_q != gt_status_rx_resetdone_updated_w);
  assign gt_status_cpll_lock_updated       = (gt_status_cpll_lock_updated_q    != gt_allch_cpll_lock);
  assign gt_status_qpll_lock_updated       = (gt_status_qpll_lock_updated_q    != cfg_phy_mem_map_status[`QPLLLOCK]);
  assign gt_status_qpll1_lock_updated      = (gt_status_qpll1_lock_updated_q   != cfg_phy_mem_map_status[`QPLL1LOCK]);
  assign gt_status_tx_alignment_updated    = (gt_status_tx_alignment_updated_q != gt_allch_txalign_done);
  assign mmcm_tx_usrclk_lock_event_re      = (~mmcm_tx_usrclk_lock_event_updated_q & cfg_phy_mem_map_status[`MMCM_TXUSRCLK_LOCKED]);
  assign mmcm_rx_usrclk_lock_event_re      = (~mmcm_rx_usrclk_lock_event_updated_q & cfg_phy_mem_map_status[`MMCM_RXUSRCLK_LOCKED]);
  assign clkdet_tx_freq_event_updated_re   = (~clkdet_tx_freq_event_updated_q  & cfg_phy_mem_map_status[`CLKDET_TX_FREQ_EVENT]);
  assign clkdet_rx_freq_event_updated_re   = (~clkdet_rx_freq_event_updated_q  & cfg_phy_mem_map_status[`CLKDET_RX_FREQ_EVENT]);
  assign clkdet_tx_timer_event_updated_re  = (~clkdet_tx_timer_event_updated_q & cfg_phy_mem_map_status[`CLKDET_TX_TMR_EVENT]);
  assign clkdet_rx_timer_event_updated_re  = (~clkdet_rx_timer_event_updated_q & cfg_phy_mem_map_status[`CLKDET_RX_TMR_EVENT]);

  vid_phy_controller_v2_2_2_interrupts vid_phy_controller_interrupts_inst
  (
    .clk                        (S_AXI_ACLK),
    .rst_n                      (S_AXI_ARESETN),
    .wr_en_2_isr                (wr_en_2_isr),
    .wr_en_2_ier                (wr_en_2_ier),
    .wr_en_2_idr                (wr_en_2_idr),
    .isr_write                  (isr_write),
    .isr_read                   (isr_read),
    .ier                        (ier),
    .idr                        (idr),
    .imr                        (imr),

    .gt_status_tx_resetdone_updated (gt_status_tx_resetdone_updated),
    .gt_status_rx_resetdone_updated (gt_status_rx_resetdone_updated),
    .gt_status_cpll_lock_updated    (gt_status_cpll_lock_updated),
    .gt_status_qpll_lock_updated    (gt_status_qpll_lock_updated),
    .gt_status_tx_alignment_updated (gt_status_tx_alignment_updated),
    .gt_status_qpll1_lock_updated   (gt_status_qpll1_lock_updated),
    .mmcm_tx_usrclk_lock_event_updated  (mmcm_tx_usrclk_lock_event_re),
    .mmcm_rx_usrclk_lock_event_updated  (mmcm_rx_usrclk_lock_event_re),
    .clkdet_tx_timer_event_updated  (clkdet_tx_timer_event_updated_re),
    .clkdet_tx_freq_event_updated   (clkdet_tx_freq_event_updated_re),
    .clkdet_rx_timer_event_updated  (clkdet_rx_timer_event_updated_re),
    .clkdet_rx_freq_event_updated   (clkdet_rx_freq_event_updated_re),

    .irq                        (irq) 
  );
  generate
    if (C_Err_Irq_En == 1)
    begin
        localparam integer N_ERR_IRQ_BITS = 6;
        reg  [N_ERR_IRQ_BITS-1:0] slv_reg_0x3C_q;
        wire [N_ERR_IRQ_BITS-1:0] slv_reg_0x3C_re;
        genvar i;
        for (i=0; i<N_ERR_IRQ_BITS-1; i=i+1) 
        begin : gen_err_irq_bits
            always @(posedge S_AXI_ACLK) 
                begin
                    slv_reg_0x3C_q[i] <= slv_reg_0x3C[i];
                end  
            assign slv_reg_0x3C_re[i] = (~slv_reg_0x3C_q[i] & slv_reg_0x3C[i]);
        end
        assign err_irq = |slv_reg_0x3C_re;
    end
    else
    begin
        assign err_irq = 0;
    end
  endgenerate

endmodule
