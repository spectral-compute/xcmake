include_guard(GLOBAL)

define_xcmake_target_property(
    CUDA FLAG
    BRIEF_DOCS "Enable CUDA support"
    FULL_DOCS "Enable CUDA support. Note that this does have a few downsides (like no LTO), so use only when necessary."
    DEFAULT OFF
)

# Handy target to hold the CUDA flags. Not actually interface-linked, however, since these flags are only applied to
# cuda translation units (not to whole targets).
add_library(CUDA_FLAGS INTERFACE)

target_compile_options(CUDA_FLAGS INTERFACE
    -Wno-cuda-compat  # Clang is less restrictive when compiling CUDA than NVCC
    -x cuda
)

if(WIN32)
    target_compile_options(CUDA_FLAGS INTERFACE -Wno-unused-command-line-argument) # Don't warn about unused /TP added by cmake
endif()

target_optional_compile_options(CUDA_FLAGS INTERFACE
    -fcuda-short-ptr
)

if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
    find_package(Scale REQUIRED)

    target_compile_options(CUDA_FLAGS INTERFACE
        --cuda-path=$<SHELL_PATH:${SCALE_AMD_TOOLKIT_ROOT_DIR}>
        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )

    message(BOLD_RED "${TARGET}: Found support for CUDA on AMD in ${SCALE_AMD_TOOLKIT_ROOT_DIR}")
elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    find_package(CUDA 8.0 REQUIRED)
    target_link_libraries(CUDA_EFFECTS INTERFACE cudart)

    # Warn about CUDA 9
    if ("${CUDA_VERSION_MAJOR}" EQUAL 9)
        message(WARNING "CUDA 9 has been found to harm performance. Consider upgrading (or downgrading).")
    endif ()

    target_compile_options(CUDA_FLAGS INTERFACE
        --cuda-path=$<SHELL_PATH:${CUDA_TOOLKIT_ROOT_DIR}>

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Pass a bunch of extra useful ptxas flags, provided we have a version of cmake supporting the
    # "Please don't fucking deduplicate my fucking compiler flags" option, which for some
    # reason is what they implemented instead of just *NOT DEDUPLICATING COMPILER OPTIONS?!?!*.
    if (NOT ${CMAKE_VERSION} VERSION_LESS "3.12.0")
        target_compile_options(CUDA_FLAGS INTERFACE
            # Only enable local memory warnings in configurations that aren't expecting them.
            # Bonus points if anyone can work out how to make cmake accept splitting this across multiple lines :/
            $<IF:$<OR:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,none>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,size>,$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,debug>>,,-Xcuda-ptxas --warn-on-local-memory-usage -Xcuda-ptxas --warn-on-spills>

            # Unsafe math optimisations for CUDA that aren't automatically enabled by `-Ofast` in clang.
            $<IF:$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,unsafe>,-fcuda-flush-denormals-to-zero,>

            # Nicer nvdiasm output, larger binary size.
            $<IF:$<BOOL:$<TARGET_PROPERTY:DEBUG_INFO>>,-Xcuda-ptxas --preserve-relocs,>

            # `-O<n>` propagates through clang into ptxas, but there are several ptxas flags that aren't enabled
            # automatically when you pass `-Og` to ptxas.
            $<IF:$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,debug>,-Xcuda-ptxas --return-at-end -Xcuda-ptxas --dont-merge-basicblocks -Xcuda-ptxas --disable-optimizer-constants,>
        )

        if ("${CUDA_VERSION_MAJOR}" GREATER_EQUAL 9)
            target_compile_options(CUDA_FLAGS INTERFACE
                # Unsafe math optimisations for CUDA that aren't automatically enabled by `-Ofast` in clang.
                $<IF:$<STREQUAL:$<TARGET_PROPERTY:OPT_LEVEL>,unsafe>,-Xcuda-ptxas --optimize-float-atomics,>
            )
        endif()
    endif()

    message(BOLD_GREEN "Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")
else()
    target_compile_options(CUDA_FLAGS INTERFACE --cuda-works-better-if-you-enable-gpu-support-in-xcmake) # :D
endif()
