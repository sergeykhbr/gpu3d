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

`timescale 1 ps / 1 ps

`ifndef SCLK_PERIOD
  // FPGA 200 MHz
  `define SCLK_PERIOD 5ns
`endif


module kc705_top_tb;

    parameter real HALF_PERIOD = `SCLK_PERIOD / 2.0;
    // UART simulation speed-up rate. Directly use as a divider for the 'scaler' register
    // 0=no speed-up, 1=2x speed, 2=4x speed, 3=8x speed, 4=16x speed, .. etc
    parameter int SIM_UART_SPEED_UP_RATE = 3;

    localparam DDR3_CS_WIDTH              = 1;
    localparam DDR3_MEMORY_WIDTH          = 8;
    localparam DDR3_DQ_WIDTH              = 64;
    localparam DDR3_DQS_WIDTH             = 8;
    localparam DDR3_NUM_COMP              = DDR3_DQ_WIDTH/DDR3_MEMORY_WIDTH;

    //! Input reset. Active HIGH.
    logic i_rst;
    logic sys_rst_n;
    //! Differential clock (LVDS) positive/negaive signal.
    wire i_sclk_p;
    wire i_sclk_n;
    //! GPIO: [11:4] LEDs; [3:0] DIP switch
    wire [11:0] io_gpio;
    wire [11:0] io_gpio_in;
    reg [11:0] io_gpio_out;
    bit [11:0] io_gpio_dir;
// I2C
logic w_i2c_scl;
wire w_i2c_sda;
logic w_i2c_nreset;
logic w_hdmi_clk;
logic w_hdmi_hsync;
logic w_hdmi_vsync;
logic w_hdmi_de;
logic [17:0] wb_hdmi_d;
logic w_hdmi_spdif;
logic w_hdmi_spdif_out;
logic w_hdmi_int;
logic w_bufo_i2c0_sda;
logic w_vipo_i2c0_sda;
logic w_vipo_i2c0_sda_dir;
    // JTAG
    logic i_jtag_trst;
    logic i_jtag_tck;
    logic i_jtag_tms;
    logic i_jtag_tdi;
    logic o_jtag_tdo;
    logic o_jtag_vref;
    //! UART1 signals:
    logic i_uart1_rd;
    logic o_uart1_td;
    logic w_uart1_loopback_ena;
    // ddr3
    wire o_ddr3_reset_n;
    wire [0:0] o_ddr3_ck_n;
    wire [0:0] o_ddr3_ck_p;
    wire [0:0] o_ddr3_cke;
    wire [0:0] o_ddr3_cs_n;
    wire o_ddr3_ras_n;
    wire o_ddr3_cas_n;
    wire o_ddr3_we_n;
    wire [7:0] o_ddr3_dm;
    wire [2:0] o_ddr3_ba;
    wire [13:0] o_ddr3_addr;
    wire [63:0] io_ddr3_dq;
    wire [7:0] io_ddr3_dqs_p;
    wire [7:0] io_ddr3_dqs_n;
    wire [0:0] o_ddr3_odt;
    // delayed
    wire [DDR3_DQ_WIDTH-1:0]  wb_ddr3_dq_sdram;
    wire [DDR3_DQS_WIDTH-1:0] wb_ddr3_dqs_p_sdram;
    wire [DDR3_DQS_WIDTH-1:0] wb_ddr3_dqs_n_sdram;
    wire o_ddr3_init_calib_complete;
    // PCIE
    wire rp_sys_clk;
    // PCI-Express Interface
    wire i_pcie_clk_p;
    wire i_pcie_clk_n;
    wire [0:0] i_rp_pci_exp_txn;    // rootport output -> soc endpoint input
    wire [0:0] i_rp_pci_exp_txp;    // rootport output -> soc endpoint input
    wire [0:0] o_ep_pci_exp_txn;    // endpoint output -> rootport input
    wire [0:0] o_ep_pci_exp_txp;    // endpoint output -> rootport input


    logic clk;
    logic pcie_clk_100mhz;
    int clk_cnt;


  initial begin
    clk = 0;
    pcie_clk_100mhz = 0;

    io_gpio_dir = 12'h0;
  end

  always #HALF_PERIOD clk=~clk;
  always #5ns pcie_clk_100mhz = ~pcie_clk_100mhz;

//  assign io_gpio = '0;
  assign (weak0, weak1) io_gpio[11:4]  = 8'h00;
  assign io_gpio[3:0] = 4'hF;

  assign i_sclk_p = clk;
  assign i_sclk_n = ~clk;
  assign i_pcie_clk_p = pcie_clk_100mhz;
  assign i_pcie_clk_n = ~pcie_clk_100mhz;

  assign w_uart1_loopback_ena = 1'b0;

  // always_latch begin

  //     for (int i = 0; i < 12; i++) begin
  //         //io_gpio_in(i) = io_gpio(i);
  //         //io_gpio(i) = (io_gpio_dir(i) == 1'b1) ? io_gpio_out(i) : 1'bZ;
  //     end
  // end

  always_ff@(posedge clk) begin
    if (clk_cnt == 0) begin
        $display("[%t] : System Reset Asserted...", $realtime);
    end

    if (clk_cnt <= 10) begin
        i_rst <= 1'b1;
    end else begin
        if (i_rst) begin
            i_rst <= 1'b0;
            $display("[%t] : System Reset De-asserted...", $realtime);
        end
   end
    clk_cnt <= clk_cnt + 1;
  end
  assign sys_rst_n = ~i_rst;
  assign o_ddr3_init_calib_complete = tt.w_ddr3_init_calib_done;

  kc705_top #(
    .SIM_BYPASS_INIT_CAL("FAST"),  // "FAST"-for simulation true; "OFF"
    .SIMULATION("TRUE"),
    .sim_uart_speedup_rate(SIM_UART_SPEED_UP_RATE)
  ) tt (
    .i_rst (i_rst),
    .i_sclk_p (i_sclk_p),
    .i_sclk_n (i_sclk_n),
    .io_gpio (io_gpio),
    //! JTAG signals:
    .i_jtag_trst(i_jtag_trst),
    .i_jtag_tck(i_jtag_tck),
    .i_jtag_tms(i_jtag_tms),
    .i_jtag_tdi(i_jtag_tdi),
    .o_jtag_tdo(o_jtag_tdo),
    .o_jtag_vref(o_jtag_vref),
    //! UART1 signals:
    .i_uart1_rd(i_uart1_rd),
    .o_uart1_td(o_uart1_td),
    // I2C
    .o_i2c0_scl(w_i2c_scl),
    .io_i2c0_sda(w_i2c_sda),
    .o_i2c0_nreset(w_i2c_nreset),
    // HDMI
    .o_hdmi_clk(w_hdmi_clk),
    .o_hdmi_hsync(w_hdmi_hsync),
    .o_hdmi_vsync(w_hdmi_vsync),
    .o_hdmi_de(w_hdmi_de),
    .o_hdmi_d(wb_hdmi_d),
    .o_hdmi_spdif(w_hdmi_spdif),
    .i_hdmi_spdif_out(w_hdmi_spdif_out),
    .i_hdmi_int(w_hdmi_int),
    // DDR signals:
    .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_ck_n(o_ddr3_ck_n),
    .o_ddr3_ck_p(o_ddr3_ck_p),
    .o_ddr3_cke(o_ddr3_cke),
    .o_ddr3_cs_n(o_ddr3_cs_n),
    .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n),
    .o_ddr3_we_n(o_ddr3_we_n),
    .o_ddr3_dm(o_ddr3_dm),
    .o_ddr3_ba(o_ddr3_ba),
    .o_ddr3_addr(o_ddr3_addr),
    .io_ddr3_dq(io_ddr3_dq),
    .io_ddr3_dqs_p(io_ddr3_dqs_p),
    .io_ddr3_dqs_n(io_ddr3_dqs_n),
    .o_ddr3_odt(o_ddr3_odt),
    // PCI-Express Interface
    .i_pcie_nrst(sys_rst_n),
    .i_pcie_clk_p(i_pcie_clk_p),
    .i_pcie_clk_n(i_pcie_clk_n),
    .i_pcie_rxn(i_rp_pci_exp_txn),
    .i_pcie_rxp(i_rp_pci_exp_txp),
    .o_pcie_txn(o_ep_pci_exp_txn),
    .o_pcie_txp(o_ep_pci_exp_txp)
  );

  // Global signals for Xilinx unisim modules:
  glbl glbl();


// I2C slave + IO buffer
iobuf_tech iosda0 (
    .io(w_i2c_sda),
    .o(w_bufo_i2c0_sda),
    .i(w_vipo_i2c0_sda),
    .t(w_vipo_i2c0_sda_dir)
);

vip_i2c_s #(
    .async_reset(1'b1)
) i2c0 (
    .i_clk(clk),
    .i_nrst(sys_rst_n),
    .i_scl(w_i2c_scl),
    .i_sda(w_bufo_i2c0_sda),
    .o_sda(w_vipo_i2c0_sda),
    .o_sda_dir(w_vipo_i2c0_sda_dir)
);

  vip_uart_top #(
    .async_reset(1),
    .instnum(0),
    .baudrate(115200 * (2**SIM_UART_SPEED_UP_RATE)),
    .scaler(8)
  ) UART0 (
    .i_nrst(sys_rst_n),
    .i_rx(o_uart1_td),
    .o_tx(i_uart1_rd),
    .i_loopback_ena(w_uart1_loopback_ena)
  );


  //
  // PCI-Express Model Root Port Instance
  //
  sys_clk_gen  # (
    .halfcycle(5000), // 5000 - 100 MHz, 4000 - 125 MHz,  2000 - 250 MHz
    .offset(0)
  ) CLK_GEN_RP (
    .sys_clk(rp_sys_clk)
  );


  xilinx_pcie_2_1_rport_7x # (
    .REF_CLK_FREQ(0),
    .PL_FAST_TRAIN("TRUE"),
    .ALLOW_X8_GEN2("FALSE"),
    .C_DATA_WIDTH(64),
    .LINK_CAP_MAX_LINK_WIDTH(6'h1),
    .DEVICE_ID(16'h7100),
    .LINK_CAP_MAX_LINK_SPEED(4'h2),
    .LINK_CTRL2_TARGET_LINK_SPEED(4'h2),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED(2),
    .TRN_DW("FALSE"),
    .VC0_TX_LASTPACKET(29),
    .VC0_RX_RAM_LIMIT(13'h7FF),
    .VC0_CPL_INFINITE("TRUE"),
    .VC0_TOTAL_CREDITS_PD(437),
    .VC0_TOTAL_CREDITS_CD(461),
    .USER_CLK_FREQ(1),
    .USER_CLK2_DIV2("FALSE")
  )
  RP (
    // SYS Inteface
    .sys_clk(rp_sys_clk),
    .sys_rst_n(sys_rst_n),
    // PCI-Express Interface
    .pci_exp_txn(i_rp_pci_exp_txn),
    .pci_exp_txp(i_rp_pci_exp_txp),
    .pci_exp_rxn(o_ep_pci_exp_txn),
    .pci_exp_rxp(o_ep_pci_exp_txp)
  );

  //===========================================================================
  // DDR3 env. simulation:
  //===========================================================================
  genvar dqwd;
  generate
    for (dqwd = 1; dqwd < DDR3_DQ_WIDTH; dqwd = dqwd+1) begin : dq_delay
      WireDelay # (
        .Delay_g    (0.00),
        .Delay_rd   (0.00),
        .ERR_INSERT ("OFF")
       ) u_delay_dq (
        .A             (io_ddr3_dq[dqwd]),
        .B             (wb_ddr3_dq_sdram[dqwd]),
        .reset         (sys_rst_n),
        .phy_init_done (o_ddr3_init_calib_complete)
       );
    end
    WireDelay # (
      .Delay_g    (0.00),
      .Delay_rd   (0.00),
      .ERR_INSERT ("OFF")
    ) u_delay_dq_0 (
      .A             (io_ddr3_dq[0]),
      .B             (wb_ddr3_dq_sdram[0]),
      .reset         (sys_rst_n),
      .phy_init_done (o_ddr3_init_calib_complete)
    );
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0; dqswd < DDR3_DQS_WIDTH; dqswd = dqswd+1) begin : dqs_delay
      WireDelay # (
        .Delay_g    (0.00),
        .Delay_rd   (0.00),
        .ERR_INSERT ("OFF")
       ) u_delay_dqs_p (
        .A             (io_ddr3_dqs_p[dqswd]),
        .B             (wb_ddr3_dqs_p_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (o_ddr3_init_calib_complete)
       );

      WireDelay # (
        .Delay_g    (0.00),
        .Delay_rd   (0.00),
        .ERR_INSERT ("OFF")
      ) u_delay_dqs_n (
        .A             (io_ddr3_dqs_n[dqswd]),
        .B             (wb_ddr3_dqs_n_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (o_ddr3_init_calib_complete)
       );
    end
  endgenerate

  genvar r,i;
  generate
    for (r = 0; r < DDR3_CS_WIDTH; r = r + 1) begin: mem_rnk
      for (i = 0; i < DDR3_NUM_COMP; i = i + 1) begin: gen_mem
        ddr3_model u_comp_ddr3
          (
           .rst_n   (o_ddr3_reset_n),
           .ck      (o_ddr3_ck_p[(i*DDR3_MEMORY_WIDTH)/72]),
           .ck_n    (o_ddr3_ck_n[(i*DDR3_MEMORY_WIDTH)/72]),
           .cke     (o_ddr3_cke[((i*DDR3_MEMORY_WIDTH)/72)+(1*r)]),
           .cs_n    (o_ddr3_cs_n[((i*DDR3_MEMORY_WIDTH)/72)+(1*r)]),
           .ras_n   (o_ddr3_ras_n),
           .cas_n   (o_ddr3_cas_n),
           .we_n    (o_ddr3_we_n),
           .dm_tdqs (o_ddr3_dm[i]),
           .ba      (o_ddr3_ba), //[r]), // mirror_ca is disabled
           .addr    (o_ddr3_addr), //[r]), // mirror_ca is disabled
           .dq      (wb_ddr3_dq_sdram[DDR3_MEMORY_WIDTH*(i+1)-1:DDR3_MEMORY_WIDTH*(i)]),
           .dqs     (wb_ddr3_dqs_p_sdram[i]),
           .dqs_n   (wb_ddr3_dqs_n_sdram[i]),
           .tdqs_n  (),
           .odt     (o_ddr3_odt[((i*DDR3_MEMORY_WIDTH)/72)+(1*r)])
           );
      end
    end
  endgenerate


  //tap_dpi #(
  //    .HALF_PERIOD(33.7ns)   // some async value to system clock
  //) tap0 (
  //    .i_tdo(o_jtag_tdo),
  //    .o_trst(i_jtag_trst),
  //    .o_tck(i_jtag_tck),
  //    .o_tms(i_jtag_tms),
  //    .o_tdi(i_jtag_tdi)
  //);
  assign i_jtag_trst = 1'b0;
  assign i_jtag_tck = 1'b0;
  assign i_jtag_tms = 1'b0;
  assign i_jtag_tdi = 1'b0;

endmodule
