/* Simple shift register to give a 4-clock active-high reset pulse
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

module reset_wait(input wire clk,
                  output wire reset);

   wire                       rst_1, rst_2, rst_3;

   FD #(.INIT(1)) rstff_1 (.C(clk), .D(1'b0), .Q(rst_1));

   FD #(.INIT(1)) rstff_2 (.C(clk), .D(rst_1), .Q(rst_2));

   FD #(.INIT(1)) rstff_3 (.C(clk), .D(rst_2), .Q(rst_3));

   FD #(.INIT(1)) rstff_4 (.C(clk), .D(rst_3), .Q(reset));

endmodule // reset_wait
