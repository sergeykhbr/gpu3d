/*
 *  Copyright 2025 Sergey Khabarov, sergeykhbr@gmail.com
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#pragma once
#include <inttypes.h>

#define I2C_PHYS_ADDR_MUX      0x74
#define I2C_PHYS_ADDR_HDMI     0x39

#define I2C_ADDR_WRITE 0
#define I2C_ADDR_READ  1

typedef struct scaler_bits_type {
    uint32_t scaler : 16;
    uint32_t setup : 16;
} scaler_bits_type;

typedef struct ctrl_status_bits_type {
    uint32_t state : 8;             // [7:0] [RO] idle=0
    uint32_t i_sda : 1;             // [8] [RO]
    uint32_t err_acc_header : 1;    // [9] [RW]
    uint32_t err_acc_data : 1;      // [10] [RW]
    uint32_t rsrv11 : 1;            // [11]
    uint32_t ie : 1;                // [12] [RW] IRQ enable
    uint32_t irq : 1;               // [13] [Cleared-R/W]
    uint32_t rsrv15_14 : 2;         // [15:14]
    uint32_t set_nreset : 1;        // [16] read nreset, write-0 no effect; write-1 set nreset to HIGH
    uint32_t slear_nreset : 1;      // [17] read nreset, write-0 no effect; write-1 set nreset to LOW
    uint32_t rsrv31_18 : 14;        // [31:18]
} ctrl_status_bits_type;

typedef struct start_addr_bits_type {
    uint32_t phys_addr : 7;          // [6:0] [RW] 0x74: i2c multiplexer; 0x39: HDMI transmitter
    uint32_t rsrv15_7 : 9;           // [15:7]
    uint32_t byte_cnt : 4;           // [19:16] 0..3
    uint32_t rsrv30_20 : 11;         // [30:20]
    uint32_t R_nW : 1;               // [31] 0=write; 1=read
} start_addr_bits_type;


typedef struct i2c_map {
    uint32_t scaler;              // 0x000:
    uint32_t ctrl_status;         // 0x004:
    uint32_t start_addr;          // 0x008
    uint32_t payload;             // 0x00C
} i2c_map;


