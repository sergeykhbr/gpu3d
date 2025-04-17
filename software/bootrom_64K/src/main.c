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

#include <string.h>
#include <stdio.h>
#include "axi_maps.h"
#include "encoding.h"
#include "fw_api.h"

void allocate_exception_table(void);
void allocate_interrupt_table(void);
void print_pnp(void);

void wait_ddr() {
    prci_map *prci = (prci_map *)ADDR_BUS1_APB_PRCI;
    clint_map *clint = (clint_map *)ADDR_BUS0_XSLV_CLINT;
    uint64_t *ddr = (uint64_t *)ADDR_BUS0_XSLV_DDR;

    printf("%s", "DDR Init . .");

    uint64_t t_start = clint->mtime;

    while ((prci->pll_status & PRCI_PLL_STATUS_DDR_CALIB_DONE) == 0) {
        // 3 seconds timeout:
        if ((clint->mtime - t_start) > 3 * SYS_HZ) {
            printf("%s", "NO_CALIB\r\n");
            return;
        }
    }
    printf("%s", "DONE\r\n");
}

void wait_pcie() {
    prci_map *prci = (prci_map *)ADDR_BUS1_APB_PRCI;
    clint_map *clint = (clint_map *)ADDR_BUS0_XSLV_CLINT;
    uint64_t t_start = clint->mtime;
    while ((prci->pll_status & PRCI_PLL_STATUS_PCIE_LNK_UP) == 0) {
        // 3 seconds timeout:
        if ((clint->mtime - t_start) > 3 * SYS_HZ) {
            printf("%s", "PCIE no link\r\n");
            return;
        }
    }
    printf("%s", "PCIE link up\r\n");
}

void setup_1sec_irq() {
    clint_map *clint = (clint_map *)ADDR_BUS0_XSLV_CLINT;
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;

    fw_disable_m_interrupts();
    fw_mie_enable(HART_IRQ_MTIP);

    pnp->fwdbg1 = 0;
    pnp->fwdbg2= 0;

    clint->mtimecmp[fw_get_cpuid()] = clint->mtime + SYS_HZ;

    fw_enable_m_interrupts();
}

void debug_output() {
    pcictrl_map *pcictrl = (pcictrl_map *)ADDR_BUS1_APB_PCICTRL;
    printf("req_cnt=%d\r\n", pcictrl->req_cnt);
    for (int i = 0; i < 16; i++) {
        printf("%2d: %08x.%08x\r\n", i, pcictrl->req_data[2*i+1], pcictrl->req_data[2*i]);
    }
}

uint64_t ddr_torture(uint64_t addr) {
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;
    uint64_t *ddr = (uint64_t *)ADDR_BUS0_XSLV_DDR;
    uint64_t val = 0xAABBCCDD11223344ull + addr;
    for (int i = 0; i < 16; i++) {
        ddr[addr + i] = val + i;
    }
    for (int i = 0; i < 16; i++) {
        if (ddr[addr + i] != (val + i)) {
            if (++pnp->fwdbg2 < 128) {
                printf("ddr_err at: %016x\r\n", addr + i);
            }
        }
    }
    addr += 16 * sizeof(uint64_t);
    if (addr >= 0x40000000) {
        addr = 0;
    }
    return addr;
}

int main() {
    uint32_t cfg;
    pnp_map *pnp = (pnp_map *)ADDR_BUS0_XSLV_PNP;
    uart_map *uart = (uart_map *)ADDR_BUS0_XSLV_UART0;
    gpio_map *gpio = (gpio_map *)ADDR_BUS0_XSLV_GPIO;
    pcictrl_map *pcictrl = (pcictrl_map *)ADDR_BUS1_APB_PCICTRL;
    uint64_t ddr_addr = 0;
    uint32_t cpu_max;

    pnp->fwid = 0x20241103;
    gpio->input_en = 0x000f;
    gpio->output_en = 0xfff0;
    fw_malloc_init();
    
    allocate_exception_table();
    allocate_interrupt_table();

    //uart_isr_init();   // enable printf_uart function and Tx irq=1
 
    led_set(0x01);

    cpu_max = pnp->cfg >> 28;

    printf("HARTID . . . . .%d\r\n", fw_get_cpuid());
    printf("HARTS. . . . . .%d\r\n", cpu_max);
    printf("PLIC_IRQS  . . .%d\r\n", (pnp->cfg & 0xFF));
    printf("HWID . . . . . .0x%08x\r\n", pnp->hwid);
    printf("FWID . . . . . .0x%08x\r\n", pnp->fwid);

    led_set(0x02);
    print_pnp();

    led_set(0x03);
    wait_ddr();

    led_set(0x04);
    wait_pcie();

    printf("PCIe:. . . . . .0x%04x\r\n", pcictrl->bdf);

    setup_1sec_irq();
    while (1) {
        ddr_addr = ddr_torture(ddr_addr);
    }

    // NEVER REACH THIS POINT
    return 0;
}
