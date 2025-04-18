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

namespace debugger {



class pcie_dma64_out_type {
 public:
    pcie_dma64_out_type() {
        ready = 0;
        data = 0;
        strob = 0;
        last = 0;
        valid = 0;
    }

    pcie_dma64_out_type(bool ready_,
                        sc_uint<64> data_,
                        sc_uint<8> strob_,
                        bool last_,
                        bool valid_) {
        ready = ready_;
        data = data_;
        strob = strob_;
        last = last_;
        valid = valid_;
    }

    inline bool operator == (const pcie_dma64_out_type &rhs) const {
        bool ret = true;
        ret = ret
            && rhs.ready == ready
            && rhs.data == data
            && rhs.strob == strob
            && rhs.last == last
            && rhs.valid == valid;
        return ret;
    }

    inline pcie_dma64_out_type& operator = (const pcie_dma64_out_type &rhs) {
        ready = rhs.ready;
        data = rhs.data;
        strob = rhs.strob;
        last = rhs.last;
        valid = rhs.valid;
        return *this;
    }

    inline friend void sc_trace(sc_trace_file *tf,
                                const pcie_dma64_out_type&v,
                                const std::string &NAME) {
        sc_trace(tf, v.ready, NAME + "_ready");
        sc_trace(tf, v.data, NAME + "_data");
        sc_trace(tf, v.strob, NAME + "_strob");
        sc_trace(tf, v.last, NAME + "_last");
        sc_trace(tf, v.valid, NAME + "_valid");
    }

    inline friend ostream &operator << (ostream &os,
                                        pcie_dma64_out_type const &v) {
        os << "("
        << v.ready << ","
        << v.data << ","
        << v.strob << ","
        << v.last << ","
        << v.valid << ")";
        return os;
    }

 public:
    bool ready;
    sc_uint<64> data;
    sc_uint<8> strob;
    bool last;
    bool valid;
};

// @brief   DMA output empty values.
static const pcie_dma64_out_type pcie_dma64_out_none;

// @brief DMA device input signals.
class pcie_dma64_in_type {
 public:
    pcie_dma64_in_type() {
        ready = 0;
        data = 0;
        strob = 0;
        last = 0;
        bar_hit = 0;
        err_fwd = 0;
        ecrc_err = 0;
        valid = 0;
    }

    pcie_dma64_in_type(bool ready_,
                       sc_uint<64> data_,
                       sc_uint<8> strob_,
                       bool last_,
                       sc_uint<7> bar_hit_,
                       bool err_fwd_,
                       bool ecrc_err_,
                       bool valid_) {
        ready = ready_;
        data = data_;
        strob = strob_;
        last = last_;
        bar_hit = bar_hit_;
        err_fwd = err_fwd_;
        ecrc_err = ecrc_err_;
        valid = valid_;
    }

    inline bool operator == (const pcie_dma64_in_type &rhs) const {
        bool ret = true;
        ret = ret
            && rhs.ready == ready
            && rhs.data == data
            && rhs.strob == strob
            && rhs.last == last
            && rhs.bar_hit == bar_hit
            && rhs.err_fwd == err_fwd
            && rhs.ecrc_err == ecrc_err
            && rhs.valid == valid;
        return ret;
    }

    inline pcie_dma64_in_type& operator = (const pcie_dma64_in_type &rhs) {
        ready = rhs.ready;
        data = rhs.data;
        strob = rhs.strob;
        last = rhs.last;
        bar_hit = rhs.bar_hit;
        err_fwd = rhs.err_fwd;
        ecrc_err = rhs.ecrc_err;
        valid = rhs.valid;
        return *this;
    }

    inline friend void sc_trace(sc_trace_file *tf,
                                const pcie_dma64_in_type&v,
                                const std::string &NAME) {
        sc_trace(tf, v.ready, NAME + "_ready");
        sc_trace(tf, v.data, NAME + "_data");
        sc_trace(tf, v.strob, NAME + "_strob");
        sc_trace(tf, v.last, NAME + "_last");
        sc_trace(tf, v.bar_hit, NAME + "_bar_hit");
        sc_trace(tf, v.err_fwd, NAME + "_err_fwd");
        sc_trace(tf, v.ecrc_err, NAME + "_ecrc_err");
        sc_trace(tf, v.valid, NAME + "_valid");
    }

    inline friend ostream &operator << (ostream &os,
                                        pcie_dma64_in_type const &v) {
        os << "("
        << v.ready << ","
        << v.data << ","
        << v.strob << ","
        << v.last << ","
        << v.bar_hit << ","
        << v.err_fwd << ","
        << v.ecrc_err << ","
        << v.valid << ")";
        return os;
    }

 public:
    bool ready;
    sc_uint<64> data;
    sc_uint<8> strob;
    bool last;
    sc_uint<7> bar_hit;                                     // [0]=BAR0, [1]=BAR1.. [5]=BAR5, [6]=Expansion ROM
    bool err_fwd;                                           // Receive error Forward: packet in progress is error-poisoned
    bool ecrc_err;                                          // Receive ECRC Error: current packet has an ECRC error. Asserted at the packet EOF
    bool valid;
};

static const pcie_dma64_in_type pcie_dma64_in_none;

}  // namespace debugger

