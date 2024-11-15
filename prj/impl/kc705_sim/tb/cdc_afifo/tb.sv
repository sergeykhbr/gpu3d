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

// pcie user clock 62.5 MHz
`define SCLK_PERIOD1 16ns
// system clock 40 MHz
`define SCLK_PERIOD2 25ns

module tb;

    parameter real HALF_PERIOD1 = `SCLK_PERIOD1 / 2.0;
    parameter real HALF_PERIOD2 = `SCLK_PERIOD2 / 2.0;

    //! Input reset. Active LOW.
    logic i_wrstn;
    logic i_rrstn;
    // Clocks
    wire i_wclk;
    wire i_rclk;

    logic wclk;
    logic rclk;
    int wclk_cnt;
    int rclk_cnt;

    logic i_wr;
    logic [31:0] i_wdata;
    logic o_wfull;
    logic i_rd;
    logic [31:0] o_rdata;                       // fifo payload read
    logic o_rempty;


  initial begin
    wclk = 0;
    rclk = 0;
  end

  always #HALF_PERIOD1 wclk=~wclk;
  always #HALF_PERIOD2 rclk=~rclk;

  always_ff@(posedge wclk) begin
    if (wclk_cnt <= 10) begin
        i_wrstn <= 1'b0;
        i_wr <= 1'b0;
        i_wdata <= '0;
    end else begin
        i_wrstn <= 1'b1;
        i_wr <= 1'b0;
        i_wdata <= '0;
        if ((wclk_cnt % 12) == 11 && o_wfull == 1'b0) begin
            i_wr <= 1'b1;
            i_wdata <= 32'h11220000 + wclk_cnt;
        end
    end
    wclk_cnt <= wclk_cnt + 1;
  end

  always_ff@(posedge rclk) begin
    if (rclk_cnt <= 10) begin
        i_rrstn <= 1'b0;
        i_rd <= 1'b0;
    end else begin
        i_rrstn <= 1'b1;
        i_rd <= 1'b0;
        if ((rclk_cnt % 5) == 4 && o_rempty == 1'b0) begin
            i_rd <= 1'b1;
        end
    end
    rclk_cnt <= rclk_cnt + 1;
  end

  cdc_afifo #(
    .abits(2),
    .dbits(32)
  ) tt (
    .i_wclk(wclk),
    .i_wrstn(i_wrstn),
    .i_wr(i_wr),
    .i_wdata(i_wdata),
    .o_wfull(o_wfull),
    .i_rclk(rclk),
    .i_rrstn(i_rrstn),
    .i_rd(i_rd),
    .o_rdata(o_rdata),
    .o_rempty(o_rempty)
  );


endmodule
