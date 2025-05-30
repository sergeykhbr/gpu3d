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
    i2c->payload = offset;
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (1 << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();

    i2c->start_addr = (I2C_ADDR_READ << 31) | (byte_cnt << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();
    return i2c->payload;
}

void write_hdmi_main_reg(uint32_t offset, uint32_t byte_cnt, uint32_t val) {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    i2c->payload = (val << 8) | (offset & 0xFF);
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | ((byte_cnt + 1) << 16) | I2C_PHYS_ADDR_HDMI;
    i2c_wait();
}

void check_reg(uint32_t offset, uint32_t expected) {
    uint32_t rd = read_hdmi_main_reg(offset, 1);
    printf_uart("%02x %02x exp:%02x", offset, rd, expected);
    if (rd != expected) {
        printf_uart("%s", "!!!! error !!!!");
   }
   printf_uart("%s", "\r\n");
}

void wait_seconds(int sec) {
    clint_map *clint = (clint_map *)ADDR_BUS0_XSLV_CLINT;
    uint64_t t_start = clint->mtime;
    printf_uart("Wait %d sec . . .", sec);
    while ((clint->mtime - t_start) < sec * SYS_HZ) {
    }
    printf_uart("%s", "done\r\n");
}

void setup_hdmi() {
    i2c_map *i2c = (i2c_map *)ADDR_BUS0_APB_I2C;
    uint32_t hw_revision = 0;
    printf_uart("Start HDMI setup%s", "\r\n");
    wait_seconds(30);

    i2c->ctrl_status = 1 << 16; // set nreset; active LOW for I2C multiplexer
    i2c->scaler = 0x00320064;   // scaler=100; setup time=50
    i2c->payload = 0x20;        // select channel 5:HDMI
    i2c->start_addr = (I2C_ADDR_WRITE << 31) | (1 << 16) | I2C_PHYS_ADDR_MUX;  // write 1 Byte: [0x74] <= 0x20
    i2c_wait();

    printf_uart("I2C multiplexer PCA9548A. . . %s\r\n", "configured");
    hw_revision = read_hdmi_main_reg(0x0, 1);
    printf_uart("HDMI chip revision. . . . . . %02x (expected 0x13)\r\n", hw_revision);

    // Power-up the Tx (HPD must be high)
    // 0x41[6] = 0b0 for power-up/power-down
    write_hdmi_main_reg(0x41, 1, 0x10);   //[6]=0;[4]=1
#if 1
    write_hdmi_main_reg(0x48, 1, 0x08);
    write_hdmi_main_reg(0x55, 1, 0x00);
    write_hdmi_main_reg(0x56, 1, 0x28);
#endif

    // Fixed registers that must be set on power up (no description in datasheet):
    // 0x98 = 0x03
    write_hdmi_main_reg(0x98, 1, 0x03);
    // 0x9A[7:5] = 0b111
    write_hdmi_main_reg(0x9A, 1, 0xE0);
    // 0x9C = 0x30
    write_hdmi_main_reg(0x9C, 1, 0x30);
    // 0x9D[1:0] = 0b01
    write_hdmi_main_reg(0x9D, 1, 0x61);
    // 0xA2 = 0xA4
    // 0xA3 = 0xA4
    write_hdmi_main_reg(0xA2, 2, 0xA4A4);
    // 0xAF[1] = 0=DVI Mode; 1=HDMI mode
    // 0xAF[3:2] = 01 must be set to default value
    // 0xAF[4] = 0=Current Frame NOT HDCP encrypted; 1=Current Frame HDCP encrypted
    // 0xAF[7] = 0=HDCP disable; 1=HDCP encryption enabled
    write_hdmi_main_reg(0xAF, 1, 0x06);
    // 0xE0[7:0] = 0xD0
    write_hdmi_main_reg(0xE0, 1, 0xD0);
    // 0xF9[7:0] = 0x00
    write_hdmi_main_reg(0xF9, 1, 0x00);
    // 0xBA R/W [7:5] 000*.**** Clock Delay: 000=-1.2ns; 001=-0.8ns; ..; 011=no delay; ..; 111=1.6ns
    write_hdmi_main_reg(0xBA, 1, 0x60);  // no input video clock delay

    // Set up the video input/output mode
    // 0x15[3:0]: Input Video Format
    //   0001  16, 20, 24 bit YCbCr 4:2:2 (separate sync)
    //   0010  16, 20, 24 bit YCbCr 4:2:2 (embedded sync)
    write_hdmi_main_reg(0x15, 1, 0x01);
    // 0x16[7]   Output format: 0=4:4:4; 1=4:2:2
    // 0x16[5:4] Input Color Depth: 00=invalid; 01=10bit; 10=12bit; 11=8bit
    // 0x16[3:2] Video Input Style: 00=invalid; 01=style2; 10=style1; 11= style3
    // 0x16[1]   DDR input Edge: 0=falling edge; 1=rising edge
    write_hdmi_main_reg(0x16, 1, 0x38);  // 8bit, style 1 (Cb.Y/Cr.Y)
    // 0x17[6] VSync Polarity: 0=high; 1=low
    // 0x17[5] HSync Polarity: 0=high; 1=low
    // 0x17[2] 4:2:2 to 4:4:4 interpolation: 0=zero order; 1=first order
    // 0x17[1] Aspect ratio of input video (4x3 = 0b0, 16x9 = 0b1)
    write_hdmi_main_reg(0x17, 1, 0x02);

    // Color conversion 3x3 matrix coef: HDTV YCbCr (Limited range) to RGB (Limited range)
    // 0x18[7] = 0b1 for YCbCr to RGB CSC Enable
    // 0x18[6:5] = 0b00 for YCbCr to RGB CSC Scaling Factor
    // A
    write_hdmi_main_reg(0x18, 2, 0x53AC);
    write_hdmi_main_reg(0x1A, 2, 0x0008);
    write_hdmi_main_reg(0x1C, 2, 0x0000);
    write_hdmi_main_reg(0x1E, 2, 0xD619);
    // B
    write_hdmi_main_reg(0x20, 2, 0x561C);
    write_hdmi_main_reg(0x22, 2, 0x0008);
    write_hdmi_main_reg(0x24, 2, 0x881E);
    write_hdmi_main_reg(0x26, 2, 0x9102);
    // C
    write_hdmi_main_reg(0x28, 2, 0xFF1F);
    write_hdmi_main_reg(0x2A, 2, 0x0008);
    write_hdmi_main_reg(0x2C, 2, 0x850E);
    write_hdmi_main_reg(0x2E, 2, 0xBE18);

    // 0x97[0] Rx Ready 1 irq
    // 0x97[1] Rx Ready 2 irq
    // 0x97[2] Rx Ready 3 irq
    // 0x97[3] Tx Retry Timeout irq
    // 0x97[4] Tx arbitration Lost irq
    // 0x97[5] Tx Ready irq
    // 0x97[6] BKSV Interrupt Flag (Wait for value to be 0b1 then write 0b1)
    // 0x97[7] DDC Controller Error Irq: 0=no irq detected; 1=irq detected
    write_hdmi_main_reg(0x97, 1, 0x00);


/*    printf_uart("%s", "HDMI Register verification:\r\n");
    check_reg(0x15, 0x01);
    check_reg(0x16, 0x38);
    check_reg(0x41, 0x10);
    check_reg(0x48, 0x08);
    check_reg(0x55, 0x00);
    check_reg(0x56, 0x28);
    check_reg(0x98, 0x03);
    check_reg(0x9A, 0xe0);
    check_reg(0x9C, 0x30);
    check_reg(0x9D, 0x61);
    check_reg(0xA2, 0xA4);
    check_reg(0xA3, 0xA4);
    check_reg(0xAF, 0x06);
    check_reg(0xBA, 0x60);
    check_reg(0xE0, 0xD0);
    check_reg(0xF9, 0x00);
    check_reg(0x18, 0xAC);
    check_reg(0x19, 0x53);
    check_reg(0x1A, 0x08);
    check_reg(0x1B, 0x00);
    check_reg(0x1C, 0x00);
    check_reg(0x1D, 0x00);
    check_reg(0x1E, 0x19);
    check_reg(0x1F, 0xD6);
    check_reg(0x20, 0x1C);
    check_reg(0x21, 0x56);
    check_reg(0x22, 0x08);
    check_reg(0x23, 0x00);
    check_reg(0x24, 0x1E);
    check_reg(0x25, 0x88);
    check_reg(0x26, 0x02);
    check_reg(0x27, 0x91);
    check_reg(0x28, 0x1F);
    check_reg(0x29, 0xFF);
    check_reg(0x2A, 0x08);
    check_reg(0x2B, 0x00);
    check_reg(0x2C, 0x0E);
    check_reg(0x2D, 0x85);
    check_reg(0x2E, 0x18);
    check_reg(0x2F, 0xBE);*/

/*
Set up the video output mode
Audio setup
0x01 0x03 = 0x001800 for 48kHz - N Value
0x0A[6:4] Audio Select (I2S = 0b000, SPDIF = 0b001, HBR = 0b011)
Audio Mode
0x0B[7] = 0b1    SPDIF Enable
0x0C[5:2] 0b1111 I2S Enable
0x15[7:4] I2S Sampling Frequency
0x0A[3:2] Audio Mode
0x0A[3:2] Audio Select
*/
}
