//------------------------------------------------------------------------------
// File       : design_1_tri_mode_ethernet_mac_0_0_gmii_if.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------
// (c) Copyright 2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
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
// -----------------------------------------------------------------------------
// Description:  This module creates a Gigabit Media Independent
//               Interface (GMII) by instantiating Input/Output buffers
//               and Input/Output flip-flops as required.
//
//               This interface is used to connect the Ethernet MAC to
//               an external Ethernet PHY via GMII connection.
//
//               The GMII receiver clocking logic is also defined here: the
//               receiver clock received from the PHY is unique and cannot be
//               shared across multiple instantiations of the core.  For the
//               receiver clock:
//
//------------------------------------------------------------------------------

`timescale 1 ps / 1 ps


module design_1_tri_mode_ethernet_mac_0_0_gmii_if (
    // Synchronous resets
    input            tx_reset,
    input            rx_reset,

    // The following ports are the GMII physical interface: these will be at
    // pins on the FPGA
    output     [7:0] gmii_txd,
    output           gmii_tx_en,
    output           gmii_tx_er,
    output           gmii_tx_clk,
    input      [7:0] gmii_rxd,
    input            gmii_rx_dv,
    input            gmii_rx_er,
    input            gmii_rx_clk,

    // The following ports are the internal GMII connections from IOB logic to
    // the TEMAC core
    input      [7:0] txd_from_mac,
    input            tx_en_from_mac,
    input            tx_er_from_mac,
    input            tx_clk,
    output reg [7:0] rxd_to_mac   = 0,
    output reg       rx_dv_to_mac = 0,
    output reg       rx_er_to_mac = 0,

    // Receiver clock for the MAC and Client Logic
    output           rx_clk

    );


  //----------------------------------------------------------------------------
  // internal signals
  //----------------------------------------------------------------------------

  wire            gmii_tx_clk_obuf;
  reg    [7:0]    gmii_txd_obuf;
  reg             gmii_tx_en_obuf;
  reg             gmii_tx_er_obuf;
  wire   [7:0]    gmii_rxd_ibuf;
  wire            gmii_rx_dv_ibuf;
  wire            gmii_rx_er_ibuf;
  wire            gmii_rx_clk_ibuf;

  wire            gmii_rx_dv_delay;
  wire            gmii_rx_er_delay;
  wire   [7:0]    gmii_rxd_delay;

  wire            rx_clk_int;
  wire            rx_clk_iob;




  //----------------------------------------------------------------------------
  // Input/Output Buffers
  //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   // GMII
   //----------------------------------------------------------------------------
assign gmii_tx_clk = tx_clk;

//   OBUF gmii_tx_clk_obuf_i (
//      .I              (gmii_tx_clk_obuf),
//      .O              (gmii_tx_clk)
//   );
  
//   OBUF gmii_tx_en_obuf_i (
//      .I              (gmii_tx_en_obuf),
//      .O              (gmii_tx_en)
//   );
  
//   OBUF gmii_tx_er_obuf_i (
//      .I              (gmii_tx_er_obuf),
//      .O              (gmii_tx_er)
//   );
  
//   genvar loopa;
//   generate for (loopa=0; loopa<8; loopa=loopa+1)
//     begin : obuf_data
//       OBUF gmii_txd_obuf_i (
//          .I              (gmii_txd_obuf[loopa]),
//          .O              (gmii_txd[loopa])
//       );
//     end
//   endgenerate

  
 assign  gmii_rx_clk_ibuf = gmii_rx_clk;

//   IBUF gmii_rx_clk_ibuf_i (
//      .I              (gmii_rx_clk),
//      .O              (gmii_rx_clk_ibuf)
//   );
  
//   IBUF gmii_rx_dv_ibuf_i (
//      .I              (gmii_rx_dv),
//      .O              (gmii_rx_dv_ibuf)
//   );
  
//   IBUF gmii_rx_er_ibuf_i (
//      .I              (gmii_rx_er),
//      .O              (gmii_rx_er_ibuf)
//   );
  
//   genvar loopi;
//   generate for (loopi=0; loopi<8; loopi=loopi+1)
//     begin : ibuf_data
//       IBUF gmii_rxd_ibuf_i (
//          .I              (gmii_rxd[loopi]),
//          .O              (gmii_rxd_ibuf[loopi])
//       );
//     end
//   endgenerate 
    

  //----------------------------------------------------------------------------
  // GMII Transmitter Clock Management :
  // drive gmii_tx_clk through IOB onto GMII interface
  //----------------------------------------------------------------------------


   // Instantiate a DDR output register.  This is a good way to drive
   // GMII_TX_CLK since the clock-to-PAD delay will be the same as that
   // for data driven from IOB Ouput flip-flops eg gmii_rxd[7:0].
   // This is set to produce an inverted clock w.r.t. gmii_tx_clk_int
   // so that the rising edge is centralised within the
   // gmii_rxd[7:0] valid window.
//   ODDRE1 #(
//      .SRVAL         (1'b0)
//   ) 
//   gmii_tx_clk_ddr_iob (
//      .Q             (gmii_tx_clk_obuf),
//      .C             (tx_clk),
//      .D1            (1'b0),
//      .D2            (1'b1),
//      .SR            (1'b0)
//   );
   
   //---------------------------------------------------------------------------
   // GMII Transmitter Logic : drive TX signals through IOBs registers onto
   // GMII interface
   //---------------------------------------------------------------------------


   // Infer IOB Output flip-flops.
//   always @(posedge tx_clk)
//   begin
//      gmii_tx_en_obuf           <= tx_en_from_mac;
//      gmii_tx_er_obuf           <= tx_er_from_mac;
//      gmii_txd_obuf             <= txd_from_mac;
//   end

//   always @(posedge tx_clk)
//   begin
 assign      gmii_tx_en           = tx_en_from_mac;
 assign      gmii_tx_er           = tx_er_from_mac;
 assign      gmii_txd             = txd_from_mac;
//   end


   //---------------------------------------------------------------------------
   // GMII Receiver Clock Logic
   //---------------------------------------------------------------------------
   
   assign rx_clk_int = gmii_rx_clk_ibuf;

   // Route gmii_rx_clk through a BUFG onto regional clock routing
   //BUFG bufio_gmii_rx_clk (
   //   .I                (gmii_rx_clk_ibuf),
   //   .O                (rx_clk_int)
   //);


   assign rx_clk_iob = gmii_rx_clk_ibuf;
   // Route gmii_rx_clk through a BUFG for connecting to IOB flops
   //BUFG bufio_gmii_rx_clk_iob (
   //   .I                (gmii_rx_clk_ibuf),
   //   .O                (rx_clk_iob)
   //);

   // Assign the internal clock signal to the output port
   assign rx_clk = rx_clk_int;

   //---------------------------------------------------------------------------
   // GMII Receiver Logic : receive RX signals through IOBs from GMII interface
   //---------------------------------------------------------------------------

   // Use IDELAY to delay data to the capturing register.

   // Note: Delay value is set in UCF file
   // Please modify the IOBDELAY_VALUE according to your design.
   // For more information on IDELAYCTRL and IDELAY, please refer to
   // the User Guide.
  assign gmii_rx_dv_delay = gmii_rx_dv;

//   IDELAYE3 #(
//      .DELAY_TYPE       ("FIXED"),
//      .REFCLK_FREQUENCY (333.333),
//      .SIM_DEVICE      ("ULTRASCALE_PLUS_ES1")
      
//   )
//   delay_gmii_rx_dv (
//      .IDATAIN       (gmii_rx_dv_ibuf),
//      .DATAOUT       (gmii_rx_dv_delay),
//      .DATAIN        (1'b0),
//      .CLK           (1'b0),
//      .CE            (1'b0),
//      .INC           (1'b0),
//      .CNTVALUEIN    (9'h0),
//      .CNTVALUEOUT   (),
//      .LOAD          (1'b0),
//      .RST           (1'b0),
//      .CASC_IN       (1'b0),
//      .CASC_RETURN   (1'b0),
//      .CASC_OUT      (),
//      .EN_VTC        (1'b1)
//      );
assign gmii_rx_er_delay = gmii_rx_er;

//   IDELAYE3 #(
//      .DELAY_TYPE       ("FIXED"),
//      .REFCLK_FREQUENCY (333.333),
//      .SIM_DEVICE      ("ULTRASCALE_PLUS_ES1")
//      
//   )
//   delay_gmii_rx_er (
//      .IDATAIN       (gmii_rx_er_ibuf),
//      .DATAOUT       (gmii_rx_er_delay),
//      .DATAIN        (1'b0),
//      .CLK           (1'b0),
//      .CE            (1'b0),
//      .INC           (1'b0),
//      .CNTVALUEIN    (9'h0),
//      .CNTVALUEOUT   (),
//      .LOAD          (1'b0),
//      .RST           (1'b0),
//      .CASC_IN       (1'b0),
//      .CASC_RETURN   (1'b0),
//      .CASC_OUT      (),
//      .EN_VTC        (1'b1)
//      );

   genvar i;
   generate for (i=0; i<8; i=i+1)


     begin : rxdata_bus

     assign gmii_rxd_delay[i] = gmii_rxd[i];

//      IDELAYE3 #(
//         .DELAY_TYPE        ("FIXED"),
//         .REFCLK_FREQUENCY  (333.333),
//          .SIM_DEVICE      ("ULTRASCALE_PLUS_ES1")
//      
//      )
//      delay_gmii_rxd (
//         .IDATAIN       (gmii_rxd_ibuf[i]),
//         .DATAOUT       (gmii_rxd_delay[i]),
//         .DATAIN        (1'b0),
//         .CLK           (1'b0),
//         .CE            (1'b0),
//         .INC           (1'b0),
//         .CNTVALUEIN    (9'h0),
//         .CNTVALUEOUT   (),
//         .LOAD          (1'b0),
//         .RST           (1'b0),
//         .CASC_IN       (1'b0),
//         .CASC_RETURN   (1'b0),
//         .CASC_OUT      (),
//         .EN_VTC        (1'b1)
//      );
     end
   endgenerate

   // Infer IOB Input flip-flops.
   always @(posedge rx_clk_iob)
   begin
      rx_dv_to_mac <= gmii_rx_dv_delay;
      rx_er_to_mac <= gmii_rx_er_delay;
      rxd_to_mac   <= gmii_rxd_delay;
   end


endmodule
