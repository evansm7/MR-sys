/* Top-level generic SoC for MattRISC project
 *
 * This module is wrapped by a platform module which generates clocks,
 * resets etc. (in a platform-specific way).
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


module mr_top(input wire         clk,
	      input wire         reset,

	      input wire         vid0_pclk,
	      output wire [23:0] vid0_rgb,
	      output wire        vid0_hs,
	      output wire        vid0_vs,
	      output wire        vid0_de,
	      output wire        vid0_blank,

	      input wire [31:0]  gpio_i,
	      output wire [31:0] gpio_o,

	      output wire        ram_a_ncen,
	      output wire        ram_a_nce0,
	      output wire        ram_a_nce1,
	      output wire        ram_a_advld,
	      output wire        ram_a_nwe,
	      output wire [7:0]  ram_a_nbw,
	      output wire [20:0] ram_a_addr,
	      inout wire [63:0]  ram_a_dq,

              output wire        ram_b_ncen,
	      output wire        ram_b_nce0,
	      output wire        ram_b_nce1,
	      output wire        ram_b_advld,
	      output wire        ram_b_nwe,
	      output wire [7:0]  ram_b_nbw,
	      output wire [20:0] ram_b_addr,
	      inout wire [63:0]  ram_b_dq,

	      output wire        console_tx,
	      input wire         console_rx,

	      output wire [7:0]  dbg_tx_data,
              output wire        dbg_tx_has_data,
	      input wire         dbg_tx_consume,
	      input wire [7:0]   dbg_rx_data,
	      output wire        dbg_rx_has_space,
	      input wire         dbg_rx_produce,

              output wire        i2s_dout,
              output wire        i2s_bclk,
              output wire        i2s_wclk,

              output wire        spi_0_sclk,
              output wire        spi_0_dout,
              input wire         spi_0_din,
              output wire        spi_0_cs0,
              output wire        spi_1_sclk,
              output wire        spi_1_dout,
              input wire         spi_1_din,
              output wire        spi_1_cs0,
              input wire         spi_1_irq, // External interrupt associated with SPI1

              input wire         ps2_kbd_clk_in,
              output wire        ps2_kbd_clk_pd,
              input wire         ps2_kbd_dat_in,
              output wire        ps2_kbd_dat_pd,
              input wire         ps2_mse_clk_in,
              output wire        ps2_mse_clk_pd,
              input wire         ps2_mse_dat_in,
              output wire        ps2_mse_dat_pd,

              output wire        sd_clk,
              input wire         sd_cmd_in,
              output wire        sd_cmd_out,
              output wire        sd_cmd_out_en,
              input wire [3:0]   sd_data_in,
              output wire [3:0]  sd_data_out,
              output wire        sd_data_out_en
	      );

   parameter CLK_RATE = 50000000;
   parameter RAM_INIT_FILE = "";
   parameter REAL_RAM = 0;
   parameter BLK_RAM_SIZE = 64;
   parameter BOOT_RAM_SIZE = 64;
   parameter WITH_I2S = 0;
   parameter WITH_LCDC0 = 0;
   parameter WITH_SD = 0;

   ///////////////////////////////////////////////////////////////////////////
   // Instantiate CPU

   /* MIC from requester (CPU) to mic */
   wire 			    r0o_tv; // Reqs
   wire 			    r0o_tr;
   wire [63:0] 			    r0o_td;
   wire 			    r0o_tl;
   wire 			    r0i_tv; // Resps
   wire 			    r0i_tr;
   wire [63:0] 			    r0i_td;
   wire 			    r0i_tl;

   /* MIC from other requesters: */
   wire 			    r1o_tv; // Reqs
   wire 			    r1o_tr;
   wire [63:0] 			    r1o_td;
   wire 			    r1o_tl;
   wire 			    r1i_tv; // Resps
   wire 			    r1i_tr;
   wire [63:0] 			    r1i_td;
   wire 			    r1i_tl;

   wire 			    r2o_tv; // Reqs
   wire 			    r2o_tr;
   wire [63:0] 			    r2o_td;
   wire 			    r2o_tl;
   wire 			    r2i_tv; // Resps
   wire 			    r2i_tr;
   wire [63:0] 			    r2i_td;
   wire 			    r2i_tl;

   wire 			    r3o_tv; // Reqs
   wire 			    r3o_tr;
   wire [63:0] 			    r3o_td;
   wire 			    r3o_tl;
   wire 			    r3i_tv; // Resps
   wire 			    r3i_tr;
   wire [63:0] 			    r3i_td;
   wire 			    r3i_tl;

   /* Second-level requesters (a bit further away, via an extra hop) */
   wire 			    r4o_tv; // Reqs
   wire 			    r4o_tr;
   wire [63:0] 			    r4o_td;
   wire 			    r4o_tl;
   wire 			    r4i_tv; // Resps
   wire 			    r4i_tr;
   wire [63:0] 			    r4i_td;
   wire 			    r4i_tl;

   wire 			    r5o_tv; // Reqs
   wire 			    r5o_tr;
   wire [63:0] 			    r5o_td;
   wire 			    r5o_tl;
   wire 			    r5i_tv; // Resps
   wire 			    r5i_tr;
   wire [63:0] 			    r5i_td;
   wire 			    r5i_tl;

   wire 			    r6o_tv; // Reqs
   wire 			    r6o_tr;
   wire [63:0] 			    r6o_td;
   wire 			    r6o_tl;
   wire 			    r6i_tv; // Resps
   wire 			    r6i_tr;
   wire [63:0] 			    r6i_td;
   wire 			    r6i_tl;

   wire 			    r7o_tv; // Reqs
   wire 			    r7o_tr;
   wire [63:0] 			    r7o_td;
   wire 			    r7o_tl;
   wire 			    r7i_tv; // Resps
   wire 			    r7i_tr;
   wire [63:0] 			    r7i_td;
   wire 			    r7i_tl;

   wire 			    irq;

   wire [63:0] 			    pctrs;

   /* CPU */
`define WITH_CPU yes_for_sure
`ifdef WITH_CPU
   mr_cpu_mic #(.IO_REGION(2'b10) /* IO 1G at 0x80000000 */,
		.HIGH_VECTORS(1)  /* Reset to 0xfff00100 */
		)
              CPU(.clk(clk),
		  .reset(reset),

		  .IRQ(irq),
		  .pctrs(pctrs),

		  .O_TVALID(r0o_tv),
		  .O_TREADY(r0o_tr),
		  .O_TDATA(r0o_td),
		  .O_TLAST(r0o_tl),

		  .I_TVALID(r0i_tv),
		  .I_TREADY(r0i_tr),
		  .I_TDATA(r0i_td),
		  .I_TLAST(r0i_tl)
		  );
`else
   assign r0o_tv = 0;
   assign r0o_td = 0;
   assign r0o_tl = 0;
`endif // !`ifdef WITH_CPU

   mr_pctrs PCTRS(.clk(clk),
		  .reset(reset),

		  .pctrs(pctrs)
		  /* Eventually, APB/IRQ */
		  );

   ///////////////////////////////////////////////////////////////////////////
   // Instantiate MIC interconnect

   wire 			    c0i_tv; // Reqs
   wire 			    c0i_tr;
   wire [63:0] 			    c0i_td;
   wire 			    c0i_tl;
   wire 			    c0o_tv; // Resps
   wire 			    c0o_tr;
   wire [63:0] 			    c0o_td;
   wire 			    c0o_tl;

   wire 			    c1i_tv; // Reqs
   wire 			    c1i_tr;
   wire [63:0] 			    c1i_td;
   wire 			    c1i_tl;
   wire 			    c1o_tv; // Resps
   wire 			    c1o_tr;
   wire [63:0] 			    c1o_td;
   wire 			    c1o_tl;

   wire 			    c2i_tv; // Reqs
   wire 			    c2i_tr;
   wire [63:0] 			    c2i_td;
   wire 			    c2i_tl;
   wire 			    c2o_tv; // Resps
   wire 			    c2o_tr;
   wire [63:0] 			    c2o_td;
   wire 			    c2o_tl;

   wire 			    c3i_tv; // Reqs
   wire 			    c3i_tr;
   wire [63:0] 			    c3i_td;
   wire 			    c3i_tl;
   wire 			    c3o_tv; // Resps
   wire 			    c3o_tr;
   wire [63:0] 			    c3o_td;
   wire 			    c3o_tl;

  /* The main interconnect */
   mic_4r4c #(.ROUTE_BIT(24) /* Hack: 16MB interleave to make C0/C1 mem contiguous */)
            MIC(.clk(clk),
		.reset(reset),

		/* Requester port 0 request input (from requester output) */
		.R0I_TVALID(r0o_tv),
		.R0I_TREADY(r0o_tr),
		.R0I_TDATA(r0o_td),
		.R0I_TLAST(r0o_tl),
		/* Requester port 0 response output (to response input) */
		.R0O_TVALID(r0i_tv),
		.R0O_TREADY(r0i_tr),
		.R0O_TDATA(r0i_td),
		.R0O_TLAST(r0i_tl),

		/* Requester port 1 request input */
		.R1I_TVALID(r1o_tv),
		.R1I_TREADY(r1o_tr),
		.R1I_TDATA(r1o_td),
		.R1I_TLAST(r1o_tl),
		/* Requester port 1 response output */
		.R1O_TVALID(r1i_tv),
		.R1O_TREADY(r1i_tr),
		.R1O_TDATA(r1i_td),
		.R1O_TLAST(r1i_tl),

		/* Req port 2 request input */
		.R2I_TVALID(r2o_tv),
		.R2I_TREADY(r2o_tr),
		.R2I_TDATA(r2o_td),
		.R2I_TLAST(r2o_tl),
		/* Req port 2 response output */
		.R2O_TVALID(r2i_tv),
		.R2O_TREADY(r2i_tr),
		.R2O_TDATA(r2i_td),
		.R2O_TLAST(r2i_tl),

		/* Requester port 3 request input (from second-level MIC) */
		.R3I_TVALID(r3o_tv),
		.R3I_TREADY(r3o_tr),
		.R3I_TDATA(r3o_td),
		.R3I_TLAST(r3o_tl),
		/* Requester port 3 response output */
		.R3O_TVALID(r3i_tv),
		.R3O_TREADY(r3i_tr),
		.R3O_TDATA(r3i_td),
		.R3O_TLAST(r3i_tl),

                //

		/* Completer port 0 request output (to device input) */
		.C0O_TVALID(c0i_tv),
		.C0O_TREADY(c0i_tr),
		.C0O_TDATA(c0i_td),
		.C0O_TLAST(c0i_tl),
		/* Completer port 0 response input (from device output) */
		.C0I_TVALID(c0o_tv),
		.C0I_TREADY(c0o_tr),
		.C0I_TDATA(c0o_td),
		.C0I_TLAST(c0o_tl),

		/* Completer port 1 request output (to in) */
		.C1O_TVALID(c1i_tv),
		.C1O_TREADY(c1i_tr),
		.C1O_TDATA(c1i_td),
		.C1O_TLAST(c1i_tl),
		/* Completer port 1 response input (from out) */
		.C1I_TVALID(c1o_tv),
		.C1I_TREADY(c1o_tr),
		.C1I_TDATA(c1o_td),
		.C1I_TLAST(c1o_tl),

		/* Completer port 2 request output (to in) */
		.C2O_TVALID(c2i_tv),
		.C2O_TREADY(c2i_tr),
		.C2O_TDATA(c2i_td),
		.C2O_TLAST(c2i_tl),
		/* Completer port 2 response input (from out) */
		.C2I_TVALID(c2o_tv),
		.C2I_TREADY(c2o_tr),
		.C2I_TDATA(c2o_td),
		.C2I_TLAST(c2o_tl),

		/* Completer port 3 request output (to in) */
		.C3O_TVALID(c3i_tv),
		.C3O_TREADY(c3i_tr),
		.C3O_TDATA(c3i_td),
		.C3O_TLAST(c3i_tl),
		/* Completer port 3 response input (from out) */
		.C3I_TVALID(c3o_tv),
		.C3I_TREADY(c3o_tr),
		.C3I_TDATA(c3o_td),
		.C3I_TLAST(c3o_tl)
		);

   mic_4r1c MICU1(.clk(clk),
		  .reset(reset),

                  /* Requester port 4 request input (from requester output) */
		  .R0I_TVALID(r4o_tv),
		  .R0I_TREADY(r4o_tr),
		  .R0I_TDATA(r4o_td),
		  .R0I_TLAST(r4o_tl),
		  /* Requester port 4 response output (to response input) */
		  .R0O_TVALID(r4i_tv),
		  .R0O_TREADY(r4i_tr),
		  .R0O_TDATA(r4i_td),
		  .R0O_TLAST(r4i_tl),

		  /* Requester port 5 request input */
		  .R1I_TVALID(r5o_tv),
		  .R1I_TREADY(r5o_tr),
		  .R1I_TDATA(r5o_td),
		  .R1I_TLAST(r5o_tl),
		  /* Requester port 5 response output */
		  .R1O_TVALID(r5i_tv),
		  .R1O_TREADY(r5i_tr),
		  .R1O_TDATA(r5i_td),
		  .R1O_TLAST(r5i_tl),

		  /* Requester port 6 request input */
		  .R2I_TVALID(r6o_tv),
		  .R2I_TREADY(r6o_tr),
		  .R2I_TDATA(r6o_td),
		  .R2I_TLAST(r6o_tl),
		  /* Requester port 6 response output */
		  .R2O_TVALID(r6i_tv),
		  .R2O_TREADY(r6i_tr),
		  .R2O_TDATA(r6i_td),
		  .R2O_TLAST(r6i_tl),

		  /* Requester port 7 request input */
		  .R3I_TVALID(r7o_tv),
		  .R3I_TREADY(r7o_tr),
		  .R3I_TDATA(r7o_td),
		  .R3I_TLAST(r7o_tl),
		  /* Requester port 7 response output */
		  .R3O_TVALID(r7i_tv),
		  .R3O_TREADY(r7i_tr),
		  .R3O_TDATA(r7i_td),
		  .R3O_TLAST(r7i_tl),

		  /* Completer port response input (to/from lower MIC) */
                  .C0O_TVALID(r3o_tv),
		  .C0O_TREADY(r3o_tr),
		  .C0O_TDATA(r3o_td),
		  .C0O_TLAST(r3o_tl),

		  .C0I_TVALID(r3i_tv),
		  .C0I_TREADY(r3i_tr),
		  .C0I_TDATA(r3i_td),
		  .C0I_TLAST(r3i_tl)
                  );

   /* Current port assignment:
    *	0	CPU0
    * 	1	-
    * 	2	-
    * 	3	(cascade to second MIC)
    * 	4	Audio
    * 	5	SD
    * 	6	Display
    * 	7	Debug
    */

   /* Tie off unused requester ports: */
   assign r1o_tv = 1'b0;
   assign r1o_td = 64'h0;
   assign r1o_tl = 1'b0;
   assign r1i_tr = 1'b0;

   assign r2o_tv = 1'b0;
   assign r2o_td = 64'h0;
   assign r2o_tl = 1'b0;
   assign r2i_tr = 1'b0;


   ///////////////////////////////////////////////////////////////////////////
   // Instantiate main memory at address 0/port 0 and 0x40000000/port1:

   generate
      if (REAL_RAM != 0) begin
         s_ssram RAMA_SRAM(.clk(clk),
		           .reset(reset),

		           .I_TDATA(c0i_td),
		           .I_TVALID(c0i_tv),
		           .I_TREADY(c0i_tr),
		           .I_TLAST(c0i_tl),

		           .O_TDATA(c0o_td),
		           .O_TVALID(c0o_tv),
		           .O_TREADY(c0o_tr),
		           .O_TLAST(c0o_tl),

		           .sram_clk(), // FIXME
		           .sram_ncen(ram_a_ncen),
		           .sram_nce0(ram_a_nce0),
		           .sram_nce1(ram_a_nce1),
		           .sram_advld(ram_a_advld),
		           .sram_nwe(ram_a_nwe),
		           .sram_nbw(ram_a_nbw),
		           .sram_addr(ram_a_addr[20:0]),
		           .sram_dq(ram_a_dq)
		           );

         s_ssram RAMB_SRAM(.clk(clk),
		           .reset(reset),

		           .I_TDATA(c1i_td),
		           .I_TVALID(c1i_tv),
		           .I_TREADY(c1i_tr),
		           .I_TLAST(c1i_tl),

		           .O_TDATA(c1o_td),
		           .O_TVALID(c1o_tv),
		           .O_TREADY(c1o_tr),
		           .O_TLAST(c1o_tl),

                           .sram_clk(), // FIXME
		           .sram_ncen(ram_b_ncen),
		           .sram_nce0(ram_b_nce0),
		           .sram_nce1(ram_b_nce1),
		           .sram_advld(ram_b_advld),
		           .sram_nwe(ram_b_nwe),
		           .sram_nbw(ram_b_nbw),
		           .sram_addr(ram_b_addr[20:0]),
		           .sram_dq(ram_b_dq)
		           );
      end else begin
         s_bram #(.NAME("RAM_BRAM"),
`ifdef SIM
                  .INIT_FILE("main_ram.hex"),
                  .KB_SIZE(16384)
`else
                  // Some non-sim HW platforms hit this (for now),
                  // so make this reasonable to actually synthesise.
                  .KB_SIZE(BLK_RAM_SIZE)
`endif
                  )
         RAMA_BRAM
	   (.clk(clk),
	    .reset(reset),

	    .I_TDATA(c0i_td),
	    .I_TVALID(c0i_tv),
	    .I_TREADY(c0i_tr),
	    .I_TLAST(c0i_tl),

	    .O_TDATA(c0o_td),
	    .O_TVALID(c0o_tv),
	    .O_TREADY(c0o_tr),
	    .O_TLAST(c0o_tl)
	    );

         s_bram #(.NAME("RAM_BRAM_B"),
`ifdef SIM
                  .KB_SIZE(16384)
`else
                  .KB_SIZE(BLK_RAM_SIZE)
`endif
                  )
         RAMB_BRAM
	   (.clk(clk),
	    .reset(reset),

	    .I_TDATA(c1i_td),
	    .I_TVALID(c1i_tv),
	    .I_TREADY(c1i_tr),
	    .I_TLAST(c1i_tl),

	    .O_TDATA(c1o_td),
	    .O_TVALID(c1o_tv),
	    .O_TREADY(c1o_tr),
	    .O_TLAST(c1o_tl)
	    );
      end
   endgenerate


   ///////////////////////////////////////////////////////////////////////////
   // Instantiate Block RAM at address 0xc0000000/port 3:

   s_bram #(.NAME("RAM_BOOT"),
            .KB_SIZE(BOOT_RAM_SIZE),
	    .INIT_FILE(RAM_INIT_FILE)
            )
          RAM_BOOT
	    (.clk(clk),
	     .reset(reset),

	     .I_TDATA(c3i_td),
	     .I_TVALID(c3i_tv),
	     .I_TREADY(c3i_tr),
	     .I_TLAST(c3i_tl),

	     .O_TDATA(c3o_td),
	     .O_TVALID(c3o_tv),
	     .O_TREADY(c3o_tr),
	     .O_TLAST(c3o_tl)
	     );


   ///////////////////////////////////////////////////////////////////////////
   // Instantiate MIC-APB bridge at address 0x80000000/port 2:

   wire [15:0] 			    apb_PADDR;
   wire 			    apb_PWRITE;

   wire 			    apb_PSEL;
   wire [3:0] 			    apb_PSEL_bank; // Decoded to...
   reg 				    apb_PSEL0;     // ...these
   reg 				    apb_PSEL1;
   reg 				    apb_PSEL2;
   reg 				    apb_PSEL3;
   reg 				    apb_PSEL4;
   reg 				    apb_PSEL5;
   reg 				    apb_PSEL6;
   reg 				    apb_PSEL7;
   reg 				    apb_PSEL8;
   reg 				    apb_PSEL9;
   reg 				    apb_PSEL10;
   reg 				    apb_PSEL11;
   reg 				    apb_PSEL12;
   reg 				    apb_PSEL13;
   reg 				    apb_PSEL14;
   reg 				    apb_PSEL15;

   wire 			    apb_PENABLE;
   wire [31:0] 			    apb_PWDATA;

   reg [31:0] 			    apb_PRDATA; // Wire
   wire [31:0] 			    apb_PRDATA0;
   wire [31:0] 			    apb_PRDATA1;
   wire [31:0] 			    apb_PRDATA2;
   wire [31:0] 			    apb_PRDATA3;
   wire [31:0] 			    apb_PRDATA4;
   wire [31:0] 			    apb_PRDATA5;
   wire [31:0] 			    apb_PRDATA6;
   wire [31:0] 			    apb_PRDATA7;
   wire [31:0] 			    apb_PRDATA8;
   wire [31:0] 			    apb_PRDATA9;
   wire [31:0] 			    apb_PRDATA10;
   wire [31:0] 			    apb_PRDATA11;
   wire [31:0] 			    apb_PRDATA12;
   wire [31:0] 			    apb_PRDATA13;
   wire [31:0] 			    apb_PRDATA14;
   wire [31:0] 			    apb_PRDATA15;

   reg 				    apb_PREADY; // Wire
   wire 			    apb_PREADY0 = 1; /* Not needed yet */
   wire 			    apb_PREADY1 = 1;
   wire 			    apb_PREADY2 = 1;
   wire 			    apb_PREADY3 = 1;
   wire 			    apb_PREADY4 = 1;
   wire 			    apb_PREADY5 = 1;
   wire 			    apb_PREADY6 = 1;
   wire 			    apb_PREADY7 = 1;
   wire 			    apb_PREADY8 = 1;
   wire 			    apb_PREADY9 = 1;
   wire 			    apb_PREADY10 = 1;
   wire 			    apb_PREADY11 = 1;
   wire 			    apb_PREADY12 = 1;
   wire 			    apb_PREADY13 = 1;
   wire 			    apb_PREADY14 = 1;
   wire 			    apb_PREADY15 = 1;


   s_mic_apb #(.DECODE_BITS(16),
	       .NUM_CSEL_LOG2(4) // Decode 16 devices
	       )
             APB_BRIDGE(.clk(clk),
			.reset(reset),

			.I_TDATA(c2i_td),
			.I_TVALID(c2i_tv),
			.I_TREADY(c2i_tr),
			.I_TLAST(c2i_tl),

			.O_TDATA(c2o_td),
			.O_TVALID(c2o_tv),
			.O_TREADY(c2o_tr),
			.O_TLAST(c2o_tl),

			.PADDR(apb_PADDR),
			.PWRITE(apb_PWRITE),
			.PSEL(apb_PSEL),
			.PSEL_BANK(apb_PSEL_bank),
			.PENABLE(apb_PENABLE),
			.PWDATA(apb_PWDATA),
			.PRDATA(apb_PRDATA),
			.PREADY(apb_PREADY)
			);

   /* Decode to APB peripherals */
   always @(*) begin
      apb_PREADY = 1'b0;
      apb_PRDATA = 32'h0;
      apb_PSEL0  = 1'b0;
      apb_PSEL1  = 1'b0;
      apb_PSEL2  = 1'b0;
      apb_PSEL3  = 1'b0;
      apb_PSEL4  = 1'b0;
      apb_PSEL5  = 1'b0;
      apb_PSEL6  = 1'b0;
      apb_PSEL7  = 1'b0;
      apb_PSEL8  = 1'b0;
      apb_PSEL9  = 1'b0;
      apb_PSEL10 = 1'b0;
      apb_PSEL11 = 1'b0;
      apb_PSEL12 = 1'b0;
      apb_PSEL13 = 1'b0;
      apb_PSEL14 = 1'b0;
      apb_PSEL15 = 1'b0;

      case (apb_PSEL_bank)
	4'd0: begin
	  apb_PREADY = apb_PREADY0;  apb_PRDATA = apb_PRDATA0;  apb_PSEL0  = apb_PSEL;
	end
	4'd1: begin
	  apb_PREADY = apb_PREADY1;  apb_PRDATA = apb_PRDATA1;  apb_PSEL1  = apb_PSEL;
	end
	4'd2: begin
	  apb_PREADY = apb_PREADY2;  apb_PRDATA = apb_PRDATA2;  apb_PSEL2  = apb_PSEL;
	end
	4'd3: begin
	  apb_PREADY = apb_PREADY3;  apb_PRDATA = apb_PRDATA3;  apb_PSEL3  = apb_PSEL;
	end
	4'd4: begin
	  apb_PREADY = apb_PREADY4;  apb_PRDATA = apb_PRDATA4;  apb_PSEL4  = apb_PSEL;
	end
	4'd5: begin
	  apb_PREADY = apb_PREADY5;  apb_PRDATA = apb_PRDATA5;  apb_PSEL5  = apb_PSEL;
	end
	4'd6: begin
	  apb_PREADY = apb_PREADY6;  apb_PRDATA = apb_PRDATA6;  apb_PSEL6  = apb_PSEL;
	end
	4'd7: begin
	  apb_PREADY = apb_PREADY7;  apb_PRDATA = apb_PRDATA7;  apb_PSEL7  = apb_PSEL;
	end
	4'd8: begin
	  apb_PREADY = apb_PREADY8;  apb_PRDATA = apb_PRDATA8;  apb_PSEL8  = apb_PSEL;
	end
	4'd9: begin
	  apb_PREADY = apb_PREADY9;  apb_PRDATA = apb_PRDATA9;  apb_PSEL9  = apb_PSEL;
	end
	4'd10: begin
	  apb_PREADY = apb_PREADY10; apb_PRDATA = apb_PRDATA10; apb_PSEL10 = apb_PSEL;
	end
	4'd11: begin
	  apb_PREADY = apb_PREADY11; apb_PRDATA = apb_PRDATA11; apb_PSEL11 = apb_PSEL;
	end
	4'd12: begin
	  apb_PREADY = apb_PREADY12; apb_PRDATA = apb_PRDATA12; apb_PSEL12 = apb_PSEL;
	end
	4'd13: begin
	  apb_PREADY = apb_PREADY13; apb_PRDATA = apb_PRDATA13; apb_PSEL13 = apb_PSEL;
	end
	4'd14: begin
	  apb_PREADY = apb_PREADY14; apb_PRDATA = apb_PRDATA14; apb_PSEL14 = apb_PSEL;
	end
	4'd15: begin
	  apb_PREADY = apb_PREADY15; apb_PRDATA = apb_PRDATA15; apb_PSEL15 = apb_PSEL;
	end
      endcase
   end


   ///////////////////////////////////////////////////////////////////////////
   // Peripherals

   wire [5:0] 			    pirqs; // 2 edge, 4 level
   assign pirqs[5] 		    = ~spi_1_irq; // Falling edge
   assign pirqs[4] 		    = 1'b0;

   // Device 0, console UART:
   apb_uart #(
`ifdef SIM
	      // Make the serial output really fast
	      .CLK_DIVISOR(5)
`else
	      .CLK_DIVISOR(CLK_RATE / 230400)
`endif
	      )
	    CONSOLE_UART(.clk(clk),
			 .reset(reset),

			 .PENABLE(apb_PENABLE),
			 .PSEL(apb_PSEL0),
			 .PWRITE(apb_PWRITE),
			 .PADDR(apb_PADDR[3:0]),
			 .PWDATA(apb_PWDATA),
			 .PRDATA(apb_PRDATA0),

			 .txd(console_tx),
			 .rxd(console_rx),

			 .IRQ(pirqs[0])
			 );

   // Device 1, KBD PS2:
   apb_uart_ps2 #(
	          .CLK_RATE(CLK_RATE)
	          )
	    KBD_PS2(.clk(clk),
		    .reset(reset),

		    .PENABLE(apb_PENABLE),
		    .PSEL(apb_PSEL1),
		    .PWRITE(apb_PWRITE),
		    .PADDR(apb_PADDR[3:0]),
		    .PWDATA(apb_PWDATA),
		    .PRDATA(apb_PRDATA1),

                    .ps2_clk_in(ps2_kbd_clk_in),
                    .ps2_clk_pd(ps2_kbd_clk_pd),
                    .ps2_dat_in(ps2_kbd_dat_in),
                    .ps2_dat_pd(ps2_kbd_dat_pd),

		    .IRQ(pirqs[1])
		    );

   // Device 2, Mouse PS2:
   apb_uart_ps2 #(
	          .CLK_RATE(CLK_RATE)
	          )
	    MSE_PS2(.clk(clk),
		    .reset(reset),

		    .PENABLE(apb_PENABLE),
		    .PSEL(apb_PSEL2),
		    .PWRITE(apb_PWRITE),
		    .PADDR(apb_PADDR[3:0]),
		    .PWDATA(apb_PWDATA),
		    .PRDATA(apb_PRDATA2),

                    .ps2_clk_in(ps2_mse_clk_in),
                    .ps2_clk_pd(ps2_mse_clk_pd),
                    .ps2_dat_in(ps2_mse_dat_in),
                    .ps2_dat_pd(ps2_mse_dat_pd),

		    .IRQ(pirqs[2])
		    );

   // Device 3, AUX UART
   assign apb_PRDATA3 = 32'h0;

   // Device 4, APB control for LCDC0:
   // FIXME: Parameterise this: for PDP, only 4BPP ever output so can save palette storage etc.
   generate
      if (WITH_LCDC0) begin
         m_lcdc_apb LCDC0(.sys_clk(clk),
		          .reset(reset),
		          /* MIC */
		          .O_TVALID(r6o_tv),
		          .O_TREADY(r6o_tr),
		          .O_TDATA(r6o_td),
		          .O_TLAST(r6o_tl),
		          .I_TVALID(r6i_tv),
		          .I_TREADY(r6i_tr),
		          .I_TDATA(r6i_td),
		          .I_TLAST(r6i_tl),

		          .PCLK(clk), // APB clock == sysclk
		          .nRESET(!reset),
		          .PENABLE(apb_PENABLE),
		          .PSEL(apb_PSEL4),
		          .PWRITE(apb_PWRITE),
		          .PADDR(apb_PADDR[5:0]),
		          .PWDATA(apb_PWDATA),
		          .PRDATA(apb_PRDATA4),

		          .pixel_clk(vid0_pclk),
		          .rgb(vid0_rgb),
		          .hs(vid0_hs),
		          .vs(vid0_vs),
		          .de(vid0_de),
		          .blank(vid0_blank),

		          .IRQ_VS( /* Not yet */ ),
		          .IRQ_HS( /* Not yet */ )
		          );
      end else begin // if (WITH_LCDC0)
         assign r6o_tv = 1'b0;
         assign r6o_td = 64'h0;
         assign r6o_tl = 1'b0;
         assign r6i_tr = 1'b0;
         assign apb_PRDATA4 = 32'h0;
         assign vid0_rgb = 24'h0;
         assign vid0_hs = 1'b0;
         assign vid0_vs = 1'b0;
         assign vid0_de = 1'b0;
         assign vid0_blank = 1'b0;
      end
   endgenerate

   // Device 5, LCDC1
   assign apb_PRDATA5 = 32'h0;

   // Device 6, GPIO
   apb_SIO gpio0(.PCLK(clk),
		 .nRESET(~reset),

		 .PENABLE(apb_PENABLE),
		 .PSEL(apb_PSEL6),
		 .PWRITE(apb_PWRITE),
		 .PADDR(apb_PADDR[3:0]),
		 .PWDATA(apb_PWDATA),
		 .PRDATA(apb_PRDATA6),
		 .outport(gpio_o),
		 .inport(gpio_i)
		 );

   // Device 7, INTC
   apb_intc #(.NR_IRQS(6),
	      .NR_LEVEL(4))
            INTC(.clk(clk),
		 .reset(reset),

		 .PENABLE(apb_PENABLE),
		 .PSEL(apb_PSEL7),
		 .PWRITE(apb_PWRITE),
		 .PADDR(apb_PADDR[4:0]),
		 .PWDATA(apb_PWDATA),
		 .PRDATA(apb_PRDATA7),

		 .irqs({26'h0, pirqs}),
		 .irq_out(irq)
		 );

   // Device 8, SPI0
   apb_spi SPI0(.clk(clk),
                .reset(reset),

		.PENABLE(apb_PENABLE),
		.PSEL(apb_PSEL8),
		.PWRITE(apb_PWRITE),
		.PADDR(apb_PADDR[4:0]),
		.PWDATA(apb_PWDATA),
		.PRDATA(apb_PRDATA8),

                .spi_clk(spi_0_sclk),
                .spi_dout(spi_0_dout),
                .spi_din(spi_0_din),
                .spi_cs(spi_0_cs0)
                );

   // Device 9, SPI1
   apb_spi SPI1(.clk(clk),
                .reset(reset),

		.PENABLE(apb_PENABLE),
		.PSEL(apb_PSEL9),
		.PWRITE(apb_PWRITE),
		.PADDR(apb_PADDR[4:0]),
		.PWDATA(apb_PWDATA),
		.PRDATA(apb_PRDATA9),

                .spi_clk(spi_1_sclk),
                .spi_dout(spi_1_dout),
                .spi_din(spi_1_din),
                .spi_cs(spi_1_cs0)
                );

   // Device 10, audio
   generate
      if (WITH_I2S) begin
         r_i2s_apb #(.CLK_RATE(CLK_RATE)
               )
             I2S0(.clk(clk),
                  .reset(reset),

                  /* MIC request port out */
                  .O_TVALID(r4o_tv),
                  .O_TREADY(r4o_tr),
                  .O_TDATA(r4o_td),
                  .O_TLAST(r4o_tl),

                  /* MIC response port in */
                  .I_TVALID(r4i_tv),
                  .I_TREADY(r4i_tr),
                  .I_TDATA(r4i_td),
                  .I_TLAST(r4i_tl),

                  .PCLK(clk),
                  .nRESET(~reset),
                  .PENABLE(apb_PENABLE),
                  .PSEL(apb_PSEL10),
                  .PWRITE(apb_PWRITE),
                  .PADDR(apb_PADDR[5:0]),
                  .PWDATA(apb_PWDATA),
                  .PRDATA(apb_PRDATA10),

                  .IRQ_edge(), /* Unused for now */

                  .i2s_dout(i2s_dout),
                  .i2s_bclk(i2s_bclk),
                  .i2s_wclk(i2s_wclk)
                  );
      end else begin // if (WITH_LCDC0)
         assign r4o_tv = 1'b0;
         assign r4o_td = 64'h0;
         assign r4o_tl = 1'b0;
         assign r4i_tr = 1'b0;
         assign apb_PRDATA10 = 32'h0;
         assign i2s_dout = 1'b0;
         assign i2s_bclk = 1'b0;
         assign i2s_wclk = 1'b0;
      end
   endgenerate

   generate
      if (WITH_SD) begin
         sd	#(.CLK_RATE(CLK_RATE)
                  )
                SD0(.clk(clk),
                    .reset(reset),

                    .PENABLE(apb_PENABLE),
                    .PSEL(apb_PSEL11),
                    .PWRITE(apb_PWRITE),
                    .PADDR(apb_PADDR[7:0]),
                    .PWDATA(apb_PWDATA),
                    .PRDATA(apb_PRDATA11),

                    .irq(pirqs[3]),

                    /* MIC request port out */
                    .O_TVALID(r5o_tv),
                    .O_TREADY(r5o_tr),
                    .O_TDATA(r5o_td),
                    .O_TLAST(r5o_tl),

                    /* MIC response port in */
                    .I_TVALID(r5i_tv),
                    .I_TREADY(r5i_tr),
                    .I_TDATA(r5i_td),
                    .I_TLAST(r5i_tl),

                    .sd_clk(sd_clk),
                    .sd_data_in(sd_data_in),
                    .sd_data_out(sd_data_out),
                    .sd_data_out_en(sd_data_out_en),
                    .sd_cmd_in(sd_cmd_in),
                    .sd_cmd_out(sd_cmd_out),
                    .sd_cmd_out_en(sd_cmd_out_en)
                    );

      end else begin // if (WITH_SD)
         assign r5o_tv = 1'b0;
         assign r5o_td = 64'h0;
         assign r5o_tl = 1'b0;
         assign r5i_tr = 1'b0;
         assign apb_PRDATA11 = 32'h0;
         assign sd_cmd_out = 0;
         assign sd_cmd_out_en = 0;
         assign sd_data_out = 0;
         assign sd_data_out_en = 0;
         assign sd_clk = 0;
      end
   endgenerate

   // Others: more SPI, flash control, network.
   assign apb_PRDATA12 = 32'h0;
   assign apb_PRDATA13 = 32'h0;
   assign apb_PRDATA14 = 32'h0;
   assign apb_PRDATA15 = 32'h0;


   ///////////////////////////////////////////////////////////////////////////
   /* Debug initiator:
    *
    * The MR system exports the bytestream interface hosted by this component.
    */

   r_debug DBG(.clk(clk),
               .reset(reset),

               /* MIC request port out */
               .O_TVALID(r7o_tv),
               .O_TREADY(r7o_tr),
               .O_TDATA(r7o_td),
               .O_TLAST(r7o_tl),

               /* MIC response port in */
               .I_TVALID(r7i_tv),
               .I_TREADY(r7i_tr),
               .I_TDATA(r7i_td),
               .I_TLAST(r7i_tl),

               /* Bytestream for TX */
               .tx_data(dbg_tx_data),
               .tx_has_data(dbg_tx_has_data),
               .tx_data_consume(dbg_tx_consume),

               /* Bytestream for RX */
               .rx_data(dbg_rx_data),
               .rx_has_space(dbg_rx_has_space),
               .rx_data_produce(dbg_rx_produce)
               );

endmodule // mr_top
