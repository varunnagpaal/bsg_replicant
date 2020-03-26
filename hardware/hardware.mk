# Copyright (c) 2019, University of Washington All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
# 
# Neither the name of the copyright holder nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This makefile fragmeent adds to the list of hardware sources
# $(VSOURCES) and $(VHEADERS) that are necessary to use this project.

# Some $(VSOURCES) and $(VHEADERS) are generated by scripts. These
# files have rules that generate the outputs, so it is good practice
# to have rules depend on $(VSOURCES) and $(VHEADERS)

# This file REQUIRES several variables to be set. They are typically
# set by the Makefile that includes this makefile..
#
# : The path to the Makefile.machine.include that defines Machine parameters
ifndef BSG_MACHINE_PATH
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: BSG_MACHINE_PATH is not defined$(NC)"))
endif

# HARDWARE_PATH: The path to the hardware folder in BSG F1
ifndef HARDWARE_PATH
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: HARDWARE_PATH is not defined$(NC)"))
endif

# BSG_MANYCORE_DIR: The path to the bsg_manycore repository
ifndef BSG_MANYCORE_DIR
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: BSG_MANYCORE_DIR is not defined$(NC)"))
endif

# BASEJUMP_STL_DIR: The path to the bsg_manycore repository
ifndef BASEJUMP_STL_DIR
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: BASEJUMP_STL_DIR is not defined$(NC)"))
endif

# Makefile.machine.include defines the Manycore hardware
# configuration.
include $(BSG_MACHINE_PATH)/Makefile.machine.include
CL_MANYCORE_MAX_EPA_WIDTH            := $(BSG_MACHINE_MAX_EPA_WIDTH)
CL_MANYCORE_DATA_WIDTH               := $(BSG_MACHINE_DATA_WIDTH)
CL_MANYCORE_VCACHE_WAYS              := $(BSG_MACHINE_VCACHE_WAY)
CL_MANYCORE_VCACHE_SETS              := $(BSG_MACHINE_VCACHE_SET)
CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS  := $(BSG_MACHINE_VCACHE_BLOCK_SIZE_WORDS)
CL_MANYCORE_VCACHE_MISS_FIFO_ELS     := $(BSG_MACHINE_VCACHE_MISS_FIFO_ELS)
CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS := $(BSG_MACHINE_VCACHE_STRIPE_SIZE_WORDS)
CL_MANYCORE_IO_REMOTE_LOAD_CAP       := $(BSG_MACHINE_IO_REMOTE_LOAD_CAP)
CL_MANYCORE_IO_HOST_CREDITS_CAP      := $(BSG_MACHINE_IO_HOST_CREDITS_CAP)
CL_MANYCORE_IO_EP_MAX_OUT_CREDITS    := $(BSG_MACHINE_IO_EP_MAX_OUT_CREDITS)
CL_MANYCORE_BRANCH_TRACE_EN          := $(BSG_MACHINE_BRANCH_TRACE_EN)
CL_MANYCORE_DRAM_BANK_SIZE_WORDS     := $(BSG_MACHINE_DRAM_BANK_SIZE_WORDS)
CL_MANYCORE_VCACHE_DMA_DATA_WIDTH    := $(BSG_MACHINE_VCACHE_DMA_DATA_WIDTH)
CL_MANYCORE_RELEASE_VERSION          ?= $(shell echo $(FPGA_IMAGE_VERSION) | sed 's/\([0-9]*\)\.\([0-9]*\).\([0-9]*\)/000\10\20\3/')
CL_MANYCORE_COMPILATION_DATE         ?= $(shell date +%m%d%Y)
CL_TOP_MODULE                        := cl_manycore

# The following variables are defined by environment.mk if this bsg_f1
# repository is a submodule of bsg_bladerunner. If they are not set,
# we use default values.
BASEJUMP_STL_COMMIT_ID ?= deadbeef
BSG_MANYCORE_COMMIT_ID ?= feedcafe
BSG_F1_COMMIT_ID       ?= 42c0ffee
FPGA_IMAGE_VERSION     ?= 0.0.0

# The manycore architecture sources are defined in arch_filelist.mk. The
# unsynthesizable simulation sources (for tracing, etc) are defined in
# sim_filelist.mk. Each file adds to VSOURCES and VINCLUDES and depends on
# BSG_MANYCORE_DIR
include $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3_pkg.v

# So that we can limit tool-specific to a few specific spots we use VDEFINES,
# VINCLUDES, and VSOURCES to hold lists of macros, include directores, and
# verilog sources (respectively). These are used during simulation compilation,
# but transformed into a tool-specific syntax where necesssary.
VINCLUDES += $(HARDWARE_PATH)
VINCLUDES += $(BSG_MACHINE_PATH)

VSOURCES += $(HARDWARE_PATH)/bsg_bladerunner_mem_cfg_pkg.v
# Machine-Specific Source (Autogenerated)
VSOURCES += $(BSG_MACHINE_PATH)/bsg_bladerunner_configuration.v

VSOURCES += $(HARDWARE_PATH)/cl_manycore_pkg.v
VSOURCES += $(HARDWARE_PATH)/$(CL_TOP_MODULE).sv
VSOURCES += $(HARDWARE_PATH)/bsg_manycore_wrapper.v
VSOURCES += $(HARDWARE_PATH)/bsg_print_stat_snoop.v

# Static sources
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_axi_rx.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_axi_tx.v
VSOURCES += $(BSG_MANYCORE_DIR)/v/vanilla_bean/hash_function_reverse.v
VSOURCES += $(BSG_MANYCORE_DIR)/v/vanilla_bean/bsg_cache_to_axi_hashed.v

# Machine-Specific Source (Autogenerated)
VSOURCES += $(BSG_MACHINE_PATH)/bsg_bladerunner_rom_pkg.vh
VSOURCES += $(CL_DIR)/hardware/bsg_manycore_link_to_axil_pkg.v
VSOURCES += $(CL_DIR)/hardware/bsg_mcl_axil_fifos_master.v
VSOURCES += $(CL_DIR)/hardware/bsg_mcl_axil_fifos_slave.v
VSOURCES += $(CL_DIR)/hardware/bsg_manycore_endpoint_to_fifos.v
VSOURCES += $(CL_DIR)/hardware/bsg_manycore_link_to_axil.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_serial_in_parallel_out_full.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_1_to_n.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_one_fifo.v

# Machine-Specific Source (Autogenerated)
VHEADERS += $(BSG_MACHINE_PATH)/f1_parameters.vh
VHEADERS += $(HARDWARE_PATH)/bsg_axi_bus_pkg.vh
VHEADERS += $(HARDWARE_PATH)/cl_manycore_defines.vh
VHEADERS += $(HARDWARE_PATH)/cl_id_defines.vh


# The following functions convert a decimal string to a binary string,
# and a hexadecimal string (WITHOUT the preceeding 0x) into binary
# strings of 32-characters in length
define dec2bin
	`perl -e 'printf "%032b\n",'$(strip $(1))`
endef

define hex2bin
	`perl -e 'printf "%032b\n",'0x$(strip $(1))`
endef

define charv2hex
	$(shell python -c 'print("{:02x}{:02x}{:02x}{:02x}".format(*(ord(c) for c in $(strip $(1))[::-1])))')
endef

charv2bin = $(call hex2bin, $(call charv2hex, $(1)))

# Each manycore design contains a Read-Only Memory (ROM) that
# describes its configuration. This ROM is generated by BaseJump using
# bsg_ascii_to_rom, which parses an ASCII file that encodes binary
# data. Each rom entry is a 32-character string with 1/0 values. Each
# line is a separate entry. This target generates the verilog for the rom.
$(BSG_MACHINE_PATH)/%.v: $(BSG_MACHINE_PATH)/%.rom
	env python2 $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< \
               bsg_bladerunner_configuration > $@


include $(HARDWARE_PATH)/memsys.mk

# This target generates the ASCII file for the ROM. To add entries to
# the ROM, add more commands below.
$(BSG_MACHINE_PATH)/bsg_bladerunner_configuration.rom: $(BSG_MACHINE_PATH)/Makefile.machine.include
	@echo $(call hex2bin,$(CL_MANYCORE_RELEASE_VERSION))   > $@.temp
	@echo $(call hex2bin,$(CL_MANYCORE_COMPILATION_DATE))  >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MAX_EPA_WIDTH))     >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DATA_WIDTH))        >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DIM_X))             >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DIM_Y))             >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_HOST_COORD_X))      >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_HOST_COORD_Y))      >> $@.temp
	@echo $(call dec2bin,0)                                >> $@.temp
	@echo $(call hex2bin,$(BASEJUMP_STL_COMMIT_ID))        >> $@.temp
	@echo $(call hex2bin,$(BSG_MANYCORE_COMMIT_ID))        >> $@.temp
	@echo $(call hex2bin,$(BSG_F1_COMMIT_ID))              >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_WAYS))       >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_SETS))       >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS))  >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_MISS_FIFO_ELS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_IO_REMOTE_LOAD_CAP)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_IO_HOST_CREDITS_CAP)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_IO_EP_MAX_OUT_CREDITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DRAM_CHANNELS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DRAM_BANK_SIZE_WORDS)) >> $@.temp
	@echo $(call charv2bin,$(CL_MANYCORE_MEMSYS_ID)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_RO_BITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BG_BITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BA_BITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_CO_BITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BYTE_OFF_BITS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_RO_BITIDX)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BG_BITIDX)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BA_BITIDX)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_CO_BITIDX)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MEMSYS_DRAM_BYTE_OFF_BITIDX)) >> $@.temp
	mv $@.temp $@

# Each manycore design on has a set of parameters that define
# it. Instead of passing these parameters as command-line defines
# (which is tool-specific) we generate a header file.
$(BSG_MACHINE_PATH)/f1_parameters.vh: $(BSG_MACHINE_PATH)/Makefile.machine.include
	@echo "\`ifndef F1_DEFINES" > $@
	@echo "\`define F1_DEFINES" >> $@
	@echo "\`define CL_MANYCORE_MAX_EPA_WIDTH $(CL_MANYCORE_MAX_EPA_WIDTH)" >> $@
	@echo "\`define CL_MANYCORE_DATA_WIDTH $(CL_MANYCORE_DATA_WIDTH)" >> $@
	@echo "\`define CL_MANYCORE_DIM_X $(CL_MANYCORE_DIM_X)" >> $@
	@echo "\`define CL_MANYCORE_DIM_Y $(CL_MANYCORE_DIM_Y)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_SETS $(CL_MANYCORE_VCACHE_SETS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_WAYS $(CL_MANYCORE_VCACHE_WAYS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS $(CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS $(CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_MISS_FIFO_ELS $(CL_MANYCORE_VCACHE_MISS_FIFO_ELS)" >> $@
	@echo "\`define CL_MANYCORE_MEM_CFG $(CL_MANYCORE_MEM_CFG)" >> $@
	@echo "\`define CL_MANYCORE_BRANCH_TRACE_EN $(CL_MANYCORE_BRANCH_TRACE_EN)" >> $@
	@echo "\`define CL_MANYCORE_IO_EP_MAX_OUT_CREDITS $(CL_MANYCORE_IO_EP_MAX_OUT_CREDITS)" >> $@
	@echo "\`define CL_MANYCORE_DRAM_CHANNELS $(CL_MANYCORE_DRAM_CHANNELS)" >> $@
	@echo "\`define CL_MANYCORE_DRAM_BANK_SIZE_WORDS $(CL_MANYCORE_DRAM_BANK_SIZE_WORDS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_DMA_DATA_WIDTH $(CL_MANYCORE_VCACHE_DMA_DATA_WIDTH)" >> $@
	@echo "\`endif" >> $@

# This package defines the number of lines in the ROM
$(BSG_MACHINE_PATH)/bsg_bladerunner_rom_pkg.vh: $(BSG_MACHINE_PATH)/bsg_bladerunner_configuration.rom
	@echo "\`ifndef BSG_BLADERUNNER_ROM_PKG" > $@
	@echo "\`define BSG_BLADERUNNER_ROM_PKG" >> $@
	@echo >> $@
	@echo "package bsg_bladerunner_rom_pkg;" >> $@
	@echo >> $@
	@echo "parameter rom_width_gp = 32;" >> $@
	@echo "parameter rom_els_gp = `wc -l < $<`;" >> $@
	@echo >> $@
	@echo "endpackage" >> $@
	@echo >> $@
	@echo "\`endif" >> $@


.PHONY: hardware.clean

hardware.clean:
	rm -f $(MACHINES_PATH)/*/bsg_bladerunner_configuration.{rom,v}
	rm -f $(MACHINES_PATH)/*/f1_parameters.vh
	rm -f $(MACHINES_PATH)/*/bsg_bladerunner_rom_pkg.vh

.PRECIOUS: $(BSG_MACHINE_PATH)/bsg_bladerunner_configuration.v $(BSG_MACHINE_PATH)/bsg_bladerunner_configuration.rom
