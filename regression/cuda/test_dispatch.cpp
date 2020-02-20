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

#include "test_dispatch.hpp"
#include <sys/stat.h>
#include <bsg_manycore_responder.h>
#include <chrono>
#include <array>

#define ALLOC_NAME "default_allocator"

#define CUDA_CALL(expr)                                                 \
        {                                                               \
                int __r = expr;                                         \
                if (__r != HB_MC_SUCCESS) {                             \
                        bsg_pr_err("'%s' failed: %s\n", #expr, hb_mc_strerror(__r)); \
                        return __r;                                     \
                }                                                       \
        }

/*
  Responder stuff
*/


static hb_mc_request_packet_id_t ids [] = {
        RQST_ID( RQST_ID_ANY_X, RQST_ID_ANY_Y, RQST_ID_ADDR(0xFFF0) ),
        { }
};

std::array<std::chrono::system_clock::time_point, 16> times;

static int respond(hb_mc_responder_t *rsp,
                   hb_mc_manycore_t *mc,
                   const hb_mc_request_packet_t *rqst)
{
        int i = static_cast<int>
                (
                        hb_mc_request_packet_get_x_src(rqst) *
                        4 + (hb_mc_request_packet_get_y_src(rqst)-1)
                );
        
        times[i] = std::chrono::system_clock::now();
        return HB_MC_SUCCESS;
}

static int quit(hb_mc_responder_t *rsp,
                hb_mc_manycore_t *mc)
{
        return HB_MC_SUCCESS;
}

static FILE *data_file = NULL;

int test_loader (int argc, char **argv) {
        char *bin_path, *test_name;
        struct arguments_path args = {NULL, NULL};

        argp_parse (&argp_path, argc, argv, 0, 0, &args);
        bin_path = args.path;
        test_name = args.name;

        srand(time(0));

        /**********************************************************************/
        /* Define path to binary.                                             */
        /* Initialize device, load binary and unfreeze tiles.                 */
        /**********************************************************************/
        hb_mc_device_t device;
        CUDA_CALL(hb_mc_device_init(&device, test_name, 0));
        CUDA_CALL(hb_mc_device_program_init(&device, bin_path, ALLOC_NAME, 0));


        // add a responder
        hb_mc_responder_t responder(test_name, ids, nullptr, quit, respond);
        CUDA_CALL(hb_mc_responder_add(&responder));

        // if file does not exist
        struct stat st;
        if (stat("test_dispatch.csv", &st) != 0) {
                data_file = fopen("test_dispatch.csv", "w");
                fprintf(data_file, "x,y,dispatch_seconds\n");
        } else {        
                data_file = fopen("test_dispatch.csv", "a+");
        }

        /**********************************************************************/
        /* Define block_size_x/y: amount of work for each tile group          */
        /* Define tg_dim_x/y: number of tiles in each tile group              */
        /* Calculate grid_dim_x/y: number of                                  */
        /* tile groups needed based on block_size_x/y                         */
        /**********************************************************************/
        const hb_mc_config_t *cfg =
                hb_mc_manycore_get_config(device.mc);

        hb_mc_dimension_t vcore =
                hb_mc_config_get_dimension_vcore(cfg);
        
        hb_mc_dimension_t tg_dim = { .x = vcore.x, .y = vcore.y }; 
        hb_mc_dimension_t grid_dim = { .x = 1, .y = 1 };

        bsg_pr_test_info("Running the CUDA Unified Main %s "
                         "on a grid of %dx%d tile groups\n\n",
                         test_name, vcore.x, vcore.y);

        /****************************************/
        /* Allocate a word for the return value */
        /****************************************/
        hb_mc_eva_t raddr;
        CUDA_CALL(hb_mc_device_malloc(&device, sizeof(uint32_t), &raddr));
        CUDA_CALL(hb_mc_device_memset(&device, &raddr, 0, sizeof(uint32_t)));

        /**********************************************************************/
        /* Prepare list of input arguments for kernel.                        */
        /**********************************************************************/
        uint32_t kernel_argv[] = {raddr};

        char kernel_name[256];
        snprintf(kernel_name, sizeof(kernel_name), "kernel_%s", test_name + sizeof("test_") - 1);
        /**********************************************************************/
        /* Enquque grid of tile groups, pass in grid and tile group dimensions*/
        /* kernel name, number and list of input arguments                    */
        /**********************************************************************/
        CUDA_CALL(hb_mc_kernel_enqueue (&device, grid_dim, tg_dim, kernel_name, 1, kernel_argv));


        /**********************************************************************/
        /* Launch and execute all tile groups on device and wait for finish.  */ 
        /**********************************************************************/
        std::chrono::system_clock::time_point start =
                std::chrono::system_clock::now();
        
        CUDA_CALL(hb_mc_device_tile_groups_execute(&device));

        for (int x = 0; x < 4; x++) {
                for (int y = 0; y< 4; y++) {
                        auto & end  = times[x * 4 + y];
                        std::chrono::duration<double> diff = end - start;                
                        bsg_pr_info("core (%d,%d) response time: %1.10f seconds\n", x, y, diff.count());
                        fprintf(data_file, "%d,%d,%1.10f\n", x, y, diff.count());
                }
        }

        fclose(data_file);
        
        std::chrono::system_clock::time_point end =
                std::chrono::system_clock::now();

        std::chrono::duration<double> diff = end-start;
        bsg_pr_info("job completion: %f seconds\n", diff.count());
        
        /*************************/
        /* Read the return value */
        /*************************/
        uint32_t rcode;
        CUDA_CALL(hb_mc_device_memcpy(&device, &rcode, (const void*)raddr, sizeof(rcode),
                                      HB_MC_MEMCPY_TO_HOST));

        /**********************************************************************/
        /* Freeze the tiles and memory manager cleanup.                       */
        /**********************************************************************/
        CUDA_CALL(hb_mc_device_finish(&device));
        
        /*************************/
        /* Check the return code */
        /*************************/
        if (rcode != 0) {
                bsg_pr_err("kernel returned non-zero.\n");
                return HB_MC_FAIL;
        }

        return HB_MC_SUCCESS;
}

#ifdef COSIM
void cosim_main(uint32_t *exit_code, char * args) {
        // We aren't passed command line arguments directly so we parse them
        // from *args. args is a string from VCS - to pass a string of arguments
        // to args, pass c_args to VCS as follows: +c_args="<space separated
        // list of args>"
        int argc = get_argc(args);
        char *argv[argc];
        get_argv(args, argc, argv);

#ifdef VCS
        svScope scope;
        scope = svGetScopeFromName("tb");
        svSetScope(scope);
#endif
        bsg_pr_test_info("Unified Main Regression Test (COSIMULATION)\n");
        int rc = test_loader(argc, argv);
        *exit_code = rc;
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return;
}
#else
int main(int argc, char ** argv) {
        bsg_pr_test_info("Unified Main CUDA Regression Test (F1)\n");
        int rc = test_loader(argc, argv);
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return rc;
}
#endif

