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

#include "afifo_xslv_tb.h"
#include "api_core.h"

namespace debugger {

afifo_xslv_tb::afifo_xslv_tb(sc_module_name name)
    : sc_module(name) {

    clk1 = 0;
    clk2 = 0;
    slv0 = 0;
    tt = 0;

    clk1 = new vip_clk("clk1",
                        5.0);
    clk1->o_clk(w_clk1);

    clk2 = new vip_clk("clk2",
                        25.0);
    clk2->o_clk(w_clk2);

    tt = new afifo_xslv<2,
                        10>("tt");
    tt->i_xslv_nrst(i_nrst);
    tt->i_xslv_clk(w_clk1);
    tt->i_xslvi(wb_clk1_xslvi);
    tt->o_xslvo(wb_clk1_xslvo);
    tt->i_xmst_nrst(i_nrst);
    tt->i_xmst_clk(w_clk2);
    tt->o_xmsto(wb_clk2_xmsto);
    tt->i_xmsti(wb_clk2_xmsti);

    slv0 = new axi_slv("slv0",
                        0,
                        0,
                        0);
    slv0->i_clk(w_clk2);
    slv0->i_nrst(i_nrst);
    slv0->i_mapinfo(wb_slv_i_mapinfo);
    slv0->o_cfg(wb_slv_o_cfg);
    slv0->i_xslvi(wb_clk2_xmsto);
    slv0->o_xslvo(wb_clk2_xmsti);
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
    sensitive << w_clk1;
    sensitive << w_clk2;
    sensitive << wb_clk1_xslvi;
    sensitive << wb_clk1_xslvo;
    sensitive << wb_clk2_xmsto;
    sensitive << wb_clk2_xmsti;
    sensitive << wb_slv_i_mapinfo;
    sensitive << wb_slv_o_cfg;
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

    SC_METHOD(test_clk1);
    sensitive << w_clk1.posedge_event();

    SC_METHOD(test_clk2);
    sensitive << w_clk2.posedge_event();
}

afifo_xslv_tb::~afifo_xslv_tb() {
    if (clk1) {
        delete clk1;
    }
    if (clk2) {
        delete clk2;
    }
    if (slv0) {
        delete slv0;
    }
    if (tt) {
        delete tt;
    }
}

void afifo_xslv_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk1) {
        clk1->generateVCD(i_vcd, o_vcd);
    }
    if (clk2) {
        clk2->generateVCD(i_vcd, o_vcd);
    }
    if (slv0) {
        slv0->generateVCD(i_vcd, o_vcd);
    }
    if (tt) {
        tt->generateVCD(i_vcd, o_vcd);
    }
}

void afifo_xslv_tb::comb() {
    mapinfo_type vb_mapinfo;
    axi4_slave_in_type vb_xslvi;
    axi4_master_in_type vb_xmsti;

    vb_mapinfo.addr_start = 0x000008000000;
    vb_mapinfo.addr_end = 0x000008001000;
    wb_slv_i_mapinfo = vb_mapinfo;
}

void afifo_xslv_tb::test_clk1() {
    axi4_slave_in_type vb_xslvi;

    wb_clk1_cnt = (wb_clk1_cnt + 1);
    if (wb_clk1_cnt < 10) {
        i_nrst = 0;
    } else {
        i_nrst = 1;
    }

    vb_xslvi = axi4_slave_in_none;
    vb_xslvi.r_ready = 1;
    vb_xslvi.b_ready = 1;
    if (wb_clk1_cnt == 20) {
        vb_xslvi.aw_valid = 1;
        vb_xslvi.aw_bits.addr = 0x000008000008;
        vb_xslvi.aw_bits.size = 0x3;
        vb_xslvi.aw_bits.len = 0x3;
    } else if (wb_clk1_cnt == 21) {
        vb_xslvi.w_valid = 1;
        vb_xslvi.w_data = 0x1122334455667788;
        vb_xslvi.w_strb = 0xFF;
    } else if (wb_clk1_cnt == 22) {
        vb_xslvi.w_valid = 1;
        vb_xslvi.w_data = 0x2222334455667788;
        vb_xslvi.w_strb = 0xFF;
    } else if (wb_clk1_cnt == 23) {
        vb_xslvi.w_valid = 1;
        vb_xslvi.w_data = 0x3322334455667788;
        vb_xslvi.w_strb = 0xFF;
    } else if (wb_clk1_cnt == 24) {
        vb_xslvi.w_valid = 1;
        vb_xslvi.w_data = 0x4422334455667788;
        vb_xslvi.w_strb = 0xFF;
        vb_xslvi.w_last = 1;
    } else if (wb_clk1_cnt == 1000) {
        vb_xslvi.ar_valid = 1;
        vb_xslvi.ar_bits.addr = 0x000008000008;
        vb_xslvi.ar_bits.size = 0x3;
        vb_xslvi.ar_bits.len = 0x3;
    }

    wb_clk1_xslvi = vb_xslvi;
}

void afifo_xslv_tb::test_clk2() {
    if (i_nrst.read() == 0) {
        rd_valid = 0;
        rd_addr = 0;
    } else {
        if ((w_slv_o_req_write.read() == 1) && (w_slv_o_req_valid.read() == 1)) {
            mem[wb_slv_o_req_addr.read()(5, 2).to_int()] = wb_slv_o_req_wdata.read();
        }
        rd_addr = wb_slv_o_req_addr.read()(5, 2);
        rd_valid = w_slv_o_req_valid.read();
    }
    wb_slv_i_resp_rdata = mem[rd_addr(3, 0).to_int()];
    w_slv_i_resp_valid = rd_valid;
    w_slv_i_req_ready = 1;
    w_slv_i_resp_err = 0;
}

}  // namespace debugger

