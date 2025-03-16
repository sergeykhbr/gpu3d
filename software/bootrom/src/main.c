/*
 *  Copyright 2023 Sergey Khabarov, sergeykhbr@gmail.com
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

//#define PRINT_DDR_IMAGE

void allocate_exception_table(void);
void allocate_interrupt_table(void);
void test_plic(void);
void test_swirq(void);
void test_mtimer(void);
int test_ddr();
void print_pnp(void);

void wait_pcie() {
    prci_map *prci = (prci_map *)ADDR_BUS1_APB_PRCI;
    clint_map *clint = (clint_map *)ADDR_BUS0_XSLV_CLINT;
    uint64_t t_start = clint->mtime;
    while ((prci->pll_status & PRCI_PLL_STATUS_PCIE_LNK_UP) == 0) {
        // 3 seconds timeout:
        if ((clint->mtime - t_start) > 3 * SYS_HZ) {
            printf_uart("%s", "PCIE no link\r\n");
            return;
        }
    }
    printf_uart("%s", "PCIE link up\r\n");
}

int __main() {
    uint32_t cfg;
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;
    uart_map *uart = (uart_map *)ADDR_BUS0_XSLV_UART0;
    gpio_map *gpio = (gpio_map *)ADDR_BUS0_XSLV_GPIO;
    uint64_t bar;
    uint32_t cpu_max;

    pnp->fwid = 0x20241103;
    gpio->input_en = 0x000f;
    gpio->output_en = 0xfff0;
    fw_malloc_init();
    
    allocate_exception_table();
    allocate_interrupt_table();

    uart_isr_init();   // enable printf_uart function and Tx irq=1
 
    led_set(0x01);

    cpu_max = pnp->cfg >> 28;

    printf_uart("HARTID . . . . .%d\r\n", fw_get_cpuid());
    printf_uart("HARTS. . . . . .%d\r\n", cpu_max);
    printf_uart("PLIC_IRQS  . . .%d\r\n", (pnp->cfg & 0xFF));
    printf_uart("HWID . . . . . .0x%08x\r\n", pnp->hwid);
    printf_uart("FWID . . . . . .0x%08x\r\n", pnp->fwid);

    led_set(0x02);

    test_plic();
    test_mtimer();
    test_swirq();

    led_set(0x55);
    print_pnp();

    led_set(0x1F);

    test_ddr();

    wait_pcie();

    while (1) {}

    // NEVER REACH THIS POINT
    return 0;
}
