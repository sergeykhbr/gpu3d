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
    o_dbg_valid("o_dbg_valid"),
    o_dbg_payload("o_dbg_payload") {

    async_reset_ = async_reset;
    reqfifo = 0;
    respfifo = 0;
    PIO_EP_inst = 0;
    xdma0 = 0;

    // PCIE EP (200 MHz) -> DMA (40 MHz)
    reqfifo = new cdc_afifo<CFG_PCIE_DMAFIFO_DEPTH,
                            REQ_FIFO_WIDTH>("reqfifo");
    reqfifo->i_nrst(i_nrst);
    reqfifo->i_wclk(i_pcie_phy_clk);
    reqfifo->i_wr(w_pcie_dmai_valid);
    reqfifo->i_wdata(wb_reqfifo_payload_i);
    reqfifo->o_wready(w_reqfifo_wready);
    reqfifo->i_rclk(i_clk);
    reqfifo->i_rd(w_reqfifo_rd);
    reqfifo->o_rdata(wb_reqfifo_payload_o);
    reqfifo->o_rvalid(w_reqfifo_rvalid);
    // DMA (40 MHz) -> PCIE EP (200 MHz)
    respfifo = new cdc_afifo<CFG_PCIE_DMAFIFO_DEPTH,
                             RESP_FIFO_WIDTH>("respfifo");
    respfifo->i_nrst(i_nrst);
    respfifo->i_wclk(i_clk);
    respfifo->i_wr(w_respfifo_wr);
    respfifo->i_wdata(wb_respfifo_payload_i);
    respfifo->o_wready(w_respfifo_wready);
    respfifo->i_rclk(i_pcie_phy_clk);
    respfifo->i_rd(w_pcie_dmai_ready);
    respfifo->o_rdata(wb_respfifo_payload_o);
    respfifo->o_rvalid(w_respfifo_rvalid);

    PIO_EP_inst = new pcie_io_ep<C_DATA_WIDTH,
                                 KEEP_WIDTH>("PIO_EP_inst");
    PIO_EP_inst->i_nrst(i_nrst);
    PIO_EP_inst->i_clk(i_clk);
    PIO_EP_inst->i_s_axis_tx_tready(w_respfifo_wready);
    PIO_EP_inst->o_s_axis_tx_tdata(wb_s_axis_tx_tdata);
    PIO_EP_inst->o_s_axis_tx_tkeep(wb_s_axis_tx_tkeep);
    PIO_EP_inst->o_s_axis_tx_tlast(w_s_axis_tx_tlast);
    PIO_EP_inst->o_s_axis_tx_tvalid(w_respfifo_wr);
    PIO_EP_inst->o_tx_src_dsc(w_tx_src_dsc);
    PIO_EP_inst->i_m_axis_rx_tdata(wb_m_axis_rx_tdata);
    PIO_EP_inst->i_m_axis_rx_tkeep(wb_m_axis_rx_tkeep);
    PIO_EP_inst->i_m_axis_rx_tlast(w_m_axis_rx_tlast);
    PIO_EP_inst->i_m_axis_rx_tvalid(w_reqfifo_rvalid);
    PIO_EP_inst->o_m_axis_rx_tready(w_reqfifo_rd);
    PIO_EP_inst->i_m_axis_rx_tuser(wb_m_axis_rx_tuser);
    PIO_EP_inst->i_cfg_completer_id(i_pcie_completer_id);
    PIO_EP_inst->i_req_mem_ready(w_req_mem_ready);
    PIO_EP_inst->o_req_mem_valid(w_req_mem_valid);
    PIO_EP_inst->o_req_mem_write(w_req_mem_write);
    PIO_EP_inst->o_req_mem_bytes(wb_req_mem_bytes);
    PIO_EP_inst->o_req_mem_addr(wb_req_mem_addr);
    PIO_EP_inst->o_req_mem_strob(wb_req_mem_strob);
    PIO_EP_inst->o_req_mem_data(wb_req_mem_data);
    PIO_EP_inst->o_req_mem_last(w_req_mem_last);
    PIO_EP_inst->i_resp_mem_valid(w_resp_mem_valid);
    PIO_EP_inst->i_resp_mem_last(w_resp_mem_last);
    PIO_EP_inst->i_resp_mem_fault(w_resp_mem_fault);
    PIO_EP_inst->i_resp_mem_addr(wb_resp_mem_addr);
    PIO_EP_inst->i_resp_mem_data(wb_resp_mem_data);
    PIO_EP_inst->o_resp_mem_ready(w_resp_mem_ready);

    xdma0 = new axi_dma<CFG_PCIE_DMAADDR_WIDTH>("xdma0",
                                                async_reset,
                                                1,
                                                0x000000000000);
    xdma0->i_nrst(i_nrst);
    xdma0->i_clk(i_clk);
    xdma0->o_req_mem_ready(w_req_mem_ready);
    xdma0->i_req_mem_valid(w_req_mem_valid);
    xdma0->i_req_mem_write(w_req_mem_write);
    xdma0->i_req_mem_bytes(wb_req_mem_bytes);
    xdma0->i_req_mem_addr(wb_req_mem_addr);
    xdma0->i_req_mem_strob(wb_req_mem_strob);
    xdma0->i_req_mem_data(wb_req_mem_data);
    xdma0->i_req_mem_last(w_req_mem_last);
    xdma0->o_resp_mem_valid(w_resp_mem_valid);
    xdma0->o_resp_mem_last(w_resp_mem_last);
    xdma0->o_resp_mem_fault(w_resp_mem_fault);
    xdma0->o_resp_mem_addr(wb_resp_mem_addr);
    xdma0->o_resp_mem_data(wb_resp_mem_data);
    xdma0->i_resp_mem_ready(w_resp_mem_ready);
    xdma0->i_msti(i_xmsti);
    xdma0->o_msto(o_xmsto);
    xdma0->o_dbg_valid(o_dbg_valid);
    xdma0->o_dbg_payload(o_dbg_payload);

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
    sensitive << w_reqfifo_wready;
    sensitive << w_reqfifo_rvalid;
    sensitive << w_reqfifo_rd;
    sensitive << wb_respfifo_payload_i;
    sensitive << wb_respfifo_payload_o;
    sensitive << w_respfifo_wready;
    sensitive << w_respfifo_rvalid;
    sensitive << w_respfifo_wr;
    sensitive << wb_m_axis_rx_tuser;
    sensitive << w_m_axis_rx_tlast;
    sensitive << wb_m_axis_rx_tkeep;
    sensitive << wb_m_axis_rx_tdata;
    sensitive << w_s_axis_tx_tlast;
    sensitive << wb_s_axis_tx_tkeep;
    sensitive << wb_s_axis_tx_tdata;
    sensitive << w_tx_src_dsc;
    sensitive << w_req_mem_ready;
    sensitive << w_req_mem_valid;
    sensitive << w_req_mem_write;
    sensitive << wb_req_mem_bytes;
    sensitive << wb_req_mem_addr;
    sensitive << wb_req_mem_strob;
    sensitive << wb_req_mem_data;
    sensitive << w_req_mem_last;
    sensitive << w_resp_mem_valid;
    sensitive << w_resp_mem_last;
    sensitive << w_resp_mem_fault;
    sensitive << wb_resp_mem_addr;
    sensitive << wb_resp_mem_data;
    sensitive << w_resp_mem_ready;
}

pcie_dma::~pcie_dma() {
    if (reqfifo) {
        delete reqfifo;
    }
    if (respfifo) {
        delete respfifo;
    }
    if (PIO_EP_inst) {
        delete PIO_EP_inst;
    }
    if (xdma0) {
        delete xdma0;
    }
}

void pcie_dma::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    if (o_vcd) {
        sc_trace(o_vcd, i_pcie_phy_clk, i_pcie_phy_clk.name());
        sc_trace(o_vcd, i_pcie_completer_id, i_pcie_completer_id.name());
        sc_trace(o_vcd, o_dma_state, o_dma_state.name());
        sc_trace(o_vcd, i_pcie_dmai, i_pcie_dmai.name());
        sc_trace(o_vcd, o_pcie_dmao, o_pcie_dmao.name());
        sc_trace(o_vcd, i_xmsti, i_xmsti.name());
        sc_trace(o_vcd, o_xmsto, o_xmsto.name());
        sc_trace(o_vcd, o_dbg_valid, o_dbg_valid.name());
        sc_trace(o_vcd, o_dbg_payload, o_dbg_payload.name());
    }

    if (reqfifo) {
        reqfifo->generateVCD(i_vcd, o_vcd);
    }
    if (respfifo) {
        respfifo->generateVCD(i_vcd, o_vcd);
    }
    if (PIO_EP_inst) {
        PIO_EP_inst->generateVCD(i_vcd, o_vcd);
    }
    if (xdma0) {
        xdma0->generateVCD(i_vcd, o_vcd);
    }
}

void pcie_dma::comb() {
    dev_config_type vb_xmst_cfg;
    axi4_master_out_type vb_xmsto;
    pcie_dma64_out_type vb_pcie_dmao;
    sc_uint<9> vb_m_axis_rx_tuser;
    bool v_m_axis_rx_tlast;
    sc_uint<KEEP_WIDTH> vb_m_axis_rx_tkeep;
    sc_uint<C_DATA_WIDTH> vb_m_axis_rx_tdata;

    vb_m_axis_rx_tuser = 0;
    v_m_axis_rx_tlast = 0;
    vb_m_axis_rx_tkeep = 0;
    vb_m_axis_rx_tdata = 0;

    vb_xmst_cfg.descrsize = PNP_CFG_DEV_DESCR_BYTES;
    vb_xmst_cfg.descrtype = PNP_CFG_TYPE_MASTER;
    vb_xmst_cfg.vid = VENDOR_OPTIMITECH;
    vb_xmst_cfg.did = OPTIMITECH_PCIE_DMA;
    o_xmst_cfg = vb_xmst_cfg;

    o_dma_state = 0;

    w_pcie_dmai_valid = i_pcie_dmai.read().valid;
    w_pcie_dmai_ready = i_pcie_dmai.read().ready;

    // PCIE PHY clock to system clock AFIFO:
    wb_reqfifo_payload_i = (i_pcie_dmai.read().bar_hit,
            i_pcie_dmai.read().ecrc_err,
            i_pcie_dmai.read().err_fwd,
            i_pcie_dmai.read().last,
            i_pcie_dmai.read().strob,
            i_pcie_dmai.read().data);

    // SystemC limitation, cannot assign directly to signal:
    vb_m_axis_rx_tuser = wb_reqfifo_payload_o.read()(81, 73);
    v_m_axis_rx_tlast = wb_reqfifo_payload_o.read()[72];
    vb_m_axis_rx_tkeep = wb_reqfifo_payload_o.read()(71, 64);
    vb_m_axis_rx_tdata = wb_reqfifo_payload_o.read()(63, 0);
    wb_m_axis_rx_tuser = vb_m_axis_rx_tuser;
    w_m_axis_rx_tlast = v_m_axis_rx_tlast;
    wb_m_axis_rx_tkeep = vb_m_axis_rx_tkeep;
    wb_m_axis_rx_tdata = vb_m_axis_rx_tdata;

    // System Clock to PCIE PHY clock AFIFO:
    wb_respfifo_payload_i = (w_s_axis_tx_tlast.read(),
            wb_s_axis_tx_tkeep.read(),
            wb_s_axis_tx_tdata.read());

    vb_pcie_dmao.valid = w_respfifo_rvalid.read();
    vb_pcie_dmao.ready = w_reqfifo_wready.read();
    vb_pcie_dmao.last = wb_respfifo_payload_o.read()[72];
    vb_pcie_dmao.strob = wb_respfifo_payload_o.read()(71, 64);
    vb_pcie_dmao.data = wb_respfifo_payload_o.read()(63, 0);
    o_pcie_dmao = vb_pcie_dmao;
}

}  // namespace debugger

