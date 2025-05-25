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
package vip_i2c_s_pkg;


// SPI states
localparam bit [7:0] STATE_IDLE = 8'h00;
localparam bit [7:0] STATE_HEADER = 8'h02;
localparam bit [7:0] STATE_ACK_HEADER = 8'h04;
localparam bit [7:0] STATE_RX_DATA = 8'h08;
localparam bit [7:0] STATE_ACK_DATA = 8'h10;
localparam bit [7:0] STATE_TX_DATA = 8'h20;
localparam bit [7:0] STATE_WAIT_ACK_DATA = 8'h40;

localparam bit PIN_DIR_INPUT = 1'b1;
localparam bit PIN_DIR_OUTPUT = 1'b0;

typedef struct {
    logic sda;
    logic scl;
    logic [7:0] state;
    logic control_start;
    logic control_stop;
    logic [6:0] addr;
    logic read;
    logic [7:0] rdata;
    logic sda_dir;
    logic [8:0] txbyte;                                     // ack + data
    logic [7:0] rxbyte;
    logic [2:0] bit_cnt;
} vip_i2c_s_registers;

const vip_i2c_s_registers vip_i2c_s_r_reset = '{
    1'b1,                               // sda
    1'b1,                               // scl
    STATE_IDLE,                         // state
    1'b0,                               // control_start
    1'b0,                               // control_stop
    '0,                                 // addr
    1'b0,                               // read
    '0,                                 // rdata
    PIN_DIR_OUTPUT,                     // sda_dir
    '1,                                 // txbyte
    '0,                                 // rxbyte
    '0                                  // bit_cnt
};
endpackage: vip_i2c_s_pkg
