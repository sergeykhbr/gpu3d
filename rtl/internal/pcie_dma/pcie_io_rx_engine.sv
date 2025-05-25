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

module pcie_io_rx_engine #(
    parameter int C_DATA_WIDTH = 64,
    parameter int KEEP_WIDTH = (C_DATA_WIDTH / 8)
)
(
    input logic i_nrst,
    input logic i_clk,                                      // System bus clock
    // 
    input logic [C_DATA_WIDTH-1:0] i_m_axis_rx_tdata,
    input logic [KEEP_WIDTH-1:0] i_m_axis_rx_tkeep,
    input logic i_m_axis_rx_tlast,
    input logic i_m_axis_rx_tvalid,
    output logic o_m_axis_rx_tready,
    input logic [8:0] i_m_axis_rx_tuser,
    // 
    output logic o_tx_ena,                                  // Trigger Tx engine to wait response from xDMA
    output logic o_tx_completion,                           // Transmit completion TLP
    output logic o_tx_with_data,                            // Transmit TLP with payload
    input logic i_compl_done,
    // 
    output logic [2:0] o_req_tc,                            // Memory Read TC
    output logic o_req_td,                                  // Memory Read TD
    output logic o_req_ep,                                  // Memory Read EP
    output logic [1:0] o_req_attr,                          // Memory Read Attribute
    output logic [9:0] o_req_len,                           // Memory Read Length (1DW)
    output logic [15:0] o_req_rid,                          // Memory Read Requestor ID
    output logic [7:0] o_req_tag,                           // Memory Read Tag
    output logic [7:0] o_req_be,                            // Memory Read Byte Enables
    output logic [pcie_cfg_pkg::CFG_PCIE_DMAADDR_WIDTH-1:0] o_req_addr,// Memory Read Address
    // 
    input logic i_req_mem_ready,                            // Ready to accept next memory request
    output logic o_req_mem_valid,                           // Request data is valid to accept
    output logic o_req_mem_write,                           // 0=read; 1=write operation
    output logic [9:0] o_req_mem_bytes,                     // 0=1024 B; 4=DWORD; 8=QWORD; ...
    output logic [pcie_cfg_pkg::CFG_PCIE_DMAADDR_WIDTH-1:0] o_req_mem_addr,// Address to read/write
    output logic [7:0] o_req_mem_strob,                     // Byte enabling write strob
    output logic [63:0] o_req_mem_data,                     // Data to write
    output logic o_req_mem_last,                            // Last data payload in a sequence
    input logic i_resp_mem_valid                            // Read/Write data is valid. All write transaction with valid response.
);

import pcie_cfg_pkg::*;

localparam bit [6:0] PIO_RX_MEM_RD32_FMT_TYPE = 7'h00;
localparam bit [6:0] PIO_RX_MEM_WR32_FMT_TYPE = 7'h40;
localparam bit [6:0] PIO_RX_MEM_RD64_FMT_TYPE = 7'h20;
localparam bit [6:0] PIO_RX_MEM_WR64_FMT_TYPE = 7'h60;
localparam bit [6:0] PIO_RX_IO_RD32_FMT_TYPE = 7'h02;
localparam bit [6:0] PIO_RX_IO_WR32_FMT_TYPE = 7'h42;

localparam bit [6:0] PIO_RX_RST_STATE = 7'h00;
localparam bit [6:0] PIO_RX_MEM_RD32_DW1DW2 = 7'h01;
localparam bit [6:0] PIO_RX_MEM_WR32_DW1DW2 = 7'h02;
localparam bit [6:0] PIO_RX_MEM_RD64_DW1DW2 = 7'h04;
localparam bit [6:0] PIO_RX_MEM_WR64_DW1DW2 = 7'h08;
localparam bit [6:0] PIO_RX_MEM_WR_BURST = 7'h10;
localparam bit [6:0] PIO_RX_IO_WR_DW1DW2 = 7'h20;           // Burst disabled
localparam bit [6:0] PIO_RX_WAIT_TX_COMPLETION = 7'h40;
// TLP Response Types:
localparam bit [2:0] TLP_NON_POSTED = 3'h1;                 // No response at all
localparam bit [2:0] TLP_POSTED = 3'h5;                     // Response with data payload
localparam bit [2:0] TLP_COMPLETION = 3'h3;                 // Response without payload

typedef struct {
    logic m_axis_rx_tready;
    logic req_valid;
    logic req_last;
    logic [2:0] req_tc;
    logic req_td;
    logic req_ep;
    logic [1:0] req_attr;
    logic [9:0] req_len;
    logic [15:0] req_rid;
    logic [7:0] req_tag;
    logic [7:0] req_be;
    logic [9:0] req_bytes;
    logic [CFG_PCIE_DMAADDR_WIDTH-1:0] req_addr;
    logic wr_en;
    logic [63:0] wr_data;
    logic [7:0] wr_strob;
    logic [31:0] wr_data_dw1;                               // Odd word in a burst sequence
    logic wr_dw1_valid;                                     // Not last DW1 was received in burst sequence
    logic [6:0] state;
    logic [7:0] tlp_type;
    logic [2:0] tlp_resp;
} pcie_io_rx_engine_registers;

const pcie_io_rx_engine_registers pcie_io_rx_engine_r_reset = '{
    1'b0,                               // m_axis_rx_tready
    1'b0,                               // req_valid
    1'b0,                               // req_last
    3'd0,                               // req_tc
    1'b0,                               // req_td
    1'b0,                               // req_ep
    2'd0,                               // req_attr
    10'd0,                              // req_len
    16'd0,                              // req_rid
    8'd0,                               // req_tag
    8'd0,                               // req_be
    '0,                                 // req_bytes
    34'd0,                              // req_addr
    1'b0,                               // wr_en
    '0,                                 // wr_data
    '0,                                 // wr_strob
    '0,                                 // wr_data_dw1
    '0,                                 // wr_dw1_valid
    PIO_RX_RST_STATE,                   // state
    8'd0,                               // tlp_type
    '0                                  // tlp_resp
};
pcie_io_rx_engine_registers r;
pcie_io_rx_engine_registers rin;


always_comb
begin: comb_proc
    pcie_io_rx_engine_registers v;
    logic [1:0] vb_req_addr_1_0;
    logic [1:0] vb_add_be20;
    logic [1:0] vb_add_be21;
    logic [9:0] vb_req_bytes;
    logic [CFG_PCIE_DMAADDR_WIDTH-1:0] vb_bar_offset;
    logic [CFG_PCIE_DMAADDR_WIDTH-1:0] vb_addr_ldw;
    logic [CFG_PCIE_DMAADDR_WIDTH-1:0] vb_addr_mdw;

    v = r;
    vb_req_addr_1_0 = '0;
    vb_add_be20 = '0;
    vb_add_be21 = '0;
    vb_req_bytes = '0;
    vb_bar_offset = '0;
    vb_addr_ldw = '0;
    vb_addr_mdw = '0;


    if (i_m_axis_rx_tuser[2] == 1'b1) begin                 // Select BAR0 region
        vb_bar_offset = 34'h008000000;                      // BAR0, 32-bits, 2MB, SRAM
    end else begin
        vb_bar_offset = 34'h080000000;                      // BAR2/BAR3 64-bits, 4GB to DDR
    end

    if (r.req_be[0] == 1'b1) begin
        vb_req_addr_1_0 = 2'd0;
    end else if (r.req_be[1] == 1'b1) begin
        vb_req_addr_1_0 = 2'd1;
    end else if (r.req_be[2] == 1'b1) begin
        vb_req_addr_1_0 = 2'd2;
    end else if (r.req_be[3] == 1'b1) begin
        vb_req_addr_1_0 = 2'd3;
    end
    // Max implemented BAR is 4GB so take 32-bits of address
    vb_addr_ldw = {vb_bar_offset[(CFG_PCIE_DMAADDR_WIDTH - 1): 16],
            i_m_axis_rx_tdata[15: 2],
            vb_req_addr_1_0};
    vb_addr_mdw = {vb_bar_offset[(CFG_PCIE_DMAADDR_WIDTH - 1): 16],
            i_m_axis_rx_tdata[47: 34],
            vb_req_addr_1_0};

    // Calculate byte count based on byte enable
    vb_add_be20 = ({1'b0, r.req_be[3]} + {1'b0, r.req_be[2]});
    vb_add_be21 = ({1'b0, r.req_be[1]} + {1'b0, r.req_be[0]});
    if (r.req_len == 10'd1) begin
        vb_req_bytes = ({8'd0, vb_add_be20} + {8'd0, vb_add_be21});
    end else begin
        vb_req_bytes = {r.req_len, 2'd0};
    end

    if (i_req_mem_ready == 1'b1) begin
        v.req_valid = 1'b0;
        v.req_last = 1'b0;
    end
    if (i_m_axis_rx_tvalid == 1'b1) begin
        v.m_axis_rx_tready = 1'b0;
    end

    case (r.state)
    PIO_RX_RST_STATE: begin
        v.m_axis_rx_tready = 1'b1;
        v.tlp_resp = 3'd0;
        v.wr_en = 1'b0;                                     // IO Write
        v.wr_strob = 8'd0;
        v.wr_data = 64'd0;
        v.req_len = 10'd0;

        if ((r.m_axis_rx_tready == 1'b1) && (i_m_axis_rx_tvalid == 1'b1)) begin
            v.tlp_type = i_m_axis_rx_tdata[31: 24];
            v.req_tc = i_m_axis_rx_tdata[22: 20];
            v.req_td = i_m_axis_rx_tdata[15];
            v.req_ep = i_m_axis_rx_tdata[14];
            v.req_attr = i_m_axis_rx_tdata[13: 12];
            v.req_len = i_m_axis_rx_tdata[9: 0];
            v.req_rid = i_m_axis_rx_tdata[63: 48];
            v.req_tag = i_m_axis_rx_tdata[47: 40];
            v.req_be = i_m_axis_rx_tdata[39: 32];

            case (i_m_axis_rx_tdata[30: 24])
            PIO_RX_MEM_RD32_FMT_TYPE: begin
                v.state = PIO_RX_MEM_RD32_DW1DW2;
            end

            PIO_RX_MEM_WR32_FMT_TYPE: begin
                v.state = PIO_RX_MEM_WR32_DW1DW2;
                v.wr_en = 1'b1;
            end

            PIO_RX_MEM_RD64_FMT_TYPE: begin
                v.state = PIO_RX_MEM_RD64_DW1DW2;
            end

            PIO_RX_MEM_WR64_FMT_TYPE: begin
                v.state = PIO_RX_MEM_WR64_DW1DW2;
                v.wr_en = 1'b1;
            end

            PIO_RX_IO_RD32_FMT_TYPE: begin
                v.state = PIO_RX_MEM_RD32_DW1DW2;
            end

            PIO_RX_IO_WR32_FMT_TYPE: begin
                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.state = PIO_RX_IO_WR_DW1DW2;
                    v.wr_en = 1'b1;
                end
            end

            default: begin
                v.state = PIO_RX_RST_STATE;
            end
            endcase
        end else begin
            v.state = PIO_RX_RST_STATE;
        end
    end

    PIO_RX_MEM_RD32_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_valid = 1'b1;
            v.req_last = i_m_axis_rx_tlast;
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.tlp_resp = TLP_POSTED;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        end
    end

    PIO_RX_MEM_RD64_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_valid = 1'b1;
            v.req_addr = vb_addr_mdw;
            v.req_bytes = vb_req_bytes;
            v.tlp_resp = TLP_POSTED;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        end
    end

    PIO_RX_MEM_WR32_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_valid = i_m_axis_rx_tlast;
            v.req_last = i_m_axis_rx_tlast;
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.wr_data = {i_m_axis_rx_tdata[63: 32], i_m_axis_rx_tdata[63: 32]};
            v.wr_data_dw1 = i_m_axis_rx_tdata[63: 32];
            if (i_m_axis_rx_tdata[2] == 1'b1) begin
                v.wr_strob = {r.req_be[3: 0], r.req_be[7: 4]};
            end else begin
                v.wr_strob = r.req_be;
            end

            // Burst support:
            v.m_axis_rx_tready = (i_req_mem_ready & (~i_m_axis_rx_tlast));
            if (i_m_axis_rx_tlast == 1'b1) begin
                // Send response after full TLP received:
                v.tlp_resp = TLP_NON_POSTED;
                v.state = PIO_RX_WAIT_TX_COMPLETION;
            end else begin
                v.wr_dw1_valid = 1'b1;
                v.wr_strob = 8'hFF;
                v.state = PIO_RX_MEM_WR_BURST;
            end
        end
    end

    PIO_RX_MEM_WR64_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_addr = vb_addr_mdw;
            v.req_bytes = vb_req_bytes;
            if (i_m_axis_rx_tdata[34] == 1'b1) begin
                v.wr_strob = {r.req_be[3: 0], r.req_be[7: 4]};
            end else begin
                v.wr_strob = r.req_be;
            end
            v.state = PIO_RX_MEM_WR_BURST;
        end
    end

    PIO_RX_MEM_WR_BURST: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.m_axis_rx_tready = (i_req_mem_ready & (~i_m_axis_rx_tlast));
            v.req_valid = 1'b1;
            v.req_last = i_m_axis_rx_tlast;
            if (((|i_m_axis_rx_tkeep[7: 4]) == 1'b1) && ((|i_m_axis_rx_tkeep[3: 0]) == 1'b1)) begin
                if (r.wr_dw1_valid == 1'b1) begin
                    v.wr_data = {i_m_axis_rx_tdata[31: 0], r.wr_data_dw1};
                    v.wr_data_dw1 = i_m_axis_rx_tdata[63: 32];
                end else begin
                    v.wr_data = i_m_axis_rx_tdata;
                end
            end else begin
                v.wr_dw1_valid = 1'b0;
                if (r.wr_dw1_valid == 1'b1) begin
                    v.wr_data = {i_m_axis_rx_tdata[31: 0], r.wr_data_dw1[31: 0]};
                end else begin
                    v.wr_data = {i_m_axis_rx_tdata[31: 0], i_m_axis_rx_tdata[31: 0]};
                end
            end

            if (i_m_axis_rx_tlast == 1'b1) begin
                // Send response after full TLP received:
                v.wr_dw1_valid = 1'b0;                      // Software has to use 8-bytes aligned burst transactions
                v.tlp_resp = TLP_NON_POSTED;
                v.state = PIO_RX_WAIT_TX_COMPLETION;
            end
        end
    end

    PIO_RX_IO_WR_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_valid = 1'b1;
            v.wr_en = 1'b1;
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.wr_data = {i_m_axis_rx_tdata[63: 32], i_m_axis_rx_tdata[63: 32]};
            if (i_m_axis_rx_tdata[2] == 1'b1) begin
                v.wr_strob = {r.req_be[3: 0], r.req_be[7: 4]};
            end else begin
                v.wr_strob = r.req_be;
            end
            v.tlp_resp = TLP_COMPLETION;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        end
    end

    PIO_RX_WAIT_TX_COMPLETION: begin
        if (i_compl_done == 1'b1) begin
            v.m_axis_rx_tready = 1'b1;
            v.wr_en = 1'b0;                                 // IO Write
            v.wr_strob = 8'd0;
            v.wr_data = 64'd0;
            v.req_len = 10'd0;
            v.tlp_resp = 3'd0;
            v.state = PIO_RX_RST_STATE;
        end
    end

    default: begin
        v.state = PIO_RX_RST_STATE;
    end
    endcase

    rin = v;
end: comb_proc


assign o_m_axis_rx_tready = r.m_axis_rx_tready;
assign o_tx_ena = r.tlp_resp[0];
assign o_tx_completion = r.tlp_resp[1];
assign o_tx_with_data = r.tlp_resp[2];
assign o_req_tc = r.req_tc;
assign o_req_td = r.req_td;
assign o_req_ep = r.req_ep;
assign o_req_attr = r.req_attr;
assign o_req_len = r.req_len;
assign o_req_rid = r.req_rid;
assign o_req_tag = r.req_tag;
assign o_req_be = r.req_be;
assign o_req_addr = r.req_addr;

assign o_req_mem_valid = r.req_valid;
assign o_req_mem_write = r.wr_en;
assign o_req_mem_bytes = r.req_bytes;
assign o_req_mem_addr = r.req_addr;
assign o_req_mem_strob = r.wr_strob;
assign o_req_mem_data = r.wr_data;
assign o_req_mem_last = r.req_last;

always_ff @(posedge i_clk, negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
        r <= pcie_io_rx_engine_r_reset;
    end else begin
        r <= rin;
    end
end

endmodule: pcie_io_rx_engine
