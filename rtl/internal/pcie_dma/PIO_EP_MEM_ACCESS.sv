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

module PIO_EP_MEM_ACCESS(
    input logic i_nrst,
    input logic i_clk,                                      // System bus clock
    // Read Port
    input logic [10:0] i_rd_addr,
    input logic [3:0] i_rd_be,
    output logic [31:0] o_rd_data,
    // Write Port
    input logic [10:0] i_wr_addr,
    input logic [7:0] i_wr_be,
    input logic [31:0] i_wr_data,
    input logic i_wr_en,
    output logic o_wr_busy
);

logic [10:0] wb_addr;
logic r_wr_busy;

ram_bytes_tech #(
    .abits(11),
    .log2_dbytes(2)
) ram0 (
    .i_clk(i_clk),
    .i_addr(wb_addr),
    .i_wena(i_wr_en),
    .i_wstrb(i_wr_be[3:0]),
    .i_wdata(i_wr_data),
    .o_rdata(o_rd_data)
);

always_comb
begin: comb_proc
    if (i_wr_en == 1'b1) begin
        wb_addr = i_wr_addr;
    end else begin
        wb_addr = i_rd_addr;
    end
end: comb_proc

assign o_wr_busy = r_wr_busy;


always_ff @(posedge i_clk) begin: reqff_proc
    if (i_nrst == 1'b0) begin
        r_wr_busy <= 0;
    end else begin
        r_wr_busy <= i_wr_en;
    end
end: reqff_proc

endmodule: PIO_EP_MEM_ACCESS
