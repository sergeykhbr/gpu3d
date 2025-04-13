//--------------------------------------------------------------------------
//! @author     Sergey Khabarov
//! @brief      Virtual Gigabits buffer with the differential signals.
//--------------------------------------------------------------------------

module igdsbuf_tech (
    input gclk_p,
    input gclk_n,
    output logic o_clk
);
 
    IBUFDS_GTE2 x1(.I(gclk_p), .IB(gclk_n), .CEB(1'b0), .O(o_clk), .ODIV2());
 
endmodule
