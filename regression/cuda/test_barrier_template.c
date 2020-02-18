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

/******************************************************************************/
/* Runs the new template barrier on a single grid of 2x2 tile group           */
/* This tests uses the software/spmd/bsg_cuda_lite_runtime/barrier_template/  */
/* manycore binary in the BSG Manycore repository.                            */
/******************************************************************************/


#include "test_barrier_template.h"

#define ALLOC_NAME "default_allocator"



int kernel_barrier_template (int argc, char **argv) {
        int rc;
        char *bin_path, *test_name;
        struct arguments_path args = {NULL, NULL};

        argp_parse (&argp_path, argc, argv, 0, 0, &args);
        bin_path = args.path;
        test_name = args.name;

        bsg_pr_test_info("Running the CUDA Barrier Template "
                         "Kernel on a 1x1 grid of 2x2 tile group.\n\n");

        srand(time(NULL)); 


        /**********************************************************************/
        /* Define path to binary.                                             */
        /* Initialize device, load binary and unfreeze tiles.                 */
        /**********************************************************************/
        hb_mc_device_t device;
        hb_mc_dimension_t device_dim = {.x = 2, .y = 2};
        rc = hb_mc_device_init_custom_dimensions(&device, test_name, 0, device_dim);
        if (rc != HB_MC_SUCCESS) { 
                bsg_pr_err("failed to initialize device.\n");
                return rc;
        }


        rc = hb_mc_device_program_init(&device, bin_path, ALLOC_NAME, 0);
        if (rc != HB_MC_SUCCESS) { 
                bsg_pr_err("failed to initialize program.\n");
                return rc;
        }




        /**********************************************************************/
        /* Define tg_dim_x/y: number of tiles in each tile group              */
        /* Calculate grid_dim_x/y: number of                                  */
        /* tile groups needed based on block_size_x/y                         */
        /**********************************************************************/

        hb_mc_dimension_t tg_dim = { .x = 2, .y = 2}; 

        hb_mc_dimension_t grid_dim = { .x = 1, .y = 1}; 


        /**********************************************************************/
        /* Prepare list of input arguments for kernel.                        */
        /**********************************************************************/
        int cuda_argv[1] = {};

        
        /**********************************************************************/
        /* Enquque grid of tile groups, pass in grid and tile group dimensions*/
        /* kernel name, number and list of input arguments                    */
        /**********************************************************************/
        rc = hb_mc_kernel_enqueue (&device, grid_dim, tg_dim, "kernel_barrier_template", 0, cuda_argv);
        if (rc != HB_MC_SUCCESS) { 
                bsg_pr_err("failed to initialize grid.\n");
                return rc;
        }


        /**********************************************************************/
        /* Launch and execute all tile groups on device and wait for finish.  */ 
        /**********************************************************************/
        rc = hb_mc_device_tile_groups_execute(&device);
        if (rc != HB_MC_SUCCESS) { 
                bsg_pr_err("failed to execute tile groups.\n");
                return rc;
        }



        /**********************************************************************/
        /* Freeze the tiles and memory manager cleanup.                       */
        /**********************************************************************/
        rc = hb_mc_device_finish(&device); 
        if (rc != HB_MC_SUCCESS) { 
                bsg_pr_err("failed to de-initialize device.\n");
                return rc;
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
        bsg_pr_test_info("test_barrier_template Regression Test (COSIMULATION)\n");
        int rc = kernel_barrier_template(argc, argv);
        *exit_code = rc;
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return;
}
#else
int main(int argc, char ** argv) {
        bsg_pr_test_info("test_barrier_template Regression Test (F1)\n");
        int rc = kernel_barrier_template(argc, argv);
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return rc;
}
#endif

