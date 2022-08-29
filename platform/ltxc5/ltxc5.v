/* Toplevel for MR project, on ARM LogicTile LT-XC5VLX330 platform
 *
 * IO names roughly match those on schematic.  Main IO is done through
 * HDRY with a breakout board from the Samtec connector.
 *
 * Rather than name those pins directly, they're `defined in
 * lt_breakout_conns to the corresponding YU[x] pin name for
 * flexibility in reassignment.
 *
 * ME 040620
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

`include "lt_breakout_conns.vh"


module ltxc5 (/* Clocks, in, out, buffers etc. etc.*/
	      input wire	   CLK_LOOP0_IN,
	      input wire	   CLK_LOOP1_IN,
	      output wire	   CLK_LOOP0_OUT,
	      output wire	   CLK_LOOP1_OUT,
	      input wire	   CLK_NEG_DN_IN,
	      input wire	   CLK_NEG_UP_IN,
	      output wire	   CLK_NEG_DN_OUT,
	      output wire	   CLK_NEG_UP_OUT,
	      input wire	   CLK_POS_DN_IN,
	      input wire	   CLK_POS_UP_IN,
	      output wire	   CLK_POS_DN_OUT,
	      output wire	   CLK_POS_UP_OUT,
	      input wire	   CLK_IN_PLUS1,
	      input wire	   CLK_IN_PLUS2,
	      input wire	   CLK_IN_MINUS1,
	      input wire	   CLK_IN_MINUS2,
	      input wire	   CLK0, // From ICS307 osc 0
	      input wire	   CLK1, // ICS307 osc 1
	      input wire	   CLK2, // ICS307 osc 2
	      input wire	   CLK_24MHZ_FPGA, // Reference clock input
	      input wire	   CLK_EXTERN, // SMA connector
	      input wire	   CLK_BUF_LOOP,
	      input wire	   CLK_GLOBAL_IN,
	      output wire	   CLK_GLOBAL_OUT,
	      output wire	   CLK_OUT_TO_BUF,
	      output wire	   CLK_GLBL_nEN,

	      /* Resets from boards/base */
	      input wire	   nSYSRST,
	      input wire	   nSYSPOR,

	      /* ICS307 clock synth control */
	      output wire	   CLK_DATA,
	      output wire	   CLK_SCLK,
	      output wire [2:0]	   CLK_STROBE,

	      /* JTAG */
	      output wire	   D_TDO,
	      output wire	   D_RTCK,
	      input wire	   FPGA_D_TMS,
	      input wire	   D_TDI,
	      input wire	   D_TCK,
	      input wire	   D_nTRST,
	      input wire	   D_nSRST,

	      /* General IO */
	      output wire [7:0]	   USER_LED, // Board LEDs
	      input wire [7:0]	   USER_SW, // Board DIP switches
	      input wire	   nPB, // Button

	      output wire	   FnCE, // Flash CS

	      /* ZBT SSRAM bank A (2 chips, so 2 CEs/CLKs) */
	      output wire	   RAM_A_SCLK0,
	      output wire	   RAM_A_SnCE0,
	      output wire	   RAM_A_SCLK1,
	      output wire	   RAM_A_SnCE1,
	      output wire	   RAM_A_SnCKE, // CLK enable
	      output wire [7:0]	   RAM_A_SnWBYTE, // Byte WE
	      output wire	   RAM_A_SnOE, // OE
	      output wire	   RAM_A_SnWE,
	      output wire	   RAM_A_SADVnLD,
	      output wire	   RAM_A_SMODE,
	      output wire [23:3]   RAM_A_SA, // Address
	      inout wire [63:0]	   RAM_A_SD, // Data

	      /* ZBT SSRAM bank B */
	      output wire	   RAM_B_SCLK0,
	      output wire	   RAM_B_SnCE0,
	      output wire	   RAM_B_SCLK1,
	      output wire	   RAM_B_SnCE1,
	      output wire	   RAM_B_SnCKE,
	      output wire [7:0]	   RAM_B_SnWBYTE,
	      output wire	   RAM_B_SnOE,
	      output wire	   RAM_B_SnWE,
	      output wire	   RAM_B_SADVnLD,
	      output wire	   RAM_B_SMODE,
	      output wire [23:3]   RAM_B_SA,
	      inout wire [63:0]	   RAM_B_SD,

	      /* Logictile's X,Y,Z IO connectors: */
	      inout wire [143:0]   XU,
	      inout wire [143:0]   YU,
	      inout wire [234:128] ZU,
	      inout wire [143:0]   XL,
	      inout wire [143:0]   YL,
	      inout wire [234:128] ZL,
	      inout wire [127:0]   Z,

	      /* IO connectors FOLD/THRU stuff: */
	      output wire	   nXL_FOLD,
	      output wire	   nXU_FOLD,
	      output wire	   nX_THRU,
	      output wire	   nYL_FOLD,
	      output wire	   nYU_FOLD,
	      output wire	   nY_THRU,
	      output wire	   nZL_FOLD,
	      output wire	   nZU_FOLD,
	      output wire	   nZ_THRU
	      );


   /* Signals for ICS307 PLLs on-board -- not used yet!
    * They're flexible and will be good for things like pixel clock synth
    * though, particularly for external HDMI output.
    */
   assign CLK_SCLK		= 0;
   assign CLK_DATA		= 0;
   assign CLK_STROBE[2:0]	= 3'b000;

   // Not using any of the clock outputs:
   assign CLK_LOOP0_OUT		= 0;
   assign CLK_LOOP1_OUT		= 0;
   assign CLK_LOOP2_OUT		= 0;
   assign CLK_LOOP3_OUT		= 0;
   assign CLK_GLOBAL_OUT	= 0;
   assign CLK_OUT_TO_BUF	= 0;
   assign CLK_NEG_DN_OUT	= 0;
   assign CLK_NEG_UP_OUT	= 0;
   assign CLK_POS_DN_OUT	= 0;
   assign CLK_POS_UP_OUT	= 0;
   assign CLK_GLBL_nEN		= 1; // Don't drive CLK_GLBL line

   // I don't really care about JTAG passthrough from baseboard, but do as
   // other designs do and loop it through:
   assign D_TDO			= D_TDI;
   assign D_RTCK		= D_TCK;
   assign nRTCKEN		= 0;

   // Banks A & B are driven by SSRAM controller.  Tie off
   // some static signals:
   assign RAM_A_SnOE		= 0;
   assign RAM_A_SMODE		= 0;
   assign RAM_B_SnOE		= 0;
   assign RAM_B_SMODE		= 0;

   assign FnCE			= 1;	// No flash

   // Don't care too much about X/Z headers, but don't leave configs floating:
   assign nXL_FOLD		= 1'b1;
   assign nXU_FOLD		= 1'b1;
   assign nX_THRU		= 1'b1;
   assign nYL_FOLD		= 1'b1;
   assign nYU_FOLD		= 1'b1;
   assign nY_THRU		= 1'b1;
   assign nZL_FOLD		= 1'b1;
   assign nZU_FOLD		= 1'b1;
   assign nZ_THRU		= 1'b1;

   ///////////////////////////////////////////////////////////////////////////
   // Top-level gunk for MattRISC SoC:

   reg		     reset;

   // I/O

   ///////////////////////////////////////////////////////////////////////////
   // UARTs

   wire		     uart_rx = `LT_PROTO_RX0;
   wire		     uart_tx;
   assign	     `LT_PROTO_TX0 = uart_tx;


   ///////////////////////////////////////////////////////////////////////////
   // Misc LEDs/switches/reset

   wire [7:0]	     baseboard_SW = `LT_BB_SW;	// Unused
   wire [7:0]	     baseboard_LED;
   assign `LT_BB_LEDS = baseboard_LED;

   wire		     button_reset = `LT_PROTO_BTN_A; // Protoboard button A

   assign baseboard_LED[7:4]	= {
				   button_reset,
				   `LT_PROTO_BTN_B,
				   reset,
				   1'b0
				   };
   // The other baseboard LEDs are driven below


   ///////////////////////////////////////////////////////////////////////////
   // I2C for DVI
   wire              lt_dvi_sda_o, lt_dvi_sda_i;
   wire              lt_dvi_scl_o, lt_dvi_scl_i;
   /* DVI I2C:  Use IOBUF to simulate open-drain: */
   IOBUF pb_sda_io(.IO(`LT_DVI_AB_SDA),
                   .I(0), /* Signal to drive out to pin */
                   .T(lt_dvi_sda_o), /* Active-low enable for output: 1=Tristate (pullups) */
                   .O(lt_dvi_sda_i)); /* Input from the buffer output */
   IOBUF pb_scl_io(.IO(`LT_DVI_AB_SCL),
                   .I(0),
                   .T(lt_dvi_scl_o),
                   .O(lt_dvi_scl_i));

   // GPIO
   wire [31:0] 	     gpio_i;
   wire [31:0] 	     gpio_o;

   // GPIO outs:
   assign lt_dvi_scl_o 	 = gpio_o[25];
   assign lt_dvi_sda_o 	 = gpio_o[24];
   assign USER_LED 	 = gpio_o[7:0];
   assign `LT_SPI_C_RST1 = gpio_o[21];
   // FIXME PDP disable, gamma/BG intensity controls
   // FIXME ICS307 SCLK/DATA/STROBE

   // GPIO ins:
   assign gpio_i[31] 	= 0; // Flag for running on sim vs hw
   assign gpio_i[30:26] = 0;
   assign gpio_i[25] 	= lt_dvi_scl_i;
   assign gpio_i[24] 	= lt_dvi_sda_i;
   assign gpio_i[23] 	= ~`LT_PROTO_BTN_B;
   assign gpio_i[22] 	= ~nPB;
   assign gpio_i[21:8] 	= 0;
   assign gpio_i[7:0] 	= USER_SW[7:0];


   ///////////////////////////////////////////////////////////////////////////
   /* PDP out on port D: */
   wire              pdp_d_vs;
   wire              pdp_d_hs;
   wire [23:0]       pdp_d_rgb;
   wire [3:0]        pdp_pixel_data = ~pdp_d_rgb[23:20];
   wire              pdp_d_de;
   wire              pdp_d_clk;
   wire              pdp_d_blank;
   wire              pdp_d_disable;

   assign pdp_d_disable = USER_SW[7]; // FIXME, this will be GPIO.
   /* Pixel clock should be 28MHz or so; 24 will work but lower refresh obviously: */
   assign pdp_d_clk = CLK_24MHZ_FPGA;

   // FIXME: Gamma/intensity outputs from GPIO
   assign `LT_PDP_D_VS = pdp_d_vs;
   assign `LT_PDP_D_HS = pdp_d_hs;
   assign `LT_PDP_D_DTIM = pdp_d_de;
   assign `LT_PDP_D_DISABLE = pdp_d_disable;
   assign `LT_PDP_D_BLANK = pdp_d_blank;
   assign `LT_PDP_D_CLK = pdp_d_clk;
   assign `LT_PDP_D_D0 = pdp_pixel_data[0];
   assign `LT_PDP_D_D1 = pdp_pixel_data[1];
   assign `LT_PDP_D_D2 = pdp_pixel_data[2];
   assign `LT_PDP_D_D3 = pdp_pixel_data[3];

   /* DVI out on port AB, currently mirroring PDP: */
   // FIXME: Clean split, support LCDC1, route with switch input
   assign `LT_DVI_AB_RGB = pdp_d_rgb[23:0];
   assign `LT_DVI_AB_CLK = pdp_d_clk;
   assign `LT_DVI_AB_HS  = pdp_d_hs;
   assign `LT_DVI_AB_VS  = pdp_d_vs;
   assign `LT_DVI_AB_DE  = pdp_d_de;

   ///////////////////////////////////////////////////////////////////////////
   /* PS/2 ports:
    * Simple physical interface uses a tristate (similar to I2C) to simulate
    * an open-drain input/output.
    */

   wire              ps2_kbd_clk_pd, ps2_kbd_clk_in, ps2_kbd_dat_pd, ps2_kbd_dat_in;
   wire              ps2_mse_clk_pd, ps2_mse_clk_in, ps2_mse_dat_pd, ps2_mse_dat_in;

   IOBUF pb_ps2kc_io(.IO(`LT_PROTO_PS2KC),
                     .I(0),
                     .T(~ps2_kbd_clk_pd),
                     .O(ps2_kbd_clk_in));
   IOBUF pb_ps2kd_io(.IO(`LT_PROTO_PS2KD),
                     .I(0),
                     .T(~ps2_kbd_dat_pd),
                     .O(ps2_kbd_dat_in));

   IOBUF pb_ps2mc_io(.IO(`LT_PROTO_PS2MC),
                     .I(0),
                     .T(~ps2_mse_clk_pd),
                     .O(ps2_mse_clk_in));
   IOBUF pb_ps2md_io(.IO(`LT_PROTO_PS2MD),
                     .I(0),
                     .T(~ps2_mse_dat_pd),
                     .O(ps2_mse_dat_in));


   ///////////////////////////////////////////////////////////////////////////
   // SD pins

   wire              sd_clk;
   wire [3:0]        sd_data_in;
   wire [3:0]        sd_data_out;
   wire              sd_data_out_en;
   wire              sd_cmd_in;
   wire              sd_cmd_out;
   wire              sd_cmd_out_en;

   assign `LT_SPI_C_SD_CLK = sd_clk;

   assign `LT_SPI_C_SD_CMD = sd_cmd_out_en ? sd_cmd_out : 1'bz;
   assign sd_cmd_in = `LT_SPI_C_SD_CMD;

   assign `LT_SPI_C_SD_D3 = sd_data_out_en ? sd_data_out[3] : 1'bz;
   assign `LT_SPI_C_SD_D2 = sd_data_out_en ? sd_data_out[2] : 1'bz;
   assign `LT_SPI_C_SD_D1 = sd_data_out_en ? sd_data_out[1] : 1'bz;
   assign `LT_SPI_C_SD_D0 = sd_data_out_en ? sd_data_out[0] : 1'bz;
   assign sd_data_in = {`LT_SPI_C_SD_D3, `LT_SPI_C_SD_D2, `LT_SPI_C_SD_D1, `LT_SPI_C_SD_D0};


   ///////////////////////////////////////////////////////////////////////////
   // Set up clocks & reset for the system:

   wire		     clkint;
   wire		     clk_2x;
   wire		     clk_ram;
   wire		     clk_ram_ext;
   wire		     clks_locked;

`define SYS_CLK_RATE (60*1000000)
   v5clocks #(.REFCLK_RATE(24000000),
              .SYSCLK_RATE(`SYS_CLK_RATE))
            V5CLKS(.refclk(CLK_24MHZ_FPGA),
		   .clk_regular(clkint),
		   .clk_ram(/* clk_ram */),	/* fast (96-128) */
		   .clk_ram_ext(clk_ram_ext),	/* 270deg fast */
		   .locked(clks_locked));
   // System clock:
   wire		     clk = clkint;

   // RAM clock = system clock
   assign clk_ram = clk;

   // External reset => GSR
   STARTUP_VIRTEX5 startup(.GSR(~button_reset));

   // System reset (synchronous to clk) to wire 'reset':
   reg               l_sync[1:0];
   wire		     reset_pulse;

   reset_wait rst(.clk(clk), .reset(reset_pulse));

   // Sync PLL lock to system clock domain:
   always @(posedge clk) begin
      l_sync[0] <= clks_locked;
      l_sync[1] <= l_sync[0];
      reset 	<= reset_pulse && !l_sync[1];
   end


   ///////////////////////////////////////////////////////////////////////////
   // SRAM B-related stuff

   v5clkout clkoutA(.clk(clk_ram), .O(RAM_B_SCLK0)); // clock 1:1
   v5clkout clkoutB(.clk(clk_ram), .O(RAM_B_SCLK1));

   v5clkout clkoutC(.clk(clk_ram), .O(RAM_A_SCLK0)); // clock 1:1
   v5clkout clkoutD(.clk(clk_ram), .O(RAM_A_SCLK1));

   // FIXME:  Programmable phase shift/delay
   // FIXME:  Programmable delays on DQs


   ///////////////////////////////////////////////////////////////////////////
   // Instantiate SoC:

   wire [7:0]        dbg_tx_data;
   wire              dbg_tx_has_data;
   wire              dbg_tx_consume;
   wire [7:0]        dbg_rx_data;
   wire              dbg_rx_has_space;
   wire              dbg_rx_produce;

   mr_top #(.CLK_RATE(`SYS_CLK_RATE),
            .WITH_I2S(1),
            .WITH_LCDC0(1),
            .WITH_SD(1),
	    .RAM_INIT_FILE("ram_init.hex"),
            .REAL_RAM(1)
	    )
	  MR(.clk(clk),
	     .reset(reset),

	     .vid0_pclk(pdp_d_clk),
	     .vid0_rgb(pdp_d_rgb),
	     .vid0_hs(pdp_d_hs),
	     .vid0_vs(pdp_d_vs),
	     .vid0_de(pdp_d_de),
	     .vid0_blank(pdp_d_blank),

	     .gpio_i(gpio_i),
	     .gpio_o(gpio_o),

	     .ram_a_ncen(RAM_A_SnCKE),
	     .ram_a_nce0(RAM_A_SnCE0),
	     .ram_a_nce1(RAM_A_SnCE1),
	     .ram_a_advld(RAM_A_SADVnLD),
	     .ram_a_nwe(RAM_A_SnWE),
	     .ram_a_nbw(RAM_A_SnWBYTE),
	     .ram_a_addr(RAM_A_SA[23:3]),
	     .ram_a_dq(RAM_A_SD),

             .ram_b_ncen(RAM_B_SnCKE),
	     .ram_b_nce0(RAM_B_SnCE0),
	     .ram_b_nce1(RAM_B_SnCE1),
	     .ram_b_advld(RAM_B_SADVnLD),
	     .ram_b_nwe(RAM_B_SnWE),
	     .ram_b_nbw(RAM_B_SnWBYTE),
	     .ram_b_addr(RAM_B_SA[23:3]),
	     .ram_b_dq(RAM_B_SD),

	     .console_tx(uart_tx),
	     .console_rx(uart_rx),

             .dbg_tx_data(dbg_tx_data),
             .dbg_tx_has_data(dbg_tx_has_data),
             .dbg_tx_consume(dbg_tx_consume),
             .dbg_rx_data(dbg_rx_data),
             .dbg_rx_has_space(dbg_rx_has_space),
             .dbg_rx_produce(dbg_rx_produce),

             .i2s_dout(`LT_PROTO_DATA),
             .i2s_bclk(`LT_PROTO_BCLK),
             .i2s_wclk(`LT_PROTO_WCLK),

             .spi_0_sclk(`LT_SPI_C_CLK0),
             .spi_0_dout(`LT_SPI_C_DOUT0),
             .spi_0_din(`LT_SPI_C_DIN0),
             .spi_0_cs0(`LT_SPI_C_CS0),
             .spi_1_sclk(`LT_SPI_C_CLK1),
             .spi_1_dout(`LT_SPI_C_DOUT1),
             .spi_1_din(`LT_SPI_C_DIN1),
             .spi_1_cs0(`LT_SPI_C_CS1),
             .spi_1_irq(`LT_SPI_C_IRQ1),

             .ps2_kbd_clk_in(ps2_kbd_clk_in),
             .ps2_kbd_clk_pd(ps2_kbd_clk_pd),
             .ps2_kbd_dat_in(ps2_kbd_dat_in),
             .ps2_kbd_dat_pd(ps2_kbd_dat_pd),
             .ps2_mse_clk_in(ps2_mse_clk_in),
             .ps2_mse_clk_pd(ps2_mse_clk_pd),
             .ps2_mse_dat_in(ps2_mse_dat_in),
             .ps2_mse_dat_pd(ps2_mse_dat_pd),

             .sd_clk(sd_clk),
             .sd_data_in(sd_data_in),
             .sd_data_out(sd_data_out),
             .sd_data_out_en(sd_data_out_en),
             .sd_cmd_in(sd_cmd_in),
             .sd_cmd_out(sd_cmd_out),
             .sd_cmd_out_en(sd_cmd_out_en)
	     );

   // Instantiate debug interface via ft232h:
   wire              dbg_rx_strobe;

   bytestream_ft232 BSF(.clk(clk),
                        .reset(reset),

                        .bs_data_in(dbg_tx_data),
                        .bs_data_in_valid(dbg_tx_has_data),
                        .bs_data_in_consume(dbg_tx_consume),
                        .bs_data_out(dbg_rx_data),
                        .bs_data_out_produce(dbg_rx_strobe),

                        .ft_data({`LT_FTDI_D7, `LT_FTDI_D6, `LT_FTDI_D5, `LT_FTDI_D4, `LT_FTDI_D3, `LT_FTDI_D2, `LT_FTDI_D1, `LT_FTDI_D0}),
                        .ft_nRXF(`LT_FTDI_NRXF),
                        .ft_nRD(`LT_FTDI_NRD),
                        .ft_nTXE(`LT_FTDI_NTXE),
                        .ft_nWR(`LT_FTDI_NWR)
                        );
   assign dbg_rx_produce = dbg_rx_strobe && dbg_rx_has_space;

   // Aliveness test:
   reg [23:0]	     counter;

   always @(posedge clk) begin
      if (reset)
	counter <= 0;
      else
	counter <= counter + 1;
   end


   reg [7:0]	     leds;

   // Stated as a case statement to ease adding other views:
   always @(*) begin
      case (USER_SW[3:0])
	default:
	  leds = counter[23:16];
      endcase
   end

   assign baseboard_LED[3:0] = leds[7:4];

endmodule
