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

#include "river_amba.h"
#include "api_core.h"

namespace debugger {

RiverAmba::RiverAmba(sc_module_name name,
                     bool async_reset,
                     uint32_t hartid,
                     bool fpu_ena,
                     bool coherence_ena,
                     bool tracer_ena)
    : sc_module(name),
    i_clk("i_clk"),
    i_nrst("i_nrst"),
    i_mtimer("i_mtimer"),
    i_msti("i_msti"),
    o_msto("o_msto"),
    i_dport("i_dport"),
    o_dport("o_dport"),
    i_irq_pending("i_irq_pending"),
    o_flush_l2("o_flush_l2"),
    o_halted("o_halted"),
    o_available("o_available"),
    i_progbuf("i_progbuf") {

    async_reset_ = async_reset;
    hartid_ = hartid;
    fpu_ena_ = fpu_ena;
    coherence_ena_ = coherence_ena;
    tracer_ena_ = tracer_ena;
    river0 = 0;

    river0 = new RiverTop("river0",
                           async_reset,
                           hartid,
                           fpu_ena,
                           coherence_ena,
                           tracer_ena);
    river0->i_clk(i_clk);
    river0->i_nrst(i_nrst);
    river0->i_mtimer(i_mtimer);
    river0->i_req_mem_ready(req_mem_ready_i);
    river0->o_req_mem_path(req_mem_path_o);
    river0->o_req_mem_valid(req_mem_valid_o);
    river0->o_req_mem_type(req_mem_type_o);
    river0->o_req_mem_size(req_mem_size_o);
    river0->o_req_mem_addr(req_mem_addr_o);
    river0->o_req_mem_strob(req_mem_strob_o);
    river0->o_req_mem_data(req_mem_data_o);
    river0->i_resp_mem_valid(resp_mem_valid_i);
    river0->i_resp_mem_path(r.req_path);
    river0->i_resp_mem_data(resp_mem_data_i);
    river0->i_resp_mem_load_fault(resp_mem_load_fault_i);
    river0->i_resp_mem_store_fault(resp_mem_store_fault_i);
    river0->i_req_snoop_valid(req_snoop_valid_i);
    river0->i_req_snoop_type(req_snoop_type_i);
    river0->o_req_snoop_ready(req_snoop_ready_o);
    river0->i_req_snoop_addr(req_snoop_addr_i);
    river0->i_resp_snoop_ready(resp_snoop_ready_i);
    river0->o_resp_snoop_valid(resp_snoop_valid_o);
    river0->o_resp_snoop_data(resp_snoop_data_o);
    river0->o_resp_snoop_flags(resp_snoop_flags_o);
    river0->o_flush_l2(o_flush_l2);
    river0->i_irq_pending(i_irq_pending);
    river0->i_haltreq(w_dporti_haltreq);
    river0->i_resumereq(w_dporti_resumereq);
    river0->i_dport_req_valid(w_dporti_req_valid);
    river0->i_dport_type(wb_dporti_dtype);
    river0->i_dport_addr(wb_dporti_addr);
    river0->i_dport_wdata(wb_dporti_wdata);
    river0->i_dport_size(wb_dporti_size);
    river0->o_dport_req_ready(w_dporto_req_ready);
    river0->i_dport_resp_ready(w_dporti_resp_ready);
    river0->o_dport_resp_valid(w_dporto_resp_valid);
    river0->o_dport_resp_error(w_dporto_resp_error);
    river0->o_dport_rdata(wb_dporto_rdata);
    river0->i_progbuf(i_progbuf);
    river0->o_halted(o_halted);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_mtimer;
    sensitive << i_msti;
    sensitive << i_dport;
    sensitive << i_irq_pending;
    sensitive << i_progbuf;
    sensitive << req_mem_ready_i;
    sensitive << req_mem_path_o;
    sensitive << req_mem_valid_o;
    sensitive << req_mem_type_o;
    sensitive << req_mem_size_o;
    sensitive << req_mem_addr_o;
    sensitive << req_mem_strob_o;
    sensitive << req_mem_data_o;
    sensitive << resp_mem_data_i;
    sensitive << resp_mem_valid_i;
    sensitive << resp_mem_load_fault_i;
    sensitive << resp_mem_store_fault_i;
    sensitive << req_snoop_valid_i;
    sensitive << req_snoop_type_i;
    sensitive << req_snoop_ready_o;
    sensitive << req_snoop_addr_i;
    sensitive << resp_snoop_ready_i;
    sensitive << resp_snoop_valid_o;
    sensitive << resp_snoop_data_o;
    sensitive << resp_snoop_flags_o;
    sensitive << w_dporti_haltreq;
    sensitive << w_dporti_resumereq;
    sensitive << w_dporti_resethaltreq;
    sensitive << w_dporti_hartreset;
    sensitive << w_dporti_req_valid;
    sensitive << wb_dporti_dtype;
    sensitive << wb_dporti_addr;
    sensitive << wb_dporti_wdata;
    sensitive << wb_dporti_size;
    sensitive << w_dporti_resp_ready;
    sensitive << w_dporto_req_ready;
    sensitive << w_dporto_resp_valid;
    sensitive << w_dporto_resp_error;
    sensitive << wb_dporto_rdata;
    sensitive << r.state;
    sensitive << r.req_addr;
    sensitive << r.req_path;
    sensitive << r.req_cached;
    sensitive << r.req_wdata;
    sensitive << r.req_wstrb;
    sensitive << r.req_size;
    sensitive << r.req_prot;
    sensitive << r.req_ar_snoop;
    sensitive << r.req_aw_snoop;
    sensitive << r.snoop_state;
    sensitive << r.ac_addr;
    sensitive << r.ac_snoop;
    sensitive << r.cr_resp;
    sensitive << r.req_snoop_type;
    sensitive << r.resp_snoop_data;
    sensitive << r.cache_access;
    sensitive << r.watchdog;

    SC_METHOD(registers);
    sensitive << i_nrst;
    sensitive << i_clk.pos();
}

RiverAmba::~RiverAmba() {
    if (river0) {
        delete river0;
    }
}

void RiverAmba::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_mtimer, i_mtimer.name());
        sc_trace(o_vcd, i_msti, i_msti.name());
        sc_trace(o_vcd, o_msto, o_msto.name());
        sc_trace(o_vcd, i_dport, i_dport.name());
        sc_trace(o_vcd, o_dport, o_dport.name());
        sc_trace(o_vcd, i_irq_pending, i_irq_pending.name());
        sc_trace(o_vcd, o_flush_l2, o_flush_l2.name());
        sc_trace(o_vcd, o_halted, o_halted.name());
        sc_trace(o_vcd, o_available, o_available.name());
        sc_trace(o_vcd, i_progbuf, i_progbuf.name());
        sc_trace(o_vcd, r.state, pn + ".r.state");
        sc_trace(o_vcd, r.req_addr, pn + ".r.req_addr");
        sc_trace(o_vcd, r.req_path, pn + ".r.req_path");
        sc_trace(o_vcd, r.req_cached, pn + ".r.req_cached");
        sc_trace(o_vcd, r.req_wdata, pn + ".r.req_wdata");
        sc_trace(o_vcd, r.req_wstrb, pn + ".r.req_wstrb");
        sc_trace(o_vcd, r.req_size, pn + ".r.req_size");
        sc_trace(o_vcd, r.req_prot, pn + ".r.req_prot");
        sc_trace(o_vcd, r.req_ar_snoop, pn + ".r.req_ar_snoop");
        sc_trace(o_vcd, r.req_aw_snoop, pn + ".r.req_aw_snoop");
        sc_trace(o_vcd, r.snoop_state, pn + ".r.snoop_state");
        sc_trace(o_vcd, r.ac_addr, pn + ".r.ac_addr");
        sc_trace(o_vcd, r.ac_snoop, pn + ".r.ac_snoop");
        sc_trace(o_vcd, r.cr_resp, pn + ".r.cr_resp");
        sc_trace(o_vcd, r.req_snoop_type, pn + ".r.req_snoop_type");
        sc_trace(o_vcd, r.resp_snoop_data, pn + ".r.resp_snoop_data");
        sc_trace(o_vcd, r.cache_access, pn + ".r.cache_access");
        sc_trace(o_vcd, r.watchdog, pn + ".r.watchdog");
    }

    if (river0) {
        river0->generateVCD(i_vcd, o_vcd);
    }
}

sc_uint<4> RiverAmba::reqtype2arsnoop(sc_uint<REQ_MEM_TYPE_BITS> reqtype) {
    sc_uint<4> ret;

    ret = 0;
    if (reqtype[REQ_MEM_TYPE_CACHED] == 0) {
        ret = ARSNOOP_READ_NO_SNOOP;
    } else {
        if (reqtype[REQ_MEM_TYPE_UNIQUE] == 0) {
            ret = ARSNOOP_READ_SHARED;
        } else {
            ret = ARSNOOP_READ_MAKE_UNIQUE;
        }
    }
    return ret;
}

sc_uint<4> RiverAmba::reqtype2awsnoop(sc_uint<REQ_MEM_TYPE_BITS> reqtype) {
    sc_uint<4> ret;

    ret = 0;
    if (reqtype[REQ_MEM_TYPE_CACHED] == 0) {
        ret = AWSNOOP_WRITE_NO_SNOOP;
    } else {
        if (reqtype[REQ_MEM_TYPE_UNIQUE] == 0) {
            ret = AWSNOOP_WRITE_BACK;
        } else {
            ret = AWSNOOP_WRITE_LINE_UNIQUE;
        }
    }
    return ret;
}

void RiverAmba::comb() {
    bool v_resp_mem_valid;
    bool v_mem_er_load_fault;
    bool v_mem_er_store_fault;
    bool v_next_ready;
    axi4_l1_out_type vmsto;
    dport_out_type vdporto;
    bool v_snoop_next_ready;
    bool req_snoop_valid;
    sc_uint<CFG_CPU_ADDR_BITS> vb_req_snoop_addr;
    sc_uint<SNOOP_REQ_TYPE_BITS> vb_req_snoop_type;
    bool v_cr_valid;
    sc_uint<5> vb_cr_resp;
    bool v_cd_valid;
    sc_biguint<L1CACHE_LINE_BITS> vb_cd_data;

    v = r;
    v_resp_mem_valid = 0;
    v_mem_er_load_fault = 0;
    v_mem_er_store_fault = 0;
    v_next_ready = 0;
    vmsto = axi4_l1_out_none;
    vdporto = dport_out_none;
    v_snoop_next_ready = 0;
    req_snoop_valid = 0;
    vb_req_snoop_addr = 0;
    vb_req_snoop_type = 0;
    v_cr_valid = 0;
    vb_cr_resp = 0;
    v_cd_valid = 0;
    vb_cd_data = 0;


    w_dporti_haltreq = i_dport.read().haltreq;              // systemc compatibility
    w_dporti_resumereq = i_dport.read().resumereq;          // systemc compatibility
    w_dporti_resethaltreq = i_dport.read().resethaltreq;    // systemc compatibility
    w_dporti_hartreset = i_dport.read().hartreset;          // systemc compatibility
    w_dporti_req_valid = i_dport.read().req_valid;          // systemc compatibility
    wb_dporti_dtype = i_dport.read().dtype;                 // systemc compatibility
    wb_dporti_addr = i_dport.read().addr;                   // systemc compatibility
    wb_dporti_wdata = i_dport.read().wdata;                 // systemc compatibility
    wb_dporti_size = i_dport.read().size;                   // systemc compatibility
    w_dporti_resp_ready = i_dport.read().resp_ready;        // systemc compatibility

    vdporto.req_ready = w_dporto_req_ready.read();          // systemc compatibility
    vdporto.resp_valid = w_dporto_resp_valid.read();        // systemc compatibility
    vdporto.resp_error = w_dporto_resp_error.read();        // systemc compatibility
    vdporto.rdata = wb_dporto_rdata.read();                 // systemc compatibility

    vmsto = axi4_l1_out_none;
    vmsto.ar_bits.burst = AXI_BURST_INCR;                   // INCR (possible any value actually)
    vmsto.aw_bits.burst = AXI_BURST_INCR;                   // INCR (possible any value actually)
    switch (r.state.read()) {
    case state_idle:
        v_next_ready = 1;
        if (req_mem_valid_o.read() == 1) {
            v.req_path = req_mem_path_o.read();
            v.req_addr = req_mem_addr_o.read();
            v.req_size = req_mem_size_o.read();
            // [0] 0=Unpriv/1=Priv;
            // [1] 0=Secure/1=Non-secure;
            // [2] 0=Data/1=Instruction
            v.req_prot = (req_mem_path_o.read() << 2);
            if (req_mem_type_o.read()[REQ_MEM_TYPE_WRITE] == 0) {
                v.state = state_ar;
                v.req_wdata = 0;
                v.req_wstrb = 0;
                if (req_mem_type_o.read()[REQ_MEM_TYPE_CACHED] == 1) {
                    v.req_cached = ARCACHE_WRBACK_READ_ALLOCATE;
                } else {
                    v.req_cached = ARCACHE_DEVICE_NON_BUFFERABLE;
                }
                if (coherence_ena_ == 1) {
                    v.req_ar_snoop = reqtype2arsnoop(req_mem_type_o.read());
                }
            } else {
                v.state = state_aw;
                v.req_wdata = req_mem_data_o.read();
                v.req_wstrb = req_mem_strob_o.read();
                if (req_mem_type_o.read()[REQ_MEM_TYPE_CACHED] == 1) {
                    v.req_cached = AWCACHE_WRBACK_WRITE_ALLOCATE;
                } else {
                    v.req_cached = AWCACHE_DEVICE_NON_BUFFERABLE;
                }
                if (coherence_ena_ == 1) {
                    v.req_aw_snoop = reqtype2awsnoop(req_mem_type_o.read());
                }
            }
        }
        break;
    case state_ar:
        vmsto.ar_valid = 1;
        vmsto.ar_bits.addr = r.req_addr.read();
        vmsto.ar_bits.cache = r.req_cached.read();
        vmsto.ar_bits.size = r.req_size.read();
        vmsto.ar_bits.prot = r.req_prot.read();
        vmsto.ar_snoop = r.req_ar_snoop.read();
        if ((i_msti.read().ar_ready == 1) || r.watchdog.read()[12]) {
            v.state = state_r;
        }
        break;
    case state_r:
        vmsto.r_ready = 1;
        v_mem_er_load_fault = (i_msti.read().r_resp[1] | r.watchdog.read()[12]);
        v_resp_mem_valid = i_msti.read().r_valid;
        // r_valid and r_last always should be in the same time
        if (((i_msti.read().r_valid == 1) && (i_msti.read().r_last == 1)) || r.watchdog.read()[12]) {
            v.state = state_idle;
        }
        break;
    case state_aw:
        vmsto.aw_valid = 1;
        vmsto.aw_bits.addr = r.req_addr.read();
        vmsto.aw_bits.cache = r.req_cached.read();
        vmsto.aw_bits.size = r.req_size.read();
        vmsto.aw_bits.prot = r.req_prot.read();
        vmsto.aw_snoop = r.req_aw_snoop.read();
        // axi lite to simplify L2-cache
        vmsto.w_valid = 1;
        vmsto.w_last = 1;
        vmsto.w_data = r.req_wdata.read();
        vmsto.w_strb = r.req_wstrb.read();
        if ((i_msti.read().aw_ready == 1) || r.watchdog.read()[12]) {
            if (i_msti.read().w_ready == 1) {
                v.state = state_b;
            } else {
                v.state = state_w;
            }
        }
        break;
    case state_w:
        // Shoudln't get here because of Lite interface:
        vmsto.w_valid = 1;
        vmsto.w_last = 1;
        vmsto.w_data = r.req_wdata.read();
        vmsto.w_strb = r.req_wstrb.read();
        if ((i_msti.read().w_ready == 1) || (r.watchdog.read()[12] == 1)) {
            v.state = state_b;
        }
        break;
    case state_b:
        vmsto.b_ready = 1;
        v_resp_mem_valid = i_msti.read().b_valid;
        v_mem_er_store_fault = (i_msti.read().b_resp[1] | r.watchdog.read()[12]);
        if ((i_msti.read().b_valid == 1) || r.watchdog.read()[12]) {
            v.state = state_idle;
        }
        break;
    default:
        break;
    }

    if (r.state.read() == state_idle) {
        v.watchdog = 0;
    } else {
        v.watchdog = (r.watchdog.read() + 1);
    }

    // Snoop processing:
    switch (r.snoop_state.read()) {
    case snoop_idle:
        v_snoop_next_ready = 1;
        break;
    case snoop_ac_wait_accept:
        req_snoop_valid = 1;
        vb_req_snoop_addr = r.ac_addr.read();
        vb_req_snoop_type = r.req_snoop_type.read();
        if (req_snoop_ready_o.read() == 1) {
            if (r.cache_access.read() == 0) {
                v.snoop_state = snoop_cr;
            } else {
                v.snoop_state = snoop_cd;
            }
        }
        break;
    case snoop_cr:
        if (resp_snoop_valid_o.read() == 1) {
            v_cr_valid = 1;
            if ((resp_snoop_flags_o.read()[TAG_FL_VALID] == 1)
                    && ((resp_snoop_flags_o.read()[DTAG_FL_SHARED] == 0)
                            || (r.ac_snoop.read() == AC_SNOOP_READ_UNIQUE))) {
                // Need second request with cache access
                v.cache_access = 1;
                // see table C3-21 "Snoop response bit allocation"
                vb_cr_resp[0] = 1;                          // will be Data transfer
                vb_cr_resp[4] = 1;                          // WasUnique
                if (r.ac_snoop.read() == AC_SNOOP_READ_UNIQUE) {
                    vb_req_snoop_type[SNOOP_REQ_TYPE_READCLEAN] = 1;
                } else {
                    vb_req_snoop_type[SNOOP_REQ_TYPE_READDATA] = 1;
                }
                v.req_snoop_type = vb_req_snoop_type;
                v.snoop_state = snoop_ac_wait_accept;
                if (i_msti.read().cr_ready == 1) {
                    v.snoop_state = snoop_ac_wait_accept;
                } else {
                    v.snoop_state = snoop_cr_wait_accept;
                }
            } else {
                vb_cr_resp = 0;
                if (i_msti.read().cr_ready == 1) {
                    v.snoop_state = snoop_idle;
                } else {
                    v.snoop_state = snoop_cr_wait_accept;
                }
            }
            v.cr_resp = vb_cr_resp;
        }
        break;
    case snoop_cr_wait_accept:
        v_cr_valid = 1;
        vb_cr_resp = r.cr_resp.read();
        if (i_msti.read().cr_ready == 1) {
            if (r.cache_access.read() == 1) {
                v.snoop_state = snoop_ac_wait_accept;
            } else {
                v.snoop_state = snoop_idle;
            }
        }
        break;
    case snoop_cd:
        if (resp_snoop_valid_o.read() == 1) {
            v_cd_valid = 1;
            vb_cd_data = resp_snoop_data_o.read();
            v.resp_snoop_data = resp_snoop_data_o.read();
            if (i_msti.read().cd_ready == 1) {
                v.snoop_state = snoop_idle;
            } else {
                v.snoop_state = snoop_cd_wait_accept;
            }
        }
        break;
    case snoop_cd_wait_accept:
        v_cd_valid = 1;
        vb_cd_data = r.resp_snoop_data.read();
        if (i_msti.read().cd_ready == 1) {
            v.snoop_state = snoop_idle;
        }
        break;
    default:
        break;
    }

    if ((coherence_ena_ == 1)
            && (v_snoop_next_ready == 1)
            && (i_msti.read().ac_valid == 1)) {
        req_snoop_valid = 1;
        v.cache_access = 0;
        vb_req_snoop_type = 0;                              // First snoop operation always just to read flags
        v.req_snoop_type = 0;
        vb_req_snoop_addr = i_msti.read().ac_addr;
        v.ac_addr = i_msti.read().ac_addr;
        v.ac_snoop = i_msti.read().ac_snoop;
        if (req_snoop_ready_o.read() == 1) {
            v.snoop_state = snoop_cr;
        } else {
            v.snoop_state = snoop_ac_wait_accept;
        }
    } else {
        v_snoop_next_ready = 1;
        v_cr_valid = 1;
    }

    if ((!async_reset_) && (i_nrst.read() == 0)) {
        RiverAmba_r_reset(v);
    }

    vmsto.ac_ready = v_snoop_next_ready;
    vmsto.cr_valid = v_cr_valid;
    vmsto.cr_resp = vb_cr_resp;
    vmsto.cd_valid = v_cd_valid;
    vmsto.cd_data = vb_cd_data;
    vmsto.cd_last = v_cd_valid;
    vmsto.rack = 0;
    vmsto.wack = 0;

    req_mem_ready_i = v_next_ready;
    resp_mem_valid_i = v_resp_mem_valid;
    resp_mem_data_i = i_msti.read().r_data;
    resp_mem_load_fault_i = v_mem_er_load_fault;
    resp_mem_store_fault_i = v_mem_er_store_fault;
    // AXI Snoop IOs:
    req_snoop_valid_i = req_snoop_valid;
    req_snoop_type_i = vb_req_snoop_type;
    req_snoop_addr_i = vb_req_snoop_addr;
    resp_snoop_ready_i = 1;

    o_msto = vmsto;
    o_dport = vdporto;                                      // systemc compatibility
    o_available = 1;
}

void RiverAmba::registers() {
    if ((async_reset_ == 1) && (i_nrst.read() == 0)) {
        RiverAmba_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

