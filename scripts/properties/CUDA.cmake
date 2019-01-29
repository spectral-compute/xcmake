include_guard(GLOBAL)

define_xcmake_target_property(
    CUDA
    BRIEF_DOCS "Enable CUDA support"
    FULL_DOCS "Note that this does have a few downsides (like no LTO), so use only when necessary."
    DEFAULT OFF
)

add_library(CUDA_COMPILE_EFFECTS INTERFACE)

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
    find_package(Scale REQUIRED)

    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
        --cuda-path=$<SHELL_PATH:${SCALE_AMD_TOOLKIT_ROOT_DIR}>
        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )

    target_link_libraries(CUDA_COMPILE_EFFECTS INTERFACE Scale::AMD)
    set(CUDA_LIBRARY Scale::AMD)

    message_colour(STATUS BoldRed "${TARGET}: Found support for CUDA on AMD in ${SCALE_AMD_TOOLKIT_ROOT_DIR}")
elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    find_package(CUDA 8.0 REQUIRED)
    add_library(cuda_library INTERFACE)
    set(CUDA_LIBRARY cuda_library)

    # Forbid CUDA 9, because it causes all kinda of nasty breakage.
    if ("${CUDA_VERSION_MAJOR}" EQUAL 9)
        message(FATAL_ERROR "CUDA 9 harms performance and is therefore not supported. Please use CUDA 8 or 10")
    endif ()

    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
        --cuda-path=$<SHELL_PATH:${CUDA_TOOLKIT_ROOT_DIR}>

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Get PTXAS to be less unhelpful, provided we have a version of cmake supporting the
    # "Please don't fucking deduplicate my fucking compiler flags" option, which for some
    # reason is what they implemented instead of just *NOT DEDUPLICATING COMPILER OPTIONS?!?!*.
    if (NOT ${CMAKE_VERSION} VERSION_LESS "3.12.0")
        list(APPEND XCMAKE_CUDA_COMPILE_FLAGS
            -Xcuda-ptxas --warn-on-spills

            # Assertions imply local memory usage, so don't enable this warning when assertions are turned on.
            $<IF:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,,-Xcuda-ptxas --warn-on-local-memory-usage>
        )
    endif()

    # Add the cuda runtime library.
    target_include_directories(cuda_library SYSTEM INTERFACE $<SHELL_PATH:${CUDA_INCLUDE_DIRS}>)
    target_link_libraries(cuda_library INTERFACE ${CUDA_LIBRARIES})

    message_colour(STATUS BoldGreen "Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")
else()
    list(APPEND XCMAKE_CUDA_COMPILE_FLAGS --cuda-works-better-if-you-enable-gpu-support-in-xcmake) # :D
endif()

function(CUDA_EFFECTS TARGET)
    link_if_property_set(${TARGET} CUDA PRIVATE CUDA_COMPILE_EFFECTS)
    link_if_property_set(${TARGET} CUDA PUBLIC ${CUDA_LIBRARY})
endfunction()
