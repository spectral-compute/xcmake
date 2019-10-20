#include <stdio.h>
#include <cuda_runtime.h>

#define HANDLE_CUDA_ERROR(E) \
    cudaError_t error = (E); \
    if (error != cudaSuccess) { \
        printf("Error %i trying to autodetect GPU architecture.\n", error); \
        return error; \
    }

int main() {
    int count;
    cudaDeviceProp prop;

    HANDLE_CUDA_ERROR(cudaGetDeviceCount(&count));
    if (count > 0) {
        HANDLE_CUDA_ERROR(cudaGetDeviceProperties(&prop, 0));
    }

    printf("%i", count);

    if (count > 0) {
        printf("sm_%d", prop.major * 10 + prop.minor);
    }

    return 0;
}
