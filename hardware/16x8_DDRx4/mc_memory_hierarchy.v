/**
*  mc_memory_hierarchy.v
*
*/

`include "bsg_axi_bus_pkg.vh"

module mc_memory_hierarchy
  import cl_manycore_pkg::*;
  import bsg_bladerunner_mem_cfg_pkg::*;
#(
  parameter data_width_p = "inv"
  , parameter addr_width_p = "inv"
  , parameter x_cord_width_p = "inv"
  , parameter y_cord_width_p = "inv"
  , parameter load_id_width_p = "inv"
  // cache
  , parameter num_cache_p = "inv"
  , parameter num_axi4_p = "inv"
  , parameter caches_per_axi4_p = num_cache_p/num_axi4_p
  // AXI4
  , parameter axi_id_width_p = "inv"
  , parameter axi_addr_width_p = "inv"
  , parameter axi_data_width_p = "inv"
  , localparam link_sif_width_lp =
  `bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
  , localparam axi4_mosi_bus_width_lp =
  `bsg_axi4_mosi_bus_width(1, axi_id_width_p, axi_addr_width_p, axi_data_width_p)
  , localparam axi4_miso_bus_width_lp =
  `bsg_axi4_miso_bus_width(1, axi_id_width_p, axi_addr_width_p, axi_data_width_p)
) (
  input  [ num_axi4_p-1:0]                             clks_i
  ,input  [ num_axi4_p-1:0]                             resets_i
  // manycore side
  ,input  [num_cache_p-1:0][     link_sif_width_lp-1:0] link_sif_i
  ,output [num_cache_p-1:0][     link_sif_width_lp-1:0] link_sif_o
  // AXI Memory Mapped interface out
  ,output [ num_axi4_p-1:0][axi4_mosi_bus_width_lp-1:0] m_axi4_bus_o
  ,input  [ num_axi4_p-1:0][axi4_miso_bus_width_lp-1:0] m_axi4_bus_i
);


  // -------------------------------------------------
  // manycore packet casting
  // -------------------------------------------------
  `declare_bsg_manycore_link_sif_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p, load_id_width_p);

  bsg_manycore_link_sif_s [num_cache_p-1:0] cache_link_sif_li;
  bsg_manycore_link_sif_s [num_cache_p-1:0] cache_link_sif_lo;

  assign cache_link_sif_li = link_sif_i;
  assign link_sif_o = cache_link_sif_lo;


  // -------------------------------------------------
  // AXI4 casting
  // -------------------------------------------------
  `declare_bsg_axi4_bus_s(1, axi_id_width_p, axi_addr_width_p, axi_data_width_p, bsg_axi4_mosi_bus_s, bsg_axi4_miso_bus_s);

  bsg_axi4_mosi_bus_s [num_axi4_p-1:0] m_axi4_lo_cast;
  bsg_axi4_miso_bus_s [num_axi4_p-1:0] m_axi4_li_cast;

  assign m_axi4_bus_o = m_axi4_lo_cast;
  assign m_axi4_li_cast = m_axi4_bus_i;


  localparam byte_offset_width_lp = `BSG_SAFE_CLOG2(data_width_p>>3)             ;
  localparam cache_addr_width_lp  = (addr_width_p-1+byte_offset_width_lp)        ;
  localparam dma_pkt_width_lp     = `bsg_cache_dma_pkt_width(cache_addr_width_lp);

  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0][dma_pkt_width_lp-1:0] cache_dma_pkt        ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                       cache_dma_pkt_v_lo   ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                       cache_dma_pkt_yumi_li;

  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0][data_width_p-1:0] cache_dma_data_li      ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                   cache_dma_data_v_li    ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                   cache_dma_data_ready_lo;

  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0][data_width_p-1:0] cache_dma_data_lo     ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                   cache_dma_data_v_lo   ;
  logic [num_axi4_p-1:0][caches_per_axi4_p-1:0]                   cache_dma_data_yumi_li;

  // =================================================
  // LEVEL 1
  // =================================================

  if (mem_cfg_p == e_infinite_mem) begin : lv1_inf

    wire clk_i = clks_i;
    wire reset_i = resets_i;

    // each column has a nonsynth infinite memory
    for (genvar i = 0; i < num_cache_p; i++) begin
      bsg_nonsynth_mem_infinite #(
        .data_width_p(data_width_p)
        ,.addr_width_p(addr_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
        ,.load_id_width_p(load_id_width_p)
      ) mem_infty (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        // memory systems link from bsg_manycore_wrapper
        ,.link_sif_i(cache_link_sif_li[i])
        ,.link_sif_o(cache_link_sif_lo[i])
        // coordinates for memory system are determined by bsg_manycore_wrapper
        ,.my_x_i(cache_x_lo[i])
        ,.my_y_i(cache_y_lo[i])
      );
    end

    assign m_axi4_lo_cast = '0;

    bind bsg_nonsynth_mem_infinite infinite_mem_profiler #(
      .data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) infinite_mem_prof (
      .*
      ,.global_ctr_i($root.tb.card.fpga.CL.global_ctr)
      ,.print_stat_v_i($root.tb.card.fpga.CL.mc_top.print_stat_v_lo)
      ,.print_stat_tag_i($root.tb.card.fpga.CL.mc_top.print_stat_tag_lo)
    );

  end : lv1_inf

  else if (mem_cfg_p == e_vcache_blocking_axi4_f1_dram || mem_cfg_p == e_vcache_blocking_axi4_f1_model) begin : lv1_vcache

    logic [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt        ;
    logic [num_cache_p-1:0]                       dma_pkt_v_lo   ;
    logic [num_cache_p-1:0]                       dma_pkt_yumi_li;

    logic [num_cache_p-1:0][data_width_p-1:0] dma_data_li      ;
    logic [num_cache_p-1:0]                   dma_data_v_li    ;
    logic [num_cache_p-1:0]                   dma_data_ready_lo;

    logic [num_cache_p-1:0][data_width_p-1:0] dma_data_lo     ;
    logic [num_cache_p-1:0]                   dma_data_v_lo   ;
    logic [num_cache_p-1:0]                   dma_data_yumi_li;

    for (genvar i = 0; i < num_cache_p; i++) begin : vcache
      bsg_manycore_vcache_blocking #(
        .data_width_p(data_width_p)
        ,.addr_width_p(addr_width_p)
        ,.block_size_in_words_p(block_size_in_words_p)
        ,.sets_p(sets_p)
        ,.ways_p(ways_p)

        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
        ,.load_id_width_p(load_id_width_p)
      ) vcache (
        .clk_i(clks_i[i/caches_per_axi4_p])
        ,.reset_i(resets_i[i/caches_per_axi4_p])
        // memory systems link from bsg_manycore_wrapper
        ,.link_sif_i(cache_link_sif_li[i])
        ,.link_sif_o(cache_link_sif_lo[i])
        // coordinates for memory system are determined by bsg_manycore_wrapper
        ,.my_x_i(cache_x_lo[i])
        ,.my_y_i(cache_y_lo[i])

        ,.dma_pkt_o(dma_pkt[i])
        ,.dma_pkt_v_o(dma_pkt_v_lo[i])
        ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

        ,.dma_data_i(dma_data_li[i])
        ,.dma_data_v_i(dma_data_v_li[i])
        ,.dma_data_ready_o(dma_data_ready_lo[i])

        ,.dma_data_o(dma_data_lo[i])
        ,.dma_data_v_o(dma_data_v_lo[i])
        ,.dma_data_yumi_i(dma_data_yumi_li[i])
      );      
    end : vcache

    assign cache_dma_pkt = dma_pkt;
    assign cache_dma_pkt_v_lo = dma_pkt_v_lo;
    assign dma_pkt_yumi_li = cache_dma_pkt_yumi_li;
    assign dma_data_li = cache_dma_data_li;
    assign dma_data_v_li = cache_dma_data_v_li;
    assign cache_dma_data_ready_lo = dma_data_ready_lo;
    assign cache_dma_data_lo = dma_data_lo;
    assign cache_dma_data_v_lo = dma_data_v_lo;
    assign dma_data_yumi_li = cache_dma_data_yumi_li;

  `ifdef COSIM
    bind bsg_cache vcache_profiler #(
      .data_width_p(data_width_p)
    ) vcache_prof (
      .*
      ,.global_ctr_i($root.tb.card.fpga.CL.global_ctr)
      ,.print_stat_v_i($root.tb.card.fpga.CL.mc_top.print_stat_v_lo)
      ,.print_stat_tag_i($root.tb.card.fpga.CL.mc_top.print_stat_tag_lo)
    );
  `endif

  end : lv1_vcache


  // =================================================
  // LEVEL 2
  // =================================================

  if (mem_cfg_p == e_vcache_blocking_axi4_f1_dram || mem_cfg_p == e_vcache_blocking_axi4_f1_model) begin : lv2_4_axi4

    for (genvar i = 0; i < num_axi4_p; i++) begin : cache_to_axi

      bsg_cache_to_axi_hashed #(
        .addr_width_p         (cache_addr_width_lp  ),
        .block_size_in_words_p(block_size_in_words_p),
        .data_width_p         (data_width_p         ),
        .num_cache_p          (caches_per_axi4_p    ),
        
        .axi_id_width_p       (axi_id_width_p       ),
        .axi_addr_width_p     (axi_addr_width_p     ),
        .axi_data_width_p     (axi_data_width_p     ),
        .axi_burst_len_p      (axi_burst_len_p      )
      ) cache_to_axi (
        .clk_i           (clks_i[i]                 ),
        .reset_i         (resets_i[i]               ),
        
        .dma_pkt_i       (cache_dma_pkt[i]          ),
        .dma_pkt_v_i     (cache_dma_pkt_v_lo[i]     ),
        .dma_pkt_yumi_o  (cache_dma_pkt_yumi_li[i]  ),
        
        .dma_data_o      (cache_dma_data_li[i]      ),
        .dma_data_v_o    (cache_dma_data_v_li[i]    ),
        .dma_data_ready_i(cache_dma_data_ready_lo[i]),
        
        .dma_data_i      (cache_dma_data_lo[i]      ),
        .dma_data_v_i    (cache_dma_data_v_lo[i]    ),
        .dma_data_yumi_o (cache_dma_data_yumi_li[i] ),
        
        .axi_awid_o      (m_axi4_lo_cast[i].awid   ),
        .axi_awaddr_o    (m_axi4_lo_cast[i].awaddr ),
        .axi_awlen_o     (m_axi4_lo_cast[i].awlen  ),
        .axi_awsize_o    (m_axi4_lo_cast[i].awsize ),
        .axi_awburst_o   (m_axi4_lo_cast[i].awburst),
        .axi_awcache_o   (m_axi4_lo_cast[i].awcache),
        .axi_awprot_o    (m_axi4_lo_cast[i].awprot ),
        .axi_awlock_o    (m_axi4_lo_cast[i].awlock ),
        .axi_awvalid_o   (m_axi4_lo_cast[i].awvalid),
        .axi_awready_i   (m_axi4_li_cast[i].awready),
        
        .axi_wdata_o     (m_axi4_lo_cast[i].wdata  ),
        .axi_wstrb_o     (m_axi4_lo_cast[i].wstrb  ),
        .axi_wlast_o     (m_axi4_lo_cast[i].wlast  ),
        .axi_wvalid_o    (m_axi4_lo_cast[i].wvalid ),
        .axi_wready_i    (m_axi4_li_cast[i].wready ),
        
        .axi_bid_i       (m_axi4_li_cast[i].bid    ),
        .axi_bresp_i     (m_axi4_li_cast[i].bresp  ),
        .axi_bvalid_i    (m_axi4_li_cast[i].bvalid ),
        .axi_bready_o    (m_axi4_lo_cast[i].bready ),
        
        .axi_arid_o      (m_axi4_lo_cast[i].arid   ),
        .axi_araddr_o    (m_axi4_lo_cast[i].araddr ),
        .axi_arlen_o     (m_axi4_lo_cast[i].arlen  ),
        .axi_arsize_o    (m_axi4_lo_cast[i].arsize ),
        .axi_arburst_o   (m_axi4_lo_cast[i].arburst),
        .axi_arcache_o   (m_axi4_lo_cast[i].arcache),
        .axi_arprot_o    (m_axi4_lo_cast[i].arprot ),
        .axi_arlock_o    (m_axi4_lo_cast[i].arlock ),
        .axi_arvalid_o   (m_axi4_lo_cast[i].arvalid),
        .axi_arready_i   (m_axi4_li_cast[i].arready),
        
        .axi_rid_i       (m_axi4_li_cast[i].rid    ),
        .axi_rdata_i     (m_axi4_li_cast[i].rdata  ),
        .axi_rresp_i     (m_axi4_li_cast[i].rresp  ),
        .axi_rlast_i     (m_axi4_li_cast[i].rlast  ),
        .axi_rvalid_i    (m_axi4_li_cast[i].rvalid ),
        .axi_rready_o    (m_axi4_lo_cast[i].rready )
      );

      assign m_axi4_lo_cast[i].awregion = 4'b0;
      assign m_axi4_lo_cast[i].awqos    = 4'b0;

      assign m_axi4_lo_cast[i].arregion = 4'b0;
      assign m_axi4_lo_cast[i].arqos    = 4'b0;
    end

  end // block: lv2_axi4_x4

endmodule : mc_memory_hierarchy
