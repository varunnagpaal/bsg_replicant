# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.


# TODO:
# Add check if CL_DIR and HDK_SHELL_DIR directories exist
# Add check if /build and /build/src_port_encryption directories exist
# Add check if the vivado_keyfile exist

set HDK_SHELL_DIR $::env(HDK_SHELL_DIR)
set CL_DIR $::env(CL_DIR)
set COMMON_DIR $CL_DIR/../hdl/
set BSG_MANYCORE_DIR $::env(BSG_MANYCORE_DIR)
set BSG_IP_CORES_DIR $::env(BSG_IP_CORES_DIR)
set VIVADO_IP_DIR $::env(XILINX_VIVADO)/data/ip/xilinx/

set TARGET_DIR $CL_DIR/build/src_post_encryption
set UNUSED_TEMPLATES_DIR $HDK_SHELL_DIR/design/interfaces

# Remove any previously encrypted files, that may no longer be used
if {[llength [glob -nocomplain -dir $TARGET_DIR *]] != 0} {
  eval file delete -force [glob $TARGET_DIR/*]
}

# List your design files below. Include any .inc files, but do NOT include
# AWS source files.
file copy -force $COMMON_DIR/bsg_axi_bus_pkg.vh                               $TARGET_DIR
file copy -force $COMMON_DIR/axil_to_mcl.vh                                   $TARGET_DIR
file copy -force $COMMON_DIR/axil_to_mcl.v                                    $TARGET_DIR
file copy -force $COMMON_DIR/s_axil_mcl_adapter.v                             $TARGET_DIR
file copy -force $COMMON_DIR/axil_to_mem.sv                                   $TARGET_DIR
file copy -force $COMMON_DIR/bsg_bladerunner_rom_pkg.vh                       $TARGET_DIR
file copy -force $COMMON_DIR/bsg_bladerunner_rom.v                            $TARGET_DIR

file copy -force $CL_DIR/hardware/cl_manycore_pkg.v                           $TARGET_DIR
file copy -force $CL_DIR/hardware/cl_manycore_defines.vh                      $TARGET_DIR
file copy -force $CL_DIR/hardware/cl_id_defines.vh                            $TARGET_DIR
file copy -force $CL_DIR/hardware/cl_manycore.sv                              $TARGET_DIR
file copy -force $CL_DIR/hardware/bsg_bladerunner_configuration.v             $TARGET_DIR

file copy -force $BSG_MANYCORE_DIR/v/bladerunner/bsg_manycore_wrapper.v       $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bladerunner/bsg_cache_wrapper_axi.v      $TARGET_DIR

file copy -force $VIVADO_IP_DIR/generic_baseblocks_v2_1/hdl/generic_baseblocks_v2_1_vl_rfs.v        $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_register_slice_v2_1/hdl/axi_register_slice_v2_1_vl_rfs.v        $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_crossbar_v2_1/hdl/axi_crossbar_v2_1_vl_rfs.v                    $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_dwidth_converter_v2_1/hdl/axi_dwidth_converter_v2_1_vlsyn_rfs.v $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_data_fifo_v2_1/hdl/axi_data_fifo_v2_1_vl_rfs.v                  $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_infrastructure_v1_1/hdl/axi_infrastructure_v1_1_0.vh            $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_infrastructure_v1_1/hdl/axi_infrastructure_v1_1_vl_rfs.v        $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_lite_ipif_v3_0/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd                $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axi_fifo_mm_s_v4_1/hdl/axi_fifo_mm_s_v4_1_rfs.vhd                   $TARGET_DIR

file copy -force $VIVADO_IP_DIR/fifo_generator_v13_2/hdl/fifo_generator_v13_2_vhsyn_rfs.vhd         $TARGET_DIR
file copy -force $VIVADO_IP_DIR/blk_mem_gen_v8_4/hdl/blk_mem_gen_v8_4_vhsyn_rfs.vhd                 $TARGET_DIR
file copy -force $VIVADO_IP_DIR/lib_fifo_v1_0/hdl/lib_fifo_v1_0_rfs.vhd                             $TARGET_DIR
file copy -force $VIVADO_IP_DIR/lib_pkg_v1_0/hdl/lib_pkg_v1_0_rfs.vhd                               $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axis_register_slice_v1_1/hdl/axis_register_slice_v1_1_vl_rfs.v      $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axis_infrastructure_v1_1/hdl/axis_infrastructure_v1_1_0.vh          $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axis_infrastructure_v1_1/hdl/axis_infrastructure_v1_1_vl_rfs.v      $TARGET_DIR
file copy -force $VIVADO_IP_DIR/axis_dwidth_converter_v1_1/hdl/axis_dwidth_converter_v1_1_vl_rfs.v  $TARGET_DIR

file copy -force $UNUSED_TEMPLATES_DIR/unused_apppf_irq_template.inc          $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_cl_sda_template.inc             $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_ddr_a_b_d_template.inc          $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_ddr_c_template.inc              $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_dma_pcis_template.inc           $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_pcim_template.inc               $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_sh_bar1_template.inc            $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_flr_template.inc                $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/bsg_noc/bsg_noc_pkg.v                      $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_noc/bsg_mesh_stitch.v                  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_noc/bsg_mesh_router_buffered.v         $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_noc/bsg_mesh_router.v                  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_noc/bsg_noc_links.vh                   $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_pkg.v                  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_pkt.vh                 $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_pkt_decode.v           $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_dma_pkt.vh             $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_manycore_link_to_cache.v     $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_to_axi_rx.v            $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_to_axi_tx.v            $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_to_axi.v               $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_dma.v                  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_miss.v                 $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_sbuf.v                 $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache_sbuf_queue.v           $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_cache/bsg_cache.v                      $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_round_robin_n_to_1.v      $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_fifo_tracker.v            $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_fifo_1r1w_small.v         $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_serial_in_parallel_out.v  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_parallel_in_serial_out.v  $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_two_fifo.v                $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_fifo_1r1w_large.v         $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_fifo_1rw_large.v          $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_dataflow/bsg_round_robin_2_to_2.v      $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_defines.v                     $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_decode.v                      $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_decode_with_v.v               $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_counter_clear_up.v            $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_counter_up_down.v             $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_circular_ptr.v                $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_mux_segmented.v               $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_thermometer_count.v           $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_round_robin_arb.v             $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_crossbar_o_by_i.v             $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_mux.v                         $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_mux_one_hot.v                 $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_imul_iterative.v              $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_idiv_iterative.v              $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_idiv_iterative_controller.v   $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_buf.v                         $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_buf_ctrl.v                    $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_dff_en.v                      $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_dff_reset.v                   $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_xnor.v                        $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_nor2.v                        $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_adder_cin.v                   $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_transpose.v                   $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_arb_fixed.v                   $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_priority_encode_one_hot_out.v $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_scan.v                        $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_dlatch.v                      $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_misc/bsg_clkgate_optional.v            $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_banked_crossbar.v          $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1r1w_synth.v               $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1r1w.v                     $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1rw_sync_mask_write_byte_synth.v $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.v $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1rw_sync.v                 $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_1rw_sync_synth.v           $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_2r1w_sync.v                $TARGET_DIR
file copy -force $BSG_IP_CORES_DIR/bsg_mem/bsg_mem_2r1w_sync_synth.v          $TARGET_DIR

file copy -force $BSG_IP_CORES_DIR/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v $TARGET_DIR

file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/bsg_manycore_proc_vanilla.v $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/alu.v                       $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/cl_decode.v                 $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/regfile.v                   $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/scoreboard.v                $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/icache.v                    $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/imul_idiv_iterative.v       $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/load_packer.v               $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/hobbit.v                    $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/definitions.vh              $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/vanilla_bean/parameters.vh               $TARGET_DIR

file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_endpoint_standard.v         $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_endpoint.v                  $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_lock_ctrl.v                 $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_1hold.v                              $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_pkt_encode.v                $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_link_sif_tieoff.v           $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_mesh_node.v                 $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_hetero_socket.v             $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_tile.v                      $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore.v                           $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_packet.vh                   $TARGET_DIR
file copy -force $BSG_MANYCORE_DIR/v/bsg_manycore_addr.vh                     $TARGET_DIR

# End of design files

# Make sure files have write permissions for the encryption
exec chmod +w {*}[glob $TARGET_DIR/*]

# encrypt .v/.sv/.vh/inc as verilog files
encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_keyfile.txt -lang verilog  [glob -nocomplain -- $TARGET_DIR/*.?v] [glob -nocomplain -- $TARGET_DIR/*.vh] [glob -nocomplain -- $TARGET_DIR/*.inc]

# encrypt *vhdl files
encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_vhdl_keyfile.txt -lang vhdl -quiet [ glob -nocomplain -- $TARGET_DIR/*.vhd? ]

