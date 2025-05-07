#include <systemc.h>
#include "vips/clk/vip_clk.h"

using namespace debugger;

int sc_main(int argc, char *argv[]) {
    sc_trace_file *vcd_ = sc_create_vcd_trace_file(CMAKE_BINARY_DIR"/accel");
    vcd_->set_time_unit(1, SC_PS);


    sc_signal<bool> w_clk;
    vip_clk *clk = new vip_clk("clk0",
                               10);
    clk->o_clk(w_clk);
    clk->generateVCD(0, vcd_);


/*    uart0_ = new vip_uart_top("uart0",
                              asyncReset_.to_bool(),
                              0,
                              115200 * (1 << SIM_UART_SPEED_UP_RATE),
                              uart_scaler,
                              "uart");
    uart0_->i_nrst(w_sys_nrst);
    uart0_->i_rx(w_uart1_td);
    uart0_->o_tx(w_uart1_rd);
    uart0_->i_loopback_ena(w_uart1_loopback_ena);*/


    sc_start(100, SC_NS);

    if (vcd_) {
        sc_close_vcd_trace_file(vcd_);
    }
    delete clk;

    return 0;
}