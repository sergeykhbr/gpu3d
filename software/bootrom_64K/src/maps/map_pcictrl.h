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

typedef struct pcictrl_map {
    volatile uint32_t status;  // 0x00 link status: [3:0] DMA state
    volatile uint32_t bdf;     // 0x04 [15:0] Bus:Device.Function
    volatile uint32_t req_cnt; // 0x08 request counter
    uint32_t rsrv1[29];
    uint32_t req_data[2*16];   // 0x80 requests backtrace array
} pcictrl_map;

