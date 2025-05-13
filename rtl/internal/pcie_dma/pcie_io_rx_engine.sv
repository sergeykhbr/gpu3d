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
    output logic o_req_compl,
    output logic o_req_compl_wd,                            // req completion without data (IO WR32 request)
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
    output logic [12:0] o_req_addr,                         // Memory Read Address
    // 
    output logic [10:0] o_wr_addr,                          // Memory Write Address
    output logic [3:0] o_wr_be,                             // Memory Write Byte Enable
    output logic [31:0] o_wr_data,                          // Memory Write Data
    output logic o_wr_en,                                   // Memory Write Enable
    input logic i_wr_busy                                   // Memory Write Busy
);


localparam bit [6:0] PIO_RX_MEM_RD32_FMT_TYPE = 7'h00;
localparam bit [6:0] PIO_RX_MEM_WR32_FMT_TYPE = 7'h40;
localparam bit [6:0] PIO_RX_MEM_RD64_FMT_TYPE = 7'h20;
localparam bit [6:0] PIO_RX_MEM_WR64_FMT_TYPE = 7'h60;
localparam bit [6:0] PIO_RX_IO_RD32_FMT_TYPE = 7'h02;
localparam bit [6:0] PIO_RX_IO_WR32_FMT_TYPE = 7'h42;

localparam bit [7:0] PIO_RX_RST_STATE = 8'h00;
localparam bit [7:0] PIO_RX_MEM_RD32_DW1DW2 = 8'h01;
localparam bit [7:0] PIO_RX_MEM_WR32_DW1DW2 = 8'h02;
localparam bit [7:0] PIO_RX_MEM_RD64_DW1DW2 = 8'h04;
localparam bit [7:0] PIO_RX_MEM_WR64_DW1DW2 = 8'h08;
localparam bit [7:0] PIO_RX_MEM_WR64_DW3 = 8'h10;
localparam bit [7:0] PIO_RX_WAIT_STATE = 8'h20;
localparam bit [7:0] PIO_RX_IO_WR_DW1DW2 = 8'h40;
localparam bit [7:0] PIO_RX_IO_MEM_WR_WAIT_STATE = 8'h80;

typedef struct {
    logic m_axis_rx_tready;
    logic req_compl;
    logic req_compl_wd;
    logic [2:0] req_tc;
    logic req_td;
    logic req_ep;
    logic [1:0] req_attr;
    logic [9:0] req_len;
    logic [15:0] req_rid;
    logic [7:0] req_tag;
    logic [7:0] req_be;
    logic [12:0] req_addr;
    logic [10:0] wr_addr;
    logic [7:0] wr_be;
    logic [31:0] wr_data;
    logic wr_en;
    logic [7:0] state;
    logic [7:0] tlp_type;
    logic in_packet_q;
} pcie_io_rx_engine_registers;

const pcie_io_rx_engine_registers pcie_io_rx_engine_r_reset = '{
    1'b0,                               // m_axis_rx_tready
    1'b0,                               // req_compl
    1'b1,                               // req_compl_wd
    3'd0,                               // req_tc
    1'b0,                               // req_td
    1'b0,                               // req_ep
    2'd0,                               // req_attr
    10'd0,                              // req_len
    16'd0,                              // req_rid
    8'd0,                               // req_tag
    8'd0,                               // req_be
    13'd0,                              // req_addr
    11'd0,                              // wr_addr
    8'd0,                               // wr_be
    32'd0,                              // wr_data
    1'b0,                               // wr_en
    PIO_RX_RST_STATE,                   // state
    8'd0,                               // tlp_type
    1'b0                                // in_packet_q
};
logic w_sop;
pcie_io_rx_engine_registers r;
pcie_io_rx_engine_registers rin;


always_comb
begin: comb_proc
    pcie_io_rx_engine_registers v;
    logic [1:0] vb_region_select;

    v = r;
    vb_region_select = '0;

    // Generate a signal that indicates if we are currently receiving a packet.
    // This value is one clock cycle delayed from what is actually on the AXIS
    // data bus.
    if ((i_m_axis_rx_tvalid == 1'b1) && (r.m_axis_rx_tready == 1'b1) && (i_m_axis_rx_tlast == 1'b1)) begin
        v.in_packet_q = 1'b0;
    end else if ((w_sop == 1'b1) && (r.m_axis_rx_tready == 1'b1)) begin
        v.in_packet_q = 1'b1;
    end

    if (i_m_axis_rx_tuser[8: 2] == 7'h01) begin             // Select Mem32 region
        vb_region_select = 2'h1;
    end else if (i_m_axis_rx_tuser[8: 2] == 7'h02) begin    // Select Mem64 region
        vb_region_select = 2'h2;
    end else if (i_m_axis_rx_tuser[8: 2] == 7'h40) begin    // Select EROM region
        vb_region_select = 2'h3;
    end

    v.wr_en = 1'b0;
    v.req_compl = 1'b0;

    case (r.state)
    PIO_RX_RST_STATE: begin
        v.m_axis_rx_tready = 1'b1;
        v.req_compl_wd = 1'b1;

        if (w_sop == 1'b1) begin
            case (i_m_axis_rx_tdata[30: 24])
            PIO_RX_MEM_RD32_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];
                v.m_axis_rx_tready = 1'b0;

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.req_tc = i_m_axis_rx_tdata[22: 20];
                    v.req_td = i_m_axis_rx_tdata[15];
                    v.req_ep = i_m_axis_rx_tdata[14];
                    v.req_attr = i_m_axis_rx_tdata[13: 12];
                    v.req_len = i_m_axis_rx_tdata[9: 0];
                    v.req_rid = i_m_axis_rx_tdata[63: 48];
                    v.req_tag = i_m_axis_rx_tdata[47: 40];
                    v.req_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_MEM_RD32_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
                end
            end

            PIO_RX_MEM_WR32_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];
                v.m_axis_rx_tready = 1'b0;

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.wr_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_MEM_WR32_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
                end
            end

            PIO_RX_MEM_RD64_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];
                v.m_axis_rx_tready = 1'b0;

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.req_tc = i_m_axis_rx_tdata[22: 20];
                    v.req_td = i_m_axis_rx_tdata[15];
                    v.req_ep = i_m_axis_rx_tdata[14];
                    v.req_attr = i_m_axis_rx_tdata[13: 12];
                    v.req_len = i_m_axis_rx_tdata[9: 0];
                    v.req_rid = i_m_axis_rx_tdata[63: 48];
                    v.req_tag = i_m_axis_rx_tdata[47: 40];
                    v.req_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_MEM_RD64_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
                end
            end

            PIO_RX_MEM_WR64_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.wr_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_MEM_WR64_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
                end
            end

            PIO_RX_IO_RD32_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];
                v.m_axis_rx_tready = 1'b0;

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.req_tc = i_m_axis_rx_tdata[22: 20];
                    v.req_td = i_m_axis_rx_tdata[15];
                    v.req_ep = i_m_axis_rx_tdata[14];
                    v.req_attr = i_m_axis_rx_tdata[13: 12];
                    v.req_len = i_m_axis_rx_tdata[9: 0];
                    v.req_rid = i_m_axis_rx_tdata[63: 48];
                    v.req_tag = i_m_axis_rx_tdata[47: 40];
                    v.req_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_MEM_RD32_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
                end
            end

            PIO_RX_IO_WR32_FMT_TYPE: begin
                v.tlp_type = i_m_axis_rx_tdata[31: 24];
                v.req_len = i_m_axis_rx_tdata[9: 0];
                v.m_axis_rx_tready = 1'b0;

                if (i_m_axis_rx_tdata[9: 0] == 10'd1) begin
                    v.req_tc = i_m_axis_rx_tdata[22: 20];
                    v.req_td = i_m_axis_rx_tdata[15];
                    v.req_ep = i_m_axis_rx_tdata[14];
                    v.req_attr = i_m_axis_rx_tdata[13: 12];
                    v.req_len = i_m_axis_rx_tdata[9: 0];
                    v.req_rid = i_m_axis_rx_tdata[63: 48];
                    v.req_tag = i_m_axis_rx_tdata[47: 40];
                    v.req_be = i_m_axis_rx_tdata[39: 32];
                    v.wr_be = i_m_axis_rx_tdata[39: 32];
                    v.state = PIO_RX_IO_WR_DW1DW2;
                end else begin
                    v.state = PIO_RX_RST_STATE;
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
            v.m_axis_rx_tready = 1'b0;
            v.req_addr = {vb_region_select[1: 0], i_m_axis_rx_tdata[10: 2], 2'd0};
            v.req_compl = 1'b1;
            v.req_compl_wd = 1'b1;
            v.state = PIO_RX_WAIT_STATE;
        end else begin
            v.state = PIO_RX_MEM_RD32_DW1DW2;
        end
    end

    PIO_RX_MEM_WR32_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.wr_data = i_m_axis_rx_tdata[63: 32];
            v.wr_en = 1'b1;
            v.m_axis_rx_tready = 1'b0;
            v.wr_addr = {vb_region_select[1: 0], i_m_axis_rx_tdata[10: 2]};
            v.state = PIO_RX_WAIT_STATE;
        end else begin
            v.state = PIO_RX_MEM_WR32_DW1DW2;
        end
    end

    PIO_RX_MEM_RD64_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.req_addr = {vb_region_select[1: 0], i_m_axis_rx_tdata[42: 34], 2'd0};
            v.req_compl = 1'b1;
            v.req_compl_wd = 1'b1;
            v.m_axis_rx_tready = 1'b0;
            v.state = PIO_RX_WAIT_STATE;
        end else begin
            v.state = PIO_RX_MEM_RD64_DW1DW2;
        end
    end

    PIO_RX_MEM_WR64_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.m_axis_rx_tready = 1'b0;
            v.wr_addr = {vb_region_select[1: 0], i_m_axis_rx_tdata[42: 34]};
            v.state = PIO_RX_MEM_WR64_DW3;
        end else begin
            v.state = PIO_RX_MEM_WR64_DW1DW2;
        end
    end

    PIO_RX_MEM_WR64_DW3: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.wr_data = i_m_axis_rx_tdata[31: 0];
            v.wr_en = 1'b1;
            v.m_axis_rx_tready = 1'b0;
            v.state = PIO_RX_WAIT_STATE;
        end else begin
            v.state = PIO_RX_MEM_WR64_DW3;
        end
    end

    PIO_RX_IO_WR_DW1DW2: begin
        if (i_m_axis_rx_tvalid == 1'b1) begin
            v.wr_data = i_m_axis_rx_tdata[63: 32];
            v.wr_en = 1'b1;
            v.m_axis_rx_tready = 1'b0;
            v.wr_addr = {vb_region_select[1: 0], i_m_axis_rx_tdata[10: 2]};
            v.req_compl = 1'b1;
            v.req_compl_wd = 1'b0;
            v.state = PIO_RX_WAIT_STATE;
        end else begin
            v.state = PIO_RX_IO_WR_DW1DW2;
        end
    end

    PIO_RX_WAIT_STATE: begin
        v.wr_en = 1'b0;
        v.req_compl = 1'b0;
        if ((r.tlp_type == PIO_RX_MEM_WR32_FMT_TYPE) && (i_wr_busy == 1'b0)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else if ((r.tlp_type == PIO_RX_IO_WR32_FMT_TYPE) && (i_wr_busy == 1'b0)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else if ((r.tlp_type == PIO_RX_MEM_WR64_FMT_TYPE) && (i_wr_busy == 1'b0)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else if ((r.tlp_type == PIO_RX_MEM_RD32_FMT_TYPE) && (i_compl_done == 1'b1)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else if ((r.tlp_type == PIO_RX_IO_RD32_FMT_TYPE) && (i_compl_done == 1'b1)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else if ((r.tlp_type == PIO_RX_MEM_RD64_FMT_TYPE) && (i_compl_done == 1'b1)) begin
            v.m_axis_rx_tready = 1'b1;
            v.state = PIO_RX_RST_STATE;
        end else begin
            v.state = PIO_RX_WAIT_STATE;
        end
    end

    default: begin
        v.state = PIO_RX_RST_STATE;
    end
    endcase

    rin = v;
end: comb_proc


assign w_sop = ((~r.in_packet_q) && i_m_axis_rx_tvalid);

assign o_m_axis_rx_tready = r.m_axis_rx_tready;
assign o_req_compl = r.req_compl;
assign o_req_compl_wd = r.req_compl_wd;
assign o_req_tc = r.req_tc;
assign o_req_td = r.req_td;
assign o_req_ep = r.req_ep;
assign o_req_attr = r.req_attr;
assign o_req_len = r.req_len;
assign o_req_rid = r.req_rid;
assign o_req_tag = r.req_tag;
assign o_req_be = r.req_be;
assign o_req_addr = r.req_addr;
assign o_wr_addr = r.wr_addr;
assign o_wr_be = r.wr_be[3: 0];
assign o_wr_data = r.wr_data;
assign o_wr_en = r.wr_en;

always_ff @(posedge i_clk, negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
        r <= pcie_io_rx_engine_r_reset;
    end else begin
        r <= rin;
    end
end

endmodule: pcie_io_rx_engine
