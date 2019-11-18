// Copyright (c) 2019, University of Washington All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// 
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// 
// Neither the name of the copyright holder nor the names of its contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 *  cl_manycore.v
 */

`include "bsg_bladerunner_rom_pkg.vh"

module cl_manycore
  import cl_manycore_pkg::*;
   import bsg_bladerunner_rom_pkg::*;
   import bsg_bladerunner_mem_cfg_pkg::*;
   (
`include "cl_ports.vh"
    );

   // For some silly reason, you need to leave this up here...
   logic rst_main_n_sync;

`include "bsg_defines.v"
`include "bsg_manycore_packet.vh"
`include "cl_id_defines.vh"
`include "cl_manycore_defines.vh"

   //--------------------------------------------
   // Start with Tie-Off of Unused Interfaces
   //---------------------------------------------
   // The developer should use the next set of `include to properly tie-off any
   // unused interface The list is put in the top of the module to avoid cases
   // where developer may forget to remove it from the end of the file

`include "unused_flr_template.inc"
// `include "unused_ddr_a_b_d_template.inc"
//`include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"

   localparam lc_clk_main_a0_p = 8000; // 8000 is 125 MHz
   
   //-------------------------------------------------
   // Wires
   //-------------------------------------------------
   logic pre_sync_rst_n;

   logic [15:0] vled_q;
   logic [15:0] pre_cl_sh_status_vled;
   logic [15:0] sh_cl_status_vdip_q;
   logic [15:0] sh_cl_status_vdip_q2;

   //-------------------------------------------------
   // PCI ID Values
   //-------------------------------------------------
   assign cl_sh_id0[31:0] = `CL_SH_ID0;
   assign cl_sh_id1[31:0] = `CL_SH_ID1;

   //-------------------------------------------------
   // Reset Synchronization
   //-------------------------------------------------

   always_ff @(negedge rst_main_n or posedge clk_main_a0)
     if (!rst_main_n)
       begin
          pre_sync_rst_n  <= 0;
          rst_main_n_sync <= 0;
       end
     else
       begin
          pre_sync_rst_n  <= 1;
          rst_main_n_sync <= pre_sync_rst_n;
       end

   //-------------------------------------------------
   // Virtual LED Register
   //-------------------------------------------------
   // Flop/synchronize interface signals
   always_ff @(posedge clk_main_a0)
     if (!rst_main_n_sync) begin
        sh_cl_status_vdip_q[15:0]  <= 16'h0000;
        sh_cl_status_vdip_q2[15:0] <= 16'h0000;
        cl_sh_status_vled[15:0]    <= 16'h0000;
     end
     else begin
        sh_cl_status_vdip_q[15:0]  <= sh_cl_status_vdip[15:0];
        sh_cl_status_vdip_q2[15:0] <= sh_cl_status_vdip_q[15:0];
        cl_sh_status_vled[15:0]    <= pre_cl_sh_status_vled[15:0];
     end

   // The register contains 16 read-only bits corresponding to 16 LED's.
   // The same LED values can be read from the CL to Shell interface
   // by using the linux FPGA tool: $ fpga-get-virtual-led -S 0
   always_ff @(posedge clk_main_a0)
     if (!rst_main_n_sync) begin
        vled_q[15:0] <= 16'h0000;
     end
     else begin
        vled_q[15:0] <= 16'hbeef;
     end

   assign pre_cl_sh_status_vled[15:0] = vled_q[15:0];
   assign cl_sh_status0[31:0] = 32'h0;
   assign cl_sh_status1[31:0] = 32'h0;


  // AXI SIGNAL CASTING 
  // 
  `include "bsg_axi_bus_pkg.vh"
  //-------------------------------------------------
  // AXI-Lite OCL System Post-Pipeline-Register
  //-------------------------------------------------
  logic        m_axil_ocl_awvalid;
  logic [31:0] m_axil_ocl_awaddr ;
  logic        m_axil_ocl_awready;

  logic        m_axil_ocl_wvalid;
  logic [31:0] m_axil_ocl_wdata ;
  logic [ 3:0] m_axil_ocl_wstrb ;
  logic        m_axil_ocl_wready;

  logic        m_axil_ocl_bvalid;
  logic [1:0]  m_axil_ocl_bresp ;
  logic        m_axil_ocl_bready;

  logic        m_axil_ocl_arvalid;
  logic [31:0] m_axil_ocl_araddr ;
  logic        m_axil_ocl_arready;

  logic        m_axil_ocl_rvalid;
  logic [31:0] m_axil_ocl_rdata ;
  logic [ 1:0] m_axil_ocl_rresp ;
  logic        m_axil_ocl_rready;

  axi_register_slice_light AXIL_OCL_REG_SLC (
    .aclk         (clk_main_a0       ),
    .aresetn      (rst_main_n_sync   ),
    .s_axi_awaddr (sh_ocl_awaddr     ),
    .s_axi_awprot (3'h0              ),
    .s_axi_awvalid(sh_ocl_awvalid    ),
    .s_axi_awready(ocl_sh_awready    ),
    .s_axi_wdata  (sh_ocl_wdata      ),
    .s_axi_wstrb  (sh_ocl_wstrb      ),
    .s_axi_wvalid (sh_ocl_wvalid     ),
    .s_axi_wready (ocl_sh_wready     ),
    .s_axi_bresp  (ocl_sh_bresp      ),
    .s_axi_bvalid (ocl_sh_bvalid     ),
    .s_axi_bready (sh_ocl_bready     ),
    .s_axi_araddr (sh_ocl_araddr     ),
    .s_axi_arvalid(sh_ocl_arvalid    ),
    .s_axi_arready(ocl_sh_arready    ),
    .s_axi_rdata  (ocl_sh_rdata      ),
    .s_axi_rresp  (ocl_sh_rresp      ),
    .s_axi_rvalid (ocl_sh_rvalid     ),
    .s_axi_rready (sh_ocl_rready     ),
    .m_axi_awaddr (m_axil_ocl_awaddr ),
    .m_axi_awprot (                  ),
    .m_axi_awvalid(m_axil_ocl_awvalid),
    .m_axi_awready(m_axil_ocl_awready),
    .m_axi_wdata  (m_axil_ocl_wdata  ),
    .m_axi_wstrb  (m_axil_ocl_wstrb  ),
    .m_axi_wvalid (m_axil_ocl_wvalid ),
    .m_axi_wready (m_axil_ocl_wready ),
    .m_axi_bresp  (m_axil_ocl_bresp  ),
    .m_axi_bvalid (m_axil_ocl_bvalid ),
    .m_axi_bready (m_axil_ocl_bready ),
    .m_axi_araddr (m_axil_ocl_araddr ),
    .m_axi_arvalid(m_axil_ocl_arvalid),
    .m_axi_arready(m_axil_ocl_arready),
    .m_axi_rdata  (m_axil_ocl_rdata  ),
    .m_axi_rresp  (m_axil_ocl_rresp  ),
    .m_axi_rvalid (m_axil_ocl_rvalid ),
    .m_axi_rready (m_axil_ocl_rready )
  );

  // ---------------------------------------------
  // axil ocl interface
  // ---------------------------------------------
  `declare_bsg_axil_bus_s(1, sh_ocl_si_s, sh_ocl_so_s);
  sh_ocl_si_s s_axil_ocl_li;
  sh_ocl_so_s s_axil_ocl_lo;

  assign s_axil_ocl_li.awaddr  = m_axil_ocl_awaddr;
  assign s_axil_ocl_li.awvalid = m_axil_ocl_awvalid;
  assign s_axil_ocl_li.wdata   = m_axil_ocl_wdata;
  assign s_axil_ocl_li.wstrb   = m_axil_ocl_wstrb;
  assign s_axil_ocl_li.wvalid  = m_axil_ocl_wvalid;
  assign s_axil_ocl_li.bready  = m_axil_ocl_bready;
  assign s_axil_ocl_li.araddr  = m_axil_ocl_araddr;
  assign s_axil_ocl_li.arvalid = m_axil_ocl_arvalid;
  assign s_axil_ocl_li.rready  = m_axil_ocl_rready;

  assign m_axil_ocl_awready = s_axil_ocl_lo.awready;
  assign m_axil_ocl_wready  = s_axil_ocl_lo.wready;
  assign m_axil_ocl_bresp   = s_axil_ocl_lo.bresp;
  assign m_axil_ocl_bvalid  = s_axil_ocl_lo.bvalid;
  assign m_axil_ocl_arready = s_axil_ocl_lo.arready;
  assign m_axil_ocl_rdata   = s_axil_ocl_lo.rdata;
  assign m_axil_ocl_rresp   = s_axil_ocl_lo.rresp;
  assign m_axil_ocl_rvalid  = s_axil_ocl_lo.rvalid;


  // ---------------------------------------------
  // DDR axi4 interface => Manycore Memory System
  // ---------------------------------------------
  // This is used by AWS
  localparam num_ddr_axi4_lp = 4;
  localparam num_cl_ddr_lp = 3;
  localparam ddr_axi4_id_width_lp = 6;
  localparam ddr_axi4_addr_width_lp = 64;
  localparam ddr_axi4_data_width_lp = 512;

`ifdef COSIM
  localparam enable_axi_clk_cvt_lp = 1;
`else 
  localparam enable_axi_clk_cvt_lp = 0;
`endif

  `declare_bsg_axi4_bus_s(1, ddr_axi4_id_width_lp, ddr_axi4_addr_width_lp, ddr_axi4_data_width_lp, ddr_axi_mosi_s, ddr_axi_miso_s);
  ddr_axi_mosi_s [num_ddr_axi4_lp-1:0] s_axi4_ddr_li;
  ddr_axi_miso_s [num_ddr_axi4_lp-1:0] s_axi4_ddr_lo;


  // manycore clock and reset
  // 
  logic core_clk  ;
  logic core_reset;

`ifdef COSIM
  parameter lc_core_clk_period_p = 400000;
  logic     ns_core_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(lc_core_clk_period_p)) core_clk_gen (.o(ns_core_clk));
`endif

`ifdef COSIM
  // This clock mux switches between the "fast" IO Clock and the Slow
  // Unsynthesizable "Core Clk". The assign logic below introduces
  // order-of-evaluation issues that can cause spurrious negedges
  // because the simulator doesn't know what order to evaluate clocks
  // in during a clock switch. See the following datasheet for more
  // information:
  // www.xilinx.com/support/documentation/sw_manuals/xilinx2019_1/ug974-vivado-ultrascale-libraries.pdf
  BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) BUFGMUX_inst (
    .O (core_clk               ), // 1-bit output: Clock output
    .I0(clk_main_a0            ), // 1-bit input: Clock input (S=0)
    .I1(ns_core_clk            ), // 1-bit input: Clock input (S=1)
    .S (sh_cl_status_vdip_q2[0])  // 1-bit input: Clock select
  );
  // THIS IS AN UNSAFE CLOCK CROSSING. It is only guaranteed to work
  // because 1. We're in cosimulation, and 2. we don't have ongoing
  // transfers at the start or end of simulation. This means that
  // core_clk, and clk_main_a0 *are the same signal* (See BUFGMUX
  // above).
  assign core_reset = ~rst_main_n_sync; 
`else
  assign core_clk = clk_main_a0;
  assign core_reset = ~rst_main_n_sync;
`endif


  `declare_bsg_axi4_bus_s(1, axi_id_width_p, axi_addr_width_p, axi_data_width_p, mc_axi4_mosi_s, mc_axi4_miso_s);
  mc_axi4_mosi_s [num_ddr_axi4_lp-1:0] m_mc_axi4_lo, m_mc_axi4_async_lo;
  mc_axi4_miso_s [num_ddr_axi4_lp-1:0] m_mc_axi4_li, m_mc_axi4_async_li;

  wire [num_ddr_axi4_lp-1:0] mem_clocks_li = {num_ddr_axi4_lp{core_clk}};
  wire [num_ddr_axi4_lp-1:0] mem_resets_li = {num_ddr_axi4_lp{core_reset}};

  mc_runner_top #(
    .num_axi4_p      (num_ddr_axi4_lp ),
    .mc_to_io_cdc_p  (1               ),
    .mc_to_mem_cdc_p (0               ), // currently, handle cdc outside of mc_top
    .axi_id_width_p  (axi_id_width_p  ),
    .axi_addr_width_p(axi_addr_width_p),
    .axi_data_width_p(axi_data_width_p)
  ) mc_top (
    .clk_core_i  (core_clk        ),
    .reset_core_i(core_reset      ),
    .clk_io_i    (clk_main_a0     ),
    .reset_io_i  (~rst_main_n_sync),
    .clk_mem_i   (mem_clocks_li   ),
    .reset_mem_i (mem_resets_li   ),
    .s_axil_bus_i(s_axil_ocl_li   ),
    .s_axil_bus_o(s_axil_ocl_lo   ),
    .m_axi4_bus_o(m_mc_axi4_lo    ),
    .m_axi4_bus_i(m_mc_axi4_li    )
  );


  // LEVEL 3
  //
  if (enable_axi_clk_cvt_lp == 1) begin : lv3_cdc
    for (genvar i = 0; i < num_ddr_axi4_lp; i++) begin : axi_clk_cvt
      axi4_clock_converter #(
        .device_family     (`DEVICE_FAMILY                       ),
        .s_axi_aclk_ratio_p(1                                    ),
        .m_axi_aclk_ratio_p(lc_core_clk_period_p/lc_clk_main_a0_p),
        .is_aclk_async_p   (1                                    ),
        .axi4_id_width_p   (axi_id_width_p                       ),
        .axi4_addr_width_p (axi_addr_width_p                     ),
        .axi4_data_width_p (axi_data_width_p                     )
      ) axi4_cdc (
        .clk_src_i   (core_clk             ),
        .reset_src_i (core_reset           ),
        .clk_dst_i   (clk_main_a0          ),
        .reset_dst_i (~rst_main_n_sync     ),
        .s_axi4_src_i(m_mc_axi4_lo[i]      ),
        .s_axi4_src_o(m_mc_axi4_li[i]      ),
        .m_axi4_dst_o(m_mc_axi4_async_lo[i]),
        .m_axi4_dst_i(m_mc_axi4_async_li[i])
      );
    end : axi_clk_cvt
  end : lv3_cdc
  else begin : lv3_cast
    assign m_mc_axi4_async_lo = m_mc_axi4_lo;
    assign m_mc_axi4_li = m_mc_axi4_async_li;
  end : lv3_cast

  assign s_axi4_ddr_li = m_mc_axi4_async_lo;
  assign m_mc_axi4_async_li = s_axi4_ddr_lo;


  // AXI4 casting to DDR C
  //
  assign cl_sh_ddr_awid     = s_axi4_ddr_li[0].awid;
  assign cl_sh_ddr_awaddr   = s_axi4_ddr_li[0].awaddr;
  assign cl_sh_ddr_awlen    = s_axi4_ddr_li[0].awlen;
  assign cl_sh_ddr_awsize   = s_axi4_ddr_li[0].awsize;
  assign cl_sh_ddr_awburst  = s_axi4_ddr_li[0].awburst;
  assign cl_sh_ddr_awlock   = s_axi4_ddr_li[0].awlock;
  assign cl_sh_ddr_awcache  = s_axi4_ddr_li[0].awcache;
  assign cl_sh_ddr_awprot   = s_axi4_ddr_li[0].awprot;
  assign cl_sh_ddr_awregion = s_axi4_ddr_li[0].awregion;
  assign cl_sh_ddr_awqos    = s_axi4_ddr_li[0].awqos;
  assign cl_sh_ddr_awvalid  = s_axi4_ddr_li[0].awvalid;
  assign s_axi4_ddr_lo[0].awready = sh_cl_ddr_awready;

  assign cl_sh_ddr_wdata  = s_axi4_ddr_li[0].wdata;
  assign cl_sh_ddr_wstrb  = s_axi4_ddr_li[0].wstrb;
  assign cl_sh_ddr_wlast  = s_axi4_ddr_li[0].wlast;
  assign cl_sh_ddr_wvalid = s_axi4_ddr_li[0].wvalid;
  assign s_axi4_ddr_lo[0].wready = sh_cl_ddr_wready;

  assign s_axi4_ddr_lo[0].bid    = sh_cl_ddr_bid;
  assign s_axi4_ddr_lo[0].bresp  = sh_cl_ddr_bresp;
  assign s_axi4_ddr_lo[0].bvalid = sh_cl_ddr_bvalid;
  assign cl_sh_ddr_bready = s_axi4_ddr_li[0].bready;

  assign cl_sh_ddr_arid     = s_axi4_ddr_li[0].arid;
  assign cl_sh_ddr_araddr   = s_axi4_ddr_li[0].araddr;
  assign cl_sh_ddr_arlen    = s_axi4_ddr_li[0].arlen;
  assign cl_sh_ddr_arsize   = s_axi4_ddr_li[0].arsize;
  assign cl_sh_ddr_arburst  = s_axi4_ddr_li[0].arburst;
  assign cl_sh_ddr_arlock   = s_axi4_ddr_li[0].arlock;
  assign cl_sh_ddr_arcache  = s_axi4_ddr_li[0].arcache;
  assign cl_sh_ddr_arprot   = s_axi4_ddr_li[0].arprot;
  assign cl_sh_ddr_arregion = s_axi4_ddr_li[0].arregion;
  assign cl_sh_ddr_arqos    = s_axi4_ddr_li[0].arqos;
  assign cl_sh_ddr_arvalid  = s_axi4_ddr_li[0].arvalid;
  assign s_axi4_ddr_lo[0].arready = sh_cl_ddr_arready;

  assign s_axi4_ddr_lo[0].rid    = sh_cl_ddr_rid;
  assign s_axi4_ddr_lo[0].rdata  = sh_cl_ddr_rdata;
  assign s_axi4_ddr_lo[0].rresp  = sh_cl_ddr_rresp;
  assign s_axi4_ddr_lo[0].rlast  = sh_cl_ddr_rlast;
  assign s_axi4_ddr_lo[0].rvalid = sh_cl_ddr_rvalid;
  assign cl_sh_ddr_rready = s_axi4_ddr_li[0].rready;


  // AXI4 casting to DDR A B D
  // 
  `declare_bsg_axi4_bus_s(num_cl_ddr_lp,  ddr_axi4_id_width_lp, ddr_axi4_addr_width_lp, ddr_axi4_data_width_lp, cl_ddrs_axi4_si_s, cl_ddrs_axi4_so_s);

  cl_ddrs_axi4_si_s s_axi4_ddr_hs_li;
  cl_ddrs_axi4_so_s m_axi4_ddr_hs_lo;

  axi4_transpose_h2v #(
    .num_axi4_p       (num_cl_ddr_lp   ),
    .axi4_id_width_p  (axi_id_width_p  ),
    .axi4_addr_width_p(axi_addr_width_p),
    .axi4_data_width_p(axi_data_width_p)
  ) axi4_trs (
    .s_axi4_hs_i(s_axi4_ddr_li[1+:num_cl_ddr_lp]),
    .s_axi4_hs_o(s_axi4_ddr_lo[1+:num_cl_ddr_lp]),
    .m_axi4_vs_o(s_axi4_ddr_hs_li               ),
    .m_axi4_vs_i(m_axi4_ddr_hs_lo               )
  );

  cl_sh_ddr_wrapper #(
    .num_axi4_p       (num_cl_ddr_lp   ),
    .axi4_id_width_p  (axi_id_width_p  ),
    .axi4_addr_width_p(axi_addr_width_p),
    .axi4_data_width_p(axi_data_width_p)
  ) sh_ddr_inst (
    .clk_i              (clk_main_a0                                                 ),
    .reset_i            (~rst_main_n_sync                                            ),
    .sh_ddr_stat_addr_i ({sh_ddr_stat_addr2, sh_ddr_stat_addr1, sh_ddr_stat_addr0}   ),
    .sh_ddr_stat_wr_i   ({sh_ddr_stat_wr2, sh_ddr_stat_wr1, sh_ddr_stat_wr0}         ),
    .sh_ddr_stat_rd_i   ({sh_ddr_stat_rd2, sh_ddr_stat_rd1, sh_ddr_stat_rd0}         ),
    .sh_ddr_stat_wdata_i({sh_ddr_stat_wdata2, sh_ddr_stat_wdata1, sh_ddr_stat_wdata0}),
    .ddr_sh_stat_ack_o  ({ddr_sh_stat_ack2, ddr_sh_stat_ack1, ddr_sh_stat_ack0}      ),
    .ddr_sh_stat_rdata_o({ddr_sh_stat_rdata2, ddr_sh_stat_rdata1, ddr_sh_stat_rdata0}),
    .ddr_sh_stat_int_o  ({ddr_sh_stat_int2, ddr_sh_stat_int1, ddr_sh_stat_int0}      ),
    .s_axi4_i           (s_axi4_ddr_hs_li                                            ),
    .s_axi4_o           (m_axi4_ddr_hs_lo                                            ),
    .CLK_300M_DIMM0_DP  (CLK_300M_DIMM0_DP                                           ),
    .CLK_300M_DIMM0_DN  (CLK_300M_DIMM0_DN                                           ),
    .M_A_ACT_N          (M_A_ACT_N                                                   ),
    .M_A_MA             (M_A_MA                                                      ),
    .M_A_BA             (M_A_BA                                                      ),
    .M_A_BG             (M_A_BG                                                      ),
    .M_A_CKE            (M_A_CKE                                                     ),
    .M_A_ODT            (M_A_ODT                                                     ),
    .M_A_CS_N           (M_A_CS_N                                                    ),
    .M_A_CLK_DN         (M_A_CLK_DN                                                  ),
    .M_A_CLK_DP         (M_A_CLK_DP                                                  ),
    .M_A_PAR            (M_A_PAR                                                     ),
    .M_A_DQ             (M_A_DQ                                                      ),
    .M_A_ECC            (M_A_ECC                                                     ),
    .M_A_DQS_DP         (M_A_DQS_DP                                                  ),
    .M_A_DQS_DN         (M_A_DQS_DN                                                  ),
    .cl_RST_DIMM_A_N    (cl_RST_DIMM_A_N                                             ),
    .CLK_300M_DIMM1_DP  (CLK_300M_DIMM1_DP                                           ),
    .CLK_300M_DIMM1_DN  (CLK_300M_DIMM1_DN                                           ),
    .M_B_ACT_N          (M_B_ACT_N                                                   ),
    .M_B_MA             (M_B_MA                                                      ),
    .M_B_BA             (M_B_BA                                                      ),
    .M_B_BG             (M_B_BG                                                      ),
    .M_B_CKE            (M_B_CKE                                                     ),
    .M_B_ODT            (M_B_ODT                                                     ),
    .M_B_CS_N           (M_B_CS_N                                                    ),
    .M_B_CLK_DN         (M_B_CLK_DN                                                  ),
    .M_B_CLK_DP         (M_B_CLK_DP                                                  ),
    .M_B_PAR            (M_B_PAR                                                     ),
    .M_B_DQ             (M_B_DQ                                                      ),
    .M_B_ECC            (M_B_ECC                                                     ),
    .M_B_DQS_DP         (M_B_DQS_DP                                                  ),
    .M_B_DQS_DN         (M_B_DQS_DN                                                  ),
    .cl_RST_DIMM_B_N    (cl_RST_DIMM_B_N                                             ),
    .CLK_300M_DIMM3_DP  (CLK_300M_DIMM3_DP                                           ),
    .CLK_300M_DIMM3_DN  (CLK_300M_DIMM3_DN                                           ),
    .M_D_ACT_N          (M_D_ACT_N                                                   ),
    .M_D_MA             (M_D_MA                                                      ),
    .M_D_BA             (M_D_BA                                                      ),
    .M_D_BG             (M_D_BG                                                      ),
    .M_D_CKE            (M_D_CKE                                                     ),
    .M_D_ODT            (M_D_ODT                                                     ),
    .M_D_CS_N           (M_D_CS_N                                                    ),
    .M_D_CLK_DN         (M_D_CLK_DN                                                  ),
    .M_D_CLK_DP         (M_D_CLK_DP                                                  ),
    .M_D_PAR            (M_D_PAR                                                     ),
    .M_D_DQ             (M_D_DQ                                                      ),
    .M_D_ECC            (M_D_ECC                                                     ),
    .M_D_DQS_DP         (M_D_DQS_DP                                                  ),
    .M_D_DQS_DN         (M_D_DQS_DN                                                  ),
    .cl_RST_DIMM_D_N    (cl_RST_DIMM_D_N                                             )
  );


   //-----------------------------------------------
   // Debug bridge, used if need Virtual JTAG
   //-----------------------------------------------
`ifndef DISABLE_VJTAG_DEBUG

   // Flop for timing global clock counter
   logic [63:0]               sh_cl_glcount0_q;

   always_ff @(posedge clk_main_a0)
     if (!rst_main_n_sync)
       sh_cl_glcount0_q <= 0;
     else
       sh_cl_glcount0_q <= sh_cl_glcount0;


   // Integrated Logic Analyzers (ILA)
   ila_0 CL_ILA_0 
     (
      .clk    (clk_main_a0),
      .probe0 (m_axil_ocl_awvalid)
      ,.probe1 (64'(m_axil_ocl_awaddr))
      ,.probe2 (m_axil_ocl_awready)
      ,.probe3 (m_axil_ocl_arvalid)
      ,.probe4 (64'(m_axil_ocl_araddr))
      ,.probe5 (m_axil_ocl_arready)
      );

   ila_0 CL_ILA_1 
     (
      .clk    (clk_main_a0)
      ,.probe0 (m_axil_ocl_bvalid)
      ,.probe1 (sh_cl_glcount0_q)
      ,.probe2 (m_axil_ocl_bready)
      ,.probe3 (m_axil_ocl_rvalid)
      ,.probe4 ({32'b0,m_axil_ocl_rdata[31:0]})
      ,.probe5 (m_axil_ocl_rready)
      );

   // Debug Bridge
   cl_debug_bridge CL_DEBUG_BRIDGE 
     (
      .clk(clk_main_a0)
      ,.S_BSCAN_drck(drck)
      ,.S_BSCAN_shift(shift)
      ,.S_BSCAN_tdi(tdi)
      ,.S_BSCAN_update(update)
      ,.S_BSCAN_sel(sel)
      ,.S_BSCAN_tdo(tdo)
      ,.S_BSCAN_tms(tms)
      ,.S_BSCAN_tck(tck)
      ,.S_BSCAN_runtest(runtest)
      ,.S_BSCAN_reset(reset)
      ,.S_BSCAN_capture(capture)
      ,.S_BSCAN_bscanid_en(bscanid_en)
      );

`endif //  `ifndef DISABLE_VJTAG_DEBUG

   // synopsys translate off
   int                        status;
   logic                      trace_en;
   initial begin
      assign trace_en = $test$plusargs("trace");
   end

   bind vanilla_core vanilla_core_trace 
     #(
       .x_cord_width_p(x_cord_width_p)
       ,.y_cord_width_p(y_cord_width_p)
       ,.icache_tag_width_p(icache_tag_width_p)
       ,.icache_entries_p(icache_entries_p)
       ,.data_width_p(data_width_p)
       ,.dmem_size_p(dmem_size_p)
       ) 
   vtrace 
     (
      .*
      ,.trace_en_i($root.tb.card.fpga.CL.trace_en)
      );


   // profilers
   //
   logic [31:0] global_ctr;

   bsg_cycle_counter global_cc 
     (
      .clk_i(core_clk)
      ,.reset_i(core_reset)
      ,.ctr_r_o(global_ctr)
      );


   bind vanilla_core vanilla_core_profiler 
     #(
       .x_cord_width_p(x_cord_width_p)
       ,.y_cord_width_p(y_cord_width_p)
       ,.data_width_p(data_width_p)
       ,.dmem_size_p(data_width_p)
       ) 
   vcore_prof
     (
      .*
      ,.global_ctr_i($root.tb.card.fpga.CL.global_ctr)
      ,.print_stat_v_i($root.tb.card.fpga.CL.mc_top.print_stat_v_lo)
      ,.print_stat_tag_i($root.tb.card.fpga.CL.mc_top.print_stat_tag_lo)
      ,.trace_en_i($root.tb.card.fpga.CL.trace_en)
      );

   // synopsys translate on

endmodule
