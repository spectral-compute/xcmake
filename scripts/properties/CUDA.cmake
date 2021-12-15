include_guard(GLOBAL)

# This creates the `CUDA_EFFECTS` library target
define_xcmake_target_property(
    CUDA FLAG
    BRIEF_DOCS "Enable CUDA support"
    FULL_DOCS
        "Enable CUDA support. This should be enabled only when necessary, since it has a few side effects: slower compilation "
        "(even if there's no CUDA code), no LTO, hindered linker optimisation on Windows, and no incremental linking on Windows"
    DEFAULT OFF
)

if (DEFINED ENV{CLION_IDE})
    target_compile_options(CUDA_EFFECTS INTERFACE -x cuda)
endif ()

# Handy target to hold the CUDA flags. Not actually interface-linked, however, since these flags are only applied to
# cuda translation units (not to whole targets).
add_library(CUDA_FLAGS INTERFACE)

target_compile_options(CUDA_FLAGS INTERFACE
    -Wno-cuda-compat  # Clang is less restrictive when compiling CUDA than NVCC
    -x cuda
)

if (WIN32)
    # Don't warn about unused /TP added by cmake
    target_compile_options(CUDA_FLAGS INTERFACE -Wno-unused-command-line-argument)
endif()

target_optional_compile_options(CUDA_FLAGS INTERFACE
    -fcuda-short-ptr
)

macro (populate_cuda_property)
    # Prevent use of vanilla-clang is CUDA is enabled. That specific combination gives a very confusing error if you
    # do it by accident.
    if (${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
        # Must be spectral-clang

        check_symbol_exists(__SPECTRAL__ "stdio.h" IS_SPECTRAL)
        if (NOT IS_SPECTRAL)
            fatal_error("XCMake's cuda support does not support vanilla LLVM. Either use the Spectral LLVM compiler, or use CMake's built-in CUDA support with NVCC and whatever host compiler you prefer. You'll have to delete your cmake build directory and re-configure to clear this error, after fixing the problem.")
        endif()
    endif()

    if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
        find_package(AmdCuda REQUIRED)

        target_compile_options(CUDA_FLAGS INTERFACE
            --cuda-path=$<SHELL_PATH:${AMDCUDA_TOOLKIT_ROOT_DIR}>
            # The GPU targets selected...
            --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
        )
        target_link_libraries(CUDA_EFFECTS INTERFACE AmdCuda::amdcuda)

        message(BOLD_RED "Using AMD CUDA from ${AMDCUDA_TOOLKIT_ROOT_DIR}")
    elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
        find_package(CUDA 8.0 REQUIRED)
        target_link_libraries(CUDA_EFFECTS INTERFACE cuda)
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

        if (NOT XCMAKE_CUDA_SYMBOL_HASHING)
            target_compile_options(CUDA_FLAGS INTERFACE -fcuda-disable-symbol-hashing)
        endif()

        message(BOLD_GREEN "Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")
    else()
        target_compile_options(CUDA_FLAGS INTERFACE --cuda-works-better-if-you-enable-gpu-support-in-xcmake) # :D
    endif()
endmacro()
