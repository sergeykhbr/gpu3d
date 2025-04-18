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
#pragma once

#include <systemc.h>
#include "api_core.h"

namespace debugger {

template<int abits = 6,
         int dbits = 8>
SC_MODULE(ram_dp_fifo_tech) {
 public:
    sc_in<bool> i_wclk;                                     // Write clock
    sc_in<bool> i_wena;
    sc_in<bool> i_addr;
    sc_in<sc_uint<dbits>> i_wdata;
    sc_in<bool> i_rclk;                                     // Read clock
    sc_in<bool> i_raddr;
    sc_out<sc_uint<dbits>> o_rdata;

    void wr();
    void rd();

    SC_HAS_PROCESS(ram_dp_fifo_tech);

    ram_dp_fifo_tech(sc_module_name name);


 private:
    static const int DEPTH = (1 << abits);

    sc_uint<dbits> mem[DEPTH];

};

template<int abits, int dbits>
ram_dp_fifo_tech<abits, dbits>::ram_dp_fifo_tech(sc_module_name name)
    : sc_module(name),
    i_wclk("i_wclk"),
    i_wena("i_wena"),
    i_addr("i_addr"),
    i_wdata("i_wdata"),
    i_rclk("i_rclk"),
    i_raddr("i_raddr"),
    o_rdata("o_rdata") {


    SC_METHOD(wr);
    sensitive << i_wclk.pos();

    SC_METHOD(rd);
    sensitive << i_rclk.pos();
}

template<int abits, int dbits>
void ram_dp_fifo_tech<abits, dbits>::wr() {
    if (i_wena.read() == 1) {
        mem[i_addr.read().to_int()] = i_wdata;
    }
}

template<int abits, int dbits>
void ram_dp_fifo_tech<abits, dbits>::rd() {
    o_rdata = mem[i_raddr.read().to_int()];
}

}  // namespace debugger

