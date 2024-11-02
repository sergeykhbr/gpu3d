`timescale 1ns / 1ps

module dru_tech #(
      parameter int S_MAX = 10,                               // max number of extracted bits, decimal
      parameter logic [15:0] MASK_CG = 16'b1111111111110000,  // place same number of LSb zeros
      parameter logic [15:0] MASK_PD = 16'b1111111111110000,  // place same number of LSb zeros
      parameter logic [36:0] MASK_VCO = 37'b1111111111111111111111111111111110000,  // plase same number of LSb zeros
      parameter bit EN_INTEG = 1,                             // by default 1
      parameter bit EN_ADV_COMPR = 0,                         // by default 0. when set to 1 activates the advanced compressor
      parameter bit PH_EST_DIS = 0                            // by defauls 0
)
(
    input  [19:0]   DT_IN,
    input  [36:0]   CENTER_F,
    input           EN,
    input  [4:0]    G1,
    input  [4:0]    G1_P,
    input  [4:0]    G2,
    input           CLK,
    input           PL,
    input  [31:0]   PHASE_IN,
    input           RST,
    input           RST_FREQ,
    input           EN_INTEG,
    input           PH_EST_DIS,
    output [20:0]   PH_OUT,
    output [31:0]   INTEG,
    output [31:0]   DIRECT,
    output [31:0]   CTRL,
    output          AL_PPM,
    output [19:0]   RECCLK,
    output [3:0]    SAMV,
    output [9:0]    SAM,
    output [7:0]    VER
);

`ifdef TARGET_INFERRED
    dru_inferred #(
       .S_MAX(S_MAX),
       .MASK_CG(MASK_CG),
       .MASK_PD(MASK_PD),
       .MASK_VCO(MASK_VCO),
       .EN_INTEG(EN_INTEG),
       .EN_ADV_COMPR(EN_ADV_COMPR),
       .PH_EST_DIS(PH_EST_DIS)
    ) dru0 (
       .DT_IN(DT_IN),
       .CENTER_F(CENTER_F),
       .EN(EN),
       .G1(G1),
       .G1_P(G1_P),
       .G2(G2),
       .CLK(CLK),
       .PL(PL),
       .PHASE_IN(PHASE_IN),
       .RST(RST),
       .RST_FREQ(RST_FREQ),
       .EN_INTEG(EN_INTEG),
       .PH_EST_DIS(PH_EST_DIS),
       .PH_OUT(PH_OUT),
       .INTEG(INTEG),
       .DIRECT(DIRECT),
       .CTRL(CTRL),
       .AL_PPM(AL_PPM),
       .RECCLK(RECCLK),
       .SAMV(SAMV),
       .SAM(SAM),
       .VER(VER)
    );
`elsif TARGET_KC705
    // Encoded model in file "nidru_20_v_7_encoded.vhd"
    // Do not forget to check constraint pathes
    //
    // DO NOT FORGET TO UNCOMMENT
//    dru #(
    dru_inferred #(
       .S_MAX(S_MAX),
       .MASK_CG(MASK_CG),
       .MASK_PD(MASK_PD),
       .MASK_VCO(MASK_VCO),
       .EN_INTEG(EN_INTEG),
       .EN_ADV_COMPR(EN_ADV_COMPR),
       .PH_EST_DIS(PH_EST_DIS)
    ) dru0 (
       .DT_IN(DT_IN),
       .CENTER_F(CENTER_F),
       .EN(EN),
       .G1(G1),
       .G1_P(G1_P),
       .G2(G2),
       .CLK(CLK),
       .PL(PL),
       .PHASE_IN(PHASE_IN),
       .RST(RST),
       .RST_FREQ(RST_FREQ),
       .EN_INTEG(EN_INTEG),
       .PH_EST_DIS(PH_EST_DIS),
       .PH_OUT(PH_OUT),
       .INTEG(INTEG),
       .DIRECT(DIRECT),
       .CTRL(CTRL),
       .AL_PPM(AL_PPM),
       .RECCLK(RECCLK),
       .SAMV(SAMV),
       .SAM(SAM),
       .VER(VER)
    );
`else
    initial $error("INSTANCE macro is undefined, check technology-dependent DRU model.");
`endif

endmodule
