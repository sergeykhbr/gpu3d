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
    i_dbg_valid("i_dbg_valid"),
    i_dbg_payload("i_dbg_payload") {

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
    sensitive << i_dbg_valid;
    sensitive << i_dbg_payload;
    sensitive << w_req_valid;
    sensitive << wb_req_addr;
    sensitive << w_req_write;
    sensitive << wb_req_wdata;
    sensitive << r.resp_valid;
    sensitive << r.resp_rdata;
    sensitive << r.resp_err;

    SC_METHOD(reqff);
    sensitive << i_clk.pos();

    SC_METHOD(registers);
    sensitive << i_nrst;
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
        sc_trace(o_vcd, i_dbg_valid, i_dbg_valid.name());
        sc_trace(o_vcd, i_dbg_payload, i_dbg_payload.name());
        sc_trace(o_vcd, r.resp_valid, pn + ".r.resp_valid");
        sc_trace(o_vcd, r.resp_rdata, pn + ".r.resp_rdata");
        sc_trace(o_vcd, r.resp_err, pn + ".r.resp_err");
    }

    if (pslv0) {
        pslv0->generateVCD(i_vcd, o_vcd);
    }
}

void apb_pcie::comb() {
    sc_uint<32> vb_rdata;

    v = r;
    vb_rdata = 0;

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
        vb_rdata = req_cnt;
    } else if (wb_req_addr.read()(11, 7) == 1) {
        // 0x040..0x04F: debug buffer
        if (wb_req_addr.read()[2] == 0) {
            vb_rdata = req_data_arr[wb_req_addr.read()(6, 3).to_int()](31, 0);
        } else {
            vb_rdata = req_data_arr[wb_req_addr.read()(6, 3).to_int()](63, 32);
        }
    }

    v.resp_valid = w_req_valid.read();
    v.resp_rdata = vb_rdata;

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        apb_pcie_r_reset(v);
    }
}

void apb_pcie::reqff() {
    if (i_dbg_valid.read() == 1) {
        req_data_arr[req_cnt(3, 0).to_int()] = i_dbg_payload.read();
        req_cnt = (req_cnt + 1);
    }
}

void apb_pcie::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        apb_pcie_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

