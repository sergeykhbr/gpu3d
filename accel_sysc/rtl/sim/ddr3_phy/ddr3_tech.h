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
#include "../pll/pll_generic.h"
#include "api_core.h"

namespace debugger {

template<int ROW_BITS = 14,                                 // Row address width
         int BA_BITS = 3,                                   // Bank address width
         int LANE_TOTAL = 8,                                // Lane is: 8 dq (byte) + 1 dm (mask) + 1 dqs_n/dqs_p (strob)
         int DUAL_RANK = 0,                                 // 1=Enable dual DDR; 0=disable.
         int AXI_SIZE_LOG2 = 30,                            // 30 = 1GB (default). Bus address width
         int AXI_ID_BITS = 5>                               // Custom ID field width
SC_MODULE(ddr3_tech) {
 public:
    sc_in<bool> i_nrst;                                     // DDR reset active LOW. Connected to IODELAY
    sc_in<bool> i_ctrl_clk;                                 // DDR Controller clock: MIG 200 MHz, UberDDR 1:4 PHY clock
    sc_in<bool> i_phy_clk;                                  // PHY clock default for DDR3 800 MHz
    sc_in<bool> i_ref_clk200;                               // Reference clock for internal mmcm
    // to debug PIN:
    sc_out<bool> o_ui_nrst;                                 // xilinx generte ddr clock inside ddr controller
    sc_out<bool> o_ui_clk;                                  // xilinx generte ddr clock inside ddr controller
    // DDR signals:
    sc_out<bool> o_ddr3_reset_n;
    sc_out<bool> o_ddr3_ck_n;
    sc_out<bool> o_ddr3_ck_p;
    sc_out<bool> o_ddr3_cke;
    sc_out<bool> o_ddr3_cs_n;                               // Chip select active LOW
    sc_out<bool> o_ddr3_ras_n;
    sc_out<bool> o_ddr3_cas_n;
    sc_out<bool> o_ddr3_we_n;                               // Write enable active LOW
    sc_out<sc_uint<LANE_TOTAL>> o_ddr3_dm;                  // Data mask
    sc_out<sc_uint<BA_BITS>> o_ddr3_ba;                     // Bank address
    sc_out<sc_uint<ROW_BITS>> o_ddr3_addr;
    sc_inout<sc_uint<(8 * LANE_TOTAL)>> io_ddr3_dq;
    sc_inout<sc_uint<LANE_TOTAL>> io_ddr3_dqs_n;            // Data strob positive
    sc_inout<sc_uint<LANE_TOTAL>> io_ddr3_dqs_p;            // Data strob negative
    sc_out<bool> o_ddr3_odt;                                // on-die termination
    sc_out<bool> o_init_calib_done;                         // DDR calibration done, active HIGH
    sc_out<sc_uint<12>> o_temperature;                      // Device temperature
    sc_in<bool> i_sr_req;                                   // Self-refresh request (low-power mode)
    sc_in<bool> i_ref_req;                                  // Periodic refresh request ~7.8 us
    sc_in<bool> i_zq_req;                                   // ZQ calibration request. Startup and runtime maintenance
    sc_out<bool> o_sr_active;                               // Self-resfresh is active (low-power mode or sleep)
    sc_out<bool> o_ref_ack;                                 // Refresh request acknoledged
    sc_out<bool> o_zq_ack;                                  // ZQ calibration request acknowledged
    // AXI slave interface:
    sc_in<sc_uint<AXI_ID_BITS>> i_aw_id;
    sc_in<sc_uint<AXI_SIZE_LOG2>> i_aw_addr;
    sc_in<sc_uint<8>> i_aw_len;
    sc_in<sc_uint<3>> i_aw_size;
    sc_in<sc_uint<2>> i_aw_burst;
    sc_in<bool> i_aw_lock;
    sc_in<sc_uint<4>> i_aw_cache;
    sc_in<sc_uint<3>> i_aw_prot;
    sc_in<sc_uint<4>> i_aw_qos;
    sc_in<bool> i_aw_valid;
    sc_out<bool> o_aw_ready;
    sc_in<sc_uint<64>> i_w_data;
    sc_in<sc_uint<8>> i_w_strb;
    sc_in<bool> i_w_last;
    sc_in<bool> i_w_valid;
    sc_out<bool> o_w_ready;
    sc_in<bool> i_b_ready;
    sc_out<sc_uint<AXI_ID_BITS>> o_b_id;
    sc_out<sc_uint<2>> o_b_resp;
    sc_out<bool> o_b_valid;
    sc_in<sc_uint<AXI_ID_BITS>> i_ar_id;
    sc_in<sc_uint<AXI_SIZE_LOG2>> i_ar_addr;
    sc_in<sc_uint<8>> i_ar_len;
    sc_in<sc_uint<3>> i_ar_size;
    sc_in<sc_uint<2>> i_ar_burst;
    sc_in<bool> i_ar_lock;
    sc_in<sc_uint<4>> i_ar_cache;
    sc_in<sc_uint<3>> i_ar_prot;
    sc_in<sc_uint<4>> i_ar_qos;
    sc_in<bool> i_ar_valid;
    sc_out<bool> o_ar_ready;
    sc_in<bool> i_r_ready;
    sc_out<sc_uint<AXI_ID_BITS>> o_r_id;
    sc_out<sc_uint<64>> o_r_data;
    sc_out<sc_uint<2>> o_r_resp;
    sc_out<bool> o_r_last;
    sc_out<bool> o_r_valid;

    void init();
    void comb();
    void ff();
    void registers();

    ddr3_tech(sc_module_name name);
    virtual ~ddr3_tech();

    void generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd);

 private:
    struct ddr3_tech_registers {
        sc_signal<sc_uint<8>> ddr_calib;
    };

    void ddr3_tech_r_reset(ddr3_tech_registers& iv) {
        iv.ddr_calib = 0;
    }

    sc_signal<bool> w_ui_nrst;
    sc_signal<bool> w_ui_clk;
    sc_signal<bool> w_init_calib_done;
    sc_signal<sc_uint<12>> wb_device_temp;
    sc_signal<bool> w_sr_active;
    sc_signal<bool> w_ref_ack;
    sc_signal<bool> w_zq_ack;
    sc_uint<64> mem0[16];
    ddr3_tech_registers v;
    ddr3_tech_registers r;

    pll_generic *clk0;

};

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::ddr3_tech(sc_module_name name)
    : sc_module(name),
    i_nrst("i_nrst"),
    i_ctrl_clk("i_ctrl_clk"),
    i_phy_clk("i_phy_clk"),
    i_ref_clk200("i_ref_clk200"),
    o_ui_nrst("o_ui_nrst"),
    o_ui_clk("o_ui_clk"),
    o_ddr3_reset_n("o_ddr3_reset_n"),
    o_ddr3_ck_n("o_ddr3_ck_n"),
    o_ddr3_ck_p("o_ddr3_ck_p"),
    o_ddr3_cke("o_ddr3_cke"),
    o_ddr3_cs_n("o_ddr3_cs_n"),
    o_ddr3_ras_n("o_ddr3_ras_n"),
    o_ddr3_cas_n("o_ddr3_cas_n"),
    o_ddr3_we_n("o_ddr3_we_n"),
    o_ddr3_dm("o_ddr3_dm"),
    o_ddr3_ba("o_ddr3_ba"),
    o_ddr3_addr("o_ddr3_addr"),
    io_ddr3_dq("io_ddr3_dq"),
    io_ddr3_dqs_n("io_ddr3_dqs_n"),
    io_ddr3_dqs_p("io_ddr3_dqs_p"),
    o_ddr3_odt("o_ddr3_odt"),
    o_init_calib_done("o_init_calib_done"),
    o_temperature("o_temperature"),
    i_sr_req("i_sr_req"),
    i_ref_req("i_ref_req"),
    i_zq_req("i_zq_req"),
    o_sr_active("o_sr_active"),
    o_ref_ack("o_ref_ack"),
    o_zq_ack("o_zq_ack"),
    i_aw_id("i_aw_id"),
    i_aw_addr("i_aw_addr"),
    i_aw_len("i_aw_len"),
    i_aw_size("i_aw_size"),
    i_aw_burst("i_aw_burst"),
    i_aw_lock("i_aw_lock"),
    i_aw_cache("i_aw_cache"),
    i_aw_prot("i_aw_prot"),
    i_aw_qos("i_aw_qos"),
    i_aw_valid("i_aw_valid"),
    o_aw_ready("o_aw_ready"),
    i_w_data("i_w_data"),
    i_w_strb("i_w_strb"),
    i_w_last("i_w_last"),
    i_w_valid("i_w_valid"),
    o_w_ready("o_w_ready"),
    i_b_ready("i_b_ready"),
    o_b_id("o_b_id"),
    o_b_resp("o_b_resp"),
    o_b_valid("o_b_valid"),
    i_ar_id("i_ar_id"),
    i_ar_addr("i_ar_addr"),
    i_ar_len("i_ar_len"),
    i_ar_size("i_ar_size"),
    i_ar_burst("i_ar_burst"),
    i_ar_lock("i_ar_lock"),
    i_ar_cache("i_ar_cache"),
    i_ar_prot("i_ar_prot"),
    i_ar_qos("i_ar_qos"),
    i_ar_valid("i_ar_valid"),
    o_ar_ready("o_ar_ready"),
    i_r_ready("i_r_ready"),
    o_r_id("o_r_id"),
    o_r_data("o_r_data"),
    o_r_resp("o_r_resp"),
    o_r_last("o_r_last"),
    o_r_valid("o_r_valid") {

    clk0 = 0;

    clk0 = new pll_generic("clk0",
                            5.0);
    clk0->o_clk(w_ui_clk);

    SC_THREAD(init);

    SC_METHOD(comb);
    sensitive << i_nrst;
    sensitive << i_ctrl_clk;
    sensitive << i_phy_clk;
    sensitive << i_ref_clk200;
    sensitive << io_ddr3_dq;
    sensitive << io_ddr3_dqs_n;
    sensitive << io_ddr3_dqs_p;
    sensitive << i_sr_req;
    sensitive << i_ref_req;
    sensitive << i_zq_req;
    sensitive << i_aw_id;
    sensitive << i_aw_addr;
    sensitive << i_aw_len;
    sensitive << i_aw_size;
    sensitive << i_aw_burst;
    sensitive << i_aw_lock;
    sensitive << i_aw_cache;
    sensitive << i_aw_prot;
    sensitive << i_aw_qos;
    sensitive << i_aw_valid;
    sensitive << i_w_data;
    sensitive << i_w_strb;
    sensitive << i_w_last;
    sensitive << i_w_valid;
    sensitive << i_b_ready;
    sensitive << i_ar_id;
    sensitive << i_ar_addr;
    sensitive << i_ar_len;
    sensitive << i_ar_size;
    sensitive << i_ar_burst;
    sensitive << i_ar_lock;
    sensitive << i_ar_cache;
    sensitive << i_ar_prot;
    sensitive << i_ar_qos;
    sensitive << i_ar_valid;
    sensitive << i_r_ready;
    sensitive << w_ui_nrst;
    sensitive << w_ui_clk;
    sensitive << w_init_calib_done;
    sensitive << wb_device_temp;
    sensitive << w_sr_active;
    sensitive << w_ref_ack;
    sensitive << w_zq_ack;
    sensitive << r.ddr_calib;

    SC_METHOD(ff);
    sensitive << w_ui_clk.posedge_event();

    SC_METHOD(registers);
    sensitive << w_ui_nrst;
    sensitive << w_ui_clk.posedge_event();
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::~ddr3_tech() {
    if (clk0) {
        delete clk0;
    }
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
void ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::generateVCD(sc_trace_file *i_vcd, sc_trace_file *o_vcd) {
    std::string pn(name());
    if (o_vcd) {
        sc_trace(o_vcd, i_ctrl_clk, i_ctrl_clk.name());
        sc_trace(o_vcd, i_phy_clk, i_phy_clk.name());
        sc_trace(o_vcd, i_ref_clk200, i_ref_clk200.name());
        sc_trace(o_vcd, o_ui_nrst, o_ui_nrst.name());
        sc_trace(o_vcd, o_ui_clk, o_ui_clk.name());
        sc_trace(o_vcd, o_ddr3_reset_n, o_ddr3_reset_n.name());
        sc_trace(o_vcd, o_ddr3_ck_n, o_ddr3_ck_n.name());
        sc_trace(o_vcd, o_ddr3_ck_p, o_ddr3_ck_p.name());
        sc_trace(o_vcd, o_ddr3_cke, o_ddr3_cke.name());
        sc_trace(o_vcd, o_ddr3_cs_n, o_ddr3_cs_n.name());
        sc_trace(o_vcd, o_ddr3_ras_n, o_ddr3_ras_n.name());
        sc_trace(o_vcd, o_ddr3_cas_n, o_ddr3_cas_n.name());
        sc_trace(o_vcd, o_ddr3_we_n, o_ddr3_we_n.name());
        sc_trace(o_vcd, o_ddr3_dm, o_ddr3_dm.name());
        sc_trace(o_vcd, o_ddr3_ba, o_ddr3_ba.name());
        sc_trace(o_vcd, o_ddr3_addr, o_ddr3_addr.name());
        sc_trace(o_vcd, io_ddr3_dq, io_ddr3_dq.name());
        sc_trace(o_vcd, io_ddr3_dqs_n, io_ddr3_dqs_n.name());
        sc_trace(o_vcd, io_ddr3_dqs_p, io_ddr3_dqs_p.name());
        sc_trace(o_vcd, o_ddr3_odt, o_ddr3_odt.name());
        sc_trace(o_vcd, o_init_calib_done, o_init_calib_done.name());
        sc_trace(o_vcd, o_temperature, o_temperature.name());
        sc_trace(o_vcd, i_sr_req, i_sr_req.name());
        sc_trace(o_vcd, i_ref_req, i_ref_req.name());
        sc_trace(o_vcd, i_zq_req, i_zq_req.name());
        sc_trace(o_vcd, o_sr_active, o_sr_active.name());
        sc_trace(o_vcd, o_ref_ack, o_ref_ack.name());
        sc_trace(o_vcd, o_zq_ack, o_zq_ack.name());
        sc_trace(o_vcd, i_aw_id, i_aw_id.name());
        sc_trace(o_vcd, i_aw_addr, i_aw_addr.name());
        sc_trace(o_vcd, i_aw_len, i_aw_len.name());
        sc_trace(o_vcd, i_aw_size, i_aw_size.name());
        sc_trace(o_vcd, i_aw_burst, i_aw_burst.name());
        sc_trace(o_vcd, i_aw_lock, i_aw_lock.name());
        sc_trace(o_vcd, i_aw_cache, i_aw_cache.name());
        sc_trace(o_vcd, i_aw_prot, i_aw_prot.name());
        sc_trace(o_vcd, i_aw_qos, i_aw_qos.name());
        sc_trace(o_vcd, i_aw_valid, i_aw_valid.name());
        sc_trace(o_vcd, o_aw_ready, o_aw_ready.name());
        sc_trace(o_vcd, i_w_data, i_w_data.name());
        sc_trace(o_vcd, i_w_strb, i_w_strb.name());
        sc_trace(o_vcd, i_w_last, i_w_last.name());
        sc_trace(o_vcd, i_w_valid, i_w_valid.name());
        sc_trace(o_vcd, o_w_ready, o_w_ready.name());
        sc_trace(o_vcd, i_b_ready, i_b_ready.name());
        sc_trace(o_vcd, o_b_id, o_b_id.name());
        sc_trace(o_vcd, o_b_resp, o_b_resp.name());
        sc_trace(o_vcd, o_b_valid, o_b_valid.name());
        sc_trace(o_vcd, i_ar_id, i_ar_id.name());
        sc_trace(o_vcd, i_ar_addr, i_ar_addr.name());
        sc_trace(o_vcd, i_ar_len, i_ar_len.name());
        sc_trace(o_vcd, i_ar_size, i_ar_size.name());
        sc_trace(o_vcd, i_ar_burst, i_ar_burst.name());
        sc_trace(o_vcd, i_ar_lock, i_ar_lock.name());
        sc_trace(o_vcd, i_ar_cache, i_ar_cache.name());
        sc_trace(o_vcd, i_ar_prot, i_ar_prot.name());
        sc_trace(o_vcd, i_ar_qos, i_ar_qos.name());
        sc_trace(o_vcd, i_ar_valid, i_ar_valid.name());
        sc_trace(o_vcd, o_ar_ready, o_ar_ready.name());
        sc_trace(o_vcd, i_r_ready, i_r_ready.name());
        sc_trace(o_vcd, o_r_id, o_r_id.name());
        sc_trace(o_vcd, o_r_data, o_r_data.name());
        sc_trace(o_vcd, o_r_resp, o_r_resp.name());
        sc_trace(o_vcd, o_r_last, o_r_last.name());
        sc_trace(o_vcd, o_r_valid, o_r_valid.name());
        sc_trace(o_vcd, r.ddr_calib, pn + ".r.ddr_calib");
    }

    if (clk0) {
        clk0->generateVCD(i_vcd, o_vcd);
    }
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
void ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::init() {
    w_ui_nrst = 0;
    wait(static_cast<int>(250.0), SC_NS);
    w_ui_nrst = 1;
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
void ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::comb() {
    v = r;

    if (r.ddr_calib.read()[7] == 0) {
        v.ddr_calib = (r.ddr_calib.read() + 1);
    }

    w_init_calib_done = r.ddr_calib.read()[7];
    o_ui_nrst = w_ui_nrst.read();
    o_ui_clk = w_ui_clk.read();
    o_init_calib_done = w_init_calib_done.read();
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
void ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::ff() {
}

template<int ROW_BITS, int BA_BITS, int LANE_TOTAL, int DUAL_RANK, int AXI_SIZE_LOG2, int AXI_ID_BITS>
void ddr3_tech<ROW_BITS, BA_BITS, LANE_TOTAL, DUAL_RANK, AXI_SIZE_LOG2, AXI_ID_BITS>::registers() {
    if (w_ui_nrst.read() == 0) {
        ddr3_tech_r_reset(r);
    } else {
        r = v;
    }
}

}  // namespace debugger

