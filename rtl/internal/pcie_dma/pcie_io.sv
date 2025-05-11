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

module pcie_io #(
    parameter int C_DATA_WIDTH = 64,
    parameter int KEEP_WIDTH = (C_DATA_WIDTH / 8)
)
(
    input logic i_clk,                                      // System bus clock
    input logic i_user_clk,                                 // PCIE PHY clock
    input logic i_user_reset,
    input logic i_user_lnk_up,
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
    input logic [21:0] i_m_axis_rx_tuser,
    // 
    input logic i_cfg_to_turnoff,
    output logic o_cfg_turnoff_ok,
    input logic [15:0] i_cfg_completer_id                   // Bus, Device, Function
);

import pcie_cfg_pkg::*;
// 
localparam int REQ_FIFO_WIDTH = (22  // i_m_axis_rx_tuser
        + 1  // i_m_axis_rx_tlast
        + KEEP_WIDTH  // i_m_axis_rx_tkeep
        + C_DATA_WIDTH  // i_m_axis_rx_tdata
);
localparam int RESP_FIFO_WIDTH = (1  // o_tx_src_dsc
        + 1  // o_s_axis_tx_tlast
        + KEEP_WIDTH  // o_s_axis_tx_tkeep
        + C_DATA_WIDTH  // o_s_axis_tx_tdata
);

logic [REQ_FIFO_WIDTH-1:0] wb_reqfifo_payload_i;
logic [REQ_FIFO_WIDTH-1:0] wb_reqfifo_payload_o;
logic w_m_axis_rx_tready;
logic w_m_axis_rx_tvalid;
logic [C_DATA_WIDTH-1:0] wb_m_axis_rx_tdata;
logic [KEEP_WIDTH-1:0] wb_m_axis_rx_tkeep;
logic w_m_axis_rx_tlast;
logic [21:0] wb_m_axis_rx_tuser;
logic [RESP_FIFO_WIDTH-1:0] wb_respfifo_payload_i;
logic [RESP_FIFO_WIDTH-1:0] wb_respfifo_payload_o;
logic w_s_axis_tx_tready;
logic w_s_axis_tx_tvalid;
logic w_tx_src_dsc;
logic w_s_axis_tx_tlast;
logic [KEEP_WIDTH-1:0] wb_s_axis_tx_tkeep;
logic [C_DATA_WIDTH-1:0] wb_s_axis_tx_tdata;
// 
logic w_req_compl;
logic w_compl_done;
logic r_trn_pending;                                        // Transaction pending
logic r_cfg_turnoff_ok;                                     // Turn-off handshake

// PCIE EP (200 MHz) -> DMA (40 MHz)
cdc_afifo #(
    .abits(CFG_PCIE_DMAFIFO_DEPTH),
    .dbits(REQ_FIFO_WIDTH)
) reqfifo (
    .i_nrst(i_user_lnk_up),
    .i_wclk(i_user_clk),
    .i_wr(i_m_axis_rx_tvalid),
    .i_wdata(wb_reqfifo_payload_i),
    .o_wready(o_m_axis_rx_tready),
    .i_rclk(i_clk),
    .i_rd(w_m_axis_rx_tready),
    .o_rdata(wb_reqfifo_payload_o),
    .o_rvalid(w_m_axis_rx_tvalid)
);

// DMA (40 MHz) -> PCIE EP (200 MHz)
cdc_afifo #(
    .abits(CFG_PCIE_DMAFIFO_DEPTH),
    .dbits(RESP_FIFO_WIDTH)
) respfifo (
    .i_nrst(i_user_lnk_up),
    .i_wclk(i_clk),
    .i_wr(w_s_axis_tx_tvalid),
    .i_wdata(wb_respfifo_payload_i),
    .o_wready(w_s_axis_tx_tready),
    .i_rclk(i_user_clk),
    .i_rd(i_s_axis_tx_tready),
    .o_rdata(wb_respfifo_payload_o),
    .o_rvalid(o_s_axis_tx_tvalid)
);

PIO_EP #(
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH)
) PIO_EP_inst (
    .i_nrst(i_user_lnk_up),
    .i_clk(i_clk),
    .i_s_axis_tx_tready(w_s_axis_tx_tready),
    .o_s_axis_tx_tdata(wb_s_axis_tx_tdata),
    .o_s_axis_tx_tkeep(wb_s_axis_tx_tkeep),
    .o_s_axis_tx_tlast(w_s_axis_tx_tlast),
    .o_s_axis_tx_tvalid(w_s_axis_tx_tvalid),
    .o_tx_src_dsc(w_tx_src_dsc),
    .i_m_axis_rx_tdata(wb_m_axis_rx_tdata),
    .i_m_axis_rx_tkeep(wb_m_axis_rx_tkeep),
    .i_m_axis_rx_tlast(w_m_axis_rx_tlast),
    .i_m_axis_rx_tvalid(w_m_axis_rx_tvalid),
    .o_m_axis_rx_tready(w_m_axis_rx_tready),
    .i_m_axis_rx_tuser(wb_m_axis_rx_tuser),
    .o_req_compl(w_req_compl),
    .o_compl_done(w_compl_done),
    .i_cfg_completer_id(i_cfg_completer_id)
);

// PCIE PHY clock to system clock AFIFO:
assign wb_reqfifo_payload_i = {i_m_axis_rx_tuser,
        i_m_axis_rx_tlast,
        i_m_axis_rx_tkeep,
        i_m_axis_rx_tdata};

assign wb_m_axis_rx_tuser = wb_reqfifo_payload_o[94: 73];
assign w_m_axis_rx_tlast = wb_reqfifo_payload_o[72];
assign wb_m_axis_rx_tkeep = wb_reqfifo_payload_o[71: 64];
assign wb_m_axis_rx_tdata = wb_reqfifo_payload_o[63: 0];

// System Clock to PCIE PHY clock AFIFO:
assign wb_respfifo_payload_i = {w_tx_src_dsc,
        w_s_axis_tx_tlast,
        wb_s_axis_tx_tkeep,
        wb_s_axis_tx_tdata};

assign o_tx_src_dsc = wb_respfifo_payload_o[73];
assign o_s_axis_tx_tlast = wb_respfifo_payload_o[72];
assign o_s_axis_tx_tkeep = wb_respfifo_payload_o[71: 64];
assign o_s_axis_tx_tdata = wb_respfifo_payload_o[63: 0];

assign o_cfg_turnoff_ok = r_cfg_turnoff_ok;


always_ff @(posedge i_user_clk) begin: reqff_proc
    if (i_user_lnk_up == 1'b0) begin
        r_trn_pending = 1'b0;
        r_cfg_turnoff_ok = 1'b0;
    end else begin
        if ((r_trn_pending == 1'b0) && (w_req_compl == 1'b1)) begin
            r_trn_pending = 1'b1;
        end else if (w_compl_done == 1'b1) begin
            r_trn_pending = 1'b0;
        end

        if ((r_trn_pending == 1'b0) && (i_cfg_to_turnoff == 1'b1)) begin
            r_cfg_turnoff_ok = 1'b1;
        end else begin
            r_cfg_turnoff_ok = 1'b0;
        end
    end
end: reqff_proc

endmodule: pcie_io
