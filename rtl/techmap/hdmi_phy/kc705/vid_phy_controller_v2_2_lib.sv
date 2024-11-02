/*
	Library

	Written by Marco Groeneveld
	mgroenev@xilinx.com
	(c) 2014, 2015 by Xilinx Inc.

	History
	-------
	v1.0 - initial release
*/
`timescale 1 ns / 1 ps
`include "vid_phy_controller_v2_2_2_defs.v"
`default_nettype none

/*
	Reset synchronizer
*/
module vid_phy_controller_v2_2_2_lib_rst_v1_0
(
	input wire	RST_IN,
	input wire	CLK_IN,
	output wire	RST_OUT
);

// Signals
(* async_reg = "true" *) logic	[6:0]	clk_rst;

// Logic
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_rst <= '1;
		else
			clk_rst <= {clk_rst[$bits(clk_rst)-2:0], 1'b0};
	end

// Output
	assign RST_OUT = clk_rst[$bits(clk_rst)-1];

endmodule

/*
	Data synchronizer
	This module synchronizes a single signal in the target clock domain.
	This is used for hand-shake signals
*/
module vid_phy_controller_v2_2_2_lib_sync_v1_0
#(
	parameter	LEN = 5
)
(
	input wire	CLK_IN,				// Clock
	input wire	DAT_IN,				// Data in
	output wire	DAT_OUT				// Data out
);

// Signals
(* async_reg = "true" *) logic	[LEN-1:0]	clk_sync;

// Logic
	always_ff @ (posedge CLK_IN)
	begin
			clk_sync <= {clk_sync[$bits(clk_sync)-2:0], DAT_IN};
	end

// Output
	assign DAT_OUT = clk_sync[$bits(clk_sync)-1];

endmodule

/*
	Data capture
	This module captures a logic vector in the target clock domain with two capture registers.
*/
module vid_phy_controller_v2_2_2_lib_cap_v1_0
#(
	parameter 	WIDTH = 8
)
(
	input wire				CLK_IN,				// Clock
	input wire	[WIDTH-1:0]	DAT_IN,				// Data in
	output wire	[WIDTH-1:0]	DAT_OUT				// Data out
);

// Signals
(* async_reg = "true" *) logic	[WIDTH-1:0]	clk_cap[0:1];

// Logic
	always_ff @ (posedge CLK_IN)
	begin
			clk_cap[0] <= DAT_IN;
			clk_cap[1] <= clk_cap[0];
	end

// Output
	assign DAT_OUT = clk_cap[1];

endmodule


/*
	Edge Detector
*/
module vid_phy_controller_v2_2_2_lib_edge_v1_0
(
	input wire	CLK_IN,				// Clock
	input wire	CKE_IN,				// Clock enable
	input wire	A_IN,				// Input
	output wire	RE_OUT,				// Rising edge
	output wire	FE_OUT				// Falling edge
);

// Signals
logic clk_a_del;
logic clk_a_re;
logic clk_a_fe;

// Logic
// Input Registers
	always_ff @ (posedge CLK_IN)
	begin
			// Clock enable
			if (CKE_IN)
				clk_a_del	<= A_IN;
	end

// Rising Edge Detector
	always_comb
	begin
		if (A_IN && !clk_a_del)
			clk_a_re = 1;
		else
			clk_a_re = 0;
	end

// Falling Edge Detector
	always_comb
	begin
		if (!A_IN && clk_a_del)
			clk_a_fe = 1;
		else
			clk_a_fe = 0;
	end

// Outputs
	assign RE_OUT = clk_a_re;
	assign FE_OUT = clk_a_fe;

endmodule


/*
	Clock domain adapter with gray code
*/
module vid_phy_controller_v2_2_2_lib_cda_gray_v1_0
#(
	parameter WIDTH		= 8
)
(
	// Port A
	input wire				A_CLK_IN,		// Clock
	input wire [WIDTH-1:0]	A_DAT_IN,		// Data

	// Port B
	input wire				B_CLK_IN,		// Clock
	output wire [WIDTH-1:0]	B_DAT_OUT		// Data
);

logic	[WIDTH-1:0]	aclk_din;
logic	[WIDTH-1:0]	aclk_gray;
wire	[WIDTH-1:0]	gray_from_cap;
logic	[WIDTH-1:0]	bclk_gray;
logic	[WIDTH-1:0]	bclk_bin;
logic	[WIDTH-1:0]	bclk_dout;

// Input data
	always_ff @ (posedge A_CLK_IN)
	begin
		aclk_din <= A_DAT_IN;
	end

// Gray data
	always_ff @ (posedge A_CLK_IN)
	begin
		aclk_gray[WIDTH-1] <= aclk_din[WIDTH-1];
		for (int i=WIDTH-1; i>0; i--)
			aclk_gray[i-1] <= aclk_din[i] ^ aclk_din[i-1];
	end

// Cross Domain A => B
xpm_cdc_array_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.WIDTH          ( $bits(aclk_gray)      ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	BCLK_CAP_INST 
	(
		.src_clk         (A_CLK_IN),
		.src_in          (aclk_gray),
		.dest_clk        (B_CLK_IN),
		.dest_out        (gray_from_cap)
);

/*vid_phy_controller_v2_2_2_1_lib_cap_v1_0
	#(
		.WIDTH ($bits(aclk_gray))
	)
	BCLK_CAP_INST
	(
		.CLK_IN		(B_CLK_IN),
		.DAT_IN		(aclk_gray),
		.DAT_OUT	(gray_from_cap)
	);
*/

	always_ff @ (posedge B_CLK_IN)
	begin
		bclk_gray 		<= gray_from_cap;
	end

// Convert to gray code back to binary
	always_comb
	begin
		bclk_bin[WIDTH-1] = bclk_gray[WIDTH-1];
		bclk_bin[WIDTH-2] = bclk_gray[WIDTH-1] ^ bclk_gray[WIDTH-2];
		for (int j=WIDTH-3; j>=0; j--)
		begin
			bclk_bin[j] = bclk_bin[j+1] ^ bclk_gray[j];
		end
	end

// Data Out
	always_ff @ (posedge B_CLK_IN)
	begin
		bclk_dout <= bclk_bin;
	end

	assign B_DAT_OUT = bclk_dout;
endmodule


/*
	Single Clock FIFO
	Mixed width is not supported yet!
*/
module vid_phy_controller_v2_2_2_lib_fifo_sc_v1_0
#(
	parameter			ADR_WIDTH_A	= 5,
	parameter			ADR_WIDTH_B	= 5,
	parameter			DAT_WIDTH_A	= 32,
	parameter			DAT_WIDTH_B	= 32
)

(
	input wire						RST_IN,			// Reset
	input wire						CLK_IN,			// Clock
	input wire						CKE_IN,			// Clock enable

	// Input
	input wire						WP_LD_IN,		// Write pointer load
	input wire	[ADR_WIDTH_A-1:0]	WP_IN,			// Write pointer
	input wire						WR_IN,			// Write
	input wire	[DAT_WIDTH_A-1:0]	DAT_IN,			// Write data

	// Output
	input wire						RP_LD_IN,		// Read Pointer Load
	input wire	[ADR_WIDTH_B-1:0]	RP_IN,			// Read Pointer
	input wire						RD_IN,			// Read
	output wire	[DAT_WIDTH_B-1:0]	DAT_OUT,		// Read data
	output wire						SDE_OUT,		// Single data enable
	output wire						BDE_OUT,		// Burst data enable

	// Status
	output wire	[ADR_WIDTH_A-1:0]	WP_OUT,			// Write pointer
	output wire	[ADR_WIDTH_B-1:0]	RP_OUT,			// Read pointer
	output wire	[ADR_WIDTH_A:0]		WRDS_OUT,		// Used words (port A width)
	output wire						FL_OUT,			// Full flag
	output wire						EP_OUT			// Empty flag
);

/*
	Parameters
*/
localparam par_fifo_wrds_a = 1<<ADR_WIDTH_A;
localparam par_fifo_wrds_b = 1<<ADR_WIDTH_B;

/*
	Signals
*/

logic 	[ADR_WIDTH_A-1:0]	clk_wp;
logic 	[ADR_WIDTH_B-1:0]	clk_rp;
logic 	[ADR_WIDTH_A-1:0]	clk_rp_conv;
logic 	[ADR_WIDTH_A:0]		clk_wrds;
logic						clk_sde;
logic						clk_sde_del;
logic						clk_bde;
logic						clk_bde_del;
logic						clk_fl;
logic						clk_ep;
logic						clk_peq;
logic	[DAT_WIDTH_B-1:0]	clk_dout;
logic	[DAT_WIDTH_B-1:0]	clk_dout_reg;
logic	[DAT_WIDTH_A-1:0]	clk_dpram[0:par_fifo_wrds_a] /* synthesis ramstyle = "no_rw_check" */;

/*
	Logic
*/

// RAM block inference
	always_ff @ (posedge CLK_IN)
	begin
		// Clock enable
		if (CKE_IN)
		begin
			// Write
			if (WR_IN)
				clk_dpram[clk_wp] <= DAT_IN;

			// Read
			begin
				clk_dout 		<= clk_dpram[clk_rp];
				clk_dout_reg 	<= clk_dout;
			end
		end
	end

// Write Pointer
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_wp <= 0;

		else
		begin
			// Clock
			if (CKE_IN)
			begin
				// Load
				if (WP_LD_IN)
					clk_wp <= WP_IN;

				// Increment
				else if (WR_IN)
				begin
					if (clk_wp == par_fifo_wrds_a-1)
						clk_wp <= 0;
					else
						clk_wp <= clk_wp + 1'd1;
				end
			end
		end
	end

// Read Pointer
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_rp <= 0;

		else
		begin
			// Clock enable
			if (CKE_IN)
			begin
				// Load
				if (RP_LD_IN)
					clk_rp <= RP_IN;

				// Increment
				else if (RD_IN && !clk_peq)
				begin
					if (clk_rp == par_fifo_wrds_b-1)
						clk_rp <= 0;
					else
						clk_rp <= clk_rp + 1'd1;
				end
			end
		end
	end

// Pointers Equal
	always_comb
	begin
		if (clk_wp == clk_rp_conv)
			clk_peq = 1;
		else
			clk_peq = 0;
	end

// Converted read pointer
// To calculate the used words the read pointer (port b) must be converted to the write pointer domain (port a).
generate
	// Port A is larger than port B
	if ($bits(clk_wp) > $bits(clk_rp))
		assign clk_rp_conv = clk_rp << (ADR_WIDTH_A-ADR_WIDTH_B);

	// Port A is smaller than port B
	else if ($bits(clk_wp) < $bits(clk_rp))
		assign clk_rp_conv = ($bits(clk_rp_conv))'(clk_rp >> (ADR_WIDTH_B-ADR_WIDTH_A));

	else
		assign clk_rp_conv = clk_rp;
endgenerate

// Used Words
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_wrds 	<= 0;
		else
		begin
			// Equal
			if (clk_wp == clk_rp_conv)
				clk_wrds 	<= 0;

			// Write pointer is larger
			else if (clk_wp > clk_rp_conv)
				clk_wrds <= clk_wp - clk_rp_conv;

			// Read pointer is larger
			else
				clk_wrds <= ($bits(clk_wrds))'(par_fifo_wrds_a) - clk_rp_conv + clk_wp;
		end
	end

// Data Enable
	// Single word mode
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
		begin
			clk_sde 		<= 0;
			clk_sde_del 	<= 0;
		end

		else
		begin
			// Clock enable
			if (CKE_IN)
			begin
				// Pointers are equal
				if (clk_peq)
				begin
					clk_sde 	<= 0;
					clk_sde_del 	<= 0;
				end

				// Single read request or read pointer load
				else if (RD_IN || RP_LD_IN)
				begin
					clk_sde 	<= 0;
					clk_sde_del 	<= 0;
				end

				else
				begin
					clk_sde 	<= 1;
					clk_sde_del 	<= clk_sde;
				end
			end
		end
	end

	// Burst mode
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
		begin
			clk_bde 		<= 0;
			clk_bde_del 	<= 0;
		end
		else
		begin
			// Clock enable
			if (CKE_IN)
			begin
				// Pointer are equal
				if (clk_peq)
					clk_bde <= 0;
				else
					clk_bde <= RD_IN;

				clk_bde_del <= clk_bde;
			end
		end
	end

// Full Flag
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_fl <= 0;
		else
		begin
			// Clock enable
			if (CKE_IN)
			begin
				// Shallow fifo
				if (par_fifo_wrds_a <= 8)
				begin
					// Set
					if (clk_wrds > par_fifo_wrds_a/2)
						clk_fl <= 1;

					// Clear
					else if (clk_wrds < 'd2)
						clk_fl <= 0;
				end

				else
				begin
					// Set when the fifo is 3/4 full
					if (clk_wrds >= (3 * (par_fifo_wrds_a/4)))
						clk_fl <= 1;

					// Clear when the fifo is 1/4 full
					else if (clk_wrds < (par_fifo_wrds_a/4))
						clk_fl <= 0;
				end
			end
		end
	end

// Empty Flag
// Must be combinatorial
	always_comb
	begin
		// Set
		if (clk_wrds == 0)
			clk_ep = 1;

		// Clear
		else
			clk_ep = 0;
	end

// Outputs
	assign SDE_OUT = clk_sde_del;
	assign BDE_OUT = clk_bde_del;
	assign WRDS_OUT = clk_wrds;
	assign FL_OUT = clk_fl;
	assign EP_OUT = clk_ep;
	assign WP_OUT = clk_wp;
	assign RP_OUT = clk_rp;
	assign DAT_OUT = clk_dout_reg;
endmodule

/*
	Dual Clock FIFO
	Mixed mode not supported yet!
*/
module vid_phy_controller_v2_2_2_lib_fifo_dc_v1_0
#(
	parameter			ADR_WIDTH_A	= 5,
	parameter			DAT_WIDTH_A	= 32,
	parameter			ADR_WIDTH_B	= 5,
	parameter			DAT_WIDTH_B	= 32
)

(
	input wire						A_RST_IN,		// Reset
	input wire						B_RST_IN,
	input wire						A_CLK_IN,		// Clock
	input wire						B_CLK_IN,
	input wire						A_CKE_IN,		// Clock enable
	input wire						B_CKE_IN,

	// Input (A)
	input wire						A_WP_LD_IN,		// Load write pointer
	input wire	[ADR_WIDTH_A-1:0]	A_WP_IN,		// Write pointer
	input wire						A_WR_IN,		// Write
	input wire	[DAT_WIDTH_A-1:0]	A_DAT_IN,		// Write data

	// Output (B)
	input wire						B_RP_LD_IN,		// Load read pointer
	input wire	[ADR_WIDTH_B-1:0]	B_RP_IN,		// Read pointer
	input wire						B_RD_IN,		// Read
	output wire	[DAT_WIDTH_B-1:0]	B_DAT_OUT,		// Read data
	output wire						B_SDE_OUT,		// Single data enable
	output wire						B_BDE_OUT,		// Burst data enable

	// Status (A)
	output wire	[ADR_WIDTH_A-1:0]	A_WP_OUT,		// Write pointer out
	output wire	[ADR_WIDTH_A-1:0]	A_RP_OUT,		// Read pointer
	output wire	[ADR_WIDTH_A:0]		A_WRDS_OUT,		// Used words
	output wire						A_FL_OUT,		// Full
	output wire						A_EP_OUT,		// Empty

	// Status (B)
	output wire	[ADR_WIDTH_B-1:0]	B_WP_OUT,		// Write pointer
	output wire	[ADR_WIDTH_B-1:0]	B_RP_OUT,		// Read pointer
	output wire	[ADR_WIDTH_B:0]		B_WRDS_OUT,		// Used words
	output wire						B_FL_OUT,		// Full
	output wire						B_EP_OUT		// Empty
);
/*
	Parameters
*/
localparam par_fifo_wrds_a = 1<<ADR_WIDTH_A;
localparam par_fifo_wrds_b = 1<<ADR_WIDTH_B;

/*
	Signals
*/
logic	[DAT_WIDTH_A-1:0]	aclk_dpram[0:par_fifo_wrds_a];

logic 	[ADR_WIDTH_A-1:0]	aclk_wp;
wire 	[ADR_WIDTH_B-1:0]	aclk_rp;
logic 	[ADR_WIDTH_A-1:0]	aclk_rp_conv;
logic	[ADR_WIDTH_A:0]		aclk_wrd;
logic						aclk_fl;
logic						aclk_ep;

logic 	[ADR_WIDTH_B-1:0]	bclk_rp;
wire 	[ADR_WIDTH_A-1:0]	bclk_wp;
logic 	[ADR_WIDTH_B-1:0]	bclk_wp_conv;
logic	[ADR_WIDTH_B:0]		bclk_wrd;
logic						bclk_fl;
logic						bclk_ep;
logic						bclk_peq;
logic						bclk_sde;
logic						bclk_sde_del;
logic						bclk_bde;
logic						bclk_bde_del;
(* async_reg = "true" *) logic	[DAT_WIDTH_B-1:0]	bclk_dout;
logic	[DAT_WIDTH_B-1:0]	bclk_dout_reg;


/*
	Logic
*/

// RAM block inference
	always_ff @ (posedge A_CLK_IN)
	begin
		// Clock enable
		if (A_CKE_IN)
		begin
			// Write
			if (A_WR_IN)
				aclk_dpram[aclk_wp] <= A_DAT_IN;
		end
	end

// Port A
// Write Pointer
	always_ff @ (posedge A_RST_IN, posedge A_CLK_IN)
	begin
		if (A_RST_IN)
			aclk_wp <= 0;

		else
		begin
			// Clock enable
			if (A_CKE_IN)
			begin
				// Load
				if (A_WP_LD_IN)
					aclk_wp <= A_WP_IN;

				// Increment
				else if (A_WR_IN)
				begin
					if (aclk_wp == par_fifo_wrds_a-1)
						aclk_wp <= 0;
					else
						aclk_wp <= aclk_wp + 1'b1;
				end
			end
		end
	end

// Clock Domain Adapter
// This adapter crosses the (original size) read pointer to the write pointer domain.
vid_phy_controller_v2_2_2_lib_cda_gray_v1_0
	#(
		.WIDTH		(ADR_WIDTH_B)
	)
	RP_CDA_INST
	(
		// Port A
		.A_CLK_IN	(B_CLK_IN),
		.A_DAT_IN	(bclk_rp),

		// Port B
		.B_CLK_IN	(A_CLK_IN),
		.B_DAT_OUT	(aclk_rp)
	);

// Converted read pointer
// To calculate the used words the read pointer (port b) must be converted to the write pointer domain (port a).
generate
	// Port A is larger than port B
	if ($bits(aclk_wp) > $bits(bclk_rp))
		assign aclk_rp_conv = aclk_rp << (ADR_WIDTH_A-ADR_WIDTH_B);

	// Port A is smaller than port B
	else if ($bits(aclk_wp) < $bits(bclk_rp))
		assign aclk_rp_conv = aclk_rp >> (ADR_WIDTH_B-ADR_WIDTH_A);

	else
		assign aclk_rp_conv = aclk_rp;
endgenerate

// Used Words
	always_ff @ (posedge A_RST_IN, posedge A_CLK_IN)
	begin
		if (A_RST_IN)
			aclk_wrd 	<= 0;
		else
		begin
			if (aclk_wp == aclk_rp_conv)
				aclk_wrd 	<= 0;

			else if (aclk_wp > aclk_rp_conv)
				aclk_wrd <= aclk_wp - aclk_rp_conv;

			else
				aclk_wrd <= ($bits(aclk_wrd))'(par_fifo_wrds_a - aclk_rp_conv + aclk_wp);
		end
	end

// Full Flag
	always_ff @ (posedge A_RST_IN, posedge A_CLK_IN)
	begin
		if (A_RST_IN)
			aclk_fl <= 0;
		else
		begin
			// Clock enable
			if (A_CKE_IN)
			begin
				// Set
				if (aclk_wrd > (3*(par_fifo_wrds_b/4)))
					aclk_fl <= 1;

				// Clear
				else if (aclk_wrd < (par_fifo_wrds_b/4))
					aclk_fl <= 0;
			end
		end
	end

// Empty Flag
// Must be combinatorial
	always_comb
	begin
		// Set
		if (aclk_wrd == 0)
			aclk_ep = 1;

		// Clear
		else
			aclk_ep = 0;
	end

// Port B
// Read Pointer
	always_ff @ (posedge B_RST_IN, posedge B_CLK_IN)
	begin
		if (B_RST_IN)
			bclk_rp <= 0;

		else
		begin
			// Clock enable
			if (B_CKE_IN)
			begin
				// Load
				if (B_RP_LD_IN)
					bclk_rp <= B_RP_IN;

				// Increment
				else if (B_RD_IN && !bclk_peq)
				begin
					if (bclk_rp == par_fifo_wrds_b-1)
						bclk_rp <= 0;
					else
						bclk_rp <= bclk_rp + 1'd1;
				end
			end
		end
	end

// Clock Domain Adapter
// This adapter crosses the (original size) write pointer to the read pointer domain.
vid_phy_controller_v2_2_2_lib_cda_gray_v1_0
	#(
		.WIDTH		(ADR_WIDTH_A)
	)
	WP_CDA_INST
	(
		// Port A
		.A_CLK_IN	(A_CLK_IN),
		.A_DAT_IN	(aclk_wp),

		// Port B
		.B_CLK_IN	(B_CLK_IN),
		.B_DAT_OUT	(bclk_wp)
	);

// Converted write pointer
// To calculate the used words the write pointer (port a) must be converted to the read pointer domain (port b).
generate
	// Port A is larger than port B
	if ($bits(aclk_wp) > $bits(bclk_rp))
		assign bclk_wp_conv = (bclk_wp >> (ADR_WIDTH_A-ADR_WIDTH_B));

	// Port A is smaller than port B
	else if ($bits(aclk_wp) < $bits(bclk_rp))
		assign bclk_wp_conv = (bclk_wp << (ADR_WIDTH_B-ADR_WIDTH_A));

	else
		assign bclk_wp_conv = bclk_wp;
endgenerate

// Used Words
	always_ff @ (posedge B_RST_IN, posedge B_CLK_IN)
	begin
		if (B_RST_IN)
			bclk_wrd 	<= 0;
		else
		begin
			if (bclk_wp_conv == bclk_rp)
				bclk_wrd 	<= 0;

			else if (bclk_wp_conv > bclk_rp)
				bclk_wrd <= bclk_wp_conv - bclk_rp;

			else
				bclk_wrd <= ($bits(bclk_wrd))'(par_fifo_wrds_b - bclk_rp + bclk_wp_conv);
		end
	end

// Full Flag
	always_ff @ (posedge B_RST_IN, posedge B_CLK_IN)
	begin
		if (B_RST_IN)
			bclk_fl <= 0;
		else
		begin
			// Clock enable
			if (B_CKE_IN)
			begin
				// Set
				if (bclk_wrd > (3*(par_fifo_wrds_b/4)))
					bclk_fl <= 1;

				// Clear
				else if (bclk_wrd < (par_fifo_wrds_b/4))
					bclk_fl <= 0;
			end
		end
	end

// Empty Flag
// Must be combinatorial
	always_comb
	begin
		// Set
		if (bclk_wrd == 0)
			bclk_ep = 1;

		// Clear
		else
			bclk_ep = 0;
	end

// Pointers Equal
// When both pointers are equal there is no more data in the fifo and read pointer is not incremented and the DE is de-asserted.
// The dual clock introduces latency between the actual write pointer and write pointer in the read domain.
// When the write and read pointers are active in the same fifo area, this can cause a glitch in the DE.
// When the application knows the exact mount of data to be read from the fifo,
// the parameter DEPC (Disable Equal Pointer Check) will disable the pointer equal check and suppress this behaviour.
	always_comb
	begin
		if (bclk_wp_conv == bclk_rp)
			bclk_peq = 1;
		else
			bclk_peq = 0;
	end

// Data Enable
// Single word mode
	always_ff @ (posedge B_RST_IN, posedge B_CLK_IN)
	begin
		if (B_RST_IN)
		begin
			bclk_sde 		<= 0;
			bclk_sde_del 	<= 0;
		end
		else
		begin
			// Clock enable
			if (B_CKE_IN)
			begin
				// Pointes equal (the equal check can be suppressed by the DEPC parameter)
				if (bclk_peq)
				begin
					bclk_sde 	<= 0;
					bclk_sde_del 	<= 0;
				end

				// Read or load
				else if (B_RD_IN || B_RP_LD_IN)
				begin
					bclk_sde 	<= 0;
					bclk_sde_del 	<= 0;
				end
				else
				begin
					bclk_sde 	<= 1;
					bclk_sde_del 	<= bclk_sde;
				end
			end
		end
	end

	// Burst mode
	always_ff @ (posedge B_RST_IN, posedge B_CLK_IN)
	begin
		if (B_RST_IN)
		begin
			bclk_bde 		<= 0;
			bclk_bde_del 	<= 0;
		end
		else
		begin
			// Clock enable
			if (B_CKE_IN)
			begin
				// Pointes equal (the equal check can be suppressed by the DEPC parameter)
				if (bclk_peq)
					bclk_bde <= 0;
				else
					bclk_bde <= B_RD_IN;

				bclk_bde_del 	<= bclk_bde;
			end
		end
	end

// Data output
	always_ff @ (posedge B_CLK_IN)
	begin
		// Clock enable
		if (B_CKE_IN)
		begin
			bclk_dout 		<= aclk_dpram[bclk_rp];
			bclk_dout_reg	<= bclk_dout;			// Output is registered
		end
	end

// Outputs
	assign A_FL_OUT 	= aclk_fl;
	assign A_EP_OUT 	= aclk_ep;
	assign A_WRDS_OUT 	= aclk_wrd;
	assign A_RP_OUT 	= aclk_rp_conv;
	assign A_WP_OUT 	= aclk_wp;
	assign B_DAT_OUT 	= bclk_dout_reg;
	assign B_SDE_OUT 	= bclk_sde_del;
	assign B_BDE_OUT 	= bclk_bde_del;
	assign B_FL_OUT 	= bclk_fl;
	assign B_EP_OUT 	= bclk_ep;
	assign B_WRDS_OUT 	= bclk_wrd;
	assign B_WP_OUT 	= bclk_wp_conv;
	assign B_RP_OUT 	= bclk_rp;

endmodule

/*
	Divider
	This is a non-restoring division
*/
module vid_phy_controller_v2_2_2_lib_div_v1_0
#(
	parameter					N_WIDTH = 32,		// Dividend width
	parameter					D_WIDTH = 16		// Divisor width
)
(
	input wire					RST_IN,			// Reset
	input wire					CLK_IN,			// Clock

	input wire					STR_IN,			// Start
	input wire	[N_WIDTH-1:0]	N_IN,			// Dividend
	input wire	[D_WIDTH-1:0]	D_IN,			// Divisor
	output wire	[N_WIDTH-1:0]	Q_OUT,			// Quotient
	output wire					R_OUT,			// Remainder
	output wire					VLD_OUT			// Valid
);

// Signals
enum int unsigned { sm_idle, sm_init, sm_shft, sm_add
	} clk_sm_cur, clk_sm_nxt;

logic					clk_str;
logic	[N_WIDTH-1:0]	clk_n_in;
logic	[D_WIDTH-1:0]	clk_d_in;
logic	[N_WIDTH-1:0]	clk_n;
wire					clk_n_msb;
logic	[D_WIDTH:0]		clk_d;
logic	[D_WIDTH:0]		clk_dn;
logic	[N_WIDTH-1:0]	clk_q;
logic					clk_q_clr;
logic					clk_q_shft;
logic					clk_vld;
logic					clk_vld_set;
logic	[7:0]			clk_cnt;
logic					clk_cnt_ld;
logic					clk_cnt_dec;
logic					clk_cnt_end;
logic	[D_WIDTH:0]		clk_acc;
wire					clk_acc_msb;
logic					clk_acc_ld;
logic					clk_acc_init;
logic					clk_acc_shft;
logic					clk_acc_add;
logic					clk_rem;

// Logic

// Capture inputs
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
		begin
			clk_str		<= 0;
			clk_n_in	<= 0;
			clk_d_in	<= 0;
		end

		else
		begin
			clk_str		<= STR_IN;
			clk_n_in	<= N_IN;
			clk_d_in	<= D_IN;
		end
	end

// Dividend register
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_n	<= 0;

		else
		begin
			// Load
			if (clk_str)
				clk_n <= clk_n_in;

			// Shift
			else if (clk_acc_shft)
				clk_n <= {clk_n[$bits(clk_n)-2:0], 1'b0};
		end
	end
	assign clk_n_msb = clk_n[$bits(clk_n)-1];

// Divisor registers
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
		begin
			clk_d	<= 0;
			clk_dn	<= 0;
		end

		else
		begin
			// Load
			if (clk_str)
			begin
				clk_d 	<= {1'b0, clk_d_in};
				clk_dn 	<= (~{1'b0, clk_d_in}) + 'd1;
			end
		end
	end

// Accumulator
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_acc	<= 0;

		else
		begin
			// Load
			if (clk_acc_ld)
			begin
				clk_acc[$bits(clk_acc)-1:1] 	<= 0;
				clk_acc[0] 			<= clk_n_msb;
			end

			// Init
			// This first cycle is always substract the divisor
			else if (clk_acc_init)
				clk_acc <= clk_acc + clk_dn;		// Subtract divisor

			// Shift
			else if (clk_acc_shft)
				clk_acc <= {clk_acc[($bits(clk_acc)-2):0], clk_n_msb};

			// Add
			else if (clk_acc_add)
			begin
				// Result is negative
				if (clk_acc_msb)
					clk_acc <= clk_acc + clk_d;		// Add divisor
				else
					clk_acc <= clk_acc + clk_dn;		// Subtract divisor
			end

		end
	end

	assign clk_acc_msb = clk_acc[$bits(clk_acc)-1];

// Counter
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_cnt	<= 0;

		else
		begin
			// Load
			if (clk_cnt_ld)
				//clk_cnt <= N_WIDTH-1;
				clk_cnt <= N_WIDTH;

			// Decrement
			else if (clk_cnt_dec)
				clk_cnt <= clk_cnt - 'd1;
		end
	end

// Counter end
	always_comb
	begin
		if (clk_cnt == 0)
			clk_cnt_end = 1;
		else
			clk_cnt_end = 0;
	end

// Quotient
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_q	<= 0;

		else
		begin
			// Clear
			if (clk_q_clr)
				clk_q <= 0;

			// Shift
			else if (clk_q_shft)
			begin
				if (clk_acc_msb)
					clk_q <= {clk_q[$bits(clk_q)-2:0], 1'b0};	// When the result is negative, the Q bit is cleared
				else
					clk_q <= {clk_q[$bits(clk_q)-2:0], 1'b1};	// When the result is positive, the Q bit is set
			end
		end
	end

// Valid
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_vld	<= 0;

		else
		begin
			// Set
			if (clk_vld_set)
				clk_vld <= 1;

			// Clear
			else if (clk_str)
				clk_vld <= 0;
		end
	end

// Remainder
// The remainder flag is set when there is a remainder, else the flag is cleared
	always_comb
	begin
		if (clk_acc == 0)
			clk_rem = 0;
		else
			clk_rem	= 1;
	end

// State machine
	always_ff @ (posedge RST_IN, posedge CLK_IN)
	begin
		if (RST_IN)
			clk_sm_cur <= sm_idle;

		else
			clk_sm_cur <= clk_sm_nxt;
	end

// State machine decoder
	always_comb
	begin

		// Default
		clk_cnt_ld		= 0;
		clk_cnt_dec		= 0;
		clk_acc_ld		= 0;
		clk_acc_init	= 0;
		clk_acc_shft	= 0;
		clk_acc_add		= 0;
		clk_q_clr		= 0;
		clk_q_shft		= 0;
		clk_vld_set		= 0;

		case (clk_sm_cur)

			sm_idle :
			begin
				// Wait for start
				if (clk_str)
				begin
					clk_cnt_ld	= 1;
					clk_acc_ld	= 1;
					clk_q_clr	= 1;
					clk_sm_nxt	= sm_init;
				end

				else
					clk_sm_nxt	= sm_idle;
			end

			sm_init :
			begin
				clk_acc_init	= 1;			// Init
				clk_sm_nxt		= sm_shft;
			end

			sm_shft :
			begin
				if (!clk_cnt_end)
					clk_acc_shft	= 1;			// Shift
				clk_sm_nxt		= sm_add;
			end

			sm_add :
			begin
				clk_q_shft		= 1;			// Shift quotient

				// Have we processed all bits?
				if (clk_cnt_end)
				begin
					if (clk_acc != 0)
						clk_acc_add	= 1;			// Add
					clk_vld_set	= 1;			// Set valid flag
					clk_sm_nxt	= sm_idle;		// Return to idle
				end
				else
				begin
					clk_acc_add	= 1;			// Add
					clk_cnt_dec	= 1;			// Decrement counter
					clk_sm_nxt	= sm_shft;
				end
			end

			default :
			begin
				clk_sm_nxt		= sm_idle;
			end
		endcase

	end

// Outputs
	assign Q_OUT 	= clk_q;
	assign R_OUT 	= clk_rem;
	assign VLD_OUT 	= clk_vld;

endmodule

`default_nettype wire
