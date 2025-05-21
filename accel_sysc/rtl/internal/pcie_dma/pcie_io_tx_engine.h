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
#include "pcie_cfg.h"
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
    sc_in<bool> i_tx_ena;                                   // wait request from xDMA
    sc_in<bool> i_tx_completion;                            // Send completion TLP on xDMA response
    sc_in<bool> i_tx_with_data;                             // Send TLP with payload on xDMA response
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
    sc_in<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> i_req_addr;
    sc_in<sc_uint<10>> i_req_bytes;
    // 
    sc_in<bool> i_dma_resp_valid;
    sc_in<bool> i_dma_resp_last;
    sc_in<bool> i_dma_resp_fault;                           // Error on memory access
    sc_in<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> i_dma_resp_addr;
    sc_in<sc_uint<64>> i_dma_resp_data;
    sc_out<bool> o_dma_resp_ready;                          // Ready to accept response
    sc_in<sc_uint<16>> i_completer_id;

    void comb();
    void reqff();
    void registers();

    pcie_io_tx_engine(sc_module_name name);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    // TLP Format Type fields:
    static const uint8_t PIO_CPLD_FMT_TYPE = 0x4A;
    static const uint8_t PIO_CPL_FMT_TYPE = 0x0A;
    // State machine states:
    static const uint8_t PIO_TX_RST_STATE = 0x0;
    static const uint8_t PIO_TX_WAIT_DMA_RESP = 0x1;
    static const uint8_t PIO_TX_CPLD_QW1 = 0x2;
    static const uint8_t PIO_TX_RD_BURST = 0x4;
    static const uint8_t PIO_TX_RD_BURST_LAST = 0x8;

    struct pcie_io_tx_engine_registers {
        sc_signal<sc_uint<C_DATA_WIDTH>> s_axis_tx_tdata;
        sc_signal<sc_uint<KEEP_WIDTH>> s_axis_tx_tkeep;
        sc_signal<bool> s_axis_tx_tlast;
        sc_signal<bool> s_axis_tx_tvalid;
        sc_signal<bool> dma_resp_ready;
        sc_signal<bool> req_with_data;
        sc_signal<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> req_addr;
        sc_signal<sc_uint<16>> req_rid;
        sc_signal<sc_uint<8>> req_tag;
        sc_signal<sc_uint<4>> req_be;
        sc_signal<sc_uint<64>> rd_data;
        sc_signal<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> rd_addr;
        sc_signal<bool> rd_last;
        sc_signal<bool> rd_burst;
        sc_signal<bool> rd_odd;
        sc_signal<sc_uint<4>> state;
    };

    void pcie_io_tx_engine_r_reset(pcie_io_tx_engine_registers& iv) {
        iv.s_axis_tx_tdata = 0;
        iv.s_axis_tx_tkeep = 0;
        iv.s_axis_tx_tlast = 0;
        iv.s_axis_tx_tvalid = 0;
        iv.dma_resp_ready = 0;
        iv.req_with_data = 0;
        iv.req_addr = 0;
        iv.req_rid = 0;
        iv.req_tag = 0;
        iv.req_be = 0;
        iv.rd_data = 0;
        iv.rd_addr = 0;
        iv.rd_last = 0;
        iv.rd_burst = 0;
        iv.rd_odd = 0;
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
    i_tx_ena("i_tx_ena"),
    i_tx_completion("i_tx_completion"),
    i_tx_with_data("i_tx_with_data"),
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
    sensitive << i_tx_ena;
    sensitive << i_tx_completion;
    sensitive << i_tx_with_data;
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
    sensitive << r.dma_resp_ready;
    sensitive << r.req_with_data;
    sensitive << r.req_addr;
    sensitive << r.req_rid;
    sensitive << r.req_tag;
    sensitive << r.req_be;
    sensitive << r.rd_data;
    sensitive << r.rd_addr;
    sensitive << r.rd_last;
    sensitive << r.rd_burst;
    sensitive << r.rd_odd;
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
        sc_trace(o_vcd, i_tx_ena, i_tx_ena.name());
        sc_trace(o_vcd, i_tx_completion, i_tx_completion.name());
        sc_trace(o_vcd, i_tx_with_data, i_tx_with_data.name());
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
        sc_trace(o_vcd, r.dma_resp_ready, pn + ".r.dma_resp_ready");
        sc_trace(o_vcd, r.req_with_data, pn + ".r.req_with_data");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.req_rid, pn + ".r.req_rid");
        sc_trace(o_vcd, r.req_tag, pn + ".r.req_tag");
        sc_trace(o_vcd, r.req_be, pn + ".r.req_be");
        sc_trace(o_vcd, r.rd_data, pn + ".r.rd_data");
        sc_trace(o_vcd, r.rd_addr, pn + ".r.rd_addr");
        sc_trace(o_vcd, r.rd_last, pn + ".r.rd_last");
        sc_trace(o_vcd, r.rd_burst, pn + ".r.rd_burst");
        sc_trace(o_vcd, r.rd_odd, pn + ".r.rd_odd");
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
    if (r.req_with_data.read() == 0) {
        // Request without payload
        vb_lower_addr = 0;
    } else {
        vb_lower_addr = r.req_addr.read()(6, 0);
    }

    if (i_s_axis_tx_tready.read() == 1) {
        v.s_axis_tx_tvalid = 0;
        v.s_axis_tx_tlast = 0;
    }
    if (i_dma_resp_valid.read() == 1) {
        v.dma_resp_ready = 0;
    }

    switch (r.state.read()) {
    case PIO_TX_RST_STATE:
        v.s_axis_tx_tdata = 0;
        v.s_axis_tx_tkeep = 0;
        if (i_tx_ena.read() == 1) {
            v.req_addr = i_req_addr.read();
            v.req_rid = i_req_rid.read();
            v.req_tag = i_req_tag.read();
            v.req_be = i_req_be.read();
            v.req_with_data = i_tx_with_data.read();
            vb_s_axis_tx_tdata(63, 48) = i_completer_id.read();// DW1[31:16] completer ID
            vb_s_axis_tx_tdata(47, 45) = 0;                 // DW1[15:13] compl status
            vb_s_axis_tx_tdata[44] = 0;                     // DW1[12] BCM (Byte Count Modified for PCI legacy support)
            vb_s_axis_tx_tdata(43, 32) = i_req_bytes.read();// DW1[11:0] byte count
            vb_s_axis_tx_tdata[31] = 0;                     // DW0[31] R
            if (i_tx_with_data.read() == 1) {
                vb_s_axis_tx_tdata(30, 24) = PIO_CPLD_FMT_TYPE;// DW0[30:29] fmt; DW0[28:24] type
            } else {
                vb_s_axis_tx_tdata(30, 24) = PIO_CPL_FMT_TYPE;// DW0[30:29] fmt; DW0[28:24] type
            }
            vb_s_axis_tx_tdata[23] = 0;                     // DW0[23] R
            vb_s_axis_tx_tdata(22, 20) = i_req_tc.read();   // DW0[22:20] TC
            vb_s_axis_tx_tdata(19, 16) = 0;                 // DW0[19:16] R
            vb_s_axis_tx_tdata[15] = i_req_td.read();       // DW0[15] TD
            vb_s_axis_tx_tdata[14] = i_req_ep.read();       // DW0[14] EP
            vb_s_axis_tx_tdata(13, 12) = i_req_attr.read(); // DW0[13:12] attr
            vb_s_axis_tx_tdata(11, 10) = 0;                 // DW0[11:10] R
            vb_s_axis_tx_tdata(9, 0) = i_req_len.read();    // DW0[9:0] length
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;
            v.s_axis_tx_tkeep = 0xFF;
            if (i_tx_with_data.read() == 1) {
                // Send this TLP qword only on DMA response
                v.dma_resp_ready = 1;
                v.state = PIO_TX_WAIT_DMA_RESP;
                v.rd_burst = i_req_bytes.read()(9, 3).or_reduce();// Bytes count more than 4
                v.rd_odd = i_req_bytes.read()[2];
            } else if (i_tx_completion.read() == 1) {
                // Send completion now
                v.s_axis_tx_tvalid = 1;
                v.rd_last = 1;
                v.state = PIO_TX_CPLD_QW1;
            } else {
                // Wait handshake of write sequence:
                v.dma_resp_ready = 1;
                v.state = PIO_TX_WAIT_DMA_RESP;
            }
        }
        break;

    case PIO_TX_WAIT_DMA_RESP:
        if (i_dma_resp_valid.read() == 1) {
            if (r.req_with_data.read() == 1) {
                v.s_axis_tx_tvalid = 1;                     // Transmit DW1DW2
                v.rd_data = i_dma_resp_data.read();
                v.rd_addr = i_dma_resp_addr.read();
                v.rd_last = i_dma_resp_last.read();
                v.state = PIO_TX_CPLD_QW1;
            } else {
                // Wr32/Wr64 handshaking. TODO: write memory fault.
                v.state = PIO_TX_RST_STATE;
            }
        }
        break;

    case PIO_TX_CPLD_QW1:
        if (i_s_axis_tx_tready.read() == 1) {
            v.s_axis_tx_tvalid = 1;
            v.s_axis_tx_tlast = (r.rd_last.read() & (!r.rd_burst.read()));
            // Swap DWORDS for AXI
            if (r.req_addr.read()[2] == 1) {
                vb_s_axis_tx_tdata(63, 32) = r.rd_data.read()(63, 32);
            } else {
                vb_s_axis_tx_tdata(63, 32) = r.rd_data.read()(31, 0);
            }
            vb_s_axis_tx_tdata(31, 16) = r.req_rid.read();  // DW2[31:16] Requester ID
            vb_s_axis_tx_tdata(15, 8) = r.req_tag.read();   // DW2[15:8] tag
            vb_s_axis_tx_tdata[7] = 0;                      // DW2[7] R
            vb_s_axis_tx_tdata(6, 0) = vb_lower_addr;       // DW2[6:0] lower address
            v.s_axis_tx_tdata = vb_s_axis_tx_tdata;

            // Mask data strob if data no need:
            if (r.req_with_data.read() == 1) {
                v.s_axis_tx_tkeep = 0xFF;                   // only 4-bytes reading (no burst)
            } else {
                v.s_axis_tx_tkeep = 0x0F;
            }
            if (r.rd_burst.read() == 0) {
                v.req_with_data = 0;
                v.rd_last = 0;
                v.state = PIO_TX_RST_STATE;
            } else if (r.rd_last.read() == 1) {
                v.state = PIO_TX_RD_BURST_LAST;
            } else {
                v.state = PIO_TX_RD_BURST;
            }
        }
        break;

    case PIO_TX_RD_BURST:
        v.dma_resp_ready = i_s_axis_tx_tready.read();
        if ((i_s_axis_tx_tready.read() == 1) && (i_dma_resp_valid.read() == 1) && (r.dma_resp_ready.read() == 1)) {
            v.s_axis_tx_tvalid = 1;
            v.s_axis_tx_tlast = (i_dma_resp_last.read() & r.rd_odd.read());
            v.s_axis_tx_tdata = (i_dma_resp_data.read()(31, 0), r.rd_data.read()(63, 32));
            v.s_axis_tx_tkeep = 0xFF;
            v.dma_resp_ready = (!i_dma_resp_last.read());
            v.rd_data = i_dma_resp_data.read();
            if (i_dma_resp_last.read() == 1) {
                v.req_with_data = 0;
                if (r.rd_odd.read() == 0) {
                    // 8-bytes aligned sequence
                    v.state = PIO_TX_RD_BURST_LAST;
                } else {
                    // 4-bytes aligned sequence
                    v.rd_odd = 0;
                    v.state = PIO_TX_RST_STATE;
                }
            }
        }
        break;

    case PIO_TX_RD_BURST_LAST:
        if (i_s_axis_tx_tready.read() == 1) {
            v.rd_last = 0;
            v.rd_burst = 0;
            v.s_axis_tx_tvalid = 1;
            v.s_axis_tx_tlast = 1;
            v.s_axis_tx_tdata = (r.rd_data.read()(63, 32), r.rd_data.read()(63, 32));
            v.s_axis_tx_tkeep = 0x0F;
            v.state = PIO_TX_RST_STATE;
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
    o_dma_resp_ready = r.dma_resp_ready.read();
    o_compl_done = (i_dma_resp_valid.read() & i_dma_resp_last.read() & r.dma_resp_ready.read());

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

