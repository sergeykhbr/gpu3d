// 
//  Copyright 2025 Sergey Khabarov, sergeykhbr@gmail.com
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

#include <systemc.h>
#include "../prj/impl/asic_accel_sim/asic_accel_top_tb.h"
#include "../prj/tb/pcie_dma_tb.h"
#include "../prj/tb/accel_axi2apb_bus1_tb.h"
#include "../prj/tb/apb_i2c_tb.h"
#include "../prj/tb/afifo_xslv_tb.h"
#include "../prj/tb/hdmi_tb.h"
#include "../prj/tb/mathlib_tb.h"

using namespace debugger;

int sc_main(int argc, char *argv[]) {
    sc_trace_file *vcd_ = sc_create_vcd_trace_file(CMAKE_BINARY_DIR"/accel");
    vcd_->set_time_unit(1, SC_PS);

#if 0
    mathlib_tb *tb = new mathlib_tb("tb");
#elif 0
    hdmi_tb *tb = new hdmi_tb("tb");
#elif 0
    afifo_xslv_tb *tb = new afifo_xslv_tb("tb");
#elif 1
    accel_axi2apb_bus1_tb *tb = new accel_axi2apb_bus1_tb("tb");
#elif 0
    apb_i2c_tb *tb = new apb_i2c_tb("tb");
#elif 0
    pcie_dma_tb *tb = new pcie_dma_tb("tb");
#else
    asic_accel_top_tb *tb = new asic_accel_top_tb("tb");
#endif
    tb->generateVCD(0, vcd_);

    sc_start(100, SC_NS);
    std::cout << "@" << sc_time_stamp()
              << ": Simulation started successfully. Continue for 10 ms..."
              << std::endl;

    sc_start(5, SC_MS);

    if (vcd_) {
        sc_close_vcd_trace_file(vcd_);
    }
    delete tb;

    std::cout << "@" << sc_time_stamp() << ": Done" << std::endl;
    std::cout << "Trace file: " << CMAKE_BINARY_DIR"/accel.vcd" << std::endl;

    return 0;
}