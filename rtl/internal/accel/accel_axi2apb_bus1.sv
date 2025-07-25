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

module accel_axi2apb_bus1 #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_clk,                                      // APB clock
    input logic i_nrst,                                     // Reset: active LOW
    input types_amba_pkg::mapinfo_type i_mapinfo,           // Base address information from the interconnect port
    output types_pnp_pkg::dev_config_type o_cfg,            // Slave config descriptor
    input types_amba_pkg::axi4_slave_in_type i_xslvi,       // AXI4 Interconnect Bridge interface
    output types_amba_pkg::axi4_slave_out_type o_xslvo,     // AXI4 Bridge to Interconnect interface
    input types_accel_bus1_pkg::bus1_apb_out_vector i_apbo, // APB slaves output vector
    output types_accel_bus1_pkg::bus1_apb_in_vector o_apbi, // APB slaves input vector
    output types_accel_bus1_pkg::bus1_mapinfo_vector o_mapinfo// APB devices memory mapping information
);

import types_accel_bus1_pkg::*;
import types_amba_pkg::*;
import types_pnp_pkg::*;
import accel_axi2apb_bus1_pkg::*;

logic w_req_valid;
logic [CFG_SYSBUS_ADDR_BITS-1:0] wb_req_addr;
logic [7:0] wb_req_size;
logic w_req_write;
logic [CFG_SYSBUS_DATA_BITS-1:0] wb_req_wdata;
logic [CFG_SYSBUS_DATA_BYTES-1:0] wb_req_wstrb;
logic w_req_last;
logic w_req_ready;
accel_axi2apb_bus1_registers r;
accel_axi2apb_bus1_registers rin;

axi_slv #(
    .async_reset(async_reset),
    .vid(VENDOR_OPTIMITECH),
    .did(OPTIMITECH_AXI2APB_BRIDGE)
) axi0 (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_mapinfo(i_mapinfo),
    .o_cfg(o_cfg),
    .i_xslvi(i_xslvi),
    .o_xslvo(o_xslvo),
    .o_req_valid(w_req_valid),
    .o_req_addr(wb_req_addr),
    .o_req_size(wb_req_size),
    .o_req_write(w_req_write),
    .o_req_wdata(wb_req_wdata),
    .o_req_wstrb(wb_req_wstrb),
    .o_req_last(w_req_last),
    .i_req_ready(w_req_ready),
    .i_resp_valid(r.pvalid),
    .i_resp_rdata(r.prdata),
    .i_resp_err(r.pslverr)
);

always_comb
begin: comb_proc
    accel_axi2apb_bus1_registers v;
    int iselidx;
    apb_in_type vapbi[0: (CFG_BUS1_PSLV_TOTAL + 1)-1];
    apb_out_type vapbo[0: (CFG_BUS1_PSLV_TOTAL + 1)-1];
    logic [31:0] sel_rdata;

    v = r;
    iselidx = 0;
    for (int i = 0; i < (CFG_BUS1_PSLV_TOTAL + 1); i++) begin
        vapbi[i] = apb_in_none;
    end
    for (int i = 0; i < (CFG_BUS1_PSLV_TOTAL + 1); i++) begin
        vapbo[i] = apb_out_none;
    end
    sel_rdata = '0;

    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) begin
        vapbo[i] = i_apbo[i];                               // Cannot read vector item from port in systemc
    end
    // Unmapped default slave:
    vapbo[CFG_BUS1_PSLV_TOTAL].pready = 1'b1;
    vapbo[CFG_BUS1_PSLV_TOTAL].pslverr = 1'b1;
    vapbo[CFG_BUS1_PSLV_TOTAL].prdata = '1;
    w_req_ready = 1'b0;
    v.pvalid = 1'b0;
    iselidx = int'(r.selidx);
    sel_rdata = vapbo[iselidx].prdata;

    case (r.state)
    State_Idle: begin
        w_req_ready = 1'b1;
        v.pslverr = 1'b0;
        v.penable = 1'b0;
        v.pselx = 1'b0;
        v.selidx = CFG_BUS1_PSLV_TOTAL;
        for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) begin
            if ((wb_req_addr >= CFG_BUS1_MAP[i].addr_start)
                    && (wb_req_addr < CFG_BUS1_MAP[i].addr_end)) begin
                v.selidx = i;
            end
        end
        if (w_req_valid == 1'b1) begin
            v.pwrite = w_req_write;
            v.pselx = 1'b1;
            v.paddr = {wb_req_addr[31: 2], 2'd0};
            v.pprot = 3'd0;
            v.size = wb_req_size;
            v.state = State_setup;
            if (w_req_last == 1'b0) begin
                v.state = State_out;                        // Burst is not supported
                v.pselx = 1'b0;
                v.pvalid = 1'b1;
                v.pslverr = 1'b1;
                v.prdata = '1;
            end else if (wb_req_addr[2] == 1'b1) begin
                v.pwdata = {32'd0, wb_req_wdata[63: 32]};
                v.pstrb = {4'd0, wb_req_wstrb[7: 4]};
                if (wb_req_size > 8'd4) begin
                    v.state = State_out;                    // Unaligned request
                    v.pselx = 1'b0;
                    v.pvalid = 1'b1;
                    v.pslverr = 1'b1;
                    v.prdata = '1;
                end
            end else begin
                v.pwdata = wb_req_wdata;
                v.pstrb = wb_req_wstrb;
            end
        end
    end
    State_setup: begin
        v.penable = 1'b1;
        v.state = State_access;
    end
    State_access: begin
        v.pslverr = vapbo[iselidx].pslverr;
        if (vapbo[iselidx].pready == 1'b1) begin
            v.penable = 1'b0;
            if ((r.size == 8'd8) && (r.paddr[2] == 1'b0)) begin
                v.paddr = (r.paddr + 4);
                v.pwdata = {32'd0, wb_req_wdata[63: 32]};
                v.pstrb = {4'd0, wb_req_wstrb[7: 4]};
                v.state = State_setup;
                if (r.paddr[2] == 1'b0) begin
                    v.prdata = {r.prdata[63: 32], sel_rdata};
                end else begin
                    v.prdata = {sel_rdata, r.prdata[31: 0]};
                end
            end else begin
                v.pvalid = 1'b1;
                v.state = State_out;
                v.pselx = 1'b0;
                v.pwrite = 1'b0;
                if (r.size <= 8'd4) begin
                    v.prdata = {sel_rdata, sel_rdata};
                end else if (r.paddr[2] == 1'b0) begin
                    v.prdata = {r.prdata[63: 32], sel_rdata};
                end else begin
                    v.prdata = {sel_rdata, r.prdata[31: 0]};
                end
            end
        end
    end
    State_out: begin
        v.pvalid = 1'b0;
        v.pslverr = 1'b0;
        v.state = State_Idle;
    end
    default: begin
    end
    endcase

    vapbi[iselidx].paddr = r.paddr;
    vapbi[iselidx].pwrite = r.pwrite;
    vapbi[iselidx].pwdata = r.pwdata[31: 0];
    vapbi[iselidx].pstrb = r.pstrb[3: 0];
    vapbi[iselidx].pselx = r.pselx;
    vapbi[iselidx].penable = r.penable;
    vapbi[iselidx].pprot = r.pprot;

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = accel_axi2apb_bus1_r_reset;
    end

    for (int i = 0; i < CFG_BUS1_PSLV_TOTAL; i++) begin
        o_apbi[i] = vapbi[i];
        o_mapinfo[i] = CFG_BUS1_MAP[i];
    end

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= accel_axi2apb_bus1_r_reset;
            end else begin
                r <= rin;
            end
        end

    end: async_r_en
    else begin: async_r_dis

        always_ff @(posedge i_clk) begin
            r <= rin;
        end

    end: async_r_dis
endgenerate

endmodule: accel_axi2apb_bus1
