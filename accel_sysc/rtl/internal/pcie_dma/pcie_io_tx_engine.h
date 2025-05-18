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

template<int C_DATA_WIDTH = 64,
         int KEEP_WIDTH = (C_DATA_WIDTH / 8)>
SC_MODULE(pcie_io_tx_engine) {
 public:
    sc_in<bool> i_nrst;
    sc_in<bool> i_clk;                                      // System bus clock
    // 
    sc_in<bool> i_s_axis_tx_tready;
    sc_out<sc_uint<C_DATA_WIDTH>> o_s_axis_tx_tdata;
    sc_out<sc_uint<KEEP_WIDTH>> o_s_axis_tx_tkeep;
    sc_out<bool> o_s_axis_tx_tlast;
    sc_out<bool> o_s_axis_tx_tvalid;
    sc_out<bool> o_tx_src_dsc;
    // 
    sc_in<bool> i_req_compl;
    sc_in<bool> i_req_compl_wd;
    sc_out<bool> o_compl_done;
    // 
    sc_in<sc_uint<3>> i_req_tc;
    sc_in<bool> i_req_td;
    sc_in<bool> i_req_ep;
    sc_in<sc_uint<2>> i_req_attr;
    sc_in<sc_uint<10>> i_req_len;
    sc_in<sc_uint<16>> i_req_rid;
    sc_in<sc_uint<8>> i_req_tag;
    sc_in<sc_uint<8>> i_req_be;
    sc_in<sc_uint<13>> i_req_addr;
    sc_in<sc_uint<10>> i_req_bytes;
    // 
    sc_in<bool> i_dma_resp_valid;
    sc_in<bool> i_dma_resp_last;
    sc_in<bool> i_dma_resp_fault;                           // Error on memory access
    sc_in<sc_uint<13>> i_dma_resp_addr;
    sc_in<sc_uint<64>> i_dma_resp_data;
    sc_out<bool> o_dma_resp_ready;                          // Ready to accept response
    sc_in<sc_uint<16>> i_completer_id;

    void comb();
    void reqff();
    void registers();

    pcie_io_tx_engine(sc_module_name name);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    // 
    static const uint8_t PIO_CPLD_FMT_TYPE = 0x4A;
    static const uint8_t PIO_CPL_FMT_TYPE = 0x0A;
    static const uint8_t PIO_TX_RST_STATE = 0x0;
    static const uint8_t PIO_TX_CPLD_QW1_FIRST = 0x1;
    static const uint8_t PIO_TX_CPLD_QW1 = 0x3;

    struct pcie_io_tx_engine_registers {
        sc_signal<sc_uint<C_DATA_WIDTH>> s_axis_tx_tdata;
        sc_signal<sc_uint<KEEP_WIDTH>> s_axis_tx_tkeep;
        sc_signal<bool> s_axis_tx_tlast;
        sc_signal<bool> s_axis_tx_tvalid;
        sc_signal<bool> compl_done;
        sc_signal<sc_uint<13>> req_addr;
        sc_signal<sc_uint<4>> rd_be;
        sc_signal<sc_uint<32>> rd_data;
        sc_signal<bool> req_compl_wd_q;
        sc_signal<sc_uint<2>> state;
    };

    void pcie_io_tx_engine_r_reset(pcie_io_tx_engine_registers& iv) {
        iv.s_axis_tx_tdata = 0;
        iv.s_axis_tx_tkeep = 0;
        iv.s_axis_tx_tlast = 0;
        iv.s_axis_tx_tvalid = 0;
        iv.compl_done = 0;
        iv.req_addr = 0;
        iv.rd_be = 0;
        iv.rd_data = 0;
        iv.req_compl_wd_q = 1;
        iv.state = PIO_TX_RST_STATE;
    }

    pcie_io_tx_engine_registers v;
    pcie_io_tx_engine_registers r;

};

template<int C_DATA_WIDTH, int KEEP_WIDTH>
pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH>::pcie_io_tx_engine(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_s_axis_tx_tready("i_s_axis_tx_tready"),
    o_s_axis_tx_tdata("o_s_axis_tx_tdata"),
    o_s_axis_tx_tkeep("o_s_axis_tx_tkeep"),
    o_s_axis_tx_tlast("o_s_axis_tx_tlast"),
    o_s_axis_tx_tvalid("o_s_axis_tx_tvalid"),
    o_tx_src_dsc("o_tx_src_dsc"),
    i_req_compl("i_req_compl"),
    i_req_compl_wd("i_req_compl_wd"),
    o_compl_done("o_compl_done"),
    i_req_tc("i_req_tc"),
    i_req_td("i_req_td"),
    i_req_ep("i_req_ep"),
    i_req_attr("i_req_attr"),
    i_req_len("i_req_len"),
    i_req_rid("i_req_rid"),
    i_req_tag("i_req_tag"),
    i_req_be("i_req_be"),
    i_req_addr("i_req_addr"),
    i_req_bytes("i_req_bytes"),
    i_dma_resp_valid("i_dma_resp_valid"),
    i_dma_resp_last("i_dma_resp_last"),
    i_dma_resp_fault("i_dma_resp_fault"),
    i_dma_resp_addr("i_dma_resp_addr"),
    i_dma_resp_data("i_dma_resp_data"),
    o_dma_resp_ready("o_dma_resp_ready"),
    i_completer_id("i_completer_id") {


    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_s_axis_tx_tready;
    sensitive << i_req_compl;
    sensitive << i_req_compl_wd;
    sensitive << i_req_tc;
    sensitive << i_req_td;
    sensitive << i_req_ep;
    sensitive << i_req_attr;
    sensitive << i_req_len;
    sensitive << i_req_rid;
    sensitive << i_req_tag;
    sensitive << i_req_be;
    sensitive << i_req_addr;
    sensitive << i_req_bytes;
    sensitive << i_dma_resp_valid;
    sensitive << i_dma_resp_last;
    sensitive << i_dma_resp_fault;
    sensitive << i_dma_resp_addr;
    sensitive << i_dma_resp_data;
    sensitive << i_completer_id;
    sensitive << r.s_axis_tx_tdata;
    sensitive << r.s_axis_tx_tkeep;
    sensitive << r.s_axis_tx_tlast;
    sensitive << r.s_axis_tx_tvalid;
    sensitive << r.compl_done;
    sensitive << r.req_addr;
    sensitive << r.rd_be;
    sensitive << r.rd_data;
    sensitive << r.req_compl_wd_q;
    sensitive << r.state;

    SC_METHOD(reqff);
    sensitive << i_clk.pos();

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_s_axis_tx_tready, i_s_axis_tx_tready.name());
        sc_trace(o_vcd, o_s_axis_tx_tdata, o_s_axis_tx_tdata.name());
        sc_trace(o_vcd, o_s_axis_tx_tkeep, o_s_axis_tx_tkeep.name());
        sc_trace(o_vcd, o_s_axis_tx_tlast, o_s_axis_tx_tlast.name());
        sc_trace(o_vcd, o_s_axis_tx_tvalid, o_s_axis_tx_tvalid.name());
        sc_trace(o_vcd, o_tx_src_dsc, o_tx_src_dsc.name());
        sc_trace(o_vcd, i_req_compl, i_req_compl.name());
        sc_trace(o_vcd, i_req_compl_wd, i_req_compl_wd.name());
        sc_trace(o_vcd, o_compl_done, o_compl_done.name());
        sc_trace(o_vcd, i_req_tc, i_req_tc.name());
        sc_trace(o_vcd, i_req_td, i_req_td.name());
        sc_trace(o_vcd, i_req_ep, i_req_ep.name());
        sc_trace(o_vcd, i_req_attr, i_req_attr.name());
        sc_trace(o_vcd, i_req_len, i_req_len.name());
        sc_trace(o_vcd, i_req_rid, i_req_rid.name());
        sc_trace(o_vcd, i_req_tag, i_req_tag.name());
        sc_trace(o_vcd, i_req_be, i_req_be.name());
        sc_trace(o_vcd, i_req_addr, i_req_addr.name());
        sc_trace(o_vcd, i_req_bytes, i_req_bytes.name());
        sc_trace(o_vcd, i_dma_resp_valid, i_dma_resp_valid.name());
        sc_trace(o_vcd, i_dma_resp_last, i_dma_resp_last.name());
        sc_trace(o_vcd, i_dma_resp_fault, i_dma_resp_fault.name());
        sc_trace(o_vcd, i_dma_resp_addr, i_dma_resp_addr.name());
        sc_trace(o_vcd, i_dma_resp_data, i_dma_resp_data.name());
        sc_trace(o_vcd, o_dma_resp_ready, o_dma_resp_ready.name());
        sc_trace(o_vcd, i_completer_id, i_completer_id.name());
        sc_trace(o_vcd, r.s_axis_tx_tdata, pn + ".r.s_axis_tx_tdata");
        sc_trace(o_vcd, r.s_axis_tx_tkeep, pn + ".r.s_axis_tx_tkeep");
        sc_trace(o_vcd, r.s_axis_tx_tlast, pn + ".r.s_axis_tx_tlast");
        sc_trace(o_vcd, r.s_axis_tx_tvalid, pn + ".r.s_axis_tx_tvalid");
        sc_trace(o_vcd, r.compl_done, pn + ".r.compl_done");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.rd_be, pn + ".r.rd_be");
        sc_trace(o_vcd, r.rd_data, pn + ".r.rd_data");
        sc_trace(o_vcd, r.req_compl_wd_q, pn + ".r.req_compl_wd_q");
        sc_trace(o_vcd, r.state, pn + ".r.state");
    }

}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH>::comb() {
    sc_uint<7> vb_lower_addr;
    sc_uint<C_DATA_WIDTH> vb_s_axis_tx_tdata;

    v = r;
    vb_lower_addr = 0;
    vb_s_axis_tx_tdata = 0;

    // The completer field 'lower address' DWORD[2][6:0]:
    // For completions other than for memory reads, this value is set to 0.
    // For memory reads it is the lower byte address of the first byte in
    // the returned data (or partial data). This is set for the first
    // (or only) completion and will be 0 in the lower 7 bits from then on,
    // as the completions, if split, must be naturally aligned to a read
    // completion boundary (RCB), which is usually 128 bytes
    // (though 64 bytes in root complex).
    if (r.req_compl_wd_q.read() == 0) {
        // Request without payload
        vb_lower_addr = 0;
    } else {
        vb_lower_addr = r.req_addr.read()(6, 0);
    }

    switch (r.state.read()) {
    case PIO_TX_RST_STATE:
        v.s_axis_tx_tvalid = 0;
        v.s_axis_tx_tkeep = 0xFF;
        v.s_axis_tx_tdata = 0;
        v.s_axis_tx_tlast = 0;
        v.compl_done = 0;
        if ((i_req_compl.read() == 1) && (i_dma_resp_valid.read() == 1)) {
            v.req_addr = i_req_addr.read();
            v.rd_data = i_dma_resp_data.read()(31, 0);
            v.rd_be = i_req_be.read();
            v.req_compl_wd_q = i_req_compl_wd.read();
            v.state = PIO_TX_CPLD_QW1_FIRST;
        }
        break;

    case PIO_TX_CPLD_QW1_FIRST:
        if (i_s_axis_tx_tready.read() == 1) {
            v.s_axis_tx_tlast = 0;
            vb_s_axis_tx_tdata(63, 48) = i_completer_id.read();
            vb_s_axis_tx_tdata(47, 45) = 0;
            vb_s_axis_tx_tdata[44] = 0;
            vb_s_axis_tx_tdata(43, 32) = i_req_bytes.read();
            vb_s_axis_tx_tdata[31] = 0;
            if (r.req_compl_wd_q.read() == 1) {
                vb_s_axis_tx_tdata(30, 24) = PIO_CPLD_FMT_TYPE;
            } else {
                vb_s_axis_tx_tdata(30, 24) = PIO_CPL_FMT_TYPE;
            }
            vb_s_axis_tx_tdata[23] = 0;
            vb_s_axis_tx_tdata(22, 20) = i_req_tc.read();
            vb_s_axis_tx_tdata(19, 16) = 0;
            vb_s_axis_tx_tdata[15] = i_req_td.read();
            vb_s_axis_tx_tdata[14] = i_req_ep.read();
            vb_s_axis_tx_tdata(13, 12) = i_req_attr.read();
            vb_s_axis_tx_tdata(11, 10) = 0;
            vb_s_axis_tx_tdata(9, 0) = i_req_len.read();
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;
            v.s_axis_tx_tkeep = 0xFF;
            v.state = PIO_TX_CPLD_QW1;
            v.s_axis_tx_tvalid = 1;
        } else {
            v.state = PIO_TX_RST_STATE;
        }
        break;

    case PIO_TX_CPLD_QW1:
        if (i_s_axis_tx_tready.read() == 1) {
            v.s_axis_tx_tlast = 1;
            v.s_axis_tx_tvalid = 1;
            // Swap DWORDS for AXI
            vb_s_axis_tx_tdata(63, 32) = r.rd_data.read();
            vb_s_axis_tx_tdata(31, 16) = i_req_rid.read();
            vb_s_axis_tx_tdata(15, 8) = i_req_tag.read();
            vb_s_axis_tx_tdata[7] = 0;
            vb_s_axis_tx_tdata(6, 0) = vb_lower_addr;
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;

            // Mask data strob if data no need:
            if (r.req_compl_wd_q.read() == 1) {
                v.s_axis_tx_tkeep = 0xFF;
            } else {
                v.s_axis_tx_tkeep = 0x0F;
            }
            v.compl_done = 1;
            v.state = PIO_TX_RST_STATE;
        } else {
            v.state = PIO_TX_CPLD_QW1;
        }
        break;

    default:
        v.state = PIO_TX_RST_STATE;
        break;
    }

    o_s_axis_tx_tdata = r.s_axis_tx_tdata.read();
    o_s_axis_tx_tkeep = r.s_axis_tx_tkeep.read();
    o_s_axis_tx_tlast = r.s_axis_tx_tlast.read();
    o_s_axis_tx_tvalid = r.s_axis_tx_tvalid.read();
    o_dma_resp_ready = 1;
    o_compl_done = r.compl_done.read();

    // Unused discontinue
    o_tx_src_dsc = 0;
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH>::reqff() {
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH>::registers() {
    if (i_nrst.read() == 0) {
        pcie_io_tx_engine_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

