#include "test_write_bandwidth.hpp"
#include "bsg_manycore_tile.h"
#include <chrono>
#include <cstdio>
#include <vector>
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

static int measure_write_bandwidth_of(hb_mc_npa_t addr, size_t sz)
{
    std::vector<char> data(sz, -1);
    
    auto start = chrono::system_clock::now();
        
    CUDA_CALL(hb_mc_manycore_write_mem(mc, &addr, &data[0], data.size()));
              
    auto end   = chrono::system_clock::now();
    chrono::duration<double> diff = end - start;
    
    fprintf(data_file, "%u,%u,%llu,%zu,%1.10f,%1.10f\n",
            addr.x,
            addr.y,
            addr.epa,
            data.size(),
            diff.count(),
            data.size()/diff.count());
    
    return HB_MC_SUCCESS;
}

static int warm_up()
{
    hb_mc_npa_t addr = hb_mc_npa_from_x_y(0, 1, HB_MC_TILE_EPA_DMEM_BASE);
    std::vector<char> data(4 << 10, -1);
    
    for (int i = 0; i < 100; i++) {
        auto start = chrono::system_clock::now();            
        CUDA_CALL(hb_mc_manycore_write_mem(mc, &addr, &data[0], data.size()));
    }

    return HB_MC_SUCCESS;
}

static void init_data_file()
{
    static char data_file_name [] = "write_bandwidth.csv";
    struct stat st;

    if (stat(data_file_name, &st) != 0) {
        data_file = fopen(data_file_name, "w");
        fprintf(data_file, "x,y,addr,bytes,seconds,bandwidth\n");
    } else {
        data_file = fopen(data_file_name, "a+");
    }
}

static int
test(int argc, char *argv[])
{
    std::vector<hb_mc_npa_t> addresses;
    std::vector<size_t> sizes;

    for (int x = 0; x < 4; x++)
        for (int y = 1; y < 5; y++) {
            addresses.push_back(hb_mc_npa_from_x_y(x, y, HB_MC_TILE_EPA_DMEM_BASE));
            sizes.push_back(4 << 10);
        }

    for (int x = 0; x < 4; x++) {
        addresses.push_back(hb_mc_npa_from_x_y(x, 5, HB_MC_TILE_EPA_DMEM_BASE));
        sizes.push_back(32 << 10);
    }
    
    init_data_file();
    
    CUDA_CALL(hb_mc_manycore_init(mc, "write bw", 0));
    CUDA_CALL(warm_up());

    for (size_t i = 0; i < addresses.size(); i++)
        CUDA_CALL(measure_write_bandwidth_of(addresses[i], sizes[i]));
    
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

