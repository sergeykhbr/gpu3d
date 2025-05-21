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
SC_MODULE(pcie_io_rx_engine) {
 public:
    sc_in<bool> i_nrst;
    sc_in<bool> i_clk;                                      // System bus clock
    // 
    sc_in<sc_uint<C_DATA_WIDTH>> i_m_axis_rx_tdata;
    sc_in<sc_uint<KEEP_WIDTH>> i_m_axis_rx_tkeep;
    sc_in<bool> i_m_axis_rx_tlast;
    sc_in<bool> i_m_axis_rx_tvalid;
    sc_out<bool> o_m_axis_rx_tready;
    sc_in<sc_uint<9>> i_m_axis_rx_tuser;
    // 
    sc_out<bool> o_tx_ena;                                  // Trigger Tx engine to wait response from xDMA
    sc_out<bool> o_tx_completion;                           // Transmit completion TLP
    sc_out<bool> o_tx_with_data;                            // Transmit TLP with payload
    sc_in<bool> i_compl_done;
    // 
    sc_out<sc_uint<3>> o_req_tc;                            // Memory Read TC
    sc_out<bool> o_req_td;                                  // Memory Read TD
    sc_out<bool> o_req_ep;                                  // Memory Read EP
    sc_out<sc_uint<2>> o_req_attr;                          // Memory Read Attribute
    sc_out<sc_uint<10>> o_req_len;                          // Memory Read Length (1DW)
    sc_out<sc_uint<16>> o_req_rid;                          // Memory Read Requestor ID
    sc_out<sc_uint<8>> o_req_tag;                           // Memory Read Tag
    sc_out<sc_uint<8>> o_req_be;                            // Memory Read Byte Enables
    sc_out<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> o_req_addr;     // Memory Read Address
    // 
    sc_in<bool> i_req_mem_ready;                            // Ready to accept next memory request
    sc_out<bool> o_req_mem_valid;                           // Request data is valid to accept
    sc_out<bool> o_req_mem_write;                           // 0=read; 1=write operation
    sc_out<sc_uint<10>> o_req_mem_bytes;                    // 0=1024 B; 4=DWORD; 8=QWORD; ...
    sc_out<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> o_req_mem_addr; // Address to read/write
    sc_out<sc_uint<8>> o_req_mem_strob;                     // Byte enabling write strob
    sc_out<sc_uint<64>> o_req_mem_data;                     // Data to write
    sc_out<bool> o_req_mem_last;                            // Last data payload in a sequence
    sc_in<bool> i_resp_mem_valid;                           // Read/Write data is valid. All write transaction with valid response.

    void comb();
    void registers();

    pcie_io_rx_engine(sc_module_name name);

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:

    static const uint8_t PIO_RX_MEM_RD32_FMT_TYPE = 0x00;
    static const uint8_t PIO_RX_MEM_WR32_FMT_TYPE = 0x40;
    static const uint8_t PIO_RX_MEM_RD64_FMT_TYPE = 0x20;
    static const uint8_t PIO_RX_MEM_WR64_FMT_TYPE = 0x60;
    static const uint8_t PIO_RX_IO_RD32_FMT_TYPE = 0x02;
    static const uint8_t PIO_RX_IO_WR32_FMT_TYPE = 0x42;

    static const uint8_t PIO_RX_RST_STATE = 0x00;
    static const uint8_t PIO_RX_MEM_RD32_DW1DW2 = 0x01;
    static const uint8_t PIO_RX_MEM_WR32_DW1DW2 = 0x02;
    static const uint8_t PIO_RX_MEM_RD64_DW1DW2 = 0x04;
    static const uint8_t PIO_RX_MEM_WR64_DW1DW2 = 0x08;
    static const uint8_t PIO_RX_MEM_WR_BURST = 0x10;
    static const uint8_t PIO_RX_IO_WR_DW1DW2 = 0x20;        // Burst disabled
    static const uint8_t PIO_RX_WAIT_TX_COMPLETION = 0x40;
    // TLP Response Types:
    static const uint8_t TLP_NON_POSTED = 0x1;              // No response at all
    static const uint8_t TLP_POSTED = 0x5;                  // Response with data payload
    static const uint8_t TLP_COMPLETION = 0x3;              // Response without payload

    struct pcie_io_rx_engine_registers {
        sc_signal<bool> m_axis_rx_tready;
        sc_signal<bool> req_valid;
        sc_signal<bool> req_last;
        sc_signal<sc_uint<3>> req_tc;
        sc_signal<bool> req_td;
        sc_signal<bool> req_ep;
        sc_signal<sc_uint<2>> req_attr;
        sc_signal<sc_uint<10>> req_len;
        sc_signal<sc_uint<16>> req_rid;
        sc_signal<sc_uint<8>> req_tag;
        sc_signal<sc_uint<8>> req_be;
        sc_signal<sc_uint<10>> req_bytes;
        sc_signal<sc_uint<CFG_PCIE_DMAADDR_WIDTH>> req_addr;
        sc_signal<bool> wr_en;
        sc_signal<sc_uint<64>> wr_data;
        sc_signal<sc_uint<8>> wr_strob;
        sc_signal<sc_uint<32>> wr_data_dw1;                 // Odd word in a burst sequence
        sc_signal<bool> wr_dw1_valid;                       // Not last DW1 was received in burst sequence
        sc_signal<sc_uint<7>> state;
        sc_signal<sc_uint<8>> tlp_type;
        sc_signal<sc_uint<3>> tlp_resp;
    };

    void pcie_io_rx_engine_r_reset(pcie_io_rx_engine_registers& iv) {
        iv.m_axis_rx_tready = 0;
        iv.req_valid = 0;
        iv.req_last = 0;
        iv.req_tc = 0;
        iv.req_td = 0;
        iv.req_ep = 0;
        iv.req_attr = 0;
        iv.req_len = 0;
        iv.req_rid = 0;
        iv.req_tag = 0;
        iv.req_be = 0;
        iv.req_bytes = 0;
        iv.req_addr = 0;
        iv.wr_en = 0;
        iv.wr_data = 0;
        iv.wr_strob = 0;
        iv.wr_data_dw1 = 0;
        iv.wr_dw1_valid = 0;
        iv.state = PIO_RX_RST_STATE;
        iv.tlp_type = 0;
        iv.tlp_resp = 0;
    }

    pcie_io_rx_engine_registers v;
    pcie_io_rx_engine_registers r;

};

template<int C_DATA_WIDTH, int KEEP_WIDTH>
pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH>::pcie_io_rx_engine(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_m_axis_rx_tdata("i_m_axis_rx_tdata"),
    i_m_axis_rx_tkeep("i_m_axis_rx_tkeep"),
    i_m_axis_rx_tlast("i_m_axis_rx_tlast"),
    i_m_axis_rx_tvalid("i_m_axis_rx_tvalid"),
    o_m_axis_rx_tready("o_m_axis_rx_tready"),
    i_m_axis_rx_tuser("i_m_axis_rx_tuser"),
    o_tx_ena("o_tx_ena"),
    o_tx_completion("o_tx_completion"),
    o_tx_with_data("o_tx_with_data"),
    i_compl_done("i_compl_done"),
    o_req_tc("o_req_tc"),
    o_req_td("o_req_td"),
    o_req_ep("o_req_ep"),
    o_req_attr("o_req_attr"),
    o_req_len("o_req_len"),
    o_req_rid("o_req_rid"),
    o_req_tag("o_req_tag"),
    o_req_be("o_req_be"),
    o_req_addr("o_req_addr"),
    i_req_mem_ready("i_req_mem_ready"),
    o_req_mem_valid("o_req_mem_valid"),
    o_req_mem_write("o_req_mem_write"),
    o_req_mem_bytes("o_req_mem_bytes"),
    o_req_mem_addr("o_req_mem_addr"),
    o_req_mem_strob("o_req_mem_strob"),
    o_req_mem_data("o_req_mem_data"),
    o_req_mem_last("o_req_mem_last"),
    i_resp_mem_valid("i_resp_mem_valid") {


    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_m_axis_rx_tdata;
    sensitive << i_m_axis_rx_tkeep;
    sensitive << i_m_axis_rx_tlast;
    sensitive << i_m_axis_rx_tvalid;
    sensitive << i_m_axis_rx_tuser;
    sensitive << i_compl_done;
    sensitive << i_req_mem_ready;
    sensitive << i_resp_mem_valid;
    sensitive << r.m_axis_rx_tready;
    sensitive << r.req_valid;
    sensitive << r.req_last;
    sensitive << r.req_tc;
    sensitive << r.req_td;
    sensitive << r.req_ep;
    sensitive << r.req_attr;
    sensitive << r.req_len;
    sensitive << r.req_rid;
    sensitive << r.req_tag;
    sensitive << r.req_be;
    sensitive << r.req_bytes;
    sensitive << r.req_addr;
    sensitive << r.wr_en;
    sensitive << r.wr_data;
    sensitive << r.wr_strob;
    sensitive << r.wr_data_dw1;
    sensitive << r.wr_dw1_valid;
    sensitive << r.state;
    sensitive << r.tlp_type;
    sensitive << r.tlp_resp;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_m_axis_rx_tdata, i_m_axis_rx_tdata.name());
        sc_trace(o_vcd, i_m_axis_rx_tkeep, i_m_axis_rx_tkeep.name());
        sc_trace(o_vcd, i_m_axis_rx_tlast, i_m_axis_rx_tlast.name());
        sc_trace(o_vcd, i_m_axis_rx_tvalid, i_m_axis_rx_tvalid.name());
        sc_trace(o_vcd, o_m_axis_rx_tready, o_m_axis_rx_tready.name());
        sc_trace(o_vcd, i_m_axis_rx_tuser, i_m_axis_rx_tuser.name());
        sc_trace(o_vcd, o_tx_ena, o_tx_ena.name());
        sc_trace(o_vcd, o_tx_completion, o_tx_completion.name());
        sc_trace(o_vcd, o_tx_with_data, o_tx_with_data.name());
        sc_trace(o_vcd, i_compl_done, i_compl_done.name());
        sc_trace(o_vcd, o_req_tc, o_req_tc.name());
        sc_trace(o_vcd, o_req_td, o_req_td.name());
        sc_trace(o_vcd, o_req_ep, o_req_ep.name());
        sc_trace(o_vcd, o_req_attr, o_req_attr.name());
        sc_trace(o_vcd, o_req_len, o_req_len.name());
        sc_trace(o_vcd, o_req_rid, o_req_rid.name());
        sc_trace(o_vcd, o_req_tag, o_req_tag.name());
        sc_trace(o_vcd, o_req_be, o_req_be.name());
        sc_trace(o_vcd, o_req_addr, o_req_addr.name());
        sc_trace(o_vcd, i_req_mem_ready, i_req_mem_ready.name());
        sc_trace(o_vcd, o_req_mem_valid, o_req_mem_valid.name());
        sc_trace(o_vcd, o_req_mem_write, o_req_mem_write.name());
        sc_trace(o_vcd, o_req_mem_bytes, o_req_mem_bytes.name());
        sc_trace(o_vcd, o_req_mem_addr, o_req_mem_addr.name());
        sc_trace(o_vcd, o_req_mem_strob, o_req_mem_strob.name());
        sc_trace(o_vcd, o_req_mem_data, o_req_mem_data.name());
        sc_trace(o_vcd, o_req_mem_last, o_req_mem_last.name());
        sc_trace(o_vcd, i_resp_mem_valid, i_resp_mem_valid.name());
        sc_trace(o_vcd, r.m_axis_rx_tready, pn + ".r.m_axis_rx_tready");
        sc_trace(o_vcd, r.req_valid, pn + ".r.req_valid");
        sc_trace(o_vcd, r.req_last, pn + ".r.req_last");
        sc_trace(o_vcd, r.req_tc, pn + ".r.req_tc");
        sc_trace(o_vcd, r.req_td, pn + ".r.req_td");
        sc_trace(o_vcd, r.req_ep, pn + ".r.req_ep");
        sc_trace(o_vcd, r.req_attr, pn + ".r.req_attr");
        sc_trace(o_vcd, r.req_len, pn + ".r.req_len");
        sc_trace(o_vcd, r.req_rid, pn + ".r.req_rid");
        sc_trace(o_vcd, r.req_tag, pn + ".r.req_tag");
        sc_trace(o_vcd, r.req_be, pn + ".r.req_be");
        sc_trace(o_vcd, r.req_bytes, pn + ".r.req_bytes");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.wr_en, pn + ".r.wr_en");
        sc_trace(o_vcd, r.wr_data, pn + ".r.wr_data");
        sc_trace(o_vcd, r.wr_strob, pn + ".r.wr_strob");
        sc_trace(o_vcd, r.wr_data_dw1, pn + ".r.wr_data_dw1");
        sc_trace(o_vcd, r.wr_dw1_valid, pn + ".r.wr_dw1_valid");
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.tlp_type, pn + ".r.tlp_type");
        sc_trace(o_vcd, r.tlp_resp, pn + ".r.tlp_resp");
    }

}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH>::comb() {
    sc_uint<2> vb_req_addr_1_0;
    sc_uint<2> vb_add_be20;
    sc_uint<2> vb_add_be21;
    sc_uint<10> vb_req_bytes;
    sc_uint<CFG_PCIE_DMAADDR_WIDTH> vb_bar_offset;
    sc_uint<CFG_PCIE_DMAADDR_WIDTH> vb_addr_ldw;
    sc_uint<CFG_PCIE_DMAADDR_WIDTH> vb_addr_mdw;

    v = r;
    vb_req_addr_1_0 = 0;
    vb_add_be20 = 0;
    vb_add_be21 = 0;
    vb_req_bytes = 0;
    vb_bar_offset = 0;
    vb_addr_ldw = 0;
    vb_addr_mdw = 0;


    if (i_m_axis_rx_tuser.read()(8, 2) == 0x01) {           // Select BAR0 region
        vb_bar_offset = 0x008000000;                        // BAR0, 32-bits, 2MB, SRAM
    } else if (i_m_axis_rx_tuser.read()(8, 2) == 0x02) {    // Select BAR1 region
        vb_bar_offset = 0x000000000;                        // BAR1, 32-bits, 1GB
    } else if (i_m_axis_rx_tuser.read()(8, 2) == 0x04) {    // Select BAR2 region
        vb_bar_offset = 0x080000000;                        // BAR2/BAR3 64-bits, 4GB to DDR
    }

    if (r.req_be.read()[0] == 1) {
        vb_req_addr_1_0 = 0;
    } else if (r.req_be.read()[1] == 1) {
        vb_req_addr_1_0 = 1;
    } else if (r.req_be.read()[2] == 1) {
        vb_req_addr_1_0 = 2;
    } else if (r.req_be.read()[3] == 1) {
        vb_req_addr_1_0 = 3;
    }
    // Max implemented BAR is 4GB so take 32-bits of address
    vb_addr_ldw = (vb_bar_offset + i_m_axis_rx_tdata.read()(31, 0));
    vb_addr_ldw(1, 0) = vb_req_addr_1_0;
    vb_addr_mdw = (vb_bar_offset + i_m_axis_rx_tdata.read()(63, 32));
    vb_addr_mdw(1, 0) = vb_req_addr_1_0;

    // Calculate byte count based on byte enable
    vb_add_be20 = ((0, r.req_be.read()[3]) + (0, r.req_be.read()[2]));
    vb_add_be21 = ((0, r.req_be.read()[1]) + (0, r.req_be.read()[0]));
    if (r.req_len.read() == 1) {
        vb_req_bytes = ((0, vb_add_be20) + (0, vb_add_be21));
    } else {
        vb_req_bytes = (r.req_len.read() << 2);
    }

    if (i_req_mem_ready.read() == 1) {
        v.req_valid = 0;
        v.req_last = 0;
    }
    if (i_m_axis_rx_tvalid.read() == 1) {
        v.m_axis_rx_tready = 0;
    }

    switch (r.state.read()) {
    case PIO_RX_RST_STATE:
        v.m_axis_rx_tready = 1;
        v.tlp_resp = 0;
        v.wr_en = 0;                                        // IO Write
        v.wr_strob = 0;
        v.wr_data = 0;
        v.req_len = 0;

        if ((r.m_axis_rx_tready.read() == 1) && (i_m_axis_rx_tvalid.read() == 1)) {
            v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
            v.req_tc = i_m_axis_rx_tdata.read()(22, 20);
            v.req_td = i_m_axis_rx_tdata.read()[15];
            v.req_ep = i_m_axis_rx_tdata.read()[14];
            v.req_attr = i_m_axis_rx_tdata.read()(13, 12);
            v.req_len = i_m_axis_rx_tdata.read()(9, 0);
            v.req_rid = i_m_axis_rx_tdata.read()(63, 48);
            v.req_tag = i_m_axis_rx_tdata.read()(47, 40);
            v.req_be = i_m_axis_rx_tdata.read()(39, 32);

            switch (i_m_axis_rx_tdata.read()(30, 24)) {
            case PIO_RX_MEM_RD32_FMT_TYPE:
                v.state = PIO_RX_MEM_RD32_DW1DW2;
                break;

            case PIO_RX_MEM_WR32_FMT_TYPE:
                v.state = PIO_RX_MEM_WR32_DW1DW2;
                v.wr_en = 1;
                break;

            case PIO_RX_MEM_RD64_FMT_TYPE:
                v.state = PIO_RX_MEM_RD64_DW1DW2;
                break;

            case PIO_RX_MEM_WR64_FMT_TYPE:
                v.state = PIO_RX_MEM_WR64_DW1DW2;
                v.wr_en = 1;
                break;

            case PIO_RX_IO_RD32_FMT_TYPE:
                v.state = PIO_RX_MEM_RD32_DW1DW2;
                break;

            case PIO_RX_IO_WR32_FMT_TYPE:
                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.state = PIO_RX_IO_WR_DW1DW2;
                    v.wr_en = 1;
                }
                break;

            default:
                v.state = PIO_RX_RST_STATE;
                break;
            }
        } else {
            v.state = PIO_RX_RST_STATE;
        }
        break;

    case PIO_RX_MEM_RD32_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_valid = 1;
            v.req_last = i_m_axis_rx_tlast.read();
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.tlp_resp = TLP_POSTED;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        }
        break;

    case PIO_RX_MEM_RD64_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_valid = 1;
            v.req_addr = vb_addr_mdw;
            v.req_bytes = vb_req_bytes;
            v.tlp_resp = TLP_POSTED;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        }
        break;

    case PIO_RX_MEM_WR32_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_valid = i_m_axis_rx_tlast.read();
            v.req_last = i_m_axis_rx_tlast.read();
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.wr_data = (i_m_axis_rx_tdata.read()(63, 32), i_m_axis_rx_tdata.read()(63, 32));
            v.wr_data_dw1 = i_m_axis_rx_tdata.read()(63, 32);
            if (i_m_axis_rx_tdata.read()[2] == 1) {
                v.wr_strob = (r.req_be.read()(3, 0), r.req_be.read()(7, 4));
            } else {
                v.wr_strob = r.req_be.read();
            }

            // Burst support:
            v.m_axis_rx_tready = (i_req_mem_ready.read() & (!i_m_axis_rx_tlast.read()));
            if (i_m_axis_rx_tlast.read() == 1) {
                // Send response after full TLP received:
                v.tlp_resp = TLP_NON_POSTED;
                v.state = PIO_RX_WAIT_TX_COMPLETION;
            } else {
                v.wr_dw1_valid = 1;
                v.wr_strob = 0xFF;
                v.state = PIO_RX_MEM_WR_BURST;
            }
        }
        break;

    case PIO_RX_MEM_WR64_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_addr = vb_addr_mdw;
            v.req_bytes = vb_req_bytes;
            if (i_m_axis_rx_tdata.read()[34] == 1) {
                v.wr_strob = (r.req_be.read()(3, 0), r.req_be.read()(7, 4));
            } else {
                v.wr_strob = r.req_be.read();
            }
            v.state = PIO_RX_MEM_WR_BURST;
        }
        break;

    case PIO_RX_MEM_WR_BURST:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.m_axis_rx_tready = (i_req_mem_ready.read() & (!i_m_axis_rx_tlast.read()));
            v.req_valid = 1;
            v.req_last = i_m_axis_rx_tlast.read();
            if ((i_m_axis_rx_tkeep.read()(7, 4).or_reduce() == 1) && (i_m_axis_rx_tkeep.read()(3, 0).or_reduce() == 1)) {
                if (r.wr_dw1_valid.read() == 1) {
                    v.wr_data = (i_m_axis_rx_tdata.read()(31, 0), r.wr_data_dw1.read());
                    v.wr_data_dw1 = i_m_axis_rx_tdata.read()(63, 32);
                } else {
                    v.wr_data = i_m_axis_rx_tdata.read();
                }
            } else {
                v.wr_dw1_valid = 0;
                if (r.wr_dw1_valid.read() == 1) {
                    v.wr_data = (i_m_axis_rx_tdata.read()(31, 0), r.wr_data_dw1.read()(31, 0));
                } else {
                    v.wr_data = (i_m_axis_rx_tdata.read()(31, 0), i_m_axis_rx_tdata.read()(31, 0));
                }
            }

            if (i_m_axis_rx_tlast.read() == 1) {
                // Send response after full TLP received:
                v.wr_dw1_valid = 0;                         // Software has to use 8-bytes aligned burst transactions
                v.tlp_resp = TLP_NON_POSTED;
                v.state = PIO_RX_WAIT_TX_COMPLETION;
            }
        }
        break;

    case PIO_RX_IO_WR_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_valid = 1;
            v.wr_en = 1;
            v.req_addr = vb_addr_ldw;
            v.req_bytes = vb_req_bytes;
            v.wr_data = (i_m_axis_rx_tdata.read()(63, 32), i_m_axis_rx_tdata.read()(63, 32));
            if (i_m_axis_rx_tdata.read()[2] == 1) {
                v.wr_strob = (r.req_be.read()(3, 0), r.req_be.read()(7, 4));
            } else {
                v.wr_strob = r.req_be.read();
            }
            v.tlp_resp = TLP_COMPLETION;
            v.state = PIO_RX_WAIT_TX_COMPLETION;
        }
        break;

    case PIO_RX_WAIT_TX_COMPLETION:
        if (i_compl_done.read() == 1) {
            v.m_axis_rx_tready = 1;
            v.wr_en = 0;                                    // IO Write
            v.wr_strob = 0;
            v.wr_data = 0;
            v.req_len = 0;
            v.tlp_resp = 0;
            v.state = PIO_RX_RST_STATE;
        }
        break;

    default:
        v.state = PIO_RX_RST_STATE;
        break;
    }

    o_m_axis_rx_tready = r.m_axis_rx_tready.read();
    o_tx_ena = r.tlp_resp.read()[0];
    o_tx_completion = r.tlp_resp.read()[1];
    o_tx_with_data = r.tlp_resp.read()[2];
    o_req_tc = r.req_tc.read();
    o_req_td = r.req_td.read();
    o_req_ep = r.req_ep.read();
    o_req_attr = r.req_attr.read();
    o_req_len = r.req_len.read();
    o_req_rid = r.req_rid.read();
    o_req_tag = r.req_tag.read();
    o_req_be = r.req_be.read();
    o_req_addr = r.req_addr.read();

    o_req_mem_valid = r.req_valid.read();
    o_req_mem_write = r.wr_en.read();
    o_req_mem_bytes = r.req_bytes.read();
    o_req_mem_addr = r.req_addr.read();
    o_req_mem_strob = r.wr_strob.read();
    o_req_mem_data = r.wr_data.read();
    o_req_mem_last = r.req_last.read();
}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH>::registers() {
    if (i_nrst.read() == 0) {
        pcie_io_rx_engine_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

