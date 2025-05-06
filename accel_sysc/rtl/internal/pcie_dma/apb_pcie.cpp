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

#include "apb_pcie.h"
#include "api_core.h"

namespace debugger {

apb_pcie::apb_pcie(sc_module_name name,
                   bool async_reset)
    : sc_module(name),
    i_clk("i_clk"),
    i_nrst("i_nrst"),
    i_mapinfo("i_mapinfo"),
    o_cfg("o_cfg"),
    i_apbi("i_apbi"),
    o_apbo("o_apbo"),
    i_pcie_completer_id("i_pcie_completer_id"),
    i_dma_state("i_dma_state"),
    i_dbg_pcie_dmai("i_dbg_pcie_dmai") {

    async_reset_ = async_reset;
    pslv0 = 0;

    pslv0 = new apb_slv("pslv0",
                         async_reset,
                         VENDOR_OPTIMITECH,
                         OPTIMITECH_PCIE_CTRL);
    pslv0->i_clk(i_clk);
    pslv0->i_nrst(i_nrst);
    pslv0->i_mapinfo(i_mapinfo);
    pslv0->o_cfg(o_cfg);
    pslv0->i_apbi(i_apbi);
    pslv0->o_apbo(o_apbo);
    pslv0->o_req_valid(w_req_valid);
    pslv0->o_req_addr(wb_req_addr);
    pslv0->o_req_write(w_req_write);
    pslv0->o_req_wdata(wb_req_wdata);
    pslv0->i_resp_valid(r.resp_valid);
    pslv0->i_resp_rdata(r.resp_rdata);
    pslv0->i_resp_err(r.resp_err);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_mapinfo;
    sensitive << i_apbi;
    sensitive << i_pcie_completer_id;
    sensitive << i_dma_state;
    sensitive << i_dbg_pcie_dmai;
    sensitive << w_req_valid;
    sensitive << wb_req_addr;
    sensitive << w_req_write;
    sensitive << wb_req_wdata;
    sensitive << r.resp_valid;
    sensitive << r.resp_rdata;
    sensitive << r.resp_err;
    sensitive << r.req_cnt;
    for (int i = 0; i < 16; i++) {
        sensitive << rx.req_data_arr[i];
    }

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();

    SC_METHOD(rxegisters);
    sensitive << i_clk.pos();
}

apb_pcie::~apb_pcie() {
    if (pslv0) {
        delete pslv0;
    }
}

void apb_pcie::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_apbi, i_apbi.name());
        sc_trace(o_vcd, o_apbo, o_apbo.name());
        sc_trace(o_vcd, i_pcie_completer_id, i_pcie_completer_id.name());
        sc_trace(o_vcd, i_dma_state, i_dma_state.name());
        sc_trace(o_vcd, i_dbg_pcie_dmai, i_dbg_pcie_dmai.name());
        sc_trace(o_vcd, r.resp_valid, pn + ".r.resp_valid");
        sc_trace(o_vcd, r.resp_rdata, pn + ".r.resp_rdata");
        sc_trace(o_vcd, r.resp_err, pn + ".r.resp_err");
        sc_trace(o_vcd, r.req_cnt, pn + ".r.req_cnt");
        for (int i = 0; i < 16; i++) {
            sc_trace(o_vcd, rx.req_data_arr[i], pn + ".rx.req_data_arr[i]");
        }
    }

    if (pslv0) {
        pslv0->generateVCD(i_vcd, o_vcd);
    }
}

void apb_pcie::comb() {
    sc_uint<32> vb_rdata;

    for (int i = 0; i < 16; i++) {
        vx.req_data_arr[i] = rx.req_data_arr[i].read();
    }
    v = r;
    vb_rdata = 0;


    if (i_dbg_pcie_dmai.read().valid == 1) {
        v.req_cnt = (r.req_cnt.read() + 1);
        vx.req_data_arr[r.req_cnt.read().to_int()] = i_dbg_pcie_dmai.read().data;
    }

    v.resp_err = 0;
    // Registers access:
    if (wb_req_addr.read()(11, 2) == 0) {
        // 0x00: link status
        vb_rdata(3, 0) = i_dma_state.read();
    } else if (wb_req_addr.read()(11, 2) == 1) {
        // 0x04: bus, device, function
        vb_rdata(15, 0) = i_pcie_completer_id.read();
    } else if (wb_req_addr.read()(11, 2) == 2) {
        // 0x08: request counter
        vb_rdata(3, 0) = r.req_cnt.read();
    } else if (wb_req_addr.read()(11, 7) == 1) {
        // 0x040..0x04F: debug buffer
        if (wb_req_addr.read()[2] == 0) {
            vb_rdata = rx.req_data_arr[wb_req_addr.read()(6, 3).to_int()].read()(31, 0);
        } else {
            vb_rdata = rx.req_data_arr[wb_req_addr.read()(6, 3).to_int()].read()(63, 32);
        }
    }

    v.resp_valid = w_req_valid.read();
    v.resp_rdata = vb_rdata;

    if ((~async_reset_) && (i_nrst.read() == 0)) {
        apb_pcie_r_reset(v);
    }
}

void apb_pcie::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        apb_pcie_r_reset(r);
    } else {
        r = v;
    }
}

void apb_pcie::rxegisters() {
    for (int i = 0; i < 16; i++) {
        rx.req_data_arr[i] = vx.req_data_arr[i].read();
    }
}

}  // namespace debugger

