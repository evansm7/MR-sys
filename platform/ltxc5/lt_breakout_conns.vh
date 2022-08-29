/*
 * Copyright 2020-2022 Matt Evans
 * SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 * Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may
 * not use this file except in compliance with the License, or, at your option,
 * the Apache License version 2.0. You may obtain a copy of the License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 * Unless required by applicable law or agreed to in writing, any work
 * distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

`ifndef LT_BREAKOUT_CONNS_VH
`define LT_BREAKOUT_CONNS_VH

/*
 * Pinouts for LT breakout board w/ add-on boards.
 * Currently:
 * - PORT E = protoboard w/ buttons A & B
 * - PORT A & B = DVI board
 * - PORT D = Buffer board for plasma panel
 */

/* Protoboard on PORT E */
`define LT_PROTO_E0 	  YU[119]
`define LT_PROTO_E1 	  YU[118]
`define LT_PROTO_E2 	  YU[117]
`define LT_PROTO_E3 	  YU[116]
`define LT_PROTO_E4 	  YU[115]
`define LT_PROTO_E5 	  YU[114]
`define LT_PROTO_E6 	  YU[113]
`define LT_PROTO_E7 	  YU[112]
`define LT_PROTO_E8 	  YU[111]
`define LT_PROTO_E9 	  YU[110]
`define LT_PROTO_E10 	  YU[109]
`define LT_PROTO_E11 	  YU[108]
`define LT_PROTO_E12 	  YU[107]
`define LT_PROTO_E13 	  YU[106]
`define LT_PROTO_E14 	  YU[105]
`define LT_PROTO_E15 	  YU[104]

/* Protoboard on PORT F */
`define LT_PROTO_F0 	  YU[143]
`define LT_PROTO_F1 	  YU[142]
`define LT_PROTO_F2 	  YU[141]
`define LT_PROTO_F3 	  YU[140]
`define LT_PROTO_F4 	  YU[139]
`define LT_PROTO_F5 	  YU[138]
`define LT_PROTO_F6 	  YU[137]
`define LT_PROTO_F7 	  YU[136]
`define LT_PROTO_F8 	  YU[135]
`define LT_PROTO_F9 	  YU[134]
`define LT_PROTO_F10 	  YU[133]
`define LT_PROTO_F11 	  YU[132]
`define LT_PROTO_F12 	  YU[131]
`define LT_PROTO_F13 	  YU[130]
`define LT_PROTO_F14 	  YU[129]
`define LT_PROTO_F15 	  YU[128]

`define LT_PROTO_BTN_A 	  `LT_PROTO_F0
`define LT_PROTO_BTN_B 	  `LT_PROTO_F1
`define LT_PROTO_TX0 	  `LT_PROTO_F2
`define LT_PROTO_RX0 	  `LT_PROTO_F3
`define LT_PROTO_TX1 	  `LT_PROTO_F4
`define LT_PROTO_RX1 	  `LT_PROTO_F5
`define LT_PROTO_PS2MC 	  `LT_PROTO_F6
`define LT_PROTO_PS2MD 	  `LT_PROTO_F7
`define LT_PROTO_PS2KC 	  `LT_PROTO_F8
`define LT_PROTO_PS2KD	  `LT_PROTO_F9
`define LT_PROTO_BCLK	  `LT_PROTO_F10
`define LT_PROTO_DATA	  `LT_PROTO_F11
`define LT_PROTO_WCLK	  `LT_PROTO_F12
`define LT_PROTO_BTRST	  `LT_PROTO_F13
`define LT_PROTO_SPARE1	  `LT_PROTO_F14
`define LT_PROTO_SPARE2	  `LT_PROTO_F15

/* DVI board on PORT A/B */
`define LT_DVI_AB_SDA     YU[58] // B15
`define LT_DVI_AB_SCL     YU[59] // B14
`define LT_DVI_AB_HS      YU[60] // B13
`define LT_DVI_AB_VS      YU[61] // B12
`define LT_DVI_AB_DE      YU[62] // B11
`define LT_DVI_AB_CLK     YU[88] // A1

/* Pixel data separate lines */
`define LT_DVI_AB_D0      YU[63] // B10
`define LT_DVI_AB_D1      YU[64] // B9
`define LT_DVI_AB_D2      YU[65] // B8
`define LT_DVI_AB_D3      YU[66] // B7
`define LT_DVI_AB_D4      YU[67] // B6
`define LT_DVI_AB_D5      YU[68] // B5
`define LT_DVI_AB_D6      YU[70] // B3
`define LT_DVI_AB_D7      YU[69] // B4
`define LT_DVI_AB_D8      YU[72] // B1
`define LT_DVI_AB_D9      YU[71] // B2
`define LT_DVI_AB_D10     YU[73] // B0
`define LT_DVI_AB_D11     YU[74] // A15
`define LT_DVI_AB_D12     YU[75] // A14
`define LT_DVI_AB_D13     YU[76] // A13
`define LT_DVI_AB_D14     YU[77] // A12
`define LT_DVI_AB_D15     YU[78] // A11
`define LT_DVI_AB_D16     YU[79] // A10
`define LT_DVI_AB_D17     YU[80] // A9
`define LT_DVI_AB_D18     YU[81] // A8
`define LT_DVI_AB_D19     YU[82] // A7
`define LT_DVI_AB_D20     YU[83] // A6
`define LT_DVI_AB_D21     YU[84] // A5
`define LT_DVI_AB_D22     YU[86] // A3
`define LT_DVI_AB_D23     YU[85] // A4

/* Alternatively, pixel data in RGB24: */
`define LT_DVI_AB_RGB     {YU[85],YU[86],YU[84:73],YU[71],YU[72],YU[69],YU[70],YU[68:63]} // {A[4],A[3],A[5:15],B[0],B[2],B[1],B[4],B[3],B[5:10]}

/* SPI & SD board on port C */
`define LT_SPI_C_SD_CLK	  YU[57]
`define LT_SPI_C_SD_CMD	  YU[56]
`define LT_SPI_C_IRQ1	  YU[55]
`define LT_SPI_C_RST1	  YU[54]
`define LT_SPI_C_CLK1	  YU[53]
`define LT_SPI_C_DOUT1	  YU[52]
`define LT_SPI_C_DIN1	  YU[51]
`define LT_SPI_C_CS1	  YU[50]
`define LT_SPI_C_CLK0	  YU[49]
`define LT_SPI_C_DOUT0	  YU[48]
`define LT_SPI_C_DIN0	  YU[47]
`define LT_SPI_C_CS0	  YU[46]
`define LT_SPI_C_SD_D0	  YU[45]
`define LT_SPI_C_SD_D1	  YU[44]
`define LT_SPI_C_SD_D2	  YU[43]
`define LT_SPI_C_SD_D3	  YU[42]

/* PDP driver board on port D */

`define LT_PDP_D_VS       YU[0] // D15
`define LT_PDP_D_HS       YU[1] // D14
`define LT_PDP_D_D0       YU[2] // D13
`define LT_PDP_D_D1       YU[3] // D12
`define LT_PDP_D_D2       YU[4] // D11
`define LT_PDP_D_D3       YU[5] // D10
`define LT_PDP_D_DTIM     YU[6] // D9
`define LT_PDP_D_CLK      YU[7] // D8
`define LT_PDP_D_DISABLE  YU[8] // D7
`define LT_PDP_D_BLANK    YU[9] // D6

`define LT_FTDI_D0        YU[90] // UART TX (input to FPGA)
`define LT_FTDI_D1        YU[91] // UART RX (output from FPGA)
`define LT_FTDI_D2        YU[92]
`define LT_FTDI_D3        YU[93]
`define LT_FTDI_D4        YU[94]
`define LT_FTDI_D5        YU[95]
`define LT_FTDI_D6        YU[96]
`define LT_FTDI_D7        YU[98]
`define LT_FTDI_CLK       YU[97]
`define LT_FTDI_NRXF      YU[99]
`define LT_FTDI_NTXE      YU[100]
`define LT_FTDI_NRD       YU[101]
`define LT_FTDI_NWR       YU[102]
`define LT_FTDI_NOE       YU[103]
`define LT_FTDI_TX        `LT_FTDI_D0
`define LT_FTDI_RX        `LT_FTDI_D1

// When plugged onto an IM-LT1/IM-LT2 baseboard, we
// get more switches/LEDs:
`define LT_BB_LEDS	  YL[60:53]
`define LT_BB_SW	  YL[52:45]

`define LT_MISC0	  YU[16]
`define LT_MISC1	  YU[17]
`define LT_MISC2	  YU[18]
`define LT_MISC3	  YU[19]
`define LT_MISC4	  YU[20]
`define LT_MISC5	  YU[21]
`define LT_MISC6	  YU[30]
`define LT_MISC7	  YU[31]

`endif //  `ifndef LT_BREAKOUT_CONNS_VH
