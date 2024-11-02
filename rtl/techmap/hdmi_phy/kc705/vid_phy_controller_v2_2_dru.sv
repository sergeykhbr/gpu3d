/*
    DRU

    (c) 2015 by Xilinx, Inc.
    Written by Marco Groeneveld, Gilbert Magnaye

    History
    -------
    v1.0 - Initial release
*/

`default_nettype none

module vid_phy_controller_v2_2_2_dru #
(
    // Users to add parameters here
    parameter integer       WIDTH_OUT  = 40
)
(
    // Clocks
    input wire              DRU_CLK_IN,            // Link clock

    // Config and status
    output wire             DRU_ACT_OUT,           // Active 0-disabled / 1-active

    // Input
    input wire   [39:0]     DRU_DATA_IN,           // Data in

    // Link output
    output wire  [39:0]     DRU_DATA_OUT,          // Data out
    output wire             DRU_DATA_EN_OUT,       // Data enable

    input wire              dru_ctrl_rst,          // Reset
    input wire              dru_ctrl_enable,       // Enable
    input wire              dru_ctrl_ph_est_dis,   // Phase Error Estimation method

    input wire  [36:0]      dru_center_freq,       // DRU Center Frequency
    input wire  [4:0]       dru_gain_g1,           // DRU Direct Gain
    input wire  [4:0]       dru_gain_g1_p,         // DRU Integral Pre-Gain
    input wire  [4:0]       dru_gain_g2,           // DRU Integral Post-Gain

    output wire [7:0]       dru_version            // DRU Version
);

// Signal
wire            lrst_from_rst;
wire    [19:0]  dat_to_dru;
wire    [39:0]  dat_from_dru;
wire            de_from_dru;
wire    [31:0]  ctrl_from_dru;
wire    [31:0]  integ_from_dru;
wire    [31:0]  direct_from_dru;

(* keep = "true" *) wire dru_clk_i;
assign dru_clk_i = DRU_CLK_IN;
genvar i;

// Dru reset
vid_phy_controller_v2_2_2_lib_rst_v1_0
    LRST_INST
    (
        .RST_IN     (dru_ctrl_rst),
        .CLK_IN     (dru_clk_i),
        .RST_OUT    (lrst_from_rst)
    );

// NIDRU
	nidru_20_wrapper
	#(
	//-- S_MAX              : in std_logic_vector (9 downto 0):= "1111111111";  -- max number of extracted bits, not coded
	.S_MAX              ('d10), // max number of extracted bits, decimal
	.MASK_CG            ({16{1'b1}}),  // place same number of LSb zeros
	.MASK_PD            ({16{1'b1}}),  // place same number of LSb zeros
	.MASK_VCO           ({37{1'b1}}),  // plase same number of LSb zeros
	//-- EN_INTEG           : in std_logic := '1';    -- by default 1
	//-- PH_EST_DIS         : in std_logic := '0';    -- by defauls 0
	.WDT_OUT            (WIDTH_OUT)    //  -- output width
	)
	NIDRU_INST
	(
		.RST            (lrst_from_rst), // ative high
		.RST_FREQ       (lrst_from_rst), // active high
		.CLK            (dru_clk_i),
		.DT_IN          (dat_to_dru),
		.CENTER_F       (dru_center_freq),
		.EN             (dru_ctrl_enable),
		.G1             (dru_gain_g1),
		.G1_P           (dru_gain_g1_p),
		.G2             (dru_gain_g2),
		.PH_OUT         (),
		.INTEG          (integ_from_dru),
		.DIRECT         (direct_from_dru),
		.CTRL           (ctrl_from_dru),
		.AL_PPM         (),
		//PL                 : in   std_logic;   --default 0
		//PHASE_IN           : in   std_logic_vector(31 downto 0);
		.EN_INTEG       (1'b1),                 // by default 1
		.PH_EST_DIS     (dru_ctrl_ph_est_dis),  // by default 0
		.VER            (dru_version),
		.RECCLK         (),
		.SAMV           (),
		.SAM            (),
		.EN_OUT         (de_from_dru),       // Data enable
		.DOUT           (dat_from_dru[WIDTH_OUT-1:0])          // Data
	);

    // Link data to DRU
    assign dat_to_dru = DRU_DATA_IN;

// Output
    assign DRU_ACT_OUT     = dru_ctrl_enable;
    assign DRU_DATA_OUT    = (dru_ctrl_enable) ? dat_from_dru : DRU_DATA_IN;
    assign DRU_DATA_EN_OUT = (dru_ctrl_enable) ? de_from_dru : 1'b1;

endmodule

`default_nettype wire
