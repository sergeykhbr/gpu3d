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

module hdmi_top #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_clk,                                      // CPU clock
    input logic i_hdmi_clk,                                 // HDMI clock depends on resolution for 1366x768@60Hz ~83MHz
    output logic o_hsync,                                   // Horizontal sync strob
    output logic o_vsync,                                   // Vertical sync. strob
    output logic o_de,                                      // Data enable strob
    output logic [17:0] o_data,                             // Output data in YCbCr format
    output logic o_spdif,                                   // Sound channel
    input logic i_spdif_out,                                // Reverse sound
    input logic i_irq                                       // Interrupt request from HDMI transmitter
);

logic w_sync_hsync;
logic w_sync_vsync;
logic w_sync_de;
logic [10:0] wb_sync_x;
logic [9:0] wb_sync_y;

video_sync #(
    .async_reset(async_reset),
    .H_ACTIVE(1366),
    .H_FRONT(70),
    .H_SYNC(143),
    .H_BACK(213),
    .V_ACTIVE(768),
    .V_FRONT(3),
    .V_SYNC(5),
    .V_BACK(24)
) sync0 (
    .i_nrst(i_nrst),
    .i_clk(i_hdmi_clk),
    .o_hsync(w_sync_hsync),
    .o_vsync(w_sync_vsync),
    .o_de(w_sync_de),
    .o_x(wb_sync_x),
    .o_y(wb_sync_y)
);

framebuf #(
    .async_reset(async_reset)
) fb0 (
    .i_nrst(i_nrst),
    .i_clk(i_hdmi_clk),
    .i_hsync(w_sync_hsync),
    .i_vsync(w_sync_vsync),
    .i_de(w_sync_de),
    .i_x(wb_sync_x),
    .i_y(wb_sync_y),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_de(o_de),
    .o_YCbCr(o_data)
);

assign o_spdif = 1'b0;

endmodule: hdmi_top
