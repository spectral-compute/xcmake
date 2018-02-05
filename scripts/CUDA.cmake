include(ArgHandle)

# Set up an NVIDIA CUDA target.
function(configure_for_nvidia TARGET)
    find_package(CUDA 8.0 REQUIRED)

    # This disables cmake's built-in CUDA support, which only does NVCC. This stops
    # cmake doing automatic things that derail our attempts to do this properly...
    set_source_files_properties(${ARGN} PROPERTIES LANGUAGE CXX)

    # Compiler flags for cuda compilation on clang.
    target_compile_options(${TARGET} PRIVATE
        -x cuda
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}
        -fcuda-flush-denormals-to-zero

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Add the cuda runtime library.
    target_include_directories(${TARGET} SYSTEM PUBLIC ${CUDA_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PUBLIC ${CUDA_LIBRARIES})
endfunction()

# Set up an AMD CUDA target.
function(configure_for_amd TARGET)
    find_package(Scale REQUIRED)

    # This disables cmake's built-in CUDA support, which only does NVCC. This stops
    # cmake doing automatic things that derail our attempts to do this properly...
    set_source_files_properties(${ARGN} PROPERTIES LANGUAGE CXX)

    # Compiler flags for cuda compilation on clang.
    target_compile_options(${TARGET} PRIVATE
        -x cuda
        --cuda-path=${SCALE_AMD_TOOLKIT_ROOT_DIR}

        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )

    # Add the cuda runtime library.
    target_link_libraries(${TARGET} PRIVATE Scale::AMD)
endfunction()

# Add an executable that uses CUDA.
function(add_cuda_executable TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST WIN32)
    remove_argument(FLAG SRC_LIST MACOSX_BUNDLE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    if ("${TARGET_GPU_TYPE}" STREQUAL "AMD")
        # Remove all the source files to get the flag list...
        list(REMOVE_ITEM ARGN ${SRC_LIST})

        add_executable(${TARGET} ${ARGN})
        configure_for_amd(${TARGET} ${SRC_LIST})
    elseif("${TARGET_GPU_TYPE}" STREQUAL "NVIDIA")
        add_executable(${TARGET} ${ARGN})
        configure_for_nvidia(${TARGET} ${SRC_LIST})
    elseif("${TARGET_GPU_TYPE}" STREQUAL "")
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS!")
    else()
        message(FATAL_ERROR "Unknown GPU type: ${TARGET_GPU_TYPE}")
    endif()
endfunction()

# Add a library that uses CUDA.
function(add_cuda_library TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST STATIC)
    remove_argument(FLAG SRC_LIST SHARED)
    remove_argument(FLAG SRC_LIST MODULE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    if ("${TARGET_GPU_TYPE}" STREQUAL "AMD")
        add_library(${TARGET} ${ARGN})
        configure_for_amd(${TARGET} ${SRC_LIST})
    elseif ("${TARGET_GPU_TYPE}" STREQUAL "NVIDIA")
        add_library(${TARGET} ${ARGN})
        configure_for_nvidia(${TARGET} ${SRC_LIST})
    elseif ("${TARGET_GPU_TYPE}" STREQUAL "")
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS!")
    else ()
        message(FATAL_ERROR "Unknown GPU type: ${TARGET_GPU_TYPE}")
    endif ()
endfunction()
