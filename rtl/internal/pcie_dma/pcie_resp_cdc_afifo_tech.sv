
module pcie_resp_cdc_afifo_tech (
  input i_nrst,
  input i_wclk,
  input i_wr,
  input [72:0] i_wdata,
  output o_wfull,
  input i_rclk,
  input i_rd,
  output [72:0] o_rdata,
  output o_rempty
);

// DMA (40 MHz) -> PCIE EP (200 MHz)
cdc_afifo #(
    .abits(2),
    .dbits(73)
) i1 (
    .i_nrst(i_nrst),
    .i_wclk(i_wclk),
    .i_wr(i_wr),
    .i_wdata(i_wdata),
    .o_wfull(o_wfull),
    .i_rclk(i_rclk),
    .i_rd(i_rd),
    .o_rdata(o_rdata),
    .o_rempty(o_rempty)
);

endmodule
