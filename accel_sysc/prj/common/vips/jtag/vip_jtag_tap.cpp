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

#include "vip_jtag_tap.h"
#include "api_core.h"

namespace debugger {

vip_jtag_tap::vip_jtag_tap(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_tck("i_tck"),
    i_req_valid("i_req_valid"),
    i_req_irlen("i_req_irlen"),
    i_req_ir("i_req_ir"),
    i_req_drlen("i_req_drlen"),
    i_req_dr("i_req_dr"),
    o_resp_valid("o_resp_valid"),
    o_resp_data("o_resp_data"),
    o_trst("o_trst"),
    o_tck("o_tck"),
    o_tms("o_tms"),
    o_tdo("o_tdo"),
    i_tdi("i_tdi") {


    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_tck;
    sensitive << i_req_valid;
    sensitive << i_req_irlen;
    sensitive << i_req_ir;
    sensitive << i_req_drlen;
    sensitive << i_req_dr;
    sensitive << i_tdi;
    sensitive << w_tck;
    sensitive << rx.req_valid;
    sensitive << rx.req_irlen;
    sensitive << rx.req_drlen;
    sensitive << rx.req_ir;
    sensitive << rx.req_dr;
    sensitive << rx.dr_length;
    sensitive << rx.dr;
    sensitive << rx.bypass;
    sensitive << rx.resp_valid;
    sensitive << rx.resp_data;
    sensitive << rnx.state;
    sensitive << rnx.trst;
    sensitive << rnx.tms;
    sensitive << rnx.datacnt;
    sensitive << rnx.shiftreg;
    sensitive << rnx.ir;

    SC_METHOD(rxegisters);
    sensitive << i_tck.pos();

    SC_METHOD(rnxegisters);
    sensitive << i_tck.neg();
}

void vip_jtag_tap::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_tck, i_tck.name());
        sc_trace(o_vcd, i_req_valid, i_req_valid.name());
        sc_trace(o_vcd, i_req_irlen, i_req_irlen.name());
        sc_trace(o_vcd, i_req_ir, i_req_ir.name());
        sc_trace(o_vcd, i_req_drlen, i_req_drlen.name());
        sc_trace(o_vcd, i_req_dr, i_req_dr.name());
        sc_trace(o_vcd, o_resp_valid, o_resp_valid.name());
        sc_trace(o_vcd, o_resp_data, o_resp_data.name());
        sc_trace(o_vcd, o_trst, o_trst.name());
        sc_trace(o_vcd, o_tck, o_tck.name());
        sc_trace(o_vcd, o_tms, o_tms.name());
        sc_trace(o_vcd, o_tdo, o_tdo.name());
        sc_trace(o_vcd, i_tdi, i_tdi.name());
        sc_trace(o_vcd, rx.req_valid, pn + ".rx.req_valid");
        sc_trace(o_vcd, rx.req_irlen, pn + ".rx.req_irlen");
        sc_trace(o_vcd, rx.req_drlen, pn + ".rx.req_drlen");
        sc_trace(o_vcd, rx.req_ir, pn + ".rx.req_ir");
        sc_trace(o_vcd, rx.req_dr, pn + ".rx.req_dr");
        sc_trace(o_vcd, rx.dr_length, pn + ".rx.dr_length");
        sc_trace(o_vcd, rx.dr, pn + ".rx.dr");
        sc_trace(o_vcd, rx.bypass, pn + ".rx.bypass");
        sc_trace(o_vcd, rx.resp_valid, pn + ".rx.resp_valid");
        sc_trace(o_vcd, rx.resp_data, pn + ".rx.resp_data");
        sc_trace(o_vcd, rnx.state, pn + ".rnx.state");
        sc_trace(o_vcd, rnx.trst, pn + ".rnx.trst");
        sc_trace(o_vcd, rnx.tms, pn + ".rnx.tms");
        sc_trace(o_vcd, rnx.datacnt, pn + ".rnx.datacnt");
        sc_trace(o_vcd, rnx.shiftreg, pn + ".rnx.shiftreg");
        sc_trace(o_vcd, rnx.ir, pn + ".rnx.ir");
    }

}

void vip_jtag_tap::comb() {
    sc_uint<64> vb_shiftreg;

    vnx = rnx;
    vx = rx;
    vb_shiftreg = 0;

    vnx.tms = 0;
    vx.resp_valid = 0;

    if (i_req_valid.read() == 1) {
        vx.req_valid = 1;
        vx.req_irlen = i_req_irlen.read();
        vx.req_ir = i_req_ir.read();
        vx.req_drlen = i_req_drlen.read();
        vx.req_dr = i_req_dr.read();
    }

    switch (rnx.state.read()) {
    case RESET_TAP:
        vnx.trst = 1;
        vnx.ir = ~0ull;
        vnx.state = IDLE;
        break;
    case IDLE:
        vnx.trst = 0;
        if (rx.req_valid.read() == 1) {
            vx.req_valid = 0;
            vnx.tms = 1;
            vnx.state = SELECT_DR_SCAN1;
        }
        break;
    case SELECT_DR_SCAN1:
        vnx.tms = 1;
        vnx.state = SELECT_IR_SCAN;
        break;
    case SELECT_IR_SCAN:
        vnx.state = CAPTURE_IR;
        vnx.ir = rx.req_ir.read();
        break;
    case CAPTURE_IR:
        vnx.state = SHIFT_IR;
        vb_shiftreg = rnx.ir.read();
        vnx.datacnt = rx.req_irlen.read();
        break;
    case SHIFT_IR:
        if (rnx.datacnt.read() <= 1) {
            vnx.tms = 1;
            vnx.state = EXIT1_IR;
        } else {
            vb_shiftreg = (0, rnx.shiftreg.read()(63, 1));
            vnx.datacnt = (rnx.datacnt.read() - 1);
        }
        break;
    case EXIT1_IR:
        vnx.tms = 1;
        vnx.state = UPDATE_IR;
        break;
    case UPDATE_IR:
        vnx.tms = 1;
        vnx.state = SELECT_DR_SCAN;
        break;
    case SELECT_DR_SCAN:
        vnx.state = CAPTURE_DR;
        break;
    case CAPTURE_DR:
        vb_shiftreg = rx.dr.read();
        vnx.datacnt = rx.req_drlen.read();
        vnx.state = SHIFT_DR;
        break;
    case SHIFT_DR:
        if (rnx.datacnt.read() <= 1) {
            vnx.tms = 1;
            vnx.state = EXIT1_DR;
        } else {
            vb_shiftreg = (0, rnx.shiftreg.read()(63, 1));
            vnx.datacnt = (rnx.datacnt.read() - 1);
        }
        break;
    case EXIT1_DR:
        vnx.tms = 1;
        vnx.state = UPDATE_DR;
        break;
    case UPDATE_DR:
        vx.resp_valid = 1;
        vx.resp_data = rnx.shiftreg.read();
        vnx.state = IDLE;
        break;
    default:
        vnx.state = IDLE;
        break;
    }

    vb_shiftreg[rx.req_drlen.read().to_int()] = i_tdi.read();
    vnx.shiftreg = vb_shiftreg;
    o_trst = rnx.trst.read();
    o_tck = i_tck.read();
    o_tms = rnx.tms.read();
    o_tdo = rnx.shiftreg.read()[0];
    o_resp_valid = rx.resp_valid.read();
    o_resp_data = rx.resp_data.read();
}

void vip_jtag_tap::rxegisters() {
    rx = vx;
}

void vip_jtag_tap::rnxegisters() {
    rnx = vnx;
}

}  // namespace debugger

