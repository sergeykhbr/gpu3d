
module pcie_req_cdc_afifo_tech (
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

  wire w_rst;
  assign w_rst = ~i_nrst;

  pcie_cdc_afifo f0 (
    .rst(w_rst),
    .wr_clk(i_wclk),
    .rd_clk(i_rclk),
    .din(i_wdata),
    .wr_en(i_wr.valid),
    .rd_en(w_rd),
    .dout(o_rdata),
    .full(o_wfull),
    .empty(o_rempty),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

endmodule
