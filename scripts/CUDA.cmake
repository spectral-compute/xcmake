include(ArgHandle)

# The compute capabilities to target, as a cmake list.
default_value(CUDA_COMPUTE_CAPABILITIES "30")

# Configure a library or executable target for CUDA, given the list of CUDA source files
# it has. (it may have other, non-cuda source files...)
function(configure_for_cuda TARGET)
    # This disables cmake's built-in CUDA support, which only does NVCC. This stops
    # cmake doing automatic things that derail our attempts to do this properly...
    set_source_files_properties(${ARGN} PROPERTIES LANGUAGE CXX)

    # Compiler flags for cuda compilation on clang.
    target_compile_options(${TARGET} PRIVATE
        -x cuda
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}
        -fcuda-flush-denormals-to-zero

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Add the cuda runtime library.
    find_package(CUDA 8.0 REQUIRED)
    target_include_directories(${TARGET} PRIVATE ${CUDA_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PRIVATE ${CUDA_LIBRARIES})
endfunction()


# Add an executable that uses CUDA.
function(add_cuda_executable TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST WIN32)
    remove_argument(FLAG SRC_LIST MACOSX_BUNDLE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    add_executable(${TARGET} ${ARGN})

    configure_for_cuda(${TARGET} ${SRC_LIST})
endfunction()

# Add a library that uses CUDA.
function(add_cuda_library TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST STATIC)
    remove_argument(FLAG SRC_LIST SHARED)
    remove_argument(FLAG SRC_LIST MODULE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    add_library(${TARGET} ${ARGN})

    configure_for_cuda(${TARGET} ${SRC_LIST})
endfunction()
