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

#include "pcie_dma_tb.h"
#include "api_core.h"

namespace debugger {

pcie_dma_tb::pcie_dma_tb(sc_module_name name)
    : sc_module(name) {

    clk0 = 0;
    clk1 = 0;
    slv0 = 0;
    tt = 0;

    clk0 = new vip_clk("clk0",
                        25.0);
    clk0->o_clk(i_clk);

    clk1 = new vip_clk("clk1",
                        16.0);
    clk1->o_clk(w_pci_clk);

    tt = new pcie_dma("tt",
                       0);
    tt->i_nrst(i_nrst);
    tt->i_clk(i_clk);
    tt->i_pcie_phy_clk(w_pci_clk);
    tt->i_pcie_completer_id(wb_i_pcie_completer_id);
    tt->o_dma_state(wb_o_dma_state);
    tt->i_pcie_dmai(wb_i_pcie_dmai);
    tt->o_pcie_dmao(wb_o_pcie_dmao);
    tt->o_xmst_cfg(wb_o_xmst_cfg);
    tt->i_xmsti(wb_i_xmsti);
    tt->o_xmsto(wb_o_xmsto);
    tt->o_dbg_valid(w_o_dbg_valid);
    tt->o_dbg_payload(wb_o_dbg_payload);

    slv0 = new axi_slv("slv0",
                        0,
                        0,
                        0);
    slv0->i_clk(i_clk);
    slv0->i_nrst(i_nrst);
    slv0->i_mapinfo(wb_slv_i_mapinfo);
    slv0->o_cfg(wb_slv_o_cfg);
    slv0->i_xslvi(wb_slv_i_xslvi);
    slv0->o_xslvo(wb_slv_o_xslvo);
    slv0->o_req_valid(w_slv_o_req_valid);
    slv0->o_req_addr(wb_slv_o_req_addr);
    slv0->o_req_size(wb_slv_o_req_size);
    slv0->o_req_write(w_slv_o_req_write);
    slv0->o_req_wdata(wb_slv_o_req_wdata);
    slv0->o_req_wstrb(wb_slv_o_req_wstrb);
    slv0->o_req_last(w_slv_o_req_last);
    slv0->i_req_ready(w_slv_i_req_ready);
    slv0->i_resp_valid(w_slv_i_resp_valid);
    slv0->i_resp_rdata(wb_slv_i_resp_rdata);
    slv0->i_resp_err(w_slv_i_resp_err);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << w_pci_clk;
    sensitive << wb_i_pcie_completer_id;
    sensitive << wb_o_dma_state;
    sensitive << wb_i_pcie_dmai;
    sensitive << wb_o_pcie_dmao;
    sensitive << wb_o_xmst_cfg;
    sensitive << wb_i_xmsti;
    sensitive << wb_o_xmsto;
    sensitive << w_o_dbg_valid;
    sensitive << wb_o_dbg_payload;
    sensitive << wb_slv_i_mapinfo;
    sensitive << wb_slv_o_cfg;
    sensitive << wb_slv_i_xslvi;
    sensitive << wb_slv_o_xslvo;
    sensitive << w_slv_o_req_valid;
    sensitive << wb_slv_o_req_addr;
    sensitive << wb_slv_o_req_size;
    sensitive << w_slv_o_req_write;
    sensitive << wb_slv_o_req_wdata;
    sensitive << wb_slv_o_req_wstrb;
    sensitive << w_slv_o_req_last;
    sensitive << w_slv_i_req_ready;
    sensitive << w_slv_i_resp_valid;
    sensitive << wb_slv_i_resp_rdata;
    sensitive << w_slv_i_resp_err;

    SC_METHOD(test);
    sensitive << w_pci_clk.posedge_event();

    SC_METHOD(bus);
    sensitive << i_clk.posedge_event();
}

pcie_dma_tb::~pcie_dma_tb() {
    if (clk0) {
        delete clk0;
    }
    if (clk1) {
        delete clk1;
    }
    if (slv0) {
        delete slv0;
    }
    if (tt) {
        delete tt;
    }
}

void pcie_dma_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
    if (clk1) {
        clk1->generateVCD(i_vcd, o_vcd);
    }
    if (slv0) {
        slv0->generateVCD(i_vcd, o_vcd);
    }
    if (tt) {
        tt->generateVCD(i_vcd, o_vcd);
    }
}

void pcie_dma_tb::comb() {
    mapinfo_type vb_mapinfo;
    axi4_slave_in_type vb_xslvi;
    axi4_master_in_type vb_xmsti;

    vb_mapinfo.addr_start = 0x000008000000;
    vb_mapinfo.addr_end = 0x000008001000;
    wb_slv_i_mapinfo = vb_mapinfo;

    vb_xslvi.aw_valid = wb_o_xmsto.read().aw_valid;
    vb_xslvi.aw_bits = wb_o_xmsto.read().aw_bits;
    vb_xslvi.aw_id = wb_o_xmsto.read().aw_id;
    vb_xslvi.aw_user = wb_o_xmsto.read().aw_user;
    vb_xslvi.w_valid = wb_o_xmsto.read().w_valid;
    vb_xslvi.w_data = wb_o_xmsto.read().w_data;
    vb_xslvi.w_last = wb_o_xmsto.read().w_last;
    vb_xslvi.w_strb = wb_o_xmsto.read().w_strb;
    vb_xslvi.w_user = wb_o_xmsto.read().w_user;
    vb_xslvi.b_ready = wb_o_xmsto.read().b_ready;
    vb_xslvi.ar_valid = wb_o_xmsto.read().ar_valid;
    vb_xslvi.ar_bits = wb_o_xmsto.read().ar_bits;
    vb_xslvi.ar_id = wb_o_xmsto.read().ar_id;
    vb_xslvi.ar_user = wb_o_xmsto.read().ar_user;
    vb_xslvi.r_ready = wb_o_xmsto.read().r_ready;
    wb_slv_i_xslvi = vb_xslvi;

    vb_xmsti.aw_ready = wb_slv_o_xslvo.read().aw_ready;
    vb_xmsti.w_ready = wb_slv_o_xslvo.read().w_ready;
    vb_xmsti.b_valid = wb_slv_o_xslvo.read().b_valid;
    vb_xmsti.b_resp = wb_slv_o_xslvo.read().b_resp;
    vb_xmsti.b_id = wb_slv_o_xslvo.read().b_id;
    vb_xmsti.b_user = wb_slv_o_xslvo.read().b_user;
    vb_xmsti.ar_ready = wb_slv_o_xslvo.read().ar_ready;
    vb_xmsti.r_valid = wb_slv_o_xslvo.read().r_valid;
    vb_xmsti.r_resp = wb_slv_o_xslvo.read().r_resp;
    vb_xmsti.r_data = wb_slv_o_xslvo.read().r_data;
    vb_xmsti.r_last = wb_slv_o_xslvo.read().r_last;
    vb_xmsti.r_id = wb_slv_o_xslvo.read().r_id;
    vb_xmsti.r_user = wb_slv_o_xslvo.read().r_user;
    wb_i_xmsti = vb_xmsti;
}

void pcie_dma_tb::test() {
    pcie_dma64_in_type vb_dmai;

    wb_clk_cnt = (wb_clk_cnt + 1);
    if (wb_clk_cnt < 10) {
        i_nrst = 0;
    } else {
        i_nrst = 1;
    }

    vb_dmai = pcie_dma64_in_none;
    switch (wb_clk_cnt) {
    case 20:
        vb_dmai.valid = 1;
        vb_dmai.strob = 0xFF;
        vb_dmai.data(31, 24) = 0x40;                        // Wr32
        vb_dmai.data(9, 0) = 0x001;                         // Length
        vb_dmai.data(39, 32) = 0x0F;                        // be
        break;
    case 21:
        vb_dmai.valid = 1;
        vb_dmai.last = 1;
        vb_dmai.strob = 0xFF;
        vb_dmai.data(31, 0) = 0x00000104;                   // Addr
        vb_dmai.data(63, 32) = 0x11223344;                  // Data[31:0]
        break;
    case 40:
        vb_dmai.valid = 1;
        vb_dmai.strob = 0xFF;
        vb_dmai.data(31, 24) = 0x00;                        // Rd32
        vb_dmai.data(9, 0) = 0x001;                         // Length
        vb_dmai.data(39, 32) = 0x0F;                        // be
        break;
    case 41:
        vb_dmai.valid = 1;
        vb_dmai.last = 1;
        vb_dmai.strob = 0x0F;
        vb_dmai.data(31, 0) = 0x00000104;                   // Addr
        break;

    default:
        break;
    }

    vb_dmai.ready = 1;
    wb_i_pcie_dmai = vb_dmai;
}

void pcie_dma_tb::bus() {
    if (i_nrst.read() == 0) {
        rd_valid = 0;
        rd_addr = 0;
    } else {
        if ((w_slv_o_req_write.read() == 1) && (w_slv_o_req_valid.read() == 1)) {
            mem[wb_slv_o_req_addr.read()(3, 0).to_int()] = wb_slv_o_req_wdata.read();
        }
        rd_addr = wb_slv_o_req_addr.read()(3, 0);
        rd_valid = w_slv_o_req_valid.read();
    }
    wb_slv_i_resp_rdata = mem[rd_addr(3, 0).to_int()];
    w_slv_i_resp_valid = rd_valid;
    w_slv_i_req_ready = 1;
    w_slv_i_resp_err = 0;
}

}  // namespace debugger

