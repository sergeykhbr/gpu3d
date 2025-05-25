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

module vip_i2c_s #(
    parameter logic async_reset = 1'b0
)
(
    input logic i_clk,                                      // CPU clock
    input logic i_nrst,                                     // Reset: active LOW
    input logic i_scl,                                      // Clock upto 400 kHz (default 100 kHz)
    input logic i_sda,                                      // Tri-state buffer output
    output logic o_sda,                                     // Data output (tri-state buffer input)
    output logic o_sda_dir                                  // Data to control tri-state buffer
);

import vip_i2c_s_pkg::*;

vip_i2c_s_registers r;
vip_i2c_s_registers rin;


always_comb
begin: comb_proc
    vip_i2c_s_registers v;
    logic v_latch_data;

    v = r;
    v_latch_data = 1'b0;

    v.sda = i_sda;
    v.scl = i_scl;

    v.control_start = (r.sda & (~i_sda) & i_scl);
    v.control_stop = ((~r.sda) & i_sda & i_scl);
    v_latch_data = ((~r.scl) & i_scl);
    if (v_latch_data == 1'b1) begin
        v.rxbyte = {r.rxbyte[6: 0], i_sda};
    end

    // Transmitter's state machine:
    case (r.state)
    STATE_IDLE: begin
        v.txbyte = 9'd0;
        v.addr = 7'd0;
        v.read = 1'b0;
        v.rdata = 8'd0;
        v.sda_dir = PIN_DIR_INPUT;
        if (r.control_start == 1'b1) begin
            // Start condition SDA goes LOW while SCL is HIGH
            v.bit_cnt = 3'd7;
            v.state = STATE_HEADER;
        end
    end

    STATE_HEADER: begin
        if (v_latch_data == 1'b1) begin
            if ((|r.bit_cnt) == 1'b0) begin
                v.sda_dir = PIN_DIR_OUTPUT;
                v.state = STATE_ACK_HEADER;
            end else begin
                v.bit_cnt = (r.bit_cnt - 1);
            end
        end
    end

    STATE_ACK_HEADER: begin
        if (v_latch_data == 1'b1) begin
            v.addr = r.rxbyte[7: 1];
            v.read = r.rxbyte[0];
            v.bit_cnt = 3'd7;
            if (r.rxbyte[0] == 1'b0) begin
                // 0=write
                v.sda_dir = PIN_DIR_INPUT;
                v.state = STATE_RX_DATA;
            end else begin
                // 1=read
                v.state = STATE_TX_DATA;
                v.txbyte = 9'h081;                          // Some random value to transmit as 1-st byte
            end
        end
    end

    STATE_RX_DATA: begin
        if (v_latch_data == 1'b1) begin
            if ((|r.bit_cnt) == 1'b0) begin
                v.sda_dir = PIN_DIR_OUTPUT;
                v.state = STATE_ACK_DATA;
            end else begin
                v.bit_cnt = (r.bit_cnt - 1);
            end
        end
    end

    STATE_ACK_DATA: begin
        if (v_latch_data == 1'b1) begin
            v.rdata = r.rxbyte;
            if (i_sda == 1'b1) begin
                // Not acked (last byte)
                v.state = STATE_IDLE;
            end else begin
                v.bit_cnt = 3'd7;
                v.sda_dir = PIN_DIR_INPUT;
                v.state = STATE_RX_DATA;
            end
        end
    end

    STATE_TX_DATA: begin
        if (v_latch_data == 1'b1) begin
            v.txbyte = {r.txbyte[7: 0], 1'b0};
            if ((|r.bit_cnt) == 1'b0) begin
                v.sda_dir = PIN_DIR_INPUT;
                v.state = STATE_WAIT_ACK_DATA;
            end else begin
                v.bit_cnt = (r.bit_cnt - 1);
            end
        end
    end

    STATE_WAIT_ACK_DATA: begin
        if (v_latch_data == 1'b1) begin
            v.sda_dir = PIN_DIR_OUTPUT;
            if (i_sda == 1'b1) begin
                v.state = STATE_IDLE;
            end else begin
                v.bit_cnt = 3'd7;
                v.txbyte = 9'h085;                          // Some random value to transmit
                v.state = STATE_TX_DATA;
            end
        end
    end

    default: begin
        v.state = STATE_IDLE;
    end
    endcase

    if ((r.state != STATE_IDLE) && (r.control_stop == 1'b1)) begin
        v.state = 8'd0;
    end

    if ((~async_reset) && (i_nrst == 1'b0)) begin
        v = vip_i2c_s_r_reset;
    end

    o_sda = r.txbyte[8];
    o_sda_dir = r.sda_dir;

    rin = v;
end: comb_proc

generate
    if (async_reset) begin: async_r_en

        always_ff @(posedge i_clk, negedge i_nrst) begin
            if (i_nrst == 1'b0) begin
                r <= vip_i2c_s_r_reset;
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

endmodule: vip_i2c_s
