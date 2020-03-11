#include "test_read_latency.hpp"
#include "bsg_manycore_tile.h"
#include <chrono>
#include <cstdio>
#include <sys/stat.h>

using namespace std;

#define CUDA_CALL(expr)                                                 \
    {                                                                   \
        int __r;                                                        \
        if ((__r = expr) != HB_MC_SUCCESS) {                            \
            bsg_pr_err("%s failed: %s\n", #expr, hb_mc_strerror(__r));  \
            return __r;                                                 \
        }                                                               \
    }

#define array_size(x)                           \
    (sizeof(x)/sizeof(x[0]))

static hb_mc_manycore_t manycore = {}, *mc = &manycore;
static FILE *data_file = stdout;

static int measure_read_latency_of(hb_mc_npa_t addr)
{
    auto start = chrono::system_clock::now();

    uint32_t data;
    CUDA_CALL(hb_mc_manycore_read32(mc, &addr, &data));    
    
    auto end   = chrono::system_clock::now();
    chrono::duration<double> diff = end - start;
    
    char addrstr [256];    
    fprintf(data_file, "%u,%u,%llu,%1.10f\n",
            addr.x,
            addr.y,
            addr.epa,
            diff.count());
    
    return HB_MC_SUCCESS;
}

static int warm_up()
{
    uint32_t data;
    hb_mc_npa_t addr = hb_mc_npa_from_x_y(0, 1, HB_MC_TILE_EPA_DMEM_BASE);

    for (int i = 0; i < 100; i++) {
        auto start = chrono::system_clock::now();            
        CUDA_CALL(hb_mc_manycore_read32(mc, &addr, &data));
    }

    return HB_MC_SUCCESS;
}

static void init_data_file()
{
    static char data_file_name [] = "read_latency.csv";
    struct stat st;

    if (stat(data_file_name, &st) != 0) {
        data_file = fopen(data_file_name, "w");
        fprintf(data_file, "x,y,addr,read_latency_seconds\n");
    } else {
        data_file = fopen(data_file_name, "a+");
    }
}

static int
test(int argc, char *argv[])
{
    
    hb_mc_npa_t addresses [5]; 

    addresses[0] = hb_mc_npa_from_x_y(0, 1, HB_MC_TILE_EPA_DMEM_BASE);
    addresses[1] = hb_mc_npa_from_x_y(0, 4, HB_MC_TILE_EPA_DMEM_BASE);
    addresses[2] = hb_mc_npa_from_x_y(3, 4, HB_MC_TILE_EPA_DMEM_BASE);
    addresses[3] = hb_mc_npa_from_x_y(0, 5, 0);
    addresses[4] = hb_mc_npa_from_x_y(1, 5, 0);

    init_data_file();
    
    CUDA_CALL(hb_mc_manycore_init(mc, "latency", 0));
    CUDA_CALL(warm_up());

    for (size_t i = 0; i < array_size(addresses); i++)
        CUDA_CALL(measure_read_latency_of(addresses[i]));
    
    CUDA_CALL(hb_mc_manycore_exit(mc));
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
        bsg_pr_test_info("test_unified_main Regression Test (COSIMULATION)\n");
        int rc = test(argc, argv);
        *exit_code = rc;
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return;
}
#else
int main(int argc, char ** argv) {
        bsg_pr_test_info("test_unified_main Regression Test (F1)\n");
        int rc = test(argc, argv);
        bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
        return rc;
}
#endif

