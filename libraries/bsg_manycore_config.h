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

#ifndef BSG_MANYCORE_CONFIG_H
#define BSG_MANYCORE_CONFIG_H

/* MAX AND DUSTIN'S RULE OF THUMB FOR WHAT GOES IN CONFIG
 *
 * An entity requires an accessor in config if: 
 * 1. It is in the ROM (or other configuration register)
 * 2. It is trivially derivable from data in the ROM
 * 3. It is a top-level parameter that SHOULD BE in the ROM.
 */

#include <bsg_manycore_features.h>
#include <bsg_manycore_coordinate.h>

#ifdef __cplusplus
#include <cstdint>
#include <cmath>
#else
#include <stdint.h>
#include <math.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

        // We expect a 32-bit bus for Addresses, but two bits are removed because the
        // network uses word-level addressing and handles byte-writes with a mask
#define HB_MC_CONFIG_MAX_BITWIDTH_ADDR 30
#define HB_MC_CONFIG_MAX_BITWIDTH_DATA 32

#define HB_MC_CONFIG_VCORE_BASE_X 0
#define HB_MC_CONFIG_VCORE_BASE_Y 2

        typedef uint32_t hb_mc_config_raw_t;
        /* Compilation Metadata */
        typedef struct __hb_mc_version_t {
                uint8_t major;
                uint8_t minor;
                uint8_t revision;
        } hb_mc_version_t;

        typedef struct __hb_mc_date_t {
                uint8_t month;
                uint8_t day;
                uint16_t year;
        } hb_mc_date_t;

        typedef uint32_t hb_mc_githash_t;

        typedef struct __hb_mc_config_t{
                hb_mc_version_t design_version;
                hb_mc_date_t timestamp;
                uint32_t network_bitwidth_addr;
                uint32_t network_bitwidth_data;
                hb_mc_dimension_t vcore_dimensions;
                hb_mc_coordinate_t host_interface;
                hb_mc_githash_t basejump;
                hb_mc_githash_t manycore;
                hb_mc_githash_t f1;
                uint32_t vcache_ways;
                uint32_t vcache_sets;
                uint32_t vcache_block_words;
                uint32_t vcache_stripe_words;
		uint32_t reserved0;
		uint32_t dram_channels;
		uint32_t dram_bank_size_words;
        } hb_mc_config_t;

        typedef enum __hb_mc_config_id_t {
                HB_MC_CONFIG_MIN = 0,
                HB_MC_CONFIG_VERSION = 0,
                HB_MC_CONFIG_TIMESTAMP = 1,
                HB_MC_CONFIG_NETWORK_ADDR_WIDTH = 2,
                HB_MC_CONFIG_NETWORK_DATA_WIDTH = 3,
                HB_MC_CONFIG_DEVICE_DIM_X = 4,
                HB_MC_CONFIG_DEVICE_DIM_Y = 5,
                HB_MC_CONFIG_DEVICE_HOST_INTF_COORD_X = 6,
                HB_MC_CONFIG_DEVICE_HOST_INTF_COORD_Y = 7,
                HB_MC_CONFIG_NOT_IMPLEMENTED = 8,
                HB_MC_CONFIG_REPO_BASEJUMP_HASH = 9,
                HB_MC_CONFIG_REPO_MANYCORE_HASH = 10,
                HB_MC_CONFIG_REPO_F1_HASH = 11,
                HB_MC_CONFIG_VCACHE_WAYS = 12,
                HB_MC_CONFIG_VCACHE_SETS = 13,
                HB_MC_CONFIG_VCACHE_BLOCK_WORDS = 14,
                HB_MC_CONFIG_VCACHE_STRIPE_WORDS = 15,
		HB_MC_CONFIG_RESERVED0 = 16,
		HB_MC_CONFIG_DRAM_CHANNELS = 17,
		HB_MC_CONFIG_DRAM_BANK_SIZE_WORDS = 18,
		HB_MC_CONFIG_MAX,
        } hb_mc_config_id_t;

        int hb_mc_config_init(const hb_mc_config_raw_t mc[HB_MC_CONFIG_MAX], hb_mc_config_t *config);
                
        static inline uint64_t hb_mc_config_id_to_addr(uint64_t addr, hb_mc_config_id_t id)
        {
                return (addr + (id << 2));
        }

        static inline const char *hb_mc_config_id_to_string(hb_mc_config_id_t id)
        {
                static const char *strtab [] = {
                        [HB_MC_CONFIG_VERSION] = "BLADERUNNER HARDWARE VERSION",
                        [HB_MC_CONFIG_TIMESTAMP] = "BLADERUNNER COMPILATION DATE TIMESTAMP",
                        [HB_MC_CONFIG_NETWORK_ADDR_WIDTH] = "BLADERUNNER NETWORK ADDRESS WDITH",
                        [HB_MC_CONFIG_NETWORK_DATA_WIDTH] = "BLADERUNNER NETWORK DATA WIDTH",
                        [HB_MC_CONFIG_DEVICE_DIM_X] = "BLADERUNNER DEVICE DIMENSION X",
                        [HB_MC_CONFIG_DEVICE_DIM_Y] = "BLADERUNNER DEVICE DIMENSION Y",
                        [HB_MC_CONFIG_DEVICE_HOST_INTF_COORD_X] = "BLADERUNNER HOST INTERFACE DIMENSION X",
                        [HB_MC_CONFIG_DEVICE_HOST_INTF_COORD_Y] = "BLADERUNNER HOST INTERFACE DIMENSION Y",
                        [HB_MC_CONFIG_NOT_IMPLEMENTED] = "BLADERUNNER NOT IMPLEMENTED",
                        [HB_MC_CONFIG_REPO_BASEJUMP_HASH] = "BLADERUNNER REPO BASEJUMP HASH",
                        [HB_MC_CONFIG_REPO_MANYCORE_HASH] = "BLADERUNNER REPO MANYCORE HASH",
                        [HB_MC_CONFIG_REPO_F1_HASH] = "BLADERUNNER REPO F1 HASH",
                        [HB_MC_CONFIG_VCACHE_WAYS]  = "BLADERUNNER VCACHE WAYS",
                        [HB_MC_CONFIG_VCACHE_SETS]  = "BLADERUNNER VCACHE SETS",
                        [HB_MC_CONFIG_VCACHE_BLOCK_WORDS] = "BLADERUNNER VCACHE BLOCK SIZE IN WORDS",
                        [HB_MC_CONFIG_VCACHE_STRIPE_WORDS] = "BLADERUNNER VCACHE STRIPE SIZE IN WORDS",
                };
                return strtab[id];
        }

        static inline uint8_t hb_mc_config_get_version_major(const hb_mc_config_t *cfg){
                return cfg->design_version.major;
        }

        static inline uint8_t hb_mc_config_get_version_minor(const hb_mc_config_t *cfg){
                return cfg->design_version.minor;
        }

        static inline uint8_t hb_mc_config_get_version_revision(const hb_mc_config_t *cfg){
                return cfg->design_version.revision;
        }

        static inline uint8_t hb_mc_config_get_compilation_month(const hb_mc_config_t *cfg){
                return cfg->timestamp.month;
        }

        static inline uint8_t hb_mc_config_get_compilation_day(const hb_mc_config_t *cfg){
                return cfg->timestamp.day;
        }

        static inline uint16_t hb_mc_config_get_compilation_year(const hb_mc_config_t *cfg){
                return cfg->timestamp.year;
        }

        static inline hb_mc_githash_t hb_mc_config_get_githash_basejump(const hb_mc_config_t *cfg){
                return cfg->basejump;
        }

        static inline hb_mc_githash_t hb_mc_config_get_githash_manycore(const hb_mc_config_t *cfg){
                return cfg->manycore;
        }

        static inline hb_mc_githash_t hb_mc_config_get_githash_f1(const hb_mc_config_t *cfg){
                return cfg->f1;
        }

        /* Device Metadata */
        static inline uint32_t hb_mc_config_get_network_bitwidth_addr(const hb_mc_config_t *cfg){
                return cfg->network_bitwidth_addr;
        }

        static inline uint32_t hb_mc_config_get_network_bitwidth_data(const hb_mc_config_t *cfg){
                return cfg->network_bitwidth_data;
        }

        static inline hb_mc_coordinate_t hb_mc_config_get_host_interface(const hb_mc_config_t *cfg){
                return cfg->host_interface;
        }

        static inline hb_mc_dimension_t hb_mc_config_get_dimension_vcore(const hb_mc_config_t *cfg){
                return cfg->vcore_dimensions;
        }

        static inline hb_mc_idx_t hb_mc_config_get_vcore_base_y(const hb_mc_config_t *cfg){
                return HB_MC_CONFIG_VCORE_BASE_Y; // TODO: These should be defined in the ROM?
        }

        static inline hb_mc_idx_t hb_mc_config_get_vcore_base_x(const hb_mc_config_t *cfg){
                return HB_MC_CONFIG_VCORE_BASE_X; // TODO: These should be defined in the ROM?
        }

        static inline hb_mc_coordinate_t hb_mc_config_get_origin_vcore(const hb_mc_config_t *cfg){
                return hb_mc_coordinate(hb_mc_config_get_vcore_base_x(cfg),
                                        hb_mc_config_get_vcore_base_y(cfg));
        }

        static inline hb_mc_coordinate_t hb_mc_config_get_origin_network(const hb_mc_config_t *cfg){
                return hb_mc_coordinate(0, 0);
        }

        static inline hb_mc_dimension_t hb_mc_config_get_dimension_network(const hb_mc_config_t *cfg){
                hb_mc_dimension_t dim = hb_mc_config_get_dimension_vcore(cfg);
                // The Network has three additional Y rows: An IO Row, and two DRAM/Cache Rows
                return hb_mc_dimension(hb_mc_dimension_get_x(dim), 
                                       hb_mc_dimension_get_y(dim) + 3);
        }

        static inline uint8_t hb_mc_config_get_vcache_bitwidth_tag_addr(const hb_mc_config_t *cfg)
        {
                // At the moment, the high-order bit in the network is used to address
                // tags in the Victim Cache. All other bits are used for data
                return 1;
        }

        static inline uint32_t hb_mc_config_get_vcache_bitwidth_data_addr(const hb_mc_config_t *cfg)
        {
                // All network address bits are routed to the victim caches. Some
                // high-order bits of the network address are reserved for addressing
                // tags in the victim cache and are not accessible for data accesses, so
                // we subtract them. The network address is also a word address, so we
                // add two bits to make it a byte address.
                return hb_mc_config_get_network_bitwidth_addr(cfg) -
                        hb_mc_config_get_vcache_bitwidth_tag_addr(cfg) +
                        log2(sizeof(uint32_t));
        }

	static inline size_t hb_mc_config_get_dram_bank_size(const hb_mc_config_t *cfg)
	{
		return cfg->dram_bank_size_words << 2;
	}

        /* Returns the size of DRAM accessible to each manycore tile */
        static inline size_t hb_mc_config_get_dram_size(const hb_mc_config_t *cfg)
        {
                hb_mc_idx_t cols;
                uint32_t awidth;
                hb_mc_dimension_t dim = hb_mc_config_get_dimension_network(cfg);
                cols = hb_mc_dimension_get_x(dim);
                return hb_mc_config_get_dram_bank_size(cfg) * cols;
        }

        static inline uint8_t hb_mc_config_get_dmem_bitwidth_addr(const hb_mc_config_t *cfg)
        {
                return 12; // 12 bits, this might be read from ROM
        }

        static inline size_t hb_mc_config_get_dmem_size(const hb_mc_config_t *cfg)
        {
                // 4K: this might be read from ROM if the value ever changes
                return (1 << hb_mc_config_get_dmem_bitwidth_addr(cfg)); 
        }

        static inline uint8_t hb_mc_config_get_icache_bitwidth_addr(const hb_mc_config_t *cfg)
        {
                return 12; // 12 bits, this might be read from ROM
        }

        static inline size_t hb_mc_config_get_icache_size(const hb_mc_config_t *cfg)
        {
                // 4K: this might be read from ROM if the value ever changes
                return (1 << hb_mc_config_get_icache_bitwidth_addr(cfg)); 
        }

        static inline hb_mc_idx_t hb_mc_config_get_dram_y(const hb_mc_config_t *cfg)
        {
                hb_mc_coordinate_t dims;
                dims = hb_mc_config_get_dimension_network(cfg);
                return hb_mc_coordinate_get_y(dims) - 1;
        }

        /**
         * Return the associativity of the victim cache from the configuration.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of ways per set in the victim cache.
         */
        static inline uint32_t hb_mc_config_get_vcache_ways(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_ways;
        }

        /**
         * Return the number of sets in the victim cache from the configuration.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of sets in the manycore victim cache.
         */
        static inline uint32_t hb_mc_config_get_vcache_sets(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_sets;
        }

        /**
         * Return the number of words in a victim cache block.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of words in a victim cache block.
         */
        static inline uint32_t hb_mc_config_get_vcache_block_words(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_block_words;
        }

        /**
         * Return the number of bytes in a victim cache block.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of words in a victim cache block.
         */
        static inline uint32_t hb_mc_config_get_vcache_block_size(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_block_words * sizeof(uint32_t); // words are four bytes
        }

        /**
         * Return the victim cache stripe size in words.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the victim cache stripe size in words.
         */
        static inline uint32_t hb_mc_config_get_vcache_stripe_words(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_stripe_words;
        }

        /**
         * Return the victim cache stripe size in bytes.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the victim cache stripe size in bytes.
         */
        static inline uint32_t hb_mc_config_get_vcache_stripe_size(const hb_mc_config_t *cfg)
        {
                return cfg->vcache_stripe_words * sizeof(uint32_t);
        }

        /**
         * Return the number of bytes in a victim cache block.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of words in a victim cache block.
         */
        static inline uint32_t hb_mc_config_get_vcache_size(const hb_mc_config_t *cfg)
        {
                return hb_mc_config_get_vcache_block_size(cfg) *
                        hb_mc_config_get_vcache_sets(cfg) *
                        hb_mc_config_get_vcache_ways(cfg);
        }

        /**
         * Return the number of DRAM channels in the system.
         * @param[in] cfg A configuration initialized from the manycore ROM.
         * @return the number of DRAM channels in the system.
         */
        static inline uint32_t hb_mc_config_get_dram_channels(const hb_mc_config_t *cfg)
        {
		return cfg->dram_channels;
        }


#ifdef __cplusplus
}
#endif
#endif
