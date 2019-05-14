#include "test_vec_add_parallel.h"

/*!
 * Runs the addition kernel on 4 2x2 tile groups in parallel in a 4x4 grid. 
 * This tests uses the software/spmd/bsg_cuda_lite_runtime/vec_add_parallel/ Manycore binary in the dev_cuda_v4 branch of the BSG Manycore bitbucket repository.  
*/
int kernel_vec_add_parallel () {
	fprintf(stderr, "Running the CUDA Parallel Vector Addition Kernel on 4 2x2 tile groups.\n\n");

	device_t device;
	uint8_t mesh_dim_x = 4;
	uint8_t mesh_dim_y = 4;
	uint8_t mesh_origin_x = 0;
	uint8_t mesh_origin_y = 1;
	eva_id_t eva_id = 0;

	// Load the binary
	char* elf = BSG_STRINGIFY(BSG_MANYCORE_DIR) "/software/spmd/bsg_cuda_lite_runtime" "/vec_add_parallel/main.riscv";

	hb_mc_device_init(&device, eva_id, elf, mesh_dim_x, mesh_dim_y, mesh_origin_x, mesh_origin_y);

	// Allocate input and output buffers on the manycore
	uint32_t size_buffer = 256; 
	eva_t A_device, B_device, C_device; 
	hb_mc_device_malloc(&device, size_buffer * sizeof(uint32_t), &A_device); /* allocate A on the device */
	hb_mc_device_malloc(&device, size_buffer * sizeof(uint32_t), &B_device); /* allocate B on the device */
	hb_mc_device_malloc(&device, size_buffer * sizeof(uint32_t), &C_device); /* allocate C on the device */

	// Allocate and initialize local buffers on host for input
	uint32_t A_host[size_buffer]; /* allocate A on the host */ 
	uint32_t B_host[size_buffer]; /* allocate B on the host */
	srand(0);
	for (int i = 0; i < size_buffer; i++) { /* fill A and B with arbitrary data */
		A_host[i] = rand() & 0xFFFF; 
		B_host[i] = rand() & 0xFFFF; 
	}

	// Copy the data from host to the device
	void *dst = (void *) ((intptr_t) A_device);
	void *src = (void *) &A_host[0];
	hb_mc_device_memcpy (&device, dst, src, size_buffer * sizeof(uint32_t), hb_mc_memcpy_to_device); /* Copy A1 to the device  */	
	dst = (void *) ((intptr_t) B_device);
	src = (void *) &B_host[0];
	hb_mc_device_memcpy (&device, dst, src, size_buffer * sizeof(uint32_t), hb_mc_memcpy_to_device); /* Copy B2 to the device */ 

	// Execute grid of tile groups on manycore
	// 1. Define grid and tile group dimensions
	// 2. Initialize arguments for the kernel
	// 3. Initialize grid of tile groups 
	// 4. Schedule tile groups onto tile pool until all tile groups have executed
	uint8_t grid_dim_x = 4;
	uint8_t grid_dim_y = 1;
	uint8_t tg_dim_x = 2;
	uint8_t tg_dim_y = 2;

	int argv[4] = {A_device, B_device, C_device, size_buffer};

	hb_mc_grid_init (&device, grid_dim_x, grid_dim_y, tg_dim_x, tg_dim_y, "kernel_vec_add", 4, argv);

	hb_mc_device_tile_groups_execute(&device);
	
	// Copy output from manycore to host and compare results 
	uint32_t C_host[size_buffer];
	src = (void *) ((intptr_t) C_device);
	dst = (void *) &C_host[0];
	hb_mc_device_memcpy (&device, (void *) dst, src, size_buffer * sizeof(uint32_t), hb_mc_memcpy_to_host); /* copy C to the host */


	int mismatch = 0; 
	for (int i = 0; i < size_buffer; i++) {
		if (A_host[i] + B_host[i] == C_host[i]) {
			fprintf(stderr, "Success -- A[%d] + B[%d] =  0x%x + 0x%x = 0x%x\n", i, i , A_host[i], B_host[i], C_host[i]);
		}
		else {
			fprintf(stderr, "Failed -- A[%d] + B[%d] =  0x%x + 0x%x != 0x%x\n", i, i , A_host[i], B_host[i], C_host[i]);
			mismatch = 1;
		}
	}	

	// Close manycore device 
	hb_mc_device_finish(&device); 
	

	if (mismatch)
		return HB_MC_FAIL;
	return HB_MC_SUCCESS;
}

#ifdef COSIM
void test_main(uint32_t *exit_code) {	
	bsg_pr_test_info("test_vec_add_parallel Regression Test (COSIMULATION)\n");
	int rc = kernel_vec_add_parallel();
	*exit_code = rc;
	bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
	return;
}
#else
int main() {
	bsg_pr_test_info("test_vec_add_parallel Regression Test (F1)\n");
	int rc = kernel_vec_add_parallel();
	bsg_pr_test_pass_fail(rc == HB_MC_SUCCESS);
	return rc;
}
#endif

