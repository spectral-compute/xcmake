define_xcmake_target_property(
    CUDA_TOOL_EXT FLAG
    BRIEF_DOCS "Enable CUDA tooling extensions"
    FULL_DOCS "On NVIDIA this adds NVTX. On AMD, it adds placebo-NVTX :D"
    DEFAULT OFF
)

target_compile_options(CUDA_COMPILE_EFFECTS INTERFACE
    -Wno-cuda-compat  # Clang is less restrictive when compiling CUDA than NVCC
    -x cuda
)

if ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    find_package(CUDA 8.0 REQUIRED)
    find_library(CUDA_NVTX_LIBRARY
        NAMES nvToolsExt nvTools nvtoolsext nvtools nvtx NVTX
        PATHS ${CUDA_TOOLKIT_ROOT_DIR}
        PATH_SUFFIXES "lib64" "common/lib64" "common/lib" "lib"
        DOC "Location of the CUDA Toolkit Extension (NVTX) library"
        NO_DEFAULT_PATH
    )
    mark_as_advanced(CUDA_NVTX_LIBRARY)

    target_include_directories(CUDA_TOOL_EXT_EFFECTS SYSTEM INTERFACE ${CUDA_INCLUDE_DIRS})
    target_link_libraries(CUDA_TOOL_EXT_EFFECTS INTERFACE ${CUDA_NVTX_LIBRARY})
endif()
