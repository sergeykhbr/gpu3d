
/*
    Clock Detector
    This module measures the reference clocks
    Written by Marco Groeneveld, Gilbert Magnaye
    (c) 2014, 2015, 2016 by Xilinx inc.

    History
    -------
    v1.0 - Initial release
    v1.1 - Improved performance
    v1.2 - Added enable inputs
*/

`include "vid_phy_controller_v2_2_2_defs.v"
`default_nettype none

module exdes_vid_phy_controller_0_clkdet
#(
    parameter C_TXREFCLK_RDY_INVERT = 1             
)
(
    input wire          CLK_IN,                         // Clock
    
    // Reference clock
    input wire          TX_REFCLK_IN,                   // TX reference clock
    input wire          TX_REFCLK_LOCK_IN,              // TX lock
    input wire          RX_REFCLK_IN,                   // RX reference clock
    input wire          DRU_REFCLK_IN,                  // DRU reference clock
    
    // Control Register Interface
    input wire          clkdet_ctrl_run,                // from control reg [0]
    input wire          clkdet_ctrl_tx_tmr_clr,         // from control reg [1] --> self clearing
    input wire          clkdet_ctrl_rx_tmr_clr,         // from control reg [2] --> self clearing
    input wire          clkdet_ctrl_tx_freq_rst,        // from control reg [3] --> self clearing when clkdet_stat_tx_freq_zero 
    input wire          clkdet_ctrl_rx_freq_rst,        // from control reg [4] --> self clearing when clkdet_stat_rx_freq_zero 
    input wire   [7:0]  clkdet_ctrl_lock_cntr_threshold,// Frequency Lock Counter Threshold Register Interface
    input wire          clkdet_ctrl_tx_en,              // TX enable
    input wire          clkdet_ctrl_rx_en,              // RX enable
    
    // Status Register Interface
    output wire         clkdet_stat_tx_freq_zero,       // 
    output wire         clkdet_stat_rx_freq_zero,       // 
    output wire         clkdet_stat_tx_refclk_locked,   // 
    output wire         clkdet_stat_tx_refclk_lock_cap, // 
    
    // Frequency Counter Timeout Register Interface
    input wire  [31:0]  clkdet_freq_cntr_timeout,       // 
    
    // TX Frequency Register Interface
    output wire  [31:0]  clkdet_tx_freq,                // 
    
    // RX Frequency Register Interface
    output wire  [31:0]  clkdet_rx_freq,                // 
    
    // DRU Frequency Register Interface
    output wire  [31:0]  clkdet_dru_freq,               // 
    
    // TX Timer Register Interface
    input wire  [31:0]  clkdet_tx_tmr,                  // 
    input wire          clkdet_tx_tmr_ld,               // 
    
    // RX Timer Register Interface
    input wire  [31:0]  clkdet_rx_tmr,                  // 
    input wire          clkdet_rx_tmr_ld,               // 
    
    // Interrupt Register Interface
    output wire         clkdet_tx_tmr_evt,              // to interrupt register
    output wire         clkdet_tx_freq_evt,             // to interrupt register
    output wire         clkdet_rx_tmr_evt,              // to interrupt register
    output wire         clkdet_rx_freq_evt,             // to interrupt register
    
    // Interrupt Register Interface
    input wire          clkdet_tx_tmr_evt_clr,          // from w1c reg bit of clkdet_tx_tmr_evt
    input wire          clkdet_tx_freq_evt_clr,         // from w1c reg bit of clkdet_tx_freq_evt
    input wire          clkdet_rx_tmr_evt_clr,          // from w1c reg bit of clkdet_rx_tmr_evt
    input wire          clkdet_rx_freq_evt_clr          // from w1c reg bit of clkdet_rx_freq_evt
	
);

// Logic
// CLK domain

// State machine
enum int unsigned {
    sm_idle, sm_rst, sm_wait, sm_cnt, sm_ld
    } clk_sm_cur, clk_sm_nxt;

wire    [17:0]  rx_freq_from_cap;
logic   [35:0]  clk_rx_flt_a;
logic   [35:0]  clk_rx_flt_b;
logic   [17:0]  clk_rx_flt_q[0:1];
logic   [17:0]  clk_rx_flt_delta;
logic   [7:0]   clk_rx_flt_lock_cnt;
logic           clk_rx_flt_lock_cnt_end;
logic   [31:0]  clk_rx_freq;
logic           clk_rx_freq_lock;
wire            clk_rx_freq_lock_re;
wire            clk_rx_freq_lock_fe;
logic           clk_rx_freq_zero;
logic           clkdet_ctrl_rx_tmr_clr_del;
logic           clk_rx_tmr_evt; 
logic           clk_rx_freq_evt;

wire    [17:0]  tx_freq_from_cap;
wire            tx_lock_from_cap;
logic   [31:0]  clk_tx_freq;
logic           clk_tx_freq_lock;
wire            clk_tx_freq_lock_re;
wire            clk_tx_freq_lock_fe;
logic           clk_tx_freq_zero;
logic           clkdet_ctrl_tx_tmr_clr_del;
logic           clk_tx_tmr_evt; 
logic           clk_tx_freq_evt;

wire    [17:0]  dru_freq_from_cap;
logic   [31:0]  clk_dru_freq;
logic           clk_dru_freq_lock;

logic   [31:0]  clk_cnt;
logic   [31:0]  clk_cnt_in;
logic           clk_cnt_end;
logic           clk_cnt_ld;
logic           clk_freq_cap_vld;
logic           clk_freq_rst;
logic           clk_freq_rst_clr;
logic           clk_freq_rst_set;
logic           clk_freq_run;
logic           clk_freq_run_clr;
logic           clk_freq_run_set;
logic           clk_tx_freq_rst;
logic           clk_tx_freq_run;
logic           clk_rx_freq_rst;
logic           clk_rx_freq_run;
logic           clk_dru_freq_rst;
logic           clk_dru_freq_run;

logic   [31:0]  clk_tx_tmr;
logic           clk_tx_tmr_end;
wire            clk_tx_tmr_end_re;
logic   [31:0]  clk_rx_tmr;
logic           clk_rx_tmr_end;
wire            clk_rx_tmr_end_re;

// TXCLK domain
(* keep = "true" *) wire            txclk_rst;
logic   [17:0]                      txclk_freq_cnt;
wire                                txclk_run;

// RXCLK domain
(* keep = "true" *) wire            rxclk_rst;
logic   [17:0]                      rxclk_freq_cnt;
wire                                rxclk_run;

// DRUCLK domain
(* keep = "true" *) wire            druclk_rst;
logic   [17:0]                      druclk_freq_cnt;
wire                                druclk_run;


// TX lock input capture
xpm_cdc_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.SRC_INPUT_REG  (0                      )
	) 
	TX_LOCK_CAP_INST 
	(
		.src_clk         (TX_REFCLK_IN        ),
		.src_in          (~TX_REFCLK_LOCK_IN),
		.dest_clk        (CLK_IN),
        .dest_out        (tx_lock_from_cap)
	);
	

// TX frequency capture
xpm_cdc_array_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.WIDTH          ($bits(txclk_freq_cnt)  ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	TXCLK_FREQ_CAP_INST 
	(
		.src_clk         (TX_REFCLK_IN),
		.src_in          (txclk_freq_cnt),
		.dest_clk        (CLK_IN),
		.dest_out        (tx_freq_from_cap)
);

// RX frequency capture
xpm_cdc_array_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.WIDTH          ($bits(rxclk_freq_cnt)  ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	RXCLK_FREQ_CAP_INST 
	(
		.src_clk         (RX_REFCLK_IN),
		.src_in          (rxclk_freq_cnt),
		.dest_clk        (CLK_IN),
		.dest_out        (rx_freq_from_cap)
);

// DRU frequency capture
xpm_cdc_array_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.WIDTH          ($bits(druclk_freq_cnt) ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	DRUCLK_FREQ_CAP_INST 
	(
		.src_clk         (DRU_REFCLK_IN),
		.src_in          (druclk_freq_cnt),
		.dest_clk        (CLK_IN),
		.dest_out        (dru_freq_from_cap)
);

// TX Frequency
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run && clkdet_ctrl_tx_en)
        begin
            // Capture valid
            // This signal is generated by the state machine and it is asserted when the signal from the capture is stable
            if (clk_freq_cap_vld)
                clk_tx_freq <= {3'h0, tx_freq_from_cap, 11'h0};
        end
    
        // Idle
        else
            clk_tx_freq <= 0;
    end

// DRU Frequency
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Capture valid
            // This signal is generated by the state machine and it is asserted when the signal from the capture is stable
            if (clk_freq_cap_vld)
                clk_dru_freq <= {3'h0, dru_freq_from_cap, 11'h0};
        end
 
        // Idle
        else
            clk_dru_freq <= 0;
     end

// RX filter
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run && clkdet_ctrl_rx_en)
        begin
            // Capture valid
            // This signal is generated by the state machine and it is asserted when the signal from the capture is stable
            if (clk_freq_cap_vld)
            begin
                // The filter input A coefficient is 0.25
                clk_rx_flt_a <= rx_freq_from_cap * ((2**18)/4); 
                
                // The filter input B coefficient is 0.75
                clk_rx_flt_b <= clk_rx_flt_q[0] * (((2**18)/4) * 3); 
                
                // Filter output              
                for (int i=0; i<$size(clk_rx_flt_q); i++)
                begin
                    // First element
                    if (i==0)
                        clk_rx_flt_q[i] <= clk_rx_flt_a[35:18] + clk_rx_flt_b[35:18]; 
                    
                    else
                        clk_rx_flt_q[i] <= clk_rx_flt_q[i-1];
                end

                // RX frequency
                clk_rx_freq <= {3'h0, clk_rx_flt_q[0], 11'h0};           
            end
        end

        // Idle
        else
        begin
            clk_rx_flt_a        <= 0;
            clk_rx_flt_b        <= 0;
            for (int i=0; i<$size(clk_rx_flt_q); i++)
                clk_rx_flt_q[i] <= 0;
            clk_rx_freq         <= 0; 
        end
    end

// RX 
    always_ff @ (posedge CLK_IN)
    begin
        if (clk_rx_flt_q[0] == 0)
            clk_rx_flt_delta <= '1;
        else if (clk_rx_flt_q[0] > clk_rx_flt_q[1])
            clk_rx_flt_delta <= clk_rx_flt_q[0] - clk_rx_flt_q[1];
        else
            clk_rx_flt_delta <= clk_rx_flt_q[1] - clk_rx_flt_q[0];       
    end

// RX frequency lock counter
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run && clkdet_ctrl_rx_en)
        begin  
            if (clk_freq_cap_vld)
            begin
                // Increment
                if (clk_rx_flt_delta < 'h8)
                begin
                    // Only increment when the counter has not reached its maximum value
                    if (!clk_rx_flt_lock_cnt_end)
                        clk_rx_flt_lock_cnt <= clk_rx_flt_lock_cnt +'d1;
                end

                // Clear
                else
                    clk_rx_flt_lock_cnt <= 0;          
            end
        end

        // Idle
        else
            clk_rx_flt_lock_cnt <= 0;          
    end

// RX frequency lock counter end
    always_comb
    begin
        // The frequency is measured every 1/2048s ~= 0.4ms
        // One video frame is 16 ms
        // To prevent false lock a frequency lock is assumed
        // if the clock is stable for the duration of at least one video frame
        if (clk_rx_flt_lock_cnt >= clkdet_ctrl_lock_cntr_threshold)
            clk_rx_flt_lock_cnt_end = 1;
        else
            clk_rx_flt_lock_cnt_end = 0;
    end

// RX frequency lock
    always_ff @ (posedge CLK_IN)
    begin
        clk_rx_freq_lock <= clk_rx_flt_lock_cnt_end;
    end

// RX lock edge detector
vid_phy_controller_v2_2_2_lib_edge_v1_0
    RX_FREQ_LOCK_EDGE_INST
    (
        .CLK_IN     (CLK_IN),
        .CKE_IN     (1'b1),
        .A_IN       (clk_rx_freq_lock),
        .RE_OUT     (clk_rx_freq_lock_re),
        .FE_OUT     (clk_rx_freq_lock_fe)
    );

// TX frequency lock
// The frequency lock is asserted when the frequency is stable
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run && clkdet_ctrl_tx_en)
        begin
            // Wait for valid data from capture module
            if (clk_freq_cap_vld)
                clk_tx_freq_lock <= tx_lock_from_cap & ~clkdet_ctrl_tx_freq_rst;
        end

        else
            clk_tx_freq_lock <= 0;       
    end

// TX lock edge detector
vid_phy_controller_v2_2_2_lib_edge_v1_0
    TX_FREQ_LOCK_EDGE_INST
    (
        .CLK_IN     (CLK_IN),
        .CKE_IN     (1'b1),
        .A_IN       (clk_tx_freq_lock),
        .RE_OUT     (clk_tx_freq_lock_re),
        .FE_OUT     (clk_tx_freq_lock_fe)
    );

// DRU frequency lock
// The frequency lock is asserted when the frequency is stable
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            if (clk_freq_cap_vld)
                clk_dru_freq_lock <= 1;
        end

        // Idle
        else
            clk_dru_freq_lock <= 0;
    end

// TX timer
// This timer is used to to allow some time between TX events.
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Clear
            if (clkdet_ctrl_tx_tmr_clr)
                clk_tx_tmr <= 0;

            // Load
            else if (clkdet_tx_tmr_ld)
                clk_tx_tmr <= clkdet_tx_tmr;

            // Decrement
            else if (!clk_tx_tmr_end)
                clk_tx_tmr <= clk_tx_tmr - 'd1;
        end

        // Idle
        else
            clk_tx_tmr <= 0;
    end

// TX timer end
    always_comb
    begin
        if (clk_tx_tmr == 0)
            clk_tx_tmr_end = 1;
        else
            clk_tx_tmr_end = 0;
    end

// TX timer end edge detector
vid_phy_controller_v2_2_2_lib_edge_v1_0
    TX_TMR_END_EDGE_INST
    (
        .CLK_IN     (CLK_IN),
        .CKE_IN     (1'b1),
        .A_IN       (clk_tx_tmr_end),
        .RE_OUT     (clk_tx_tmr_end_re),
        .FE_OUT     ()
    );

// Timer clear delay
// The timer clear flag must be delayed for the timer event
    always_ff @ (posedge CLK_IN)
    begin
        clkdet_ctrl_tx_tmr_clr_del <= clkdet_ctrl_tx_tmr_clr;
        clkdet_ctrl_rx_tmr_clr_del <= clkdet_ctrl_rx_tmr_clr;
    end

// TX timer event
// The timer flag is set when the timer expires
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin

            // Clear
            // when the TX timer event bit is written in the status register
            if (clkdet_tx_tmr_evt_clr)
                clk_tx_tmr_evt <= 0;

            // Set
            // When the enable counter expires, the run bit is set and the timer is not cleared
            else if (clk_tx_tmr_end_re && clkdet_ctrl_run && !clkdet_ctrl_tx_tmr_clr_del)
                clk_tx_tmr_evt <= 1;
        end

        // Idle
        else
            clk_tx_tmr_evt <= 0;
    end

// RX timer
// This timer is used to to allow some time between RX events.
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin

            // Clear
            if (clkdet_ctrl_rx_tmr_clr)
                clk_rx_tmr <= 0;

            // Load
            else if (clkdet_rx_tmr_ld)
                clk_rx_tmr <= clkdet_rx_tmr;

            // Decrement
            else if (!clk_rx_tmr_end)
                clk_rx_tmr <= clk_rx_tmr - 'd1;
        end

        // Idle
        else
            clk_rx_tmr <= 0;
    end

// RX timer end
    always_comb
    begin
        if (clk_rx_tmr == 0)
            clk_rx_tmr_end = 1;
        else
            clk_rx_tmr_end = 0;
    end

// RX timer end edge detector
vid_phy_controller_v2_2_2_lib_edge_v1_0
    RX_TMR_END_EDGE_INST
    (
        .CLK_IN     (CLK_IN),
        .CKE_IN     (1'b1),
        .A_IN       (clk_rx_tmr_end),
        .RE_OUT     (clk_rx_tmr_end_re),
        .FE_OUT     ()
    );

// RX timer event
// The timer flag is set when the timer expires
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Clear
            // when the RX timer event bit is written in the status register
            if (clkdet_rx_tmr_evt_clr)
                clk_rx_tmr_evt <= 0;

            // Set
            // When the enable counter expires, the run bit is set and the timer is not cleared
            else if (clk_rx_tmr_end_re && clkdet_ctrl_run && !clkdet_ctrl_rx_tmr_clr_del)
                clk_rx_tmr_evt <= 1;
        end

        // Idle
        else
            clk_rx_tmr_evt <= 0;
    end

// TX frequency event
// This flag is set when the TX frequency has changed.
// It is cleared when the TX frequency register is read.
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Clear
            // When the tx frequency change bit in the status register is written.
            if (clkdet_tx_freq_evt_clr)
                clk_tx_freq_evt <= 0;

            // Set
            // When the frequency lock has changed
            else if (clk_tx_freq_lock_re || clk_tx_freq_lock_fe)
                clk_tx_freq_evt <= 1;
        end

        // Idle
        else
            clk_tx_freq_evt <= 0;
    end

// TX frequency zero
// This flag is set when the TX frequency is zero.
    always_comb
    begin
        if (clk_tx_freq_lock)
            clk_tx_freq_zero = 0;
        else
            clk_tx_freq_zero = 1;
    end

// RX frequency event
// This flag is set when the RX frequency has changed.
// It is cleared when the RX frequency register is read.
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin

            // Clear
            // When the tx frequency change bit in the status register is written.
            if (clkdet_rx_freq_evt_clr)
                clk_rx_freq_evt <= 0;

            // Set
            // When the frequency lock has changed
            else if (clk_rx_freq_lock_re || clk_rx_freq_lock_fe)
                clk_rx_freq_evt <= 1;
        end

        // Idle
        else
            clk_rx_freq_evt <= 0;
    end

// RX frequency zero
// This flag is set when the RX frequency is zero.
    always_comb
    begin
        if (clk_rx_freq_lock)
            clk_rx_freq_zero = 0;
        else
            clk_rx_freq_zero = 1;
    end

// Counter
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin

            // Load
            if (clk_cnt_ld)
                clk_cnt    <= clk_cnt_in;

            // Decrement
            else if (!clk_cnt_end)
                clk_cnt   <= clk_cnt - 'd1;
        end

        // Idle
        else
            clk_cnt <= 0;
    end

// Counter end
    always_comb
    begin
        if (clk_cnt == 'd0)
            clk_cnt_end = 1;
        else
            clk_cnt_end = 0;
    end

// Frequency reset
// This register is the reset for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Clear
            if (clk_freq_rst_clr)
                clk_freq_rst <= 0;
            // Set
            else if (clk_freq_rst_set)
                clk_freq_rst <= 1;
        end

        // Idle
        else
            clk_freq_rst <= 1;
    end

// TX Frequency reset
// This register is the reset for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_tx_freq_rst <= clk_freq_rst || clkdet_ctrl_tx_freq_rst;
    end

// RX Frequency reset
// This register is the reset for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_rx_freq_rst <= clk_freq_rst || clkdet_ctrl_rx_freq_rst;
    end

// DRU Frequency reset
// This register is the reset for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_dru_freq_rst <= clk_freq_rst;
    end

// Frequency run
// This register is the run for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
        begin
            // Clear
            if (clk_freq_run_clr)
                clk_freq_run <= 0;
            // Set
            else if (clk_freq_run_set)
                clk_freq_run <= 1;
        end

        // Idle
        else
            clk_freq_run <= 0;
    end

// TX Frequency run
// This register is the run for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_tx_freq_run <= clk_freq_run && (!clkdet_ctrl_tx_freq_rst);
    end

// RX Frequency run
// This register is the run for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_rx_freq_run <= clk_freq_run && (!clkdet_ctrl_rx_freq_rst);
    end

// DRU Frequency run
// This register is the run for the frequency counter in the reference clock domain
    always_ff @ (posedge CLK_IN)
    begin
        clk_dru_freq_run <= clk_freq_run;
    end

// Frequency detector State machine
    always_ff @ (posedge CLK_IN)
    begin
        // Run
        if (clkdet_ctrl_run)
            clk_sm_cur <= clk_sm_nxt;

        // Force to idle
        else
            clk_sm_cur <= sm_idle;
    end

// State machine decoder
    always_comb
    begin
        // Default
        clk_cnt_ld         = 0;
        clk_cnt_in         = 0;
        clk_freq_cap_vld   = 0;
        clk_freq_rst_set   = 0;
        clk_freq_rst_clr   = 0;
        clk_freq_run_set   = 0;
        clk_freq_run_clr   = 0;

        case (clk_sm_cur)

            sm_idle :
            begin
                if (clkdet_ctrl_run)
                begin
                    clk_cnt_in          = 'd255;
                    clk_cnt_ld          = 1;                    // Load counter
                    clk_freq_rst_set    = 1;                    // Assert frequency counter reset
                    clk_sm_nxt          = sm_rst;
                end

                else
                    clk_sm_nxt          = sm_idle;
            end

            sm_rst :
            begin
                if (clk_cnt_end)
                begin
                    clk_freq_rst_clr    = 1;                    // Release frequency counter reset
                    clk_cnt_in          = 'd255;
                    clk_cnt_ld          = 1;                    // Load counter
                    clk_sm_nxt          = sm_wait;
                end
                else
                    clk_sm_nxt          = sm_rst;
            end

            sm_wait :
            begin
                if (clk_cnt_end)
                begin
                    clk_freq_run_set    = 1;                                  // Run frequency counter
                    clk_cnt_in          = {11'h0, clkdet_freq_cntr_timeout[31:11]};    // The system frequency is divided by 2048
                    clk_cnt_ld          = 1;                                  // Load counter
                    clk_sm_nxt          = sm_cnt;
                end
                else
                    clk_sm_nxt          = sm_wait;
            end

            sm_cnt :
            begin
                if (clk_cnt_end)
                begin
                    clk_freq_run_clr    = 1;                    // Stop frequency counter
                    clk_cnt_in          = 'd255;
                    clk_cnt_ld          = 1;                    // Load counter
                    clk_sm_nxt          = sm_ld;
                end
                else
                    clk_sm_nxt          = sm_cnt;
            end

            sm_ld :
            begin
                if (clk_cnt_end)
                begin
                    clk_freq_cap_vld    = 1;                    // Set frequency capture valid flag to indicate the frequency value from the capture modules is valid
                    clk_sm_nxt          = sm_idle;
                end
                else
                    clk_sm_nxt          = sm_ld;
            end


            default :
            begin
                clk_sm_nxt              = sm_idle;
            end
        endcase
    end

// TX reference clock domain

// Reset synchronizer
xpm_cdc_async_rst 
	#(
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.RST_ACTIVE_HIGH(1                      )
	) 
	TXCLK_RST_INST 
	(
		.src_arst        (clk_tx_freq_rst),
		.dest_clk        (TX_REFCLK_IN),
		.dest_arst       (txclk_rst)
	);

// Run capture
xpm_cdc_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.SRC_INPUT_REG  (0                      )
	) 
	TXCLK_RUN_SYNC_INST 
	(
		.src_clk         (CLK_IN),
		.src_in          (clk_tx_freq_run),
		.dest_clk        (TX_REFCLK_IN),
		.dest_out        (txclk_run)
	);

// Frequency counter
    always_ff @ (posedge txclk_rst, posedge TX_REFCLK_IN)
    begin
        // Reset
        if (txclk_rst)
            txclk_freq_cnt <= 0;
        else
        begin
            // Run
            if (txclk_run)
                txclk_freq_cnt   <= txclk_freq_cnt + 'd1;
        end
    end

// RX reference clock domain

// Reset synchronizer
xpm_cdc_async_rst 
	#(
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.RST_ACTIVE_HIGH(1                      )
	) 
	RXCLK_RST_INST 
	(
		.src_arst        (clk_rx_freq_rst),
		.dest_clk        (RX_REFCLK_IN),
		.dest_arst       (rxclk_rst)
	);

// Run capture
xpm_cdc_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.SRC_INPUT_REG  (0                      )
	) 
	RXCLK_RUN_SYNC_INST 
	(
		.src_clk         (CLK_IN),
		.src_in          (clk_rx_freq_run),
		.dest_clk        (RX_REFCLK_IN),
		.dest_out        (rxclk_run)
	);

// Frequency counter
    always_ff @ (posedge rxclk_rst, posedge RX_REFCLK_IN)
    begin
        // Reset
        if (rxclk_rst)
            rxclk_freq_cnt <= 0;
        else
        begin
            // Run
            if (rxclk_run)
                rxclk_freq_cnt   <= rxclk_freq_cnt + 'd1;
        end
    end

// DRU reference clock domain

// Reset synchronizer
xpm_cdc_async_rst 
	#(
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.RST_ACTIVE_HIGH(1                      )
	) 
	DRUCLK_RST_INST 
	(
		.src_arst        (clk_dru_freq_rst),
		.dest_clk        (DRU_REFCLK_IN),
		.dest_arst       (druclk_rst)
	);

// Run capture
xpm_cdc_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.SRC_INPUT_REG  (0                      )
	) 
	DRUCLK_RUN_SYNC_INST 
	(
		.src_clk         (CLK_IN),
		.src_in          (clk_dru_freq_run),
		.dest_clk        (DRU_REFCLK_IN),
		.dest_out        (druclk_run)
	);

// Frequency counter
    always_ff @ (posedge druclk_rst, posedge DRU_REFCLK_IN)
    begin
        // Reset
        if (druclk_rst)
            druclk_freq_cnt <= 0;
        else
        begin
            // Run
            if (druclk_run)
                druclk_freq_cnt   <= druclk_freq_cnt + 'd1;
        end
    end

// Outputs
    assign clkdet_tx_freq                   = clk_tx_freq_lock  ? clk_tx_freq  : 0;
    assign clkdet_rx_freq                   = clk_rx_freq_lock  ? clk_rx_freq  : 0;
    assign clkdet_dru_freq                  = clk_dru_freq_lock ? clk_dru_freq : 0;
    assign clkdet_stat_tx_refclk_lock_cap   = tx_lock_from_cap;
    assign clkdet_stat_tx_refclk_locked     = clk_tx_freq_lock;
    assign clkdet_stat_tx_freq_zero         = clk_tx_freq_zero;
    assign clkdet_stat_rx_freq_zero         = clk_rx_freq_zero;
    assign clkdet_tx_tmr_evt                = clk_tx_tmr_evt;
    assign clkdet_rx_tmr_evt                = clk_rx_tmr_evt;
    assign clkdet_tx_freq_evt               = clk_tx_freq_evt;
    assign clkdet_rx_freq_evt               = clk_rx_freq_evt;
endmodule

`default_nettype wire

