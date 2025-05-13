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

module pcie_io_tx_engine #(
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
    input logic i_req_compl,
    input logic i_req_compl_wd,
    output logic o_compl_done,
    // 
    input logic [2:0] i_req_tc,
    input logic i_req_td,
    input logic i_req_ep,
    input logic [1:0] i_req_attr,
    input logic [9:0] i_req_len,
    input logic [15:0] i_req_rid,
    input logic [7:0] i_req_tag,
    input logic [7:0] i_req_be,
    input logic [12:0] i_req_addr,
    // 
    output logic [10:0] o_rd_addr,
    output logic [3:0] o_rd_be,
    input logic [31:0] i_rd_data,
    input logic [15:0] i_completer_id
);

// 
localparam bit [6:0] PIO_CPLD_FMT_TYPE = 7'h4A;
localparam bit [6:0] PIO_CPL_FMT_TYPE = 7'h0A;
localparam bit [1:0] PIO_TX_RST_STATE = 2'h0;
localparam bit [1:0] PIO_TX_CPLD_QW1_FIRST = 2'h1;
localparam bit [1:0] PIO_TX_CPLD_QW1_TEMP = 2'h2;
localparam bit [1:0] PIO_TX_CPLD_QW1 = 2'h3;

typedef struct {
    logic [C_DATA_WIDTH-1:0] s_axis_tx_tdata;
    logic [KEEP_WIDTH-1:0] s_axis_tx_tkeep;
    logic s_axis_tx_tlast;
    logic s_axis_tx_tvalid;
    logic compl_done;
    logic [3:0] rd_be;
    logic req_compl_q;
    logic req_compl_wd_q;
    logic compl_busy_i;
    logic [1:0] state;
} pcie_io_tx_engine_registers;

const pcie_io_tx_engine_registers pcie_io_tx_engine_r_reset = '{
    '0,                                 // s_axis_tx_tdata
    '0,                                 // s_axis_tx_tkeep
    1'b0,                               // s_axis_tx_tlast
    1'b0,                               // s_axis_tx_tvalid
    1'b0,                               // compl_done
    '0,                                 // rd_be
    1'b0,                               // req_compl_q
    1'b1,                               // req_compl_wd_q
    1'b0,                               // compl_busy_i
    PIO_TX_RST_STATE                    // state
};
logic w_compl_wd;
pcie_io_tx_engine_registers r;
pcie_io_tx_engine_registers rin;


always_comb
begin: comb_proc
    pcie_io_tx_engine_registers v;
    logic [1:0] vb_add_be20;
    logic [1:0] vb_add_be21;
    logic [11:0] vb_byte_count;
    logic [6:0] vb_lower_addr;
    logic [C_DATA_WIDTH-1:0] vb_s_axis_tx_tdata;

    v = r;
    vb_add_be20 = '0;
    vb_add_be21 = '0;
    vb_byte_count = '0;
    vb_lower_addr = '0;
    vb_s_axis_tx_tdata = '0;

    v.rd_be = i_req_be;
    // Calculate byte count based on byte enable
    vb_add_be20 = ({1'b0, r.rd_be[3]} + {1'b0, r.rd_be[2]});
    vb_add_be21 = ({1'b0, r.rd_be[1]} + {1'b0, r.rd_be[0]});
    vb_byte_count = ({2'd0, vb_add_be20} + {2'd0, vb_add_be21});

    v.req_compl_q = i_req_compl;
    v.req_compl_wd_q = i_req_compl_wd;

    if (w_compl_wd == 1'b0) begin
        // Request without payload
        vb_lower_addr = 7'd0;
    end else if (r.rd_be[0] == 1'b1) begin
        vb_lower_addr = 7'd0;
    end else if (r.rd_be[1] == 1'b1) begin
        vb_lower_addr = {i_req_addr[6: 2], 2'd1};
    end else if (r.rd_be[2] == 1'b1) begin
        vb_lower_addr = {i_req_addr[6: 2], 2'd2};
    end else if (r.rd_be[3] == 1'b1) begin
        vb_lower_addr = {i_req_addr[6: 2], 2'd3};
    end

    v.compl_done = 1'b0;
    if (r.req_compl_q == 1'b1) begin
        v.compl_busy_i = 1'b1;
    end
    case (r.state)
    PIO_TX_RST_STATE: begin
        if (r.compl_busy_i == 1'b1) begin
            v.s_axis_tx_tdata = 64'd0;
            v.s_axis_tx_tkeep = 8'hFF;
            v.s_axis_tx_tlast = 1'b0;
            v.s_axis_tx_tvalid = 1'b0;
            if (i_s_axis_tx_tready == 1'b1) begin
                v.state = PIO_TX_CPLD_QW1_FIRST;
            end else begin
                v.state = PIO_TX_RST_STATE;
            end
        end else begin
            v.s_axis_tx_tlast = 1'b0;
            v.s_axis_tx_tvalid = 1'b0;
            v.s_axis_tx_tdata = 64'd0;
            v.s_axis_tx_tkeep = 8'hFF;
            v.compl_done = 1'b0;
            v.state = PIO_TX_RST_STATE;
        end
    end

    PIO_TX_CPLD_QW1_FIRST: begin
        if (i_s_axis_tx_tready == 1'b1) begin
            v.s_axis_tx_tlast = 1'b0;
            vb_s_axis_tx_tdata[63: 48] = i_completer_id;
            vb_s_axis_tx_tdata[47: 45] = 3'd0;
            vb_s_axis_tx_tdata[44] = 1'b0;
            vb_s_axis_tx_tdata[43: 32] = vb_byte_count;
            vb_s_axis_tx_tdata[31] = 1'b0;
            if (r.req_compl_wd_q == 1'b1) begin
                vb_s_axis_tx_tdata[30: 24] = PIO_CPLD_FMT_TYPE;
            end else begin
                vb_s_axis_tx_tdata[30: 24] = PIO_CPL_FMT_TYPE;
            end
            vb_s_axis_tx_tdata[23] = 1'b0;
            vb_s_axis_tx_tdata[22: 20] = i_req_tc;
            vb_s_axis_tx_tdata[19: 16] = 3'd0;
            vb_s_axis_tx_tdata[15] = i_req_td;
            vb_s_axis_tx_tdata[14] = i_req_ep;
            vb_s_axis_tx_tdata[13: 12] = i_req_attr;
            vb_s_axis_tx_tdata[11: 10] = 2'd0;
            vb_s_axis_tx_tdata[9: 0] = i_req_len;
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;
            v.s_axis_tx_tkeep = 8'hFF;
            v.state = PIO_TX_CPLD_QW1_TEMP;
        end else begin
            v.state = PIO_TX_RST_STATE;
        end
    end

    PIO_TX_CPLD_QW1_TEMP: begin
        v.s_axis_tx_tvalid = 1'b1;
        v.state = PIO_TX_CPLD_QW1;
    end

    PIO_TX_CPLD_QW1: begin
        if (i_s_axis_tx_tready == 1'b1) begin
            v.s_axis_tx_tlast = 1'b1;
            v.s_axis_tx_tvalid = 1'b1;
            // Swap DWORDS for AXI
            vb_s_axis_tx_tdata[63: 32] = i_rd_data;
            vb_s_axis_tx_tdata[31: 16] = i_req_rid;
            vb_s_axis_tx_tdata[15: 8] = i_req_tag;
            vb_s_axis_tx_tdata[7] = 1'b0;
            vb_s_axis_tx_tdata[6: 0] = vb_lower_addr;
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;

            // Mask data strob if data no need:
            if (r.req_compl_wd_q == 1'b1) begin
                v.s_axis_tx_tkeep = 8'hFF;
            end else begin
                v.s_axis_tx_tkeep = 8'h0F;
            end
            v.compl_done = 1'b1;
            v.compl_busy_i = 1'b0;
            v.state = PIO_TX_RST_STATE;
        end else begin
            v.state = PIO_TX_CPLD_QW1;
        end
    end

    default: begin
        v.state = PIO_TX_RST_STATE;
    end
    endcase

    rin = v;
end: comb_proc


assign w_compl_wd = r.req_compl_wd_q;
assign o_s_axis_tx_tdata = r.s_axis_tx_tdata;
assign o_s_axis_tx_tkeep = r.s_axis_tx_tkeep;
assign o_s_axis_tx_tlast = r.s_axis_tx_tlast;
assign o_s_axis_tx_tvalid = r.s_axis_tx_tvalid;
assign o_compl_done = r.compl_done;
assign o_rd_be = r.rd_be;

// Unused discontinue
assign o_tx_src_dsc = 1'b0;

// Present address and byte enable to memory module
assign o_rd_addr = i_req_addr[12: 2];

always_ff @(posedge i_clk, negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
        r <= pcie_io_tx_engine_r_reset;
    end else begin
        r <= rin;
    end
end

endmodule: pcie_io_tx_engine
