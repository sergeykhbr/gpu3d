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
    sc_out<bool> o_req_compl;
    sc_out<bool> o_req_compl_wd;                            // req completion without data (IO WR32 request)
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
    sc_out<sc_uint<13>> o_req_addr;                         // Memory Read Address
    // 
    sc_out<sc_uint<11>> o_wr_addr;                          // Memory Write Address
    sc_out<sc_uint<4>> o_wr_be;                             // Memory Write Byte Enable
    sc_out<sc_uint<32>> o_wr_data;                          // Memory Write Data
    sc_out<bool> o_wr_en;                                   // Memory Write Enable
    sc_in<bool> i_wr_busy;                                  // Memory Write Busy

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
    static const uint8_t PIO_RX_MEM_WR64_DW3 = 0x10;
    static const uint8_t PIO_RX_WAIT_STATE = 0x20;
    static const uint8_t PIO_RX_IO_WR_DW1DW2 = 0x40;
    static const uint8_t PIO_RX_IO_MEM_WR_WAIT_STATE = 0x80;

    struct pcie_io_rx_engine_registers {
        sc_signal<bool> m_axis_rx_tready;
        sc_signal<bool> req_compl;
        sc_signal<bool> req_compl_wd;
        sc_signal<sc_uint<3>> req_tc;
        sc_signal<bool> req_td;
        sc_signal<bool> req_ep;
        sc_signal<sc_uint<2>> req_attr;
        sc_signal<sc_uint<10>> req_len;
        sc_signal<sc_uint<16>> req_rid;
        sc_signal<sc_uint<8>> req_tag;
        sc_signal<sc_uint<8>> req_be;
        sc_signal<sc_uint<13>> req_addr;
        sc_signal<sc_uint<11>> wr_addr;
        sc_signal<sc_uint<8>> wr_be;
        sc_signal<sc_uint<32>> wr_data;
        sc_signal<bool> wr_en;
        sc_signal<sc_uint<8>> state;
        sc_signal<sc_uint<8>> tlp_type;
        sc_signal<bool> in_packet_q;
    };

    void pcie_io_rx_engine_r_reset(pcie_io_rx_engine_registers& iv) {
        iv.m_axis_rx_tready = 0;
        iv.req_compl = 0;
        iv.req_compl_wd = 1;
        iv.req_tc = 0;
        iv.req_td = 0;
        iv.req_ep = 0;
        iv.req_attr = 0;
        iv.req_len = 0;
        iv.req_rid = 0;
        iv.req_tag = 0;
        iv.req_be = 0;
        iv.req_addr = 0;
        iv.wr_addr = 0;
        iv.wr_be = 0;
        iv.wr_data = 0;
        iv.wr_en = 0;
        iv.state = PIO_RX_RST_STATE;
        iv.tlp_type = 0;
        iv.in_packet_q = 0;
    }

    bool w_sop;
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
    o_req_compl("o_req_compl"),
    o_req_compl_wd("o_req_compl_wd"),
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
    o_wr_addr("o_wr_addr"),
    o_wr_be("o_wr_be"),
    o_wr_data("o_wr_data"),
    o_wr_en("o_wr_en"),
    i_wr_busy("i_wr_busy") {


    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_m_axis_rx_tdata;
    sensitive << i_m_axis_rx_tkeep;
    sensitive << i_m_axis_rx_tlast;
    sensitive << i_m_axis_rx_tvalid;
    sensitive << i_m_axis_rx_tuser;
    sensitive << i_compl_done;
    sensitive << i_wr_busy;
    sensitive << r.m_axis_rx_tready;
    sensitive << r.req_compl;
    sensitive << r.req_compl_wd;
    sensitive << r.req_tc;
    sensitive << r.req_td;
    sensitive << r.req_ep;
    sensitive << r.req_attr;
    sensitive << r.req_len;
    sensitive << r.req_rid;
    sensitive << r.req_tag;
    sensitive << r.req_be;
    sensitive << r.req_addr;
    sensitive << r.wr_addr;
    sensitive << r.wr_be;
    sensitive << r.wr_data;
    sensitive << r.wr_en;
    sensitive << r.state;
    sensitive << r.tlp_type;
    sensitive << r.in_packet_q;

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
        sc_trace(o_vcd, o_req_compl, o_req_compl.name());
        sc_trace(o_vcd, o_req_compl_wd, o_req_compl_wd.name());
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
        sc_trace(o_vcd, o_wr_addr, o_wr_addr.name());
        sc_trace(o_vcd, o_wr_be, o_wr_be.name());
        sc_trace(o_vcd, o_wr_data, o_wr_data.name());
        sc_trace(o_vcd, o_wr_en, o_wr_en.name());
        sc_trace(o_vcd, i_wr_busy, i_wr_busy.name());
        sc_trace(o_vcd, r.m_axis_rx_tready, pn + ".r.m_axis_rx_tready");
        sc_trace(o_vcd, r.req_compl, pn + ".r.req_compl");
        sc_trace(o_vcd, r.req_compl_wd, pn + ".r.req_compl_wd");
        sc_trace(o_vcd, r.req_tc, pn + ".r.req_tc");
        sc_trace(o_vcd, r.req_td, pn + ".r.req_td");
        sc_trace(o_vcd, r.req_ep, pn + ".r.req_ep");
        sc_trace(o_vcd, r.req_attr, pn + ".r.req_attr");
        sc_trace(o_vcd, r.req_len, pn + ".r.req_len");
        sc_trace(o_vcd, r.req_rid, pn + ".r.req_rid");
        sc_trace(o_vcd, r.req_tag, pn + ".r.req_tag");
        sc_trace(o_vcd, r.req_be, pn + ".r.req_be");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.wr_addr, pn + ".r.wr_addr");
        sc_trace(o_vcd, r.wr_be, pn + ".r.wr_be");
        sc_trace(o_vcd, r.wr_data, pn + ".r.wr_data");
        sc_trace(o_vcd, r.wr_en, pn + ".r.wr_en");
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.tlp_type, pn + ".r.tlp_type");
        sc_trace(o_vcd, r.in_packet_q, pn + ".r.in_packet_q");
    }

}

template<int C_DATA_WIDTH, int KEEP_WIDTH>
void pcie_io_rx_engine<C_DATA_WIDTH, KEEP_WIDTH>::comb() {
    sc_uint<2> vb_region_select;

    v = r;
    vb_region_select = 0;

    // Generate a signal that indicates if we are currently receiving a packet.
    // This value is one clock cycle delayed from what is actually on the AXIS
    // data bus.
    if ((i_m_axis_rx_tvalid.read() == 1) && (r.m_axis_rx_tready.read() == 1) && (i_m_axis_rx_tlast.read() == 1)) {
        v.in_packet_q = 0;
    } else if ((w_sop == 1) && (r.m_axis_rx_tready.read() == 1)) {
        v.in_packet_q = 1;
    }

    if (i_m_axis_rx_tuser.read()(8, 2) == 0x01) {           // Select Mem32 region
        vb_region_select = 0x1;
    } else if (i_m_axis_rx_tuser.read()(8, 2) == 0x02) {    // Select Mem64 region
        vb_region_select = 0x2;
    } else if (i_m_axis_rx_tuser.read()(8, 2) == 0x40) {    // Select EROM region
        vb_region_select = 0x3;
    }

    v.wr_en = 0;
    v.req_compl = 0;

    switch (r.state.read()) {
    case PIO_RX_RST_STATE:
        v.m_axis_rx_tready = 1;
        v.req_compl_wd = 1;

        if (w_sop == 1) {
            switch (i_m_axis_rx_tdata.read()(30, 24)) {
            case PIO_RX_MEM_RD32_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                v.m_axis_rx_tready = 0;

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.req_tc = i_m_axis_rx_tdata.read()(22, 20);
                    v.req_td = i_m_axis_rx_tdata.read()[15];
                    v.req_ep = i_m_axis_rx_tdata.read()[14];
                    v.req_attr = i_m_axis_rx_tdata.read()(13, 12);
                    v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                    v.req_rid = i_m_axis_rx_tdata.read()(63, 48);
                    v.req_tag = i_m_axis_rx_tdata.read()(47, 40);
                    v.req_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_MEM_RD32_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
                }
                break;

            case PIO_RX_MEM_WR32_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                v.m_axis_rx_tready = 0;

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.wr_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_MEM_WR32_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
                }
                break;

            case PIO_RX_MEM_RD64_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                v.m_axis_rx_tready = 0;

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.req_tc = i_m_axis_rx_tdata.read()(22, 20);
                    v.req_td = i_m_axis_rx_tdata.read()[15];
                    v.req_ep = i_m_axis_rx_tdata.read()[14];
                    v.req_attr = i_m_axis_rx_tdata.read()(13, 12);
                    v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                    v.req_rid = i_m_axis_rx_tdata.read()(63, 48);
                    v.req_tag = i_m_axis_rx_tdata.read()(47, 40);
                    v.req_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_MEM_RD64_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
                }
                break;

            case PIO_RX_MEM_WR64_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.wr_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_MEM_WR64_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
                }
                break;

            case PIO_RX_IO_RD32_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                v.m_axis_rx_tready = 0;

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.req_tc = i_m_axis_rx_tdata.read()(22, 20);
                    v.req_td = i_m_axis_rx_tdata.read()[15];
                    v.req_ep = i_m_axis_rx_tdata.read()[14];
                    v.req_attr = i_m_axis_rx_tdata.read()(13, 12);
                    v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                    v.req_rid = i_m_axis_rx_tdata.read()(63, 48);
                    v.req_tag = i_m_axis_rx_tdata.read()(47, 40);
                    v.req_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_MEM_RD32_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
                }
                break;

            case PIO_RX_IO_WR32_FMT_TYPE:
                v.tlp_type = i_m_axis_rx_tdata.read()(31, 24);
                v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                v.m_axis_rx_tready = 0;

                if (i_m_axis_rx_tdata.read()(9, 0) == 1) {
                    v.req_tc = i_m_axis_rx_tdata.read()(22, 20);
                    v.req_td = i_m_axis_rx_tdata.read()[15];
                    v.req_ep = i_m_axis_rx_tdata.read()[14];
                    v.req_attr = i_m_axis_rx_tdata.read()(13, 12);
                    v.req_len = i_m_axis_rx_tdata.read()(9, 0);
                    v.req_rid = i_m_axis_rx_tdata.read()(63, 48);
                    v.req_tag = i_m_axis_rx_tdata.read()(47, 40);
                    v.req_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.wr_be = i_m_axis_rx_tdata.read()(39, 32);
                    v.state = PIO_RX_IO_WR_DW1DW2;
                } else {
                    v.state = PIO_RX_RST_STATE;
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
            v.m_axis_rx_tready = 0;
            v.req_addr = (vb_region_select(1, 0), i_m_axis_rx_tdata.read()(10, 2), 0);
            v.req_compl = 1;
            v.req_compl_wd = 1;
            v.state = PIO_RX_WAIT_STATE;
        } else {
            v.state = PIO_RX_MEM_RD32_DW1DW2;
        }
        break;

    case PIO_RX_MEM_WR32_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.wr_data = i_m_axis_rx_tdata.read()(63, 32);
            v.wr_en = 1;
            v.m_axis_rx_tready = 0;
            v.wr_addr = (vb_region_select(1, 0), i_m_axis_rx_tdata.read()(10, 2));
            v.state = PIO_RX_WAIT_STATE;
        } else {
            v.state = PIO_RX_MEM_WR32_DW1DW2;
        }
        break;

    case PIO_RX_MEM_RD64_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.req_addr = (vb_region_select(1, 0), i_m_axis_rx_tdata.read()(42, 34), 0);
            v.req_compl = 1;
            v.req_compl_wd = 1;
            v.m_axis_rx_tready = 0;
            v.state = PIO_RX_WAIT_STATE;
        } else {
            v.state = PIO_RX_MEM_RD64_DW1DW2;
        }
        break;

    case PIO_RX_MEM_WR64_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.m_axis_rx_tready = 0;
            v.wr_addr = (vb_region_select(1, 0), i_m_axis_rx_tdata.read()(42, 34));
            v.state = PIO_RX_MEM_WR64_DW3;
        } else {
            v.state = PIO_RX_MEM_WR64_DW1DW2;
        }
        break;

    case PIO_RX_MEM_WR64_DW3:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.wr_data = i_m_axis_rx_tdata.read()(31, 0);
            v.wr_en = 1;
            v.m_axis_rx_tready = 0;
            v.state = PIO_RX_WAIT_STATE;
        } else {
            v.state = PIO_RX_MEM_WR64_DW3;
        }
        break;

    case PIO_RX_IO_WR_DW1DW2:
        if (i_m_axis_rx_tvalid.read() == 1) {
            v.wr_data = i_m_axis_rx_tdata.read()(63, 32);
            v.wr_en = 1;
            v.m_axis_rx_tready = 0;
            v.wr_addr = (vb_region_select(1, 0), i_m_axis_rx_tdata.read()(10, 2));
            v.req_compl = 1;
            v.req_compl_wd = 0;
            v.state = PIO_RX_WAIT_STATE;
        } else {
            v.state = PIO_RX_IO_WR_DW1DW2;
        }
        break;

    case PIO_RX_WAIT_STATE:
        v.wr_en = 0;
        v.req_compl = 0;
        if ((r.tlp_type.read() == PIO_RX_MEM_WR32_FMT_TYPE) && (i_wr_busy.read() == 0)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else if ((r.tlp_type.read() == PIO_RX_IO_WR32_FMT_TYPE) && (i_wr_busy.read() == 0)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else if ((r.tlp_type.read() == PIO_RX_MEM_WR64_FMT_TYPE) && (i_wr_busy.read() == 0)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else if ((r.tlp_type.read() == PIO_RX_MEM_RD32_FMT_TYPE) && (i_compl_done.read() == 1)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else if ((r.tlp_type.read() == PIO_RX_IO_RD32_FMT_TYPE) && (i_compl_done.read() == 1)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else if ((r.tlp_type.read() == PIO_RX_MEM_RD64_FMT_TYPE) && (i_compl_done.read() == 1)) {
            v.m_axis_rx_tready = 1;
            v.state = PIO_RX_RST_STATE;
        } else {
            v.state = PIO_RX_WAIT_STATE;
        }
        break;

    default:
        v.state = PIO_RX_RST_STATE;
        break;
    }

    w_sop = ((!r.in_packet_q.read()) && i_m_axis_rx_tvalid.read());

    o_m_axis_rx_tready = r.m_axis_rx_tready.read();
    o_req_compl = r.req_compl.read();
    o_req_compl_wd = r.req_compl_wd.read();
    o_req_tc = r.req_tc.read();
    o_req_td = r.req_td.read();
    o_req_ep = r.req_ep.read();
    o_req_attr = r.req_attr.read();
    o_req_len = r.req_len.read();
    o_req_rid = r.req_rid.read();
    o_req_tag = r.req_tag.read();
    o_req_be = r.req_be.read();
    o_req_addr = r.req_addr.read();
    o_wr_addr = r.wr_addr.read();
    o_wr_be = r.wr_be.read()(3, 0);
    o_wr_data = r.wr_data.read();
    o_wr_en = r.wr_en.read();
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

