/* Instantiate an mr_top SoC and load its boot memory.
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

//`define DEBUG 1


`ifdef VERILATOR
 `ifdef REAL_RAM
// RAM uses Xilinx sim models which need a glbl.GSR signal:
module glbl();
   reg  GSR;
   reg  GTS;

   initial begin
      GSR = 0;
      GTS = 0;
   end
endmodule // glbl
`endif
`endif //  `ifdef VERILATOR


module tb_top(input wire clk,
	      input wire reset);

   // Bit31 = running in sim
   // Bits[7:0] = switches
   wire [31:0] 		 gpio/*verilator public_flat*/;
   assign gpio = 32'h80000000;

   /* Debug bytestream channel: to be driven by verilated TB */
   wire [7:0] 		 dbg_tx_data/*verilator public_flat*/;
   wire 		 dbg_tx_has_data/*verilator public_flat*/;
   wire 		 dbg_tx_consume/*verilator public_flat*/;
   wire [7:0] 		 dbg_rx_data/*verilator public_flat*/;
   wire 		 dbg_rx_has_space/*verilator public_flat*/;
   wire 		 dbg_rx_produce/*verilator public_flat*/;
   assign dbg_tx_consume = dbg_tx_has_data;
   assign dbg_rx_data = 8'h0;
   assign dbg_rx_produce = 0;

   ////////////////////////////////////////////////////////////////////////////////

   wire [20:0] r_a_addr;
   wire        r_a_ncen;
   wire        r_a_nce;
   wire        r_a_advld;
   wire        r_a_nwe;
   wire [7:0]  r_a_nbw;
   wire [63:0] r_a_dq;
   wire        r_a_clk;

   wire [20:0] r_b_addr;
   wire        r_b_ncen;
   wire        r_b_nce;
   wire        r_b_advld;
   wire        r_b_nwe;
   wire [7:0]  r_b_nbw;
   wire [63:0] r_b_dq;
   wire        r_b_clk;

   wire        vid0_pclk;
   wire [23:0] vid0_rgb/*verilator public_flat*/;
   wire        vid0_hs/*verilator public_flat*/;
   wire        vid0_vs/*verilator public_flat*/;
   wire        vid0_de/*verilator public_flat*/;
   wire        vid0_blank/*verilator public_flat*/;

   wire        sd_clk;
   wire        sd_cmd;
   wire        sd_cmd_out;
   wire        sd_cmd_out_en;
   wire [3:0]  sd_data;
   wire [3:0]  sd_data_out;
   wire        sd_data_out_en;

`ifdef WITH_EXTERNAL_SD_MODEL
   assign sd_data = sd_data_out_en ? sd_data_out : 4'bzzzz;
   assign sd_cmd = sd_cmd_out_en ? sd_cmd_out : 1'bz;

   // SD model
   sdModel	#(.ramdisk("sd_img.hex"),
                  .log_file("sd_log.txt")
                  ) SD_MODEL (.sdClk(sd_clk),
                              .cmd(sd_cmd),
                              .dat(sd_data)
                              );

   // Ew
   pullup	PUC (sd_cmd);
   pullup	PUC (sd_data[0]);
`else // !`ifdef WITH_EXTERNAL_SD_MODEL
   /* Looks like no card connected */
   assign sd_data = 4'b1111;
   assign sd_cmd = 1'b1;
`endif

   /* Instruct the s_bram to load contents from ram_init.hex */
   mr_top #(.RAM_INIT_FILE("ram_init.hex")
`ifdef REAL_RAM
            , .REAL_RAM(1)
`endif
            )
          MR(.clk(clk),
	     .reset(reset),

	     .vid0_pclk(clk),
	     .vid0_rgb(vid0_rgb),
	     .vid0_hs(vid0_hs),
	     .vid0_vs(vid0_vs),
	     .vid0_de(vid0_de),
	     .vid0_blank(vid0_blank),

	     .gpio_i(gpio),

	     .ram_a_ncen(r_a_ncen),
	     .ram_a_nce0(r_a_nce),
	     .ram_a_nce1(),
	     .ram_a_advld(r_a_advld),
	     .ram_a_nwe(r_a_nwe),
	     .ram_a_nbw(r_a_nbw),
	     .ram_a_addr(r_a_addr),
	     .ram_a_dq(r_a_dq),

	     .ram_b_ncen(r_b_ncen),
	     .ram_b_nce0(r_b_nce),
	     .ram_b_nce1(),
	     .ram_b_advld(r_b_advld),
	     .ram_b_nwe(r_b_nwe),
	     .ram_b_nbw(r_b_nbw),
	     .ram_b_addr(r_b_addr),
	     .ram_b_dq(r_b_dq),

	     .console_tx(),
	     .console_rx(1'b1),

	     .dbg_tx_data(dbg_tx_data),
	     .dbg_tx_has_data(dbg_tx_has_data),
	     .dbg_tx_consume(dbg_tx_consume),
	     .dbg_rx_data(dbg_rx_data),
	     .dbg_rx_has_space(dbg_rx_has_space),
	     .dbg_rx_produce(dbg_rx_produce),

             .sd_clk(sd_clk),
             .sd_data_in(sd_data),
             .sd_data_out(sd_data_out),
             .sd_data_out_en(sd_data_out_en),
             .sd_cmd_in(sd_cmd),
             .sd_cmd_out(sd_cmd_out),
             .sd_cmd_out_en(sd_cmd_out_en)
	     );

`ifdef REAL_RAM
   /* RAM models: */
   assign r_clk = clk;

   wire [7:0]  dummy_dq = 8'h0;
   G8640Z36T SSRAMA(.A(r_a_addr[20:0]),
		    .CK(r_a_clk),
		    .nBa(r_a_nbw[0]),
		    .nBb(r_a_nbw[1]),
		    .nBc(r_a_nbw[2]),
		    .nBd(r_a_nbw[3]),
		    .nW(r_a_nwe),
		    .nE1(r_a_nce),
		    .E2(1'b1),
		    .nE3(1'b0),
		    .nG(1'b0),
		    .pADV(1'b0),
		    .nCKE(1'b0),
		    .DQa({dummy_dq[0], r_a_dq[7:0]}),
		    .DQb({dummy_dq[1], r_a_dq[15:8]}),
		    .DQc({dummy_dq[2], r_a_dq[23:16]}),
		    .DQd({dummy_dq[3], r_a_dq[31:24]}),
		    .ZZ(1'b0),
		    .nFT(1'b0), // Flowthrough mode
		    .nLBO(1'b0) // aka MODE
		    );

   G8640Z36T SSRAMB(.A(r_a_addr[20:0]),
		    .CK(r_a_clk),
		    .nBa(r_a_nbw[4]),
		    .nBb(r_a_nbw[5]),
		    .nBc(r_a_nbw[6]),
		    .nBd(r_a_nbw[7]),
		    .nW(r_a_nwe),
		    .nE1(r_a_nce),
		    .E2(1'b1),
		    .nE3(1'b0),
		    .nG(1'b0),
		    .pADV(1'b0),
		    .nCKE(1'b0),
		    .DQa({dummy_dq[4], r_a_dq[39:32]}),
		    .DQb({dummy_dq[5], r_a_dq[47:40]}),
		    .DQc({dummy_dq[6], r_a_dq[55:48]}),
		    .DQd({dummy_dq[7], r_a_dq[63:56]}),
		    .ZZ(1'b0),
		    .nFT(1'b0), // Flowthrough mode
		    .nLBO(1'b0) // aka MODE
		    );

   G8640Z36T SSRAMC(.A(r_b_addr[20:0]),
		    .CK(r_b_clk),
		    .nBa(r_b_nbw[0]),
		    .nBb(r_b_nbw[1]),
		    .nBc(r_b_nbw[2]),
		    .nBd(r_b_nbw[3]),
		    .nW(r_b_nwe),
		    .nE1(r_b_nce),
		    .E2(1'b1),
		    .nE3(1'b0),
		    .nG(1'b0),
		    .pADV(1'b0),
		    .nCKE(1'b0),
		    .DQa({dummy_dq[0], r_b_dq[7:0]}),
		    .DQb({dummy_dq[1], r_b_dq[15:8]}),
		    .DQc({dummy_dq[2], r_b_dq[23:16]}),
		    .DQd({dummy_dq[3], r_b_dq[31:24]}),
		    .ZZ(1'b0),
		    .nFT(1'b0), // Flowthrough mode
		    .nLBO(1'b0) // aka MODE
		    );

   G8640Z36T SSRAMD(.A(r_b_addr[20:0]),
		    .CK(r_b_clk),
		    .nBa(r_b_nbw[4]),
		    .nBb(r_b_nbw[5]),
		    .nBc(r_b_nbw[6]),
		    .nBd(r_b_nbw[7]),
		    .nW(r_b_nwe),
		    .nE1(r_b_nce),
		    .E2(1'b1),
		    .nE3(1'b0),
		    .nG(1'b0),
		    .pADV(1'b0),
		    .nCKE(1'b0),
		    .DQa({dummy_dq[4], r_b_dq[39:32]}),
		    .DQb({dummy_dq[5], r_b_dq[47:40]}),
		    .DQc({dummy_dq[6], r_b_dq[55:48]}),
		    .DQd({dummy_dq[7], r_b_dq[63:56]}),
		    .ZZ(1'b0),
		    .nFT(1'b0), // Flowthrough mode
		    .nLBO(1'b0) // aka MODE
		    );

`endif //  `ifdef REAL_RAM

   ////////////////////////////////////////////////////////////////////////////////

`ifndef VERILATOR
   reg 			junk;
`endif

   initial begin
`ifndef VERILATOR
      if (!$value$plusargs("NO_VCD=%d", junk)) begin
         $dumpfile("tb_top.vcd");
         $dumpvars(0, TOP);
      end
`endif
   end

endmodule
