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
    input logic [15:0] i_cfg_completer_id,                  // Bus, Device, Function
    // Memory access signals:
    input logic i_req_mem_ready,                            // Ready to accept next memory request
    output logic o_req_mem_valid,                           // Request data is valid to accept
    output logic o_req_mem_write,                           // 0=read; 1=write operation
    output logic [9:0] o_req_mem_bytes,                     // 0=1024 B; 4=DWORD; 8=QWORD; ...
    output logic [12:0] o_req_mem_addr,                     // Address to read/write
    output logic [7:0] o_req_mem_strob,                     // Byte enabling write strob
    output logic [63:0] o_req_mem_data,                     // Data to write
    output logic o_req_mem_last,                            // Last data payload in a sequence
    input logic i_resp_mem_valid,                           // Read/Write data is valid. All write transaction with valid response.
    input logic i_resp_mem_last,                            // Last response in sequence
    input logic i_resp_mem_fault,                           // Error on memory access
    input logic [12:0] i_resp_mem_addr,                     // Read address value
    input logic [63:0] i_resp_mem_data,                     // Read data value
    output logic o_resp_mem_ready                           // Ready to accept response
);

logic w_tx_ena;
logic w_tx_completion;
logic w_tx_with_data;
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
logic [9:0] wb_req_bytes;
logic [C_DATA_WIDTH-1:0] wb_req_mem_data;
logic [C_DATA_WIDTH-1:0] wb_resp_mem_data;

function logic [63:0] SwapEndianess32(input logic [63:0] dword);
logic [63:0] ret;
begin
    ret[31: 0] = {dword[7: 0],
            dword[15: 8],
            dword[23: 16],
            dword[31: 24]};
    ret[63: 32] = {dword[39: 32],
            dword[47: 40],
            dword[55: 48],
            dword[63: 56]};
    return ret;
end
endfunction: SwapEndianess32

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
    .o_tx_ena(w_tx_ena),
    .o_tx_completion(w_tx_completion),
    .o_tx_with_data(w_tx_with_data),
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
    .i_req_mem_ready(i_req_mem_ready),
    .o_req_mem_valid(o_req_mem_valid),
    .o_req_mem_write(o_req_mem_write),
    .o_req_mem_bytes(wb_req_bytes),
    .o_req_mem_addr(o_req_mem_addr),
    .o_req_mem_strob(o_req_mem_strob),
    .o_req_mem_data(wb_req_mem_data),
    .o_req_mem_last(o_req_mem_last),
    .i_resp_mem_valid(i_resp_mem_valid)
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
    .i_tx_ena(w_tx_ena),
    .i_tx_completion(w_tx_completion),
    .i_tx_with_data(w_tx_with_data),
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
    .i_req_bytes(wb_req_bytes),
    .i_dma_resp_valid(i_resp_mem_valid),
    .i_dma_resp_last(i_resp_mem_last),
    .i_dma_resp_fault(i_resp_mem_fault),
    .i_dma_resp_addr(i_resp_mem_addr),
    .i_dma_resp_data(wb_resp_mem_data),
    .o_dma_resp_ready(o_resp_mem_ready),
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


    // Correct PCIe endieness:
    o_req_mem_data = SwapEndianess32(wb_req_mem_data);
    wb_resp_mem_data = SwapEndianess32(i_resp_mem_data);
end: comb_proc

assign o_req_mem_bytes = wb_req_bytes;

endmodule: pcie_io_ep
