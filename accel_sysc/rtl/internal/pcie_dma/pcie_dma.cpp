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

#include "pcie_dma.h"
#include "api_core.h"

namespace debugger {

pcie_dma::pcie_dma(sc_module_name name,
                   bool async_reset)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_clk("i_clk"),
    i_pcie_phy_clk("i_pcie_phy_clk"),
    i_pcie_completer_id("i_pcie_completer_id"),
    o_dma_state("o_dma_state"),
    i_pcie_dmai("i_pcie_dmai"),
    o_pcie_dmao("o_pcie_dmao"),
    o_xmst_cfg("o_xmst_cfg"),
    i_xmsti("i_xmsti"),
    o_xmsto("o_xmsto"),
    o_dbg_pcie_dmai("o_dbg_pcie_dmai") {

    async_reset_ = async_reset;
    reqfifo = 0;
    respfifo = 0;

    // PCIE EP (200 MHz) -> DMA (40 MHz)
    reqfifo = new cdc_afifo<CFG_PCIE_DMAFIFO_DEPTH,
                            REQ_FIFO_WIDTH>("reqfifo");
    reqfifo->i_nrst(i_nrst);
    reqfifo->i_wclk(i_pcie_phy_clk);
    reqfifo->i_wr(w_pcie_dmai_valid);
    reqfifo->i_wdata(wb_reqfifo_payload_i);
    reqfifo->o_wfull(w_reqfifo_full);
    reqfifo->i_rclk(i_clk);
    reqfifo->i_rd(w_reqfifo_rd);
    reqfifo->o_rdata(wb_reqfifo_payload_o);
    reqfifo->o_rempty(w_reqfifo_empty);
    // DMA (40 MHz) -> PCIE EP (200 MHz)
    respfifo = new cdc_afifo<CFG_PCIE_DMAFIFO_DEPTH,
                             RESP_FIFO_WIDTH>("respfifo");
    respfifo->i_nrst(i_nrst);
    respfifo->i_wclk(i_clk);
    respfifo->i_wr(w_respfifo_wr);
    respfifo->i_wdata(wb_respfifo_payload_i);
    respfifo->o_wfull(w_respfifo_full);
    respfifo->i_rclk(i_pcie_phy_clk);
    respfifo->i_rd(w_pcie_dmai_ready);
    respfifo->o_rdata(wb_respfifo_payload_o);
    respfifo->o_rempty(w_respfifo_empty);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_pcie_phy_clk;
    sensitive << i_pcie_completer_id;
    sensitive << i_pcie_dmai;
    sensitive << i_xmsti;
    sensitive << w_pcie_dmai_valid;
    sensitive << w_pcie_dmai_ready;
    sensitive << wb_reqfifo_payload_i;
    sensitive << wb_reqfifo_payload_o;
    sensitive << w_reqfifo_full;
    sensitive << w_reqfifo_empty;
    sensitive << w_reqfifo_rd;
    sensitive << wb_respfifo_payload_i;
    sensitive << wb_respfifo_payload_o;
    sensitive << w_respfifo_full;
    sensitive << w_respfifo_empty;
    sensitive << w_respfifo_wr;
    sensitive << r.state;
    sensitive << r.dw0;
    sensitive << r.dw1;
    sensitive << r.dw2;
    sensitive << r.dw3;
    sensitive << r.req_rd_locked;
    sensitive << r.xlen;
    sensitive << r.xsize;
    sensitive << r.xaddr;
    sensitive << r.xwstrb;
    sensitive << r.xwdata;
    sensitive << r.xwena;
    sensitive << r.xrdata;
    sensitive << r.xerr;
    sensitive << r.resp_with_payload;
    sensitive << r.resp_data;
    sensitive << r.resp_status;
    sensitive << r.resp_cpl;
    sensitive << r.byte_cnt;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

pcie_dma::~pcie_dma() {
    if (reqfifo) {
        delete reqfifo;
    }
    if (respfifo) {
        delete respfifo;
    }
}

void pcie_dma::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_pcie_phy_clk, i_pcie_phy_clk.name());
        sc_trace(o_vcd, i_pcie_completer_id, i_pcie_completer_id.name());
        sc_trace(o_vcd, o_dma_state, o_dma_state.name());
        sc_trace(o_vcd, i_pcie_dmai, i_pcie_dmai.name());
        sc_trace(o_vcd, o_pcie_dmao, o_pcie_dmao.name());
        sc_trace(o_vcd, i_xmsti, i_xmsti.name());
        sc_trace(o_vcd, o_xmsto, o_xmsto.name());
        sc_trace(o_vcd, o_dbg_pcie_dmai, o_dbg_pcie_dmai.name());
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.dw0, pn + ".r.dw0");
        sc_trace(o_vcd, r.dw1, pn + ".r.dw1");
        sc_trace(o_vcd, r.dw2, pn + ".r.dw2");
        sc_trace(o_vcd, r.dw3, pn + ".r.dw3");
        sc_trace(o_vcd, r.req_rd_locked, pn + ".r.req_rd_locked");
        sc_trace(o_vcd, r.xlen, pn + ".r.xlen");
        sc_trace(o_vcd, r.xsize, pn + ".r.xsize");
        sc_trace(o_vcd, r.xaddr, pn + ".r.xaddr");
        sc_trace(o_vcd, r.xwstrb, pn + ".r.xwstrb");
        sc_trace(o_vcd, r.xwdata, pn + ".r.xwdata");
        sc_trace(o_vcd, r.xwena, pn + ".r.xwena");
        sc_trace(o_vcd, r.xrdata, pn + ".r.xrdata");
        sc_trace(o_vcd, r.xerr, pn + ".r.xerr");
        sc_trace(o_vcd, r.resp_with_payload, pn + ".r.resp_with_payload");
        sc_trace(o_vcd, r.resp_data, pn + ".r.resp_data");
        sc_trace(o_vcd, r.resp_status, pn + ".r.resp_status");
        sc_trace(o_vcd, r.resp_cpl, pn + ".r.resp_cpl");
        sc_trace(o_vcd, r.byte_cnt, pn + ".r.byte_cnt");
    }

    if (reqfifo) {
        reqfifo->generateVCD(i_vcd, o_vcd);
    }
    if (respfifo) {
        respfifo->generateVCD(i_vcd, o_vcd);
    }
}

void pcie_dma::comb() {
    dev_config_type vb_xmst_cfg;
    axi4_master_out_type vb_xmsto;
    pcie_dma64_out_type vb_pcie_dmao;
    pcie_dma64_in_type vb_dbg_pcie_dmai;
    sc_uint<XSIZE_TOTAL> vb_xbytes;                         // result of function call XSize2XBytes(xsize)
    bool v_req_ready;
    sc_uint<64> vb_req_addr;
    sc_uint<2> vb_req_addr1_0;                              // address[1:0] restored from strob field be[3:0]
    sc_uint<64> vb_req_data;
    sc_uint<8> vb_req_strob;
    bool v_req_last;
    bool v_single_tlp;                                      // single 32-bit dma transaction, trnasmit as 4DW with TLP header
    bool v_resp_valid;
    sc_uint<64> vb_resp_data;
    sc_uint<8> vb_resp_strob;
    bool v_resp_last;

    v = r;
    vb_xmst_cfg = dev_config_none;
    vb_xmsto = axi4_master_out_none;
    vb_pcie_dmao = pcie_dma64_out_none;
    vb_dbg_pcie_dmai = pcie_dma64_in_none;
    vb_xbytes = 0;
    v_req_ready = 0;
    vb_req_addr = 0;
    vb_req_addr1_0 = 0;
    vb_req_data = 0;
    vb_req_strob = 0;
    v_req_last = 0;
    v_single_tlp = 0;
    v_resp_valid = 0;
    vb_resp_data = 0;
    vb_resp_strob = 0;
    v_resp_last = 0;

    w_pcie_dmai_valid = i_pcie_dmai.read().valid;
    w_pcie_dmai_ready = i_pcie_dmai.read().ready;

    if (r.dw0.read()(9, 0) == 1) {
        // DW0[9:0] = Length number of DW (4-bytes) for 32/64 bars
        v_single_tlp = 1;
    }
    vb_xmst_cfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
    vb_xmst_cfg.descrtype = PNP_CFG_TYPE_MASTER;
    vb_xmst_cfg.vid = VENDOR_OPTIMITECH;
    vb_xmst_cfg.did = OPTIMITECH_PCIE_DMA;
    vb_xbytes = XSizeToBytes(r.xsize.read());

    // Request address bits [1:0] are not transmitted, should be restored from BE[3:0]:
    // be[3:0] => addr[1:0]
    // 0000    => 00
    // xxx1    => 00
    // xx10    => 01
    // x100    => 10
    // 1000    => 11
    if (r.dw1.read()[0] == 1) {
        vb_req_addr1_0 = 0;
    } else if (r.dw1.read()[1] == 1) {
        vb_req_addr1_0 = 1;
    } else if (r.dw1.read()[2] == 1) {
        vb_req_addr1_0 = 2;
    } else if (r.dw1.read()[3] == 1) {
        vb_req_addr1_0 = 3;
    } else {
        vb_req_addr1_0 = 0;
    }

    // Request FIFO inputs/outputs:
    wb_reqfifo_payload_i = (i_pcie_dmai.read().last,
            i_pcie_dmai.read().strob,
            i_pcie_dmai.read().data);

    v_req_last = wb_reqfifo_payload_o.read()[72];
    vb_req_strob = wb_reqfifo_payload_o.read()(71, 64);
    vb_req_data = wb_reqfifo_payload_o.read()(63, 0);

    // Temporary register
    switch (r.state.read()) {
    case STATE_RST:
        v_req_ready = 1;
        v.resp_status = TLP_STATUS_SUCCESS;
        v.req_rd_locked = 0;
        v.resp_cpl = 0;
        v.resp_with_payload = 0;
        if (w_reqfifo_empty.read() == 0) {
            v.dw0 = vb_req_data(31, 0);
            v.dw1 = vb_req_data(63, 32);
            v.state = STATE_DW3DW4;
        }
        break;

    case STATE_DW3DW4:
        // 64-bits BAR could use 3DW header because if addr[63:32] is zero
        // TLP behaviour is undefined (Xilinx example ignores it):
        //   dw2 = addr[63:32]
        //   dw3 = {addr[31:2], 00}
        v_req_ready = 1;
        v.xlen = (r.dw0.read()(7, 0) - 1);                  // warning: Actual size of Length is 10 bits. 0 is 1024 DWs (4096 Bytes)
        v.dw2 = vb_req_data(31, 0);
        v.dw3 = 0;
        if (w_reqfifo_empty.read() == 0) {
            // fmt[0] = 1 when 4DW header is used
            if (r.dw0.read()[29] == 1) {
                v.dw3 = vb_req_data(63, 32);
            }
            if (r.dw0.read()[30] == 0) {
                // fmt[1]=0: read operation
                v.state = STATE_AR;
                switch (r.dw0.read()(28, 24)) {             // DW0[28:24] = Type[4:0]
                case 0x01:
                    // Read Locked request (in case of error becomes PCIE_CPL_LOCKED_READ_NODATA:
                    v.resp_cpl = PCIE_CPL_LOCKED_READ;
                    v.req_rd_locked = 1;
                    break;
                case 0x02:
                    // I/O Read request:
                    v.resp_cpl = PCIE_CPL_DATA;
                    break;
                case 0x05:
                    // Configuration Read request Root Port (type 1):
                    v.resp_cpl = PCIE_CPL_DATA;
                    break;
                default:
                    // Read request.
                    v.resp_cpl = PCIE_CPL_DATA;
                    break;
                }

                v.byte_cnt = (r.dw0.read()(7, 0) << 2);
                if (r.dw0.read()[29] == 0) {
                    // fmt[0]=0: 3DW header (32-bits address):
                    v.xsize = 2;
                    vb_req_addr(31, 0) = (vb_req_data(31, 2), vb_req_addr1_0);
                } else {
                    // fmt[0]=1: 4DW header (64-bits address):
                    v.xsize = 3;
                    vb_req_addr = (vb_req_data(31, 0), vb_req_data(63, 34), vb_req_addr1_0);
                }
            } else {
                // fmt[1] = 1: write operation
                v.state = STATE_AW;
                v.xwstrb = r.dw1.read()(7, 0);
                switch (r.dw0.read()(28, 24)) {             // DW0[28:24] = Type[4:0]
                case 0x02:
                    // I/O Write request:
                    v.resp_cpl = PCIE_CPL_NODATA;
                    break;
                case 0x05:
                    // Configuration Write request Root Port (type 1):
                    v.resp_cpl = PCIE_CPL_NODATA;
                    break;
                default:
                    // Write request. No completion.
                    break;
                }

                v.byte_cnt = (r.dw0.read()(7, 0) << 2);
                if (r.dw0.read()[29] == 0) {
                    // fmt[0]=0: 3DW header (32-bits address):
                    v.xsize = 2;
                    vb_req_addr(31, 0) = (vb_req_data(31, 2), vb_req_addr1_0);
                    v.xwdata = (vb_req_data(63, 32), vb_req_data(63, 32));
                    v.xwena = v_req_last;                   // AXI Light: burst transactions are no supported
                } else {
                    // fmt[0]=1: 4DW header (64-bits address):
                    v.xsize = 3;
                    vb_req_addr = (vb_req_data(31, 0), vb_req_data(63, 34), vb_req_addr1_0);
                }
            }
        }
        v.xaddr = vb_req_addr((CFG_SYSBUS_ADDR_BITS - 1), 0);
        break;
    case STATE_AR:
        vb_xmsto.ar_valid = 1;
        vb_xmsto.ar_bits.addr = r.xaddr.read()((CFG_SYSBUS_ADDR_BITS - 1), 0);
        // sram base address: 64'h0000000008000000
        vb_xmsto.ar_bits.addr = (0x000008001, vb_xmsto.ar_bits.addr(11, 0));
        vb_xmsto.ar_bits.len = r.xlen.read();
        vb_xmsto.ar_bits.size = r.xsize.read();
        vb_xmsto.ar_bits.lock = r.req_rd_locked.read();
        v.resp_with_payload = 1;
        if (i_xmsti.read().ar_ready == 1) {
            if (v_single_tlp == 1) {
                // 3DW header + DW 32-bits payload
                v.state = STATE_R_SINGLE32;
            } else {
                // 3DW header only
                v.state = STATE_RESP_DW0DW1;
            }
        }
        break;
    case STATE_R_SINGLE32:
        // 32-bit single transactions (no bulk). MEM32 and IO only:
        vb_xmsto.r_ready = 1;
        v.xerr = i_xmsti.read().r_resp;
        if (r.xaddr.read()[2] == 0) {
            v.xrdata = (i_xmsti.read().r_data(31, 0), i_xmsti.read().r_data(31, 0));
        } else {
            v.xrdata = (i_xmsti.read().r_data(63, 32), i_xmsti.read().r_data(63, 32));
        }
        if (i_xmsti.read().r_valid == 1) {
            v.state = STATE_RESP_DW0DW1;
        }
        break;
    case STATE_R:
        vb_xmsto.r_ready = (~w_respfifo_full.read());
        v_resp_valid = i_xmsti.read().r_valid;
        vb_resp_strob = 0xFF;
        v_resp_last = (~r.xlen.read().or_reduce());
        v.xerr = i_xmsti.read().r_resp;
        if (r.xsize.read() == 2) {
            // 32-bit transactions:
            if (r.xaddr.read()[2] == 0) {
                vb_resp_data = (i_xmsti.read().r_data(31, 0), i_xmsti.read().r_data(31, 0));
            } else {
                vb_resp_data = (i_xmsti.read().r_data(63, 32), i_xmsti.read().r_data(63, 32));
            }
        } else {
            // 64-bit transactions:
            vb_resp_data = i_xmsti.read().r_data;
        }

        if ((i_xmsti.read().r_valid == 1) && (w_respfifo_full.read() == 0)) {
            // Burst support: 
            if (i_xmsti.read().r_resp != AXI_RESP_OKAY) {
                v.resp_status = TLP_STATUS_ABORTED;
                if (r.req_rd_locked.read() == 1) {
                    // Error on Locked Read transaction:
                    v.resp_cpl = PCIE_CPL_LOCKED_READ_NODATA;
                }
                v.state = STATE_RESP_DW0DW1;
            } else if (r.xlen.read().or_reduce() == 1) {
                v.xlen = (r.xlen.read() - 1);
                v.xaddr = (r.xaddr.read() + vb_xbytes);
                v.byte_cnt = (r.byte_cnt.read() - vb_xbytes);
            } else {
                v.state = STATE_RST;
            }
        }
        break;
    case STATE_AW:
        vb_xmsto.aw_valid = 1;
        vb_xmsto.aw_bits.addr = r.xaddr.read()((CFG_SYSBUS_ADDR_BITS - 1), 0);
        // sram base address: 64'h0000000008000000
        vb_xmsto.aw_bits.addr = (0x000008001, vb_xmsto.aw_bits.addr(11, 0));
        vb_xmsto.aw_bits.len = r.xlen.read();
        vb_xmsto.aw_bits.size = r.xsize.read();
        vb_xmsto.w_valid = r.xwena.read();
        vb_xmsto.w_last = r.xwena.read();
        vb_xmsto.w_strb = r.xwstrb.read();
        vb_xmsto.w_data = (r.xwdata.read()(31, 0), r.xwdata.read()(31, 0));
        if (i_xmsti.read().aw_ready == 1) {
            if ((r.xwena.read() == 1) && (i_xmsti.read().w_ready == 1)) {
                // AXI light: no burst transactions:
                v.state = STATE_B;
                v.xwena = 0;
            } else {
                v.state = STATE_W;
            }
        }
        break;
    case STATE_W:
        if (r.xwena.read() == 1) {
            v.xwena = 0;
            vb_xmsto.w_valid = 1;
            vb_xmsto.w_strb = r.xwstrb.read();
            vb_xmsto.w_data = r.xwdata.read();
            vb_xmsto.w_last = 1;
            if (i_xmsti.read().w_ready == 1) {
                v.state = STATE_B;
            }
        } else {
            v_req_ready = i_xmsti.read().w_ready;
            vb_xmsto.w_valid = (~w_reqfifo_empty.read());
            vb_xmsto.w_strb = vb_req_strob;
            vb_xmsto.w_data = vb_req_data;
            vb_xmsto.w_last = (~r.xlen.read().or_reduce());
            if ((w_reqfifo_empty.read() == 0) && (i_xmsti.read().w_ready == 1)) {
                if (v_req_last == 1) {
                    v.state = STATE_B;
                }
            }
        }
        break;
    case STATE_B:
        vb_xmsto.b_ready = 1;
        if (i_xmsti.read().b_valid == 1) {
            v.xerr = i_xmsti.read().b_resp;
            if (i_xmsti.read().b_resp != AXI_RESP_OKAY) {
                v.resp_status = TLP_STATUS_ABORTED;
            }
            if (r.resp_cpl.read().or_reduce() == 0) {
                // Posted write TLP without response
                v.state = STATE_RST;
            } else {
                // Non-posted write TLP with response
                v.state = STATE_RESP_DW0DW1;
            }
        }
        break;

    case STATE_RESP_DW0DW1:
        v_resp_valid = 1;
        vb_resp_strob = 0xFF;
        vb_resp_data(9, 0) = r.dw0.read()(9, 0);            // DW0[9:0] Length
        vb_resp_data(11, 10) = 0;                           // DW0[11:10] Reserved
        vb_resp_data(13, 12) = r.dw0.read()(13, 12);        // DW0[13:12] Attr
        vb_resp_data[14] = r.dw0.read()[14];                // DW0[14] EP
        vb_resp_data[15] = r.dw0.read()[15];                // DW0[15] TD
        vb_resp_data(19, 16) = 0;                           // DW0[19:16] Reserved
        vb_resp_data(22, 20) = r.dw0.read()(22, 20);        // DW0[22:20] TC
        vb_resp_data[23] = 0;                               // DW0[23] Reserved
        vb_resp_data(30, 24) = r.resp_cpl.read();           // DW0[30:24] {Fmt,Type} Completion
        vb_resp_data[31] = 0;                               // DW0[31] Reserved
        vb_resp_data(43, 32) = r.byte_cnt.read();           // DW1[11:0] Byte Count
        vb_resp_data[44] = 0;                               // DW1[12] BCM
        vb_resp_data(47, 45) = r.resp_status.read();        // DW1[15:13] Status
        vb_resp_data(63, 48) = i_pcie_completer_id.read();  // DW1[31:16] Completer ID
        if (w_respfifo_full.read() == 0) {
            v.state = STATE_RESP_DW2DW3;
        }
        break;

    case STATE_RESP_DW2DW3:
        v_resp_valid = 1;
        vb_resp_strob = 0x0F;
        vb_resp_data(6, 0) = r.xaddr.read()(6, 0);          // DW2[6:0] Low Address
        vb_resp_data[7] = 0;                                // DW2[7] Reserved
        vb_resp_data(15, 8) = r.dw1.read()(15, 8);          // DW2[15:8] Tag
        vb_resp_data(31, 16) = r.dw1.read()(31, 16);        // DW2[31:16] Requester ID
        vb_resp_data(63, 32) = r.xrdata.read()(31, 0);      // DW3[31:0] payload (ignored by strob 0F)
        if (w_respfifo_full.read() == 0) {
            if (r.resp_status.read() != TLP_STATUS_SUCCESS) {
                v_resp_last = 1;
                v.state = STATE_RST;
            } else if ((v_single_tlp == 1) && (r.resp_with_payload.read() == 1)) {
                // DW4 response with the single DW payload
                vb_resp_strob = 0xFF;
                v_resp_last = 1;
                v.state = STATE_RST;
            } else if (r.resp_with_payload.read() == 1) {
                // DW3 response only if: payload not a single tlp32
                v.state = STATE_R;
            } else {
                // DW3 without payload
                v_resp_last = 1;
                v.state = STATE_RST;
            }
        }
        break;

    default:
        v.state = STATE_RST;
        break;
    }

    if ((~async_reset_) && (i_nrst.read() == 0)) {
        pcie_dma_r_reset(v);
    }

    // Response FIFO inputs/outputs:
    wb_respfifo_payload_i = (v_resp_last,
            vb_resp_strob,
            vb_resp_data);
    vb_pcie_dmao.last = wb_respfifo_payload_o.read()[72];
    vb_pcie_dmao.strob = wb_respfifo_payload_o.read()(71, 64);
    vb_pcie_dmao.data = wb_respfifo_payload_o.read()(63, 0);
    vb_pcie_dmao.ready = (!w_reqfifo_full.read());
    vb_pcie_dmao.valid = (!w_respfifo_empty.read());
    o_pcie_dmao = vb_pcie_dmao;
    w_respfifo_wr = v_resp_valid;
    w_reqfifo_rd = v_req_ready;
    o_xmst_cfg = vb_xmst_cfg;
    o_xmsto = vb_xmsto;
    // Debug signals
    vb_dbg_pcie_dmai.valid = (~w_reqfifo_empty.read());
    vb_dbg_pcie_dmai.data = vb_req_data;
    vb_dbg_pcie_dmai.strob = vb_req_strob;
    vb_dbg_pcie_dmai.last = v_req_last;
    o_dbg_pcie_dmai = vb_dbg_pcie_dmai;
}

void pcie_dma::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        pcie_dma_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

