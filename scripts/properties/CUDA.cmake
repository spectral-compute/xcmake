include_guard(GLOBAL)

define_xcmake_target_property(
    CUDA
    BRIEF_DOCS "Enable CUDA support"
    FULL_DOCS "Enable CUDA support. Note that this does have a few downsides (like no LTO), so use only when necessary."
    DEFAULT OFF
)
add_library(CUDA_EFFECTS INTERFACE)

set(XCMAKE_CUDA_COMPILE_FLAGS "")
list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
    -Wno-cuda-compat  # Clang is less restrictive when compiling CUDA than NVCC
    -x cuda
)

if (NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.0)
    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
        -fcuda-short-ptr
    )
endif()

if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
    find_package(AmdCuda REQUIRED)

    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
        --cuda-path=$<SHELL_PATH:${AMDCUDA_TOOLKIT_ROOT_DIR}>
        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )
    target_link_libraries(CUDA_EFFECTS INTERFACE AmdCuda::amdcuda)

    message_colour(STATUS BoldRed "Using AMD CUDA from ${AMDCUDA_TOOLKIT_ROOT_DIR}")
elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    find_package(CUDA 8.0 REQUIRED)
    target_link_libraries(CUDA_EFFECTS INTERFACE cudart)

    # Warn about CUDA 9
    if ("${CUDA_VERSION_MAJOR}" EQUAL 9)
        message(WARNING "CUDA 9 has been found to harm performance. Consider upgrading (or downgrading).")
    endif ()

    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
        --cuda-path=$<SHELL_PATH:${CUDA_TOOLKIT_ROOT_DIR}>

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Pass a bunch of extra useful ptxas flags, provided we have a version of cmake supporting the
    # "Please don't fucking deduplicate my fucking compiler flags" option, which for some
    # reason is what they implemented instead of just *NOT DEDUPLICATING COMPILER OPTIONS?!?!*.
    if (NOT ${CMAKE_VERSION} VERSION_LESS "3.12.0")
        list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
            # Only enable local memory warnings in configurations that aren't expecting them.
            # Bonus points if anyone can work out how to make cmake accept splitting this across multiple lines :/
            $<IF:$<OR:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,none>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,size>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,debug>>,,-Xcuda-ptxas --warn-on-local-memory-usage -Xcuda-ptxas --warn-on-spills>

            # Unsafe math optimisations for CUDA that aren't automatically enabled by `-Ofast` in clang.
            $<IF:$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,unsafe>,-fcuda-flush-denormals-to-zero -Xcuda-ptxas --optimize-float-atomics,>

            # `-O<n>` propagates through clang into ptxas, but there are several ptxas flags that aren't enabled
            # automatically when you pass `-Og` to ptxas.
            $<IF:$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,debug>,-Xcuda-ptxas --return-at-end -Xcuda-ptxas --dont-merge-basicblocks -Xcuda-ptxas --disable-optimizer-constants,>
        )
    endif()

    message_colour(STATUS BoldGreen "Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")
else()
    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS --cuda-works-better-if-you-enable-gpu-support-in-xcmake) # :D
endif()
