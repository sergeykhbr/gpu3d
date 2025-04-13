
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`ifndef __VID_PHY_DEFS__
`define __VID_PHY_DEFS__

`define tPHY_MEM_MAP_FIELDS_CONTROL [999:0]
  `define CH4_DRPADDR_US_MSB             999:997
  `define CH3_DRPADDR_US_MSB             996:994
  `define CH2_DRPADDR_US_MSB             993:991
  `define CH1_DRPADDR_US_MSB             990:988
  `define CPLL_CAL_CLK_CNT_TOL           987:970
  `define CPLL_CAL_CLK_PERIOD            969:952

  `define RX_REFCLK_CEB                      951
  `define TX_REFCLK_CEB                      950

  `define CH4_TXPRBSSEL_US_MSB               949
  `define CH3_TXPRBSSEL_US_MSB               948
  `define CH2_TXPRBSSEL_US_MSB               947
  `define CH1_TXPRBSSEL_US_MSB               946

  `define CH4_RXPRBSSEL_US_MSB               945
  `define CH3_RXPRBSSEL_US_MSB               944
  `define CH2_RXPRBSSEL_US_MSB               943
  `define CH1_RXPRBSSEL_US_MSB               942

// START - additional for HDMI PHY
  `define MMCM_RXUSRCLK_LOCK_MASK            941
  `define MMCM_TXUSRCLK_LOCK_MASK            940   

  `define CONTROL_RESERVED2              939:766

  `define PATGEN_TX_TMDS_RATIO           765:763
  
  `define DRU_CENTER_FREQ                762:726
  `define DRU_ENABLE                         725
  `define DRU_RESET                          724

  `define CLKDET_RX_FREQ_EVENT_CLR           723
  `define CLKDET_RX_TMR_EVENT_CLR            722
  `define CLKDET_TX_FREQ_EVENT_CLR           721
  `define CLKDET_TX_TMR_EVENT_CLR            720
  `define CLKDET_RX_TMR_LOAD                 719
  `define CLKDET_TX_TMR_LOAD                 718
  `define CLKDET_RX_TMR_TMOUT_CNT        717:686
  `define CLKDET_TX_TMR_TMOUT_CNT        685:654
  `define CLKDET_FREQ_CNTR_TMOUT         653:622
  `define CLKDET_FREQ_LOCK_CNTR_TRSHLD   621:614
  `define CLKDET_RX_FREQ_RST                 613
  `define CLKDET_TX_FREQ_RST                 612
  `define CLKDET_RX_TMR_CLR                  611
  `define CLKDET_TX_TMR_CLR                  610
  `define CLKDET_RUN                         609
  `define OBUFTDS_RXUSRCLK_CLKOUT1_EN        608
  `define OBUFTDS_TXUSRCLK_CLKOUT1_EN        607
  `define MMCM_RXUSRCLK_POWER_DOWN           606
  `define MMCM_TXUSRCLK_POWER_DOWN           605   
  `define GTREFCLK1_CEB                      604
  `define GTREFCLK0_CEB                      603

// END - for HDMI PHY

  `define BUFGT_RXUSRCLK_DIV             602:600
  `define BUFGT_RXUSRCLK_CLEAR               599
  `define BUFGT_TXUSRCLK_DIV             598:596
  `define BUFGT_TXUSRCLK_CLEAR               595

  `define CONTROL_RESERVED1              594:533
  
  `define MMCM_RXUSRCLK_CONFIG_RESET         532
  `define MMCM_RXUSRCLK_DRPDI            531:516
  `define MMCM_RXUSRCLK_DRPWE                515
  `define MMCM_RXUSRCLK_DRPEN                514
  `define MMCM_RXUSRCLK_DRPADDR          513:502

  `define MMCM_TXUSRCLK_CONFIG_RESET         501
  `define MMCM_TXUSRCLK_DRPDI            500:485
  `define MMCM_TXUSRCLK_DRPWE                484
  `define MMCM_TXUSRCLK_DRPEN                483
  `define MMCM_TXUSRCLK_DRPADDR          482:471

  `define CH4_RX_PLL_GT_RST              470
  `define CH3_RX_PLL_GT_RST              469
  `define CH2_RX_PLL_GT_RST              468
  `define CH1_RX_PLL_GT_RST              467

  `define CH4_TX_PLL_GT_RST              466
  `define CH3_TX_PLL_GT_RST              465
  `define CH2_TX_PLL_GT_RST              464
  `define CH1_TX_PLL_GT_RST              463

  `define COMMON_DRPDI               462:447
  `define COMMON_DRPWE                   446
  `define COMMON_DRPEN                   445
  `define COMMON_DRPADDR             444:433

  `define RX_TDLOCK_VALUE            432:401

  `define CH4_RXLPMHFOVRDEN              400
  `define CH4_RXLPMLFKLOVRDEN            399
  `define CH4_RXOSOVRDEN                 398
  `define CH4_RXCDRHOLD                  397
  `define CH4_RXLPMEN                    396

  `define CH3_RXLPMHFOVRDEN              395
  `define CH3_RXLPMLFKLOVRDEN            394
  `define CH3_RXOSOVRDEN                 393
  `define CH3_RXCDRHOLD                  392
  `define CH3_RXLPMEN                    391

  `define CH2_RXLPMHFOVRDEN              390
  `define CH2_RXLPMLFKLOVRDEN            389
  `define CH2_RXOSOVRDEN                 388
  `define CH2_RXCDRHOLD                  387
  `define CH2_RXLPMEN                    386

  `define CH1_RXLPMHFOVRDEN              385
  `define CH1_RXLPMLFKLOVRDEN            384
  `define CH1_RXOSOVRDEN                 383
  `define CH1_RXCDRHOLD                  382
  `define CH1_RXLPMEN                    381

  `define CH4_RSVD4                      380
  `define CH4_RXPRBSSEL              379:377
  `define CH4_RXPRBSCNTRESET             376
  `define CH4_RXPOLARITY                 375
  `define CH4_RX8B10BEN                  374

  `define CH3_RSVD3                      373
  `define CH3_RXPRBSSEL              372:370
  `define CH3_RXPRBSCNTRESET             369
  `define CH3_RXPOLARITY                 368
  `define CH3_RX8B10BEN                  367

  `define CH2_RSVD2                      366
  `define CH2_RXPRBSSEL              365:363
  `define CH2_RXPRBSCNTRESET             362
  `define CH2_RXPOLARITY                 361
  `define CH2_RX8B10BEN                  360

  `define CH1_RSVD1                      359
  `define CH1_RXPRBSSEL              358:356
  `define CH1_RXPRBSCNTRESET             355
  `define CH1_RXPOLARITY                 354
  `define CH1_RX8B10BEN                  353

  `define CH4_TXPRECURSOR            352:348
  `define CH4_TXPOSTCURSOR           347:343
  `define CH4_TXINHIBIT                  342
  `define CH4_TXELECIDLE                 341
  `define CH4_TXDIFFCTRL             340:337

  `define CH3_TXPRECURSOR            336:332
  `define CH3_TXPOSTCURSOR           331:327
  `define CH3_TXINHIBIT                  326
  `define CH3_TXELECIDLE                 325
  `define CH3_TXDIFFCTRL             324:321

  `define CH2_TXPRECURSOR            320:316
  `define CH2_TXPOSTCURSOR           315:311
  `define CH2_TXINHIBIT                  310
  `define CH2_TXELECIDLE                 309
  `define CH2_TXDIFFCTRL             308:305

  `define CH1_TXPRECURSOR            304:300
  `define CH1_TXPOSTCURSOR           299:295
  `define CH1_TXINHIBIT                  294
  `define CH1_TXELECIDLE                 293
  `define CH1_TXDIFFCTRL             292:289

  `define CH4_TXDLYEN                    288
  `define CH4_TXDLYBYPASS                287
  `define CH4_TXDLYRESET                 286
  `define CH4_TXPHINIT                   285
  `define CH4_TXPHDLYPD                  284
  `define CH4_TXPHALIGNEN                283
  `define CH4_TXPHALIGN                  282
  `define CH4_TXPHDLYRESET               281

  `define CH3_TXDLYEN                    280
  `define CH3_TXDLYBYPASS                279
  `define CH3_TXDLYRESET                 278
  `define CH3_TXPHINIT                   277
  `define CH3_TXPHDLYPD                  276
  `define CH3_TXPHALIGNEN                275
  `define CH3_TXPHALIGN                  274
  `define CH3_TXPHDLYRESET               273

  `define CH2_TXDLYEN                    272
  `define CH2_TXDLYBYPASS                271
  `define CH2_TXDLYRESET                 270
  `define CH2_TXPHINIT                   269
  `define CH2_TXPHDLYPD                  268
  `define CH2_TXPHALIGNEN                267
  `define CH2_TXPHALIGN                  266
  `define CH2_TXPHDLYRESET               265

  `define CH1_TXDLYEN                    264
  `define CH1_TXDLYBYPASS                263
  `define CH1_TXDLYRESET                 262
  `define CH1_TXPHINIT                   261
  `define CH1_TXPHDLYPD                  260
  `define CH1_TXPHALIGNEN                259
  `define CH1_TXPHALIGN                  258
  `define CH1_TXPHDLYRESET               257

  `define CH4_TXPRBSFORCEERR             256
  `define CH4_TXPRBSSEL              255:253
  `define CH4_TXPOLARITY                 252
  `define CH4_TX8B10B                    251

  `define CH3_TXPRBSFORCEERR             250
  `define CH3_TXPRBSSEL              249:247
  `define CH3_TXPOLARITY                 246
  `define CH3_TX8B10B                    245

  `define CH2_TXPRBSFORCEERR             244
  `define CH2_TXPRBSSEL              243:241
  `define CH2_TXPOLARITY                 240
  `define CH2_TX8B10B                    239

  `define CH1_TXPRBSFORCEERR             238
  `define CH1_TXPRBSSEL              237:235
  `define CH1_TXPOLARITY                 234
  `define CH1_TX8B10B                    233

  `define CH4_DRPDI                  232:217
  `define CH4_DRPRST                     216
  `define CH4_DRPWE                      215
  `define CH4_DRPEN                      214
  `define CH4_DRPADDR                213:205

  `define CH3_DRPDI                  204:189
  `define CH3_DRPRST                     188
  `define CH3_DRPWE                      183
  `define CH3_DRPEN                      182
  `define CH3_DRPADDR                181:173

  `define CH2_DRPDI                  172:157
  `define CH2_DRPRST                     156
  `define CH2_DRPWE                      155
  `define CH2_DRPEN                      154
  `define CH2_DRPADDR                153:145
 
  `define CH1_DRPDI                  144:129
  `define CH1_DRPRST                     128
  `define CH1_DRPWE                      127
  `define CH1_DRPEN                      126
  `define CH1_DRPADDR                125:117

  `define CH4_LOOPBACK               116:114
  `define CH3_LOOPBACK               113:111
  `define CH2_LOOPBACK               110:108
  `define CH1_LOOPBACK               107:105

  `define CH4_TXPD                   104:103
  `define CH4_RXPD                   102:101
  `define CH4_QPLL1PD                   100
  `define CH4_QPLL0PD                    99
  `define CH4_CPLLPD                     98

  `define CH3_TXPD                    97:96
  `define CH3_RXPD                    95:94
  `define CH3_QPLL1PD                    93
  `define CH3_QPLL0PD                    92
  `define CH3_CPLLPD                     91

  `define CH2_TXPD                    90:89
  `define CH2_RXPD                    88:87
  `define CH2_QPLL1PD                    86
  `define CH2_QPLL0PD                    85
  `define CH2_CPLLPD                     84

  `define CH1_TXPD                    83:82
  `define CH1_RXPD                    81:80
  `define CH1_QPLL1PD                    79
  `define CH1_QPLL0PD                    78
  `define CH1_CPLLPD                     77

  `define CH4_RXUSERRDY                  76
  `define CH4_RXBUFRESET                 75 
  `define CH4_RXPCSRESET                 74
  `define CH4_EYESCANRESET               73
  `define CH4_RXDFELPMRESET              72
  `define CH4_RXPMARESET                 71
  `define CH4_GTRXRESET                  70

  `define CH3_RXUSERRDY                  69
  `define CH3_RXBUFRESET                 68 
  `define CH3_RXPCSRESET                 67
  `define CH3_EYESCANRESET               66
  `define CH3_RXDFELPMRESET              65
  `define CH3_RXPMARESET                 64
  `define CH3_GTRXRESET                  63

  `define CH2_RXUSERRDY                  62
  `define CH2_RXBUFRESET                 61
  `define CH2_RXPCSRESET                 60
  `define CH2_EYESCANRESET               59
  `define CH2_RXDFELPMRESET              58
  `define CH2_RXPMARESET                 57
  `define CH2_GTRXRESET                  56

  `define CH1_RXUSERRDY                  55
  `define CH1_RXBUFRESET                 54
  `define CH1_RXPCSRESET                 53
  `define CH1_EYESCANRESET               52
  `define CH1_RXDFELPMRESET              51
  `define CH1_RXPMARESET                 50
  `define CH1_GTRXRESET                  49

  `define CH4_TXUSERRDY                  48             
  `define CH4_TXPCSRESET                 47             
  `define CH4_TXPMARESET                 46             
  `define CH4_GTTXRESET                  45             

  `define CH3_TXUSERRDY                  44             
  `define CH3_TXPCSRESET                 43             
  `define CH3_TXPMARESET                 42             
  `define CH3_GTTXRESET                  41             

  `define CH2_TXUSERRDY                  40             
  `define CH2_TXPCSRESET                 39             
  `define CH2_TXPMARESET                 38             
  `define CH2_GTTXRESET                  37             

  `define CH1_TXUSERRDY                  36             
  `define CH1_TXPCSRESET                 35             
  `define CH1_TXPMARESET                 34             
  `define CH1_GTTXRESET                  33             

  `define QPLL1RESET                     32             
  `define QPLL0RESET                     31             
  `define CPLLRESET                      30             

  `define RXPLLCLKSEL                 29:28             
  `define TXPLLCLKSEL                 27:26             
  `define RXSYSCLKSEL                 25:24             
  `define TXSYSCLKSEL                 23:22             
  `define QPLL1REFCLKSEL              21:18             
  `define CPLLREFCLKSEL               17:14             
  `define QPLL0REFCLKSEL              13:10             

  `define RX_BANK_SEL                  9:5              
  `define TX_BANK_SEL                  4:0              


`define tPHY_MEM_MAP_FIELDS_STATUS [399:0]

  `define MMCM_RXUSRCLK_DRPBUSY          399
  `define MMCM_RXUSRCLK_DRPRDY           398
  `define MMCM_RXUSRCLK_DRPDO        397:382

  `define MMCM_TXUSRCLK_DRPBUSY          381
  `define MMCM_TXUSRCLK_DRPRDY           380
  `define MMCM_TXUSRCLK_DRPDO        379:364

  `define DRU_GAIN_G2                363:359
  `define DRU_GAIN_G1_P              358:354
  `define DRU_GAIN_G1                353:349
  `define DRU_VERSION                348:341
  `define CH4_DRU_ACTIVE                 340
  `define CH3_DRU_ACTIVE                 339
  `define CH2_DRU_ACTIVE                 338
  `define CH1_DRU_ACTIVE                 337

  `define CLKDET_RX_FREQ_EVENT           336
  `define CLKDET_RX_TMR_EVENT            335
  `define CLKDET_TX_FREQ_EVENT           334
  `define CLKDET_TX_TMR_EVENT            333
  `define CLKDET_DRU_FREQ            332:301
  `define CLKDET_RX_FREQ             300:269
  `define CLKDET_TX_FREQ             268:237
  `define CLKDET_TX_REFCLK_LOCK_CAP      236
  `define CLKDET_TX_REFCLK_LOCK          235
  `define CLKDET_RX_FREQ_ZERO            234
  `define CLKDET_TX_FREQ_ZERO            233

  `define CH4_SYM_ERR_COUNT          232:217
  `define CH3_SYM_ERR_COUNT          216:201
  `define CH2_SYM_ERR_COUNT          200:185
  `define CH1_SYM_ERR_COUNT          184:169

  `define CH4_BUFF_BYPASS_TX_ERR         168
  `define CH3_BUFF_BYPASS_TX_ERR         167
  `define CH2_BUFF_BYPASS_TX_ERR         166
  `define CH1_BUFF_BYPASS_TX_ERR         165
                                        
  `define CH4_CPLLLOCK                   164
  `define CH3_CPLLLOCK                   163
  `define CH2_CPLLLOCK                   162
  `define CH1_CPLLLOCK                   161

  `define MMCM_RXUSRCLK_LOCKED           160
  `define MMCM_RXUSRCLK_CONFIG_DONE      159
  `define MMCM_TXUSRCLK_LOCKED           158
  `define MMCM_TXUSRCLK_CONFIG_DONE      157

  `define CH4_RXPRBSERR                  156
  `define CH3_RXPRBSERR                  155
  `define CH2_RXPRBSERR                  154
  `define CH1_RXPRBSERR                  153

  `define CH4_RXBUFSTATUS            152:150
  `define CH4_RXCDRLOCK                  149

  `define CH3_RXBUFSTATUS            148:146
  `define CH3_RXCDRLOCK                  145

  `define CH2_RXBUFSTATUS            144:142
  `define CH2_RXCDRLOCK                  141

  `define CH1_RXBUFSTATUS            140:138
  `define CH1_RXCDRLOCK                  137

  `define CH4_TXBUFSTATUS            136:135
  `define CH4_TXDLYRESETDONE             134
  `define CH4_TXPHINITDONE               133
  `define CH4_TXPHALIGNDONE              132

  `define CH3_TXBUFSTATUS            131:130
  `define CH3_TXDLYRESETDONE             129
  `define CH3_TXPHINITDONE               128
  `define CH3_TXPHALIGNDONE              127

  `define CH2_TXBUFSTATUS            126:125
  `define CH2_TXDLYRESETDONE             124
  `define CH2_TXPHINITDONE               123
  `define CH2_TXPHALIGNDONE              122

  `define CH1_TXBUFSTATUS            121:120
  `define CH1_TXDLYRESETDONE             119
  `define CH1_TXPHINITDONE               118
  `define CH1_TXPHALIGNDONE              117

  `define COMMON_DRPBUSY                 116
  `define COMMON_DRPRDY                  115
  `define COMMON_DRPDO                114:99

  `define CH4_DRPBUSY                     98
  `define CH4_DRPRDY                      97
  `define CH4_DRPDO                    96:81

  `define CH3_DRPBUSY                     80
  `define CH3_DRPRDY                      79
  `define CH3_DRPDO                    78:63

  `define CH2_DRPBUSY                     62
  `define CH2_DRPRDY                      61
  `define CH2_DRPDO                    60:45

  `define CH1_DRPBUSY                     44
  `define CH1_DRPRDY                      43
  `define CH1_DRPDO                    42:27

  `define CH4_RXGTPOWERGOOD               26
  `define CH4_RXPMARESETDONE              25
  `define CH4_RXRESETDONE                 24

  `define CH3_RXGTPOWERGOOD               23
  `define CH3_RXPMARESETDONE              22
  `define CH3_RXRESETDONE                 21

  `define CH2_RXGTPOWERGOOD               20
  `define CH2_RXPMARESETDONE              19
  `define CH2_RXRESETDONE                 18

  `define CH1_RXGTPOWERGOOD               17
  `define CH1_RXPMARESETDONE              16
  `define CH1_RXRESETDONE                 15

  `define CH4_TXGTPOWERGOOD               14
  `define CH4_TXPMARESETDONE              13
  `define CH4_TXRESETDONE                 12

  `define CH3_TXGTPOWERGOOD               11
  `define CH3_TXPMARESETDONE              10
  `define CH3_TXRESETDONE                  9

  `define CH2_TXGTPOWERGOOD                8
  `define CH2_TXPMARESETDONE               7
  `define CH2_TXRESETDONE                  6

  `define CH1_TXGTPOWERGOOD                5
  `define CH1_TXPMARESETDONE               4
  `define CH1_TXRESETDONE                  3

  `define QPLL1LOCK                        2
  `define QPLLLOCK                         1
  `define RESERVED1                        0

  //CDC Defs
  `define CDC_PULSE      0
  `define CDC_LEVEL      1
  `define CDC_LEVEL_ACK  2
  //XPM_CDC defines
  `define USE_XPM_CDC_PULSE 
  `define USE_XPM_CDC_SINGLE
  `define USE_XPM_CDC_ARRAY_SINGLE 

  `define XPM_CDC_VERSION 0
  `define XPM_CDC_SIM_ASYNC_RAND 0
  `define XPM_CDC_SIM_ASSERT_CHK 0
  `define XPM_CDC_MTBF_FFS 3

`endif

