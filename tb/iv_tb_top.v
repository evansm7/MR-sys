/* Instantiates a tb_top component, giving it CLK/reset.
 *
 * This is used by iverilog sims, which generate their own clock etc. in Verilog.
 * Verilator uses a different (C) wrapper, which instantiates the same component.
 *
 * Also, this inserts a dummy extra level of hierarchy so that VCDs match those
 * from Verilator (and can use the same save files!).
 *
 * 30/5/20 ME
 *
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

`define CLK   10
`define CLK_P (`CLK/2)

module glbl();
   reg  GSR;
   reg  GTS;

   initial begin
      GSR = 0;
      GTS = 0;
   end
endmodule // glbl

module TOP();

   reg 			clk;
   reg 			reset;

   always #`CLK_P       clk <= ~clk;

   tb_top tb_top(.clk(clk),
		 .reset(reset)
		 );

   initial begin
      clk <= 0;
      reset <= 1;

      #(`CLK*2);

      reset <= 0;

      #`CLK_P;

      #(`CLK*500000000);

      $finish;
   end

endmodule // TOP
