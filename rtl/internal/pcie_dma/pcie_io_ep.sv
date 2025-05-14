// 
//  Copyright 2022 Sergey Khabarov, sergeykhbr@gmail.com
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// 

`timescale 1ns/10ps

module pcie_io_ep #(
    parameter int C_DATA_WIDTH = 64,
    parameter int KEEP_WIDTH = (C_DATA_WIDTH / 8)
)
(
    input logic i_nrst,
    input logic i_clk,                                      // System bus clock
    // 
    input logic i_s_axis_tx_tready,
    output logic [C_DATA_WIDTH-1:0] o_s_axis_tx_tdata,
    output logic [KEEP_WIDTH-1:0] o_s_axis_tx_tkeep,
    output logic o_s_axis_tx_tlast,
    output logic o_s_axis_tx_tvalid,
    output logic o_tx_src_dsc,
    // 
    input logic [C_DATA_WIDTH-1:0] i_m_axis_rx_tdata,
    input logic [KEEP_WIDTH-1:0] i_m_axis_rx_tkeep,
    input logic i_m_axis_rx_tlast,
    input logic i_m_axis_rx_tvalid,
    output logic o_m_axis_rx_tready,
    input logic [8:0] i_m_axis_rx_tuser,
    // 
    output logic o_req_compl,
    output logic o_compl_done,
    input logic [15:0] i_cfg_completer_id,                  // Bus, Device, Function
    // Memory access signals:
    output logic o_mem_valid,
    output logic o_mem_wren,
    output logic [7:0] o_mem_wstrb,
    output logic [12:0] o_mem_addr,
    output logic [31:0] o_mem_data
);

logic [10:0] wb_rd_addr;
logic [3:0] wb_rd_be;
logic [31:0] wb_rd_data;
logic [10:0] wb_wr_addr;
logic [3:0] wb_wr_be;
logic [31:0] wb_wr_data;
logic w_wr_en;
logic w_wr_busy;
logic w_req_compl_int;
logic w_req_compl_wd;
logic w_compl_done_int;
logic [2:0] wb_req_tc;
logic w_req_td;
logic w_req_ep;
logic [1:0] wb_req_attr;
logic [9:0] wb_req_len;
logic [15:0] wb_req_rid;
logic [7:0] wb_req_tag;
logic [7:0] wb_req_be;
logic [12:0] wb_req_addr;

PIO_EP_MEM_ACCESS EP_MEM_inst (
    .rst_n(i_nrst),
    .clk(i_clk),
    .rd_addr(wb_rd_addr),
    .rd_be(wb_rd_be),
    .rd_data(wb_rd_data),
    .wr_addr(wb_wr_addr),
    .wr_be(wb_wr_be),
    .wr_data(wb_wr_data),
    .wr_en(w_wr_en),
    .wr_busy(w_wr_busy)
);

pcie_io_rx_engine #(
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH)
) EP_RX_inst (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_m_axis_rx_tdata(i_m_axis_rx_tdata),
    .i_m_axis_rx_tkeep(i_m_axis_rx_tkeep),
    .i_m_axis_rx_tlast(i_m_axis_rx_tlast),
    .i_m_axis_rx_tvalid(i_m_axis_rx_tvalid),
    .o_m_axis_rx_tready(o_m_axis_rx_tready),
    .i_m_axis_rx_tuser(i_m_axis_rx_tuser),
    .o_req_compl(w_req_compl_int),
    .o_req_compl_wd(w_req_compl_wd),
    .i_compl_done(w_compl_done_int),
    .o_req_tc(wb_req_tc),
    .o_req_td(w_req_td),
    .o_req_ep(w_req_ep),
    .o_req_attr(wb_req_attr),
    .o_req_len(wb_req_len),
    .o_req_rid(wb_req_rid),
    .o_req_tag(wb_req_tag),
    .o_req_be(wb_req_be),
    .o_req_addr(wb_req_addr),
    .o_wr_addr(wb_wr_addr),
    .o_wr_be(wb_wr_be),
    .o_wr_data(wb_wr_data),
    .o_wr_en(w_wr_en),
    .i_wr_busy(w_wr_busy)
);

pcie_io_tx_engine #(
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH)
) EP_TX_inst (
    .i_nrst(i_nrst),
    .i_clk(i_clk),
    .i_s_axis_tx_tready(i_s_axis_tx_tready),
    .o_s_axis_tx_tdata(o_s_axis_tx_tdata),
    .o_s_axis_tx_tkeep(o_s_axis_tx_tkeep),
    .o_s_axis_tx_tlast(o_s_axis_tx_tlast),
    .o_s_axis_tx_tvalid(o_s_axis_tx_tvalid),
    .o_tx_src_dsc(o_tx_src_dsc),
    .i_req_compl(w_req_compl_int),
    .i_req_compl_wd(w_req_compl_wd),
    .o_compl_done(w_compl_done_int),
    .i_req_tc(wb_req_tc),
    .i_req_td(w_req_td),
    .i_req_ep(w_req_ep),
    .i_req_attr(wb_req_attr),
    .i_req_len(wb_req_len),
    .i_req_rid(wb_req_rid),
    .i_req_tag(wb_req_tag),
    .i_req_be(wb_req_be),
    .i_req_addr(wb_req_addr),
    .o_rd_addr(wb_rd_addr),
    .o_rd_be(wb_rd_be),
    .i_rd_data(wb_rd_data),
    .i_completer_id(i_cfg_completer_id)
);

always_comb
begin: comb_proc
    logic v_mem_valid;
    logic v_mem_wren;
    logic [12:0] vb_mem_addr;
    logic [7:0] vb_mem_wstrb;
    logic [31:0] vb_mem_data;

    v_mem_valid = 1'b0;
    v_mem_wren = 1'b0;
    vb_mem_addr = '0;
    vb_mem_wstrb = '0;
    vb_mem_data = '0;

    if (w_req_compl_int == 1'b1) begin
        v_mem_valid = 1'b1;
        v_mem_wren = w_wr_en;
        vb_mem_wstrb = wb_wr_be;
        vb_mem_addr = wb_req_addr;
        vb_mem_data = wb_wr_data;
    end
    o_mem_valid = v_mem_valid;
    o_mem_wren = v_mem_wren;
    o_mem_wstrb = {4'd0, vb_mem_wstrb};
    o_mem_addr = vb_mem_addr;
    o_mem_data = vb_mem_data;
end: comb_proc

assign o_req_compl = w_req_compl_int;
assign o_compl_done = w_compl_done_int;

endmodule: pcie_io_ep
