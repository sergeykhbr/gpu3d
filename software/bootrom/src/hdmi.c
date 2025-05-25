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

#include <inttypes.h>
#include <string.h>
#include <axi_maps.h>
#include "fw_api.h"

void i2c_wait() {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    while (i2c->ctrl_status & 0xFF) {}

    uint32_t status = i2c->ctrl_status;
    if (status & (1 << 9)) {
        printf_uart("i2c err_acc_header: %08x\r\n", status);
    }
    if (status & (1 << 10)) {
        printf_uart("i2c err_acc_data: %08x\r\n", status);
    }
    i2c->ctrl_status = 0;  // clear errors, disable interrupts
}

uint32_t read_hdmi_main_reg(uint32_t offset, uint32_t byte_cnt) {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    i2c->payload = offset;        // select channel 5:HDMI
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (1 << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();

    i2c->start_addr = (I2C_ADDR_READ << 31) | (byte_cnt << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();
    return i2c->payload;
}

void write_hdmi_main_reg(uint32_t offset, uint32_t byte_cnt, uint32_t val) {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    i2c->payload = offset;        // select channel 5:HDMI
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (1 << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();

    i2c->payload = val;        // select channel 5:HDMI
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (byte_cnt << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();
}

void setup_hdmi() {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    uint32_t hw_revision = 0;
    printf_uart("Start HDMI setup%s", "\r\n");

    i2c->ctrl_status = 1 << 16; // set nreset; active LOW for I2C multiplexer
    i2c->scaler = 0x00320064;   // scaler=100; setup time=50
    i2c->payload = 0x20;        // select channel 5:HDMI
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (1 << 16) | I2C_PHYS_ADDR_MUX;  // write 1 Byte: [0x74] <= 0x20
    i2c_wait();

    printf_uart("I2C multiplexer PCA9548A. . . %s\r\n", "configured");
    hw_revision = read_hdmi_main_reg(0x0, 1);
    printf_uart("HDMI chip revision. . . . . . %02x (expected 0x13)\r\n", hw_revision);
}
