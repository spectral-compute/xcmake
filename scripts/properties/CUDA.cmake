define_xcmake_target_property(
    CUDA FLAG
    BRIEF_DOCS "Enable CUDA support"
    FULL_DOCS "Note that this does have a few downsides (like no LTO), so use only when necessary."
    DEFAULT OFF
)

target_compile_options(CUDA_EFFECTS INTERFACE
    -Wno-cuda-compat  # Clang is less restrictive when compiling CUDA than NVCC
    -x cuda
)

if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
    find_package(Scale REQUIRED)

    target_compile_options(CUDA_EFFECTS INTERFACE
        --cuda-path=${SCALE_AMD_TOOLKIT_ROOT_DIR}
        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )
    target_link_libraries(CUDA_EFFECTS INTERFACE Scale::AMD)

    message_colour(STATUS BoldRed "${TARGET}: Found support for CUDA on AMD in ${SCALE_AMD_TOOLKIT_ROOT_DIR}")
elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    # Find only the shared library versions of NVIDIA CUDA.
#    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
    find_package(CUDA 8.0 REQUIRED)

    # Forbid CUDA 9, because it causes all kinda of nasty breakage.
    if ("${CUDA_VERSION_MAJOR}" GREATER 8)
        message(FATAL_ERROR "CUDA 9 harms performance and is therefore not supported. Please use CUDA 8")
    endif ()

    target_compile_options(CUDA_EFFECTS INTERFACE
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Get PTXAS to be less unhelpful, provided we have a version of cmake supporting the
    # "Please don't fucking deduplicate my fucking compiler flags" option, which for some
    # reason is what they implemented instead of just *NOT DEDUPLICATING COMPILER OPTIONS?!?!*.
    if (NOT ${CMAKE_VERSION} VERSION_LESS "3.12.0")
        target_compile_options(CUDA_EFFECTS INTERFACE
            "SHELL:-Xcuda-ptxas --warn-on-spills"

            # Assertions imply local memory usage, so don't enable this warning when assertions are turned on.
            $<IF:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,,SHELL:-Xcuda-ptxas --warn-on-local-memory-usage>
        )
    endif()

    # Add the cuda runtime library.
    target_include_directories(CUDA_EFFECTS SYSTEM INTERFACE ${CUDA_INCLUDE_DIRS})
    target_link_libraries(CUDA_EFFECTS INTERFACE ${CUDA_LIBRARIES})
        message_colour(STATUS BoldRed "${CUDA_LIBRARIES}")
        message_colour(STATUS BoldRed "${CUDA_CUBLAS_LIBRARIES}")

    message_colour(STATUS BoldGreen "Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")
endif()
