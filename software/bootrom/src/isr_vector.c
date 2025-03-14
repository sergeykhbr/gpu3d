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

#include <inttypes.h>

void __attribute__ ((section(".after_vectors"))) exception_instr_load_fault_c() {
}

void __attribute__ ((section(".after_vectors"))) exception_load_fault_c() {
}

void __attribute__ ((section(".after_vectors"))) exception_store_fault_c() {
}

void __attribute__ ((section(".after_vectors"))) exception_stack_overflow_c() {
}

void __attribute__ ((section(".after_vectors"))) exception_stack_underflow_c() {
}

void __attribute__ ((section(".after_vectors"))) exception_handler_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_s_software_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_m_software_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_s_timer_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_m_timer_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_s_external_c() {
}

void __attribute__ ((section(".after_vectors"))) interrupt_m_external_c() {
}

long __attribute__ ((section(".after_vectors"))) interrupt_handler_c(long cause,
                                                                     long epc,
                                                                     int64_t regs[32]) {
}
