/* v5clkout
 *
 * Output a clock on a pin using the DDR FF technique.
 * Includes some slightly filthy hack options for delayed clocks
 *
 * Copyright 2020 Matt Evans
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

//`define MAKE_DELAY yes
//`define INVERT_CLK yes
`define DELAY_VALUE 15  	/* (units of 81.38ps) */
// empirically, 63 is less than 5, about 4.  so 1ns is about 16

// 72MHz is 13.88888ns
// at 270deg (90 behind), clock is 3.47ns behind
// delay 2.47 and it's 1ns behind
// 2.47ns should therefore be... 30-33?
// 72/30 nope

module v5clkout(input wire clk, output wire O);

   wire out_intermediate;
   wire out_delayed;

   (* IOB = "FORCE" *)
   ODDR #(
          .DDR_CLK_EDGE("OPPOSITE_EDGE"),
          .INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
          .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
          ) clock_forward_instA (
                                 .Q(out_intermediate),     // 1-bit DDR output data
                                 .C(clk),  // 1-bit clock input
                                 .CE(1),      // 1-bit clock enable input
`ifdef INVERT_CLK
                                 .D1(1'b0), // 1-bit data input (associated with rising edge)
                                 .D2(1'b1), // 1-bit data input (associated with falling edge)
`else
                                 .D1(1'b1), // 1-bit data input (associated with rising edge)
                                 .D2(1'b0), // 1-bit data input (associated with falling edge)
`endif
                                 .R(0),   // 1-bit reset input
                                 .S(0)   // 1-bit set input
                                 );

`ifdef MAKE_DELAY
   IODELAY # (
              .DELAY_SRC("O"),
              .IDELAY_TYPE("FIXED"),
              .IDELAY_VALUE(0),
              .ODELAY_VALUE(`DELAY_VALUE),
              .REFCLK_FREQUENCY(192)
              ) IODELAY_INST (.DATAOUT(out_delayed),
                              .IDATAIN(1'b0),
                              .DATAIN(1'b0),
                              .ODATAIN(out_intermediate),
                              .T(1'b0),
                              .CE(1'b0),
                              .INC(1'b0),
                              .C(1'b0),
                              .RST(1'b0));

   assign O  = out_delayed;
`else
   assign O  = out_intermediate;
`endif

endmodule // v5clkout
