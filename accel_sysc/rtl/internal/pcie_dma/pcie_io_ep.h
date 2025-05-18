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
#include "pcie_io_rx_engine.h"
#include "pcie_io_tx_engine.h"
#include "api_core.h"

namespace debugger {

template<int C_DATA_WIDTH = 64,
         int KEEP_WIDTH = (C_DATA_WIDTH / 8)>
SC_MODULE(pcie_io_ep) {
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
    sc_in<sc_uint<C_DATA_WIDTH>> i_m_axis_rx_tdata;
    sc_in<sc_uint<KEEP_WIDTH>> i_m_axis_rx_tkeep;
    sc_in<bool> i_m_axis_rx_tlast;
    sc_in<bool> i_m_axis_rx_tvalid;
    sc_out<bool> o_m_axis_rx_tready;
    sc_in<sc_uint<9>> i_m_axis_rx_tuser;
    sc_in<sc_uint<16>> i_cfg_completer_id;                  // Bus, Device, Function
    // Memory access signals:
    sc_in<bool> i_req_mem_ready;                            // Ready to accept next memory request
    sc_out<bool> o_req_mem_valid;                           // Request data is valid to accept
    sc_out<bool> o_req_mem_write;                           // 0=read; 1=write operation
    sc_out<sc_uint<10>> o_req_mem_bytes;                    // 0=1024 B; 4=DWORD; 8=QWORD; ...
    sc_out<sc_uint<13>> o_req_mem_addr;                     // Address to read/write
    sc_out<sc_uint<8>> o_req_mem_strob;                     // Byte enabling write strob
    sc_out<sc_uint<64>> o_req_mem_data;                     // Data to write
    sc_out<bool> o_req_mem_last;                            // Last data payload in a sequence
    sc_in<bool> i_resp_mem_valid;                           // Read/Write data is valid. All write transaction with valid response.
    sc_in<bool> i_resp_mem_last;                            // Last response in sequence
    sc_in<bool> i_resp_mem_fault;                           // Error on memory access
    sc_in<sc_uint<13>> i_resp_mem_addr;                     // Read address value
    sc_in<sc_uint<64>> i_resp_mem_data;                     // Read data value
    sc_out<bool> o_resp_mem_ready;                          // Ready to accept response

    void comb();

    pcie_io_ep(sc_module_name name);
    virtual ~pcie_io_ep();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    sc_uint<64> SwapEndianess32(sc_uint<64> dword);

    sc_signal<bool> w_req_compl_int;
    sc_signal<bool> w_req_compl_wd;
    sc_signal<bool> w_compl_done_int;
    sc_signal<sc_uint<3>> wb_req_tc;
    sc_signal<bool> w_req_td;
    sc_signal<bool> w_req_ep;
    sc_signal<sc_uint<2>> wb_req_attr;
    sc_signal<sc_uint<10>> wb_req_len;
    sc_signal<sc_uint<16>> wb_req_rid;
    sc_signal<sc_uint<8>> wb_req_tag;
    sc_signal<sc_uint<8>> wb_req_be;
    sc_signal<sc_uint<13>> wb_req_addr;
    sc_signal<sc_uint<10>> wb_req_bytes;
    sc_signal<sc_uint<C_DATA_WIDTH>> wb_req_mem_data;
    sc_signal<sc_uint<C_DATA_WIDTH>> wb_resp_mem_data;

    pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH> *EP_RX_inst;
    pcie_io_tx_engine<C_DATA_WIDTH, KEEP_WIDTH> *EP_TX_inst;

};

template<int C_DATA_WIDTH, int KEEP_WIDTH>
pcie_io_ep<C_DATA_WIDTH, KEEP_WIDTH>::pcie_io_ep(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_s_axis_tx_tready("i_s_axis_tx_tready"),
    o_s_axis_tx_tdata("o_s_axis_tx_tdata"),
    o_s_axis_tx_tkeep("o_s_axis_tx_tkeep"),
    o_s_axis_tx_tlast("o_s_axis_tx_tlast"),
    o_s_axis_tx_tvalid("o_s_axis_tx_tvalid"),
    o_tx_src_dsc("o_tx_src_dsc"),
    i_m_axis_rx_tdata("i_m_axis_rx_tdata"),
    i_m_axis_rx_tkeep("i_m_axis_rx_tkeep"),
    i_m_axis_rx_tlast("i_m_axis_rx_tlast"),
    i_m_axis_rx_tvalid("i_m_axis_rx_tvalid"),
    o_m_axis_rx_tready("o_m_axis_rx_tready"),
    i_m_axis_rx_tuser("i_m_axis_rx_tuser"),
    i_cfg_completer_id("i_cfg_completer_id"),
    i_req_mem_ready("i_req_mem_ready"),
    o_req_mem_valid("o_req_mem_valid"),
    o_req_mem_write("o_req_mem_write"),
    o_req_mem_bytes("o_req_mem_bytes"),
    o_req_mem_addr("o_req_mem_addr"),
    o_req_mem_strob("o_req_mem_strob"),
    o_req_mem_data("o_req_mem_data"),
    o_req_mem_last("o_req_mem_last"),
    i_resp_mem_valid("i_resp_mem_valid"),
    i_resp_mem_last("i_resp_mem_last"),
    i_resp_mem_fault("i_resp_mem_fault"),
    i_resp_mem_addr("i_resp_mem_addr"),
    i_resp_mem_data("i_resp_mem_data"),
    o_resp_mem_ready("o_resp_mem_ready") {

    EP_RX_inst = 0;
    EP_TX_inst = 0;

    EP_RX_inst = new pcie_io_rx_engine<C_DATA_WIDTH,
                                       KEEP_WIDTH>("EP_RX_inst");
    EP_RX_inst->i_nrst(i_nrst);
    EP_RX_inst->i_clk(i_clk);
    EP_RX_inst->i_m_axis_rx_tdata(i_m_axis_rx_tdata);
    EP_RX_inst->i_m_axis_rx_tkeep(i_m_axis_rx_tkeep);
    EP_RX_inst->i_m_axis_rx_tlast(i_m_axis_rx_tlast);
    EP_RX_inst->i_m_axis_rx_tvalid(i_m_axis_rx_tvalid);
    EP_RX_inst->o_m_axis_rx_tready(o_m_axis_rx_tready);
    EP_RX_inst->i_m_axis_rx_tuser(i_m_axis_rx_tuser);
    EP_RX_inst->o_req_compl(w_req_compl_int);
    EP_RX_inst->o_req_compl_wd(w_req_compl_wd);
    EP_RX_inst->i_compl_done(w_compl_done_int);
    EP_RX_inst->o_req_tc(wb_req_tc);
    EP_RX_inst->o_req_td(w_req_td);
    EP_RX_inst->o_req_ep(w_req_ep);
    EP_RX_inst->o_req_attr(wb_req_attr);
    EP_RX_inst->o_req_len(wb_req_len);
    EP_RX_inst->o_req_rid(wb_req_rid);
    EP_RX_inst->o_req_tag(wb_req_tag);
    EP_RX_inst->o_req_be(wb_req_be);
    EP_RX_inst->o_req_addr(wb_req_addr);
    EP_RX_inst->i_req_mem_ready(i_req_mem_ready);
    EP_RX_inst->o_req_mem_valid(o_req_mem_valid);
    EP_RX_inst->o_req_mem_write(o_req_mem_write);
    EP_RX_inst->o_req_mem_bytes(wb_req_bytes);
    EP_RX_inst->o_req_mem_addr(o_req_mem_addr);
    EP_RX_inst->o_req_mem_strob(o_req_mem_strob);
    EP_RX_inst->o_req_mem_data(wb_req_mem_data);
    EP_RX_inst->o_req_mem_last(o_req_mem_last);
    EP_RX_inst->i_resp_mem_valid(i_resp_mem_valid);

    EP_TX_inst = new pcie_io_tx_engine<C_DATA_WIDTH,
                                       KEEP_WIDTH>("EP_TX_inst");
    EP_TX_inst->i_nrst(i_nrst);
    EP_TX_inst->i_clk(i_clk);
    EP_TX_inst->i_s_axis_tx_tready(i_s_axis_tx_tready);
    EP_TX_inst->o_s_axis_tx_tdata(o_s_axis_tx_tdata);
    EP_TX_inst->o_s_axis_tx_tkeep(o_s_axis_tx_tkeep);
    EP_TX_inst->o_s_axis_tx_tlast(o_s_axis_tx_tlast);
    EP_TX_inst->o_s_axis_tx_tvalid(o_s_axis_tx_tvalid);
    EP_TX_inst->o_tx_src_dsc(o_tx_src_dsc);
    EP_TX_inst->i_req_compl(w_req_compl_int);
    EP_TX_inst->i_req_compl_wd(w_req_compl_wd);
    EP_TX_inst->o_compl_done(w_compl_done_int);
    EP_TX_inst->i_req_tc(wb_req_tc);
    EP_TX_inst->i_req_td(w_req_td);
    EP_TX_inst->i_req_ep(w_req_ep);
    EP_TX_inst->i_req_attr(wb_req_attr);
    EP_TX_inst->i_req_len(wb_req_len);
    EP_TX_inst->i_req_rid(wb_req_rid);
    EP_TX_inst->i_req_tag(wb_req_tag);
    EP_TX_inst->i_req_be(wb_req_be);
    EP_TX_inst->i_req_addr(wb_req_addr);
    EP_TX_inst->i_req_bytes(wb_req_bytes);
    EP_TX_inst->i_dma_resp_valid(i_resp_mem_valid);
    EP_TX_inst->i_dma_resp_last(i_resp_mem_last);
    EP_TX_inst->i_dma_resp_fault(i_resp_mem_fault);
    EP_TX_inst->i_dma_resp_addr(i_resp_mem_addr);
    EP_TX_inst->i_dma_resp_data(wb_resp_mem_data);
    EP_TX_inst->o_dma_resp_ready(o_resp_mem_ready);
    EP_TX_inst->i_completer_id(i_cfg_completer_id);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_s_axis_tx_tready;
    sensitive << i_m_axis_rx_tdata;
    sensitive << i_m_axis_rx_tkeep;
    sensitive << i_m_axis_rx_tlast;
    sensitive << i_m_axis_rx_tvalid;
    sensitive << i_m_axis_rx_tuser;
    sensitive << i_cfg_completer_id;
    sensitive << i_req_mem_ready;
    sensitive << i_resp_mem_valid;
    sensitive << i_resp_mem_last;
    sensitive << i_resp_mem_fault;
    sensitive << i_resp_mem_addr;
    sensitive << i_resp_mem_data;
    sensitive << w_req_compl_int;
    sensitive << w_req_compl_wd;
    sensitive << w_compl_done_int;
    sensitive << wb_req_tc;
    sensitive << w_req_td;
    sensitive << w_req_ep;
    sensitive << wb_req_attr;
    sensitive << wb_req_len;
    sensitive << wb_req_rid;
    sensitive << wb_req_tag;
    sensitive << wb_req_be;
    sensitive << wb_req_addr;
    sensitive << wb_req_bytes;
    sensitive << wb_req_mem_data;
    sensitive << wb_resp_mem_data;
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
pcie_io_ep<C_DATA_WIDTH, KEEP_WIDTH>::~pcie_io_ep() {
    if (EP_RX_inst) {
        delete EP_RX_inst;
    }
    if (EP_TX_inst) {
        delete EP_TX_inst;
    }
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_ep<C_DATA_WIDTH, KEEP_WIDTH>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_s_axis_tx_tready, i_s_axis_tx_tready.name());
        sc_trace(o_vcd, o_s_axis_tx_tdata, o_s_axis_tx_tdata.name());
        sc_trace(o_vcd, o_s_axis_tx_tkeep, o_s_axis_tx_tkeep.name());
        sc_trace(o_vcd, o_s_axis_tx_tlast, o_s_axis_tx_tlast.name());
        sc_trace(o_vcd, o_s_axis_tx_tvalid, o_s_axis_tx_tvalid.name());
        sc_trace(o_vcd, o_tx_src_dsc, o_tx_src_dsc.name());
        sc_trace(o_vcd, i_m_axis_rx_tdata, i_m_axis_rx_tdata.name());
        sc_trace(o_vcd, i_m_axis_rx_tkeep, i_m_axis_rx_tkeep.name());
        sc_trace(o_vcd, i_m_axis_rx_tlast, i_m_axis_rx_tlast.name());
        sc_trace(o_vcd, i_m_axis_rx_tvalid, i_m_axis_rx_tvalid.name());
        sc_trace(o_vcd, o_m_axis_rx_tready, o_m_axis_rx_tready.name());
        sc_trace(o_vcd, i_m_axis_rx_tuser, i_m_axis_rx_tuser.name());
        sc_trace(o_vcd, i_cfg_completer_id, i_cfg_completer_id.name());
        sc_trace(o_vcd, i_req_mem_ready, i_req_mem_ready.name());
        sc_trace(o_vcd, o_req_mem_valid, o_req_mem_valid.name());
        sc_trace(o_vcd, o_req_mem_write, o_req_mem_write.name());
        sc_trace(o_vcd, o_req_mem_bytes, o_req_mem_bytes.name());
        sc_trace(o_vcd, o_req_mem_addr, o_req_mem_addr.name());
        sc_trace(o_vcd, o_req_mem_strob, o_req_mem_strob.name());
        sc_trace(o_vcd, o_req_mem_data, o_req_mem_data.name());
        sc_trace(o_vcd, o_req_mem_last, o_req_mem_last.name());
        sc_trace(o_vcd, i_resp_mem_valid, i_resp_mem_valid.name());
        sc_trace(o_vcd, i_resp_mem_last, i_resp_mem_last.name());
        sc_trace(o_vcd, i_resp_mem_fault, i_resp_mem_fault.name());
        sc_trace(o_vcd, i_resp_mem_addr, i_resp_mem_addr.name());
        sc_trace(o_vcd, i_resp_mem_data, i_resp_mem_data.name());
        sc_trace(o_vcd, o_resp_mem_ready, o_resp_mem_ready.name());
    }

    if (EP_RX_inst) {
        EP_RX_inst->generateVCD(i_vcd, o_vcd);
    }
    if (EP_TX_inst) {
        EP_TX_inst->generateVCD(i_vcd, o_vcd);
    }
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
sc_uint<64> pcie_io_ep<C_DATA_WIDTH, KEEP_WIDTH>::SwapEndianess32(sc_uint<64> dword) {
    sc_uint<64> ret;

    ret(31, 0) = (dword(7, 0),
            dword(15, 8),
            dword(23, 16),
            dword(31, 24));
    ret(63, 32) = (dword(39, 32),
            dword(47, 40),
            dword(55, 48),
            dword(63, 56));
    return ret;
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_ep<C_DATA_WIDTH, KEEP_WIDTH>::comb() {
    bool v_mem_valid;
    bool v_mem_wren;
    sc_uint<13> vb_mem_addr;
    sc_uint<8> vb_mem_wstrb;
    sc_uint<32> vb_mem_data;

    v_mem_valid = 0;
    v_mem_wren = 0;
    vb_mem_addr = 0;
    vb_mem_wstrb = 0;
    vb_mem_data = 0;


    // Correct PCIe endieness:
    o_req_mem_data = SwapEndianess32(wb_req_mem_data.read());
    wb_resp_mem_data = SwapEndianess32(i_resp_mem_data.read());
    o_req_mem_bytes = wb_req_bytes.read();
}

}  // namespace debugger

