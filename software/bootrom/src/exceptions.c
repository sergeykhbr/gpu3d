/*
 *  Copyright 2018 Sergey Khabarov, sergeykhbr@gmail.com
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

#include <string.h>
#include "axi_maps.h"
#include "encoding.h"
#include "fw_api.h"

int get_mcause() {
    int ret;
    asm("csrr %0, mcause" : "=r" (ret));
    return ret;
}

int get_mepc() {
    int ret;
    asm("csrr %0, mepc" : "=r" (ret));
    return ret;
}

int get_mbadaddr() {
    int ret;
    asm("csrr %0, mbadaddr" : "=r" (ret));
    return ret;
}

void exception_instr_load_fault_c() {
    uint64_t t1;
    asm("csrw mepc, %0" : :"r"(t1));
    print_uart("instr_load_fault: ", 18);
    print_uart_hex(t1);
    while (1) {}
}

void exception_load_fault_c() {
    uint64_t t1;
    asm("csrw mepc, %0" : :"r"(t1));
    print_uart("data_load_fault: ", 17);
    print_uart_hex(t1);
    while (1) {}
}

void exception_store_fault_c() {
    uint64_t t1;
    asm("csrw mepc, %0" : :"r"(t1));
    print_uart("data_store_fault: ", 18);
    print_uart_hex(t1);
    while (1) {}
}

void exception_stack_overflow_c() {
    // CSR_mstackovr = 0x350 - non-standard CSR
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;
    uint64_t sp;
    // Save current stack pointer into debug regsiter
    asm("mv %0, sp" : "=r" (sp));
    pnp->fwdbg2 = sp;
}

void exception_stack_underflow_c() {
    // CSR_mstackund = 0x351 - non-standard CSR
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;
    uint64_t sp;
    // Save current stack pointer into debug regsiter
    asm("mv %0, sp" : "=r" (sp));
    pnp->fwdbg2 = sp;
}

extern void *_nmi_table;  // see startup.S

void exception_handler_c() {
    asm("fence.i");
    IRQ_HANDLER *tbl = (IRQ_HANDLER *)_nmi_table;
    int idx = get_mcause();
    if (tbl[idx] == 0) {
       print_uart("mcause:", 7);
       print_uart_hex(idx);
       print_uart(",mepc:", 6);
       print_uart_hex(get_mepc());
       print_uart("\r\n", 2);
       /// Exception trap
       led_set(0xF0);
       while (1) {}
    } else {
       tbl[idx]();
    }
}
