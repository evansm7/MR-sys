/* Module to generate system clocks for Virtex 5
 *
 * We want regular system clock, an SSRAM clock and an external SSRAM clock.
 *
 * This also generates a 200MHz clock for the IDELAYCTRL reference.
 *
 * Copyright 2020-2021 Matt Evans
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

module v5clocks(input wire refclk,
                output wire locked,
                output wire clk_regular,
                output wire clk_2x,
                output wire clk_ram,
                output wire clk_ram_ext // phase-shifted?
                );

   parameter REFCLK_RATE = 24000000;
   parameter SYSCLK_RATE = 50000000;

   wire                     clk_regular_b;
   wire                     clk_2x_b;
   wire			    clk_200M_b;
   wire			    clk_ram_b;
   wire			    clk_ram_ext_b;
   wire                     clk_200M;
   wire                     pll_fb;

   wire                     dcm_reset;
   wire                     locked_ref;

   /* Reset based off refclk */
   reset_wait dcm_rst(.clk(refclk), .reset(dcm_reset));

   /* Internal reference clock, phase-unrelated to external input;
    * a regular DCM won't take a clock as slow as 24M.  So, use a
    * PLL instead to create multiple clocks (and de-jitter):
    */
   localparam 		    M = 25; // 24*25 = 600, in range 400-1000

   PLL_BASE #(.CLKOUT0_PHASE(0),
              .CLKOUT0_DUTY_CYCLE(0.5),
              .CLKOUT0_DIVIDE(REFCLK_RATE*M/SYSCLK_RATE),

              .CLKOUT1_PHASE(0),
              .CLKOUT1_DUTY_CYCLE(0.5),
              .CLKOUT1_DIVIDE(M/2), // 2x

              // 200MHz clock for ODELAY reference:
              .CLKOUT2_PHASE(0),
              .CLKOUT2_DUTY_CYCLE(0.5),
              .CLKOUT2_DIVIDE(REFCLK_RATE*M/200000000),

              // Fast RAM for external and phase-shifted/270° internal:
              .CLKOUT3_PHASE(0),
              .CLKOUT3_DUTY_CYCLE(0.5),
              .CLKOUT3_DIVIDE(REFCLK_RATE*M/100000000),

              .CLKOUT4_PHASE(270),
              .CLKOUT4_DUTY_CYCLE(0.5),
              .CLKOUT4_DIVIDE(REFCLK_RATE*M/100000000),

              .CLKIN_PERIOD(1000000000/REFCLK_RATE),
              .CLKFBOUT_PHASE(0),
              .CLKFBOUT_MULT(M)
              )
            pll1(.RST(dcm_reset), .CLKIN(refclk),
                 .CLKFBOUT(pll_fb), .CLKFBIN(pll_fb),

                 .CLKOUT0(clk_regular_b),
                 .CLKOUT1(clk_2x_b),
                 .CLKOUT2(clk_200M_b),
                 .CLKOUT3(clk_ram_b),
                 .CLKOUT4(clk_ram_ext_b),

                 .LOCKED(locked_ref)
                 );

   BUFG clk_reg_buf(.I(clk_regular_b), .O(clk_regular));
   BUFG clk_2x_buf(.I(clk_2x_b), .O(clk_2x));
   BUFG idc_buf(.I(clk_200M_b), .O(clk_200M));
   BUFG clk_ram_buf(.I(clk_ram_b), .O(clk_ram));
   BUFG clk_ram_ext_buf(.I(clk_ram_ext_b), .O(clk_ram_ext));

   IDELAYCTRL idctrl(.REFCLK(clk_200M), .RST(~locked_delay));

   assign locked = !dcm_reset && locked_ref;

endmodule // v5clocks
