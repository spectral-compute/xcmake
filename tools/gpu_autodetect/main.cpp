#include <stdio.h>
#include <cuda_runtime.h>

#define HANDLE_CUDA_ERROR(E) {\
    cudaError_t error = (E); \
    if (error != cudaSuccess) { \
        printf("CUDA runtime error encountered trying to autodetect GPU architecture:\n    %s: %s\n", cudaGetErrorName(error), cudaGetErrorString(error)); \
        return error; \
    } \
}

int main() {
    int count;
    cudaDeviceProp prop;

    HANDLE_CUDA_ERROR(cudaGetDeviceCount(&count));
    printf("%i;", count);

    for (int i = 0; i < count; i++) {
        HANDLE_CUDA_ERROR(cudaGetDeviceProperties(&prop, i));
        printf("sm_%d;", prop.major * 10 + prop.minor);
    }

    return 0;
}
