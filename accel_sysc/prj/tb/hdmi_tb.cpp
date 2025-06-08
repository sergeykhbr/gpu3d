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

#include "hdmi_tb.h"
#include "api_core.h"

namespace debugger {

hdmi_tb::hdmi_tb(sc_module_name name)
    : sc_module(name) {

    clk = 0;
    slv0 = 0;
    tt = 0;

    clk = new vip_clk("clk",
                       25.0);
    clk->o_clk(w_clk);

    tt = new hdmi_top("tt",
                       0);
    tt->i_nrst(i_nrst);
    tt->i_clk(w_clk);
    tt->i_hdmi_nrst(i_nrst);
    tt->i_hdmi_clk(w_clk);
    tt->o_hsync(w_hdmi_hsync);
    tt->o_vsync(w_hdmi_vsync);
    tt->o_de(w_hdmi_de);
    tt->o_data(wb_hdmi_data);
    tt->o_spdif(w_hdmi_spdif);
    tt->i_spdif_out(w_hdmi_spdif_out);
    tt->i_irq(w_hdmi_irq);
    tt->o_xmst_cfg(wb_mst_o_cfg);
    tt->i_xmsti(wb_xmsti);
    tt->o_xmsto(wb_xmsto);

    slv0 = new axi_slv("slv0",
                        0,
                        0,
                        0);
    slv0->i_clk(w_clk);
    slv0->i_nrst(i_nrst);
    slv0->i_mapinfo(wb_slv_mapinfo);
    slv0->o_cfg(wb_slv_o_cfg);
    slv0->i_xslvi(wb_xslvi);
    slv0->o_xslvo(wb_xslvo);
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
    sensitive << w_clk;
    sensitive << w_hdmi_hsync;
    sensitive << w_hdmi_vsync;
    sensitive << w_hdmi_de;
    sensitive << wb_hdmi_data;
    sensitive << w_hdmi_spdif;
    sensitive << w_hdmi_spdif_out;
    sensitive << w_hdmi_irq;
    sensitive << wb_xmsto;
    sensitive << wb_xmsti;
    sensitive << wb_mst_o_cfg;
    sensitive << wb_xslvi;
    sensitive << wb_xslvo;
    sensitive << wb_slv_o_cfg;
    sensitive << wb_slv_mapinfo;
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

    SC_METHOD(test_clk);
    sensitive << w_clk.posedge_event();
}

hdmi_tb::~hdmi_tb() {
    if (clk) {
        delete clk;
    }
    if (slv0) {
        delete slv0;
    }
    if (tt) {
        delete tt;
    }
}

void hdmi_tb::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
    }

    if (clk) {
        clk->generateVCD(i_vcd, o_vcd);
    }
    if (slv0) {
        slv0->generateVCD(i_vcd, o_vcd);
    }
    if (tt) {
        tt->generateVCD(i_vcd, o_vcd);
    }
}

void hdmi_tb::comb() {
    mapinfo_type vb_mapinfo;
    axi4_slave_in_type vb_xslvi;
    axi4_master_in_type vb_xmsti;

    vb_mapinfo.addr_start = 0x000080000000;
    vb_mapinfo.addr_end = 0x000080001000;
    wb_slv_mapinfo = vb_mapinfo;
    vb_xslvi.ar_valid = wb_xmsto.read().ar_valid;
    vb_xslvi.ar_bits.addr = wb_xmsto.read().ar_bits.addr;
    vb_xslvi.ar_bits.len = wb_xmsto.read().ar_bits.len;
    vb_xslvi.ar_bits.size = wb_xmsto.read().ar_bits.size;
    vb_xslvi.ar_bits.burst = wb_xmsto.read().ar_bits.burst;
    vb_xslvi.ar_bits.lock = wb_xmsto.read().ar_bits.lock;
    vb_xslvi.ar_bits.cache = wb_xmsto.read().ar_bits.cache;
    vb_xslvi.ar_bits.prot = wb_xmsto.read().ar_bits.prot;
    vb_xslvi.ar_bits.qos = wb_xmsto.read().ar_bits.qos;
    vb_xslvi.ar_bits.region = wb_xmsto.read().ar_bits.region;
    vb_xslvi.aw_valid = wb_xmsto.read().aw_valid;
    vb_xslvi.aw_bits.addr = wb_xmsto.read().aw_bits.addr;
    vb_xslvi.aw_bits.len = wb_xmsto.read().aw_bits.len;
    vb_xslvi.aw_bits.size = wb_xmsto.read().aw_bits.size;
    vb_xslvi.aw_bits.burst = wb_xmsto.read().aw_bits.burst;
    vb_xslvi.aw_bits.lock = wb_xmsto.read().aw_bits.lock;
    vb_xslvi.aw_bits.cache = wb_xmsto.read().aw_bits.cache;
    vb_xslvi.aw_bits.prot = wb_xmsto.read().aw_bits.prot;
    vb_xslvi.aw_bits.qos = wb_xmsto.read().aw_bits.qos;
    vb_xslvi.aw_bits.region = wb_xmsto.read().aw_bits.region;
    vb_xslvi.aw_id = wb_xmsto.read().aw_id;
    vb_xslvi.aw_user = wb_xmsto.read().aw_user;
    vb_xslvi.w_valid = wb_xmsto.read().w_valid;
    vb_xslvi.w_data = wb_xmsto.read().w_data;
    vb_xslvi.w_last = wb_xmsto.read().w_last;
    vb_xslvi.w_strb = wb_xmsto.read().w_strb;
    vb_xslvi.w_user = wb_xmsto.read().w_user;
    vb_xslvi.b_ready = wb_xmsto.read().b_ready;
    vb_xslvi.ar_id = wb_xmsto.read().ar_id;
    vb_xslvi.ar_user = wb_xmsto.read().ar_user;
    vb_xslvi.r_ready = wb_xmsto.read().r_ready;

    vb_xmsti.aw_ready = wb_xslvo.read().aw_ready;
    vb_xmsti.w_ready = wb_xslvo.read().w_ready;
    vb_xmsti.b_valid = wb_xslvo.read().b_valid;
    vb_xmsti.b_resp = wb_xslvo.read().b_resp;
    vb_xmsti.b_id = wb_xslvo.read().b_id;
    vb_xmsti.b_user = wb_xslvo.read().b_user;
    vb_xmsti.ar_ready = wb_xslvo.read().ar_ready;
    vb_xmsti.r_valid = wb_xslvo.read().r_valid;
    vb_xmsti.r_resp = wb_xslvo.read().r_resp;
    vb_xmsti.r_data = wb_xslvo.read().r_data;
    vb_xmsti.r_last = wb_xslvo.read().r_last;
    vb_xmsti.r_id = wb_xslvo.read().r_id;
    vb_xmsti.r_user = wb_xslvo.read().r_user;

    wb_xslvi = vb_xslvi;
    wb_xmsti = vb_xmsti;
}

void hdmi_tb::test_clk() {
    axi4_slave_in_type vb_xslvi;

    wb_clk_cnt = (wb_clk_cnt + 1);
    if (wb_clk_cnt < 10) {
        i_nrst = 0;
    } else {
        i_nrst = 1;
    }
    if (i_nrst.read() == 0) {
        rd_valid = 0;
        req_ready = 0;
        rd_addr = 0;
        rd_data = 0;
        v_busy = 0;
    } else {
        v_busy = 0;
        if ((w_slv_o_req_write.read() == 1) && (w_slv_o_req_valid.read() == 1)) {
            mem[wb_slv_o_req_addr.read()(5, 2).to_int()] = wb_slv_o_req_wdata.read();
        }
        rd_addr = wb_slv_o_req_addr.read()(5, 2);
        if ((w_slv_o_req_valid.read() & (!v_busy)) == 1) {
            rd_data = wb_slv_o_req_addr.read();
        }
        rd_valid = (rd_valid(1, 0), (w_slv_o_req_valid.read() & (!v_busy)));
    }
    wb_slv_i_resp_rdata = rd_data;
    w_slv_i_resp_valid = rd_valid[0];
    w_slv_i_req_ready = 1;
    w_slv_i_resp_err = 0;
}

}  // namespace debugger

