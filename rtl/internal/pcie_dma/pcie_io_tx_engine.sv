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
    input logic i_tx_ena,                                   // wait request from xDMA
    input logic i_tx_completion,                            // Send completion TLP on xDMA response
    input logic i_tx_with_data,                             // Send TLP with payload on xDMA response
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
    input logic [9:0] i_req_bytes,
    // 
    input logic i_dma_resp_valid,
    input logic i_dma_resp_last,
    input logic i_dma_resp_fault,                           // Error on memory access
    input logic [12:0] i_dma_resp_addr,
    input logic [63:0] i_dma_resp_data,
    output logic o_dma_resp_ready,                          // Ready to accept response
    input logic [15:0] i_completer_id
);

// TLP Format Type fields:
localparam bit [6:0] PIO_CPLD_FMT_TYPE = 7'h4A;
localparam bit [6:0] PIO_CPL_FMT_TYPE = 7'h0A;
// State machine states:
localparam bit [2:0] PIO_TX_RST_STATE = 3'h0;
localparam bit [2:0] PIO_TX_WAIT_DMA_RESP = 3'h1;
localparam bit [2:0] PIO_TX_CPLD_QW1 = 3'h2;
localparam bit [2:0] PIO_TX_RD_BURST = 3'h4;

typedef struct {
    logic [C_DATA_WIDTH-1:0] s_axis_tx_tdata;
    logic [KEEP_WIDTH-1:0] s_axis_tx_tkeep;
    logic s_axis_tx_tlast;
    logic s_axis_tx_tvalid;
    logic dma_resp_ready;
    logic req_with_data;
    logic [12:0] req_addr;
    logic [15:0] req_rid;
    logic [7:0] req_tag;
    logic [3:0] req_be;
    logic [63:0] rd_data;
    logic [12:0] rd_addr;
    logic rd_last;
    logic rd_burst;
    logic [2:0] state;
} pcie_io_tx_engine_registers;

const pcie_io_tx_engine_registers pcie_io_tx_engine_r_reset = '{
    '0,                                 // s_axis_tx_tdata
    '0,                                 // s_axis_tx_tkeep
    1'b0,                               // s_axis_tx_tlast
    1'b0,                               // s_axis_tx_tvalid
    1'b0,                               // dma_resp_ready
    1'b0,                               // req_with_data
    '0,                                 // req_addr
    '0,                                 // req_rid
    '0,                                 // req_tag
    '0,                                 // req_be
    '0,                                 // rd_data
    '0,                                 // rd_addr
    '0,                                 // rd_last
    '0,                                 // rd_burst
    PIO_TX_RST_STATE                    // state
};
pcie_io_tx_engine_registers r;
pcie_io_tx_engine_registers rin;


always_comb
begin: comb_proc
    pcie_io_tx_engine_registers v;
    logic [6:0] vb_lower_addr;
    logic [C_DATA_WIDTH-1:0] vb_s_axis_tx_tdata;

    v = r;
    vb_lower_addr = '0;
    vb_s_axis_tx_tdata = '0;

    // The completer field 'lower address' DWORD[2][6:0]:
    // For completions other than for memory reads, this value is set to 0.
    // For memory reads it is the lower byte address of the first byte in
    // the returned data (or partial data). This is set for the first
    // (or only) completion and will be 0 in the lower 7 bits from then on,
    // as the completions, if split, must be naturally aligned to a read
    // completion boundary (RCB), which is usually 128 bytes
    // (though 64 bytes in root complex).
    if (r.req_with_data == 1'b0) begin
        // Request without payload
        vb_lower_addr = 7'd0;
    end else begin
        vb_lower_addr = r.req_addr[6: 0];
    end

    if (i_s_axis_tx_tready == 1'b1) begin
        v.s_axis_tx_tvalid = 1'b0;
        v.s_axis_tx_tlast = 1'b0;
    end
    if (i_dma_resp_valid == 1'b1) begin
        v.dma_resp_ready = 1'b0;
    end

    case (r.state)
    PIO_TX_RST_STATE: begin
        v.s_axis_tx_tdata = 64'd0;
        v.s_axis_tx_tkeep = 8'd0;
        if (i_tx_ena == 1'b1) begin
            v.req_addr = i_req_addr;
            v.req_rid = i_req_rid;
            v.req_tag = i_req_tag;
            v.req_be = i_req_be;
            v.req_with_data = i_tx_with_data;
            vb_s_axis_tx_tdata[63: 48] = i_completer_id;
            vb_s_axis_tx_tdata[47: 45] = 3'd0;
            vb_s_axis_tx_tdata[44] = 1'b0;
            vb_s_axis_tx_tdata[43: 32] = i_req_bytes;
            vb_s_axis_tx_tdata[31] = 1'b0;
            if (i_tx_with_data == 1'b1) begin
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
            if (i_tx_with_data == 1'b1) begin
                // Send this TLP qword only on DMA response
                if (i_req_bytes == 10'd4) begin
                    v.dma_resp_ready = 1'b1;
                    v.state = PIO_TX_WAIT_DMA_RESP;
                end else begin
                    // Send TLP header now, payload later
                    v.s_axis_tx_tvalid = 1'b1;
                    v.rd_burst = 1'b1;
                    v.state = PIO_TX_CPLD_QW1;
                end
            end else if (i_tx_completion == 1'b1) begin
                // Send completion now
                v.s_axis_tx_tvalid = 1'b1;
                v.rd_last = 1'b1;
                v.state = PIO_TX_CPLD_QW1;
            end else begin
                // Wait handshake of write sequence:
                v.dma_resp_ready = 1'b1;
                v.state = PIO_TX_WAIT_DMA_RESP;
            end
        end
    end

    PIO_TX_WAIT_DMA_RESP: begin
        if (i_dma_resp_valid == 1'b1) begin
            if (r.req_with_data == 1'b1) begin
                v.s_axis_tx_tvalid = 1'b1;                  // Transmit DW1DW2
                v.rd_data = i_dma_resp_data;
                v.rd_addr = i_dma_resp_addr;
                v.rd_last = i_dma_resp_last;
                v.state = PIO_TX_CPLD_QW1;
            end else begin
                // write payload handshaking. TODO: write memory fault.
                v.state = PIO_TX_RST_STATE;
            end
        end
    end

    PIO_TX_CPLD_QW1: begin
        if (i_s_axis_tx_tready == 1'b1) begin
            v.s_axis_tx_tvalid = 1'b1;
            v.s_axis_tx_tlast = r.rd_last;
            // Swap DWORDS for AXI
            if (r.req_addr[2] == 1'b1) begin
                vb_s_axis_tx_tdata[63: 32] = r.rd_data[63: 32];
            end else begin
                vb_s_axis_tx_tdata[63: 32] = r.rd_data[31: 0];
            end
            vb_s_axis_tx_tdata[31: 16] = r.req_rid;
            vb_s_axis_tx_tdata[15: 8] = r.req_tag;
            vb_s_axis_tx_tdata[7] = 1'b0;
            vb_s_axis_tx_tdata[6: 0] = vb_lower_addr;
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;

            // Mask data strob if data no need:
            if ((r.req_with_data == 1'b1) && (r.rd_burst == 1'b0)) begin
                v.s_axis_tx_tkeep = 8'hFF;                  // only 4-bytes reading (no burst)
            end else begin
                v.s_axis_tx_tkeep = 8'h0F;
            end
            v.rd_last = 1'b0;
            if (r.rd_burst == 1'b0) begin
                v.req_with_data = 1'b0;
                v.state = PIO_TX_RST_STATE;
            end else begin
                v.state = PIO_TX_RD_BURST;
            end
        end
    end

    PIO_TX_RD_BURST: begin
        v.dma_resp_ready = i_s_axis_tx_tready;
        if ((i_s_axis_tx_tready == 1'b1) && (i_dma_resp_valid == 1'b1) && (r.dma_resp_ready == 1'b1)) begin
            v.s_axis_tx_tvalid = 1'b1;
            v.s_axis_tx_tlast = i_dma_resp_last;
            v.s_axis_tx_tdata = i_dma_resp_data;
            v.s_axis_tx_tkeep = 8'hFF;
            v.dma_resp_ready = (~i_dma_resp_last);
            if (i_dma_resp_last == 1'b1) begin
                v.dma_resp_ready = 1'b0;
                v.req_with_data = 1'b0;
                v.rd_burst = 1'b0;
                v.state = PIO_TX_RST_STATE;
            end
        end
    end

    default: begin
        v.state = PIO_TX_RST_STATE;
    end
    endcase

    rin = v;
end: comb_proc


assign o_s_axis_tx_tdata = r.s_axis_tx_tdata;
assign o_s_axis_tx_tkeep = r.s_axis_tx_tkeep;
assign o_s_axis_tx_tlast = r.s_axis_tx_tlast;
assign o_s_axis_tx_tvalid = r.s_axis_tx_tvalid;
assign o_dma_resp_ready = r.dma_resp_ready;
assign o_compl_done = (i_dma_resp_valid & i_dma_resp_last & o_dma_resp_ready);

// Unused discontinue
assign o_tx_src_dsc = 1'b0;

always_ff @(posedge i_clk, negedge i_nrst) begin
    if (i_nrst == 1'b0) begin
        r <= pcie_io_tx_engine_r_reset;
    end else begin
        r <= rin;
    end
end

endmodule: pcie_io_tx_engine
