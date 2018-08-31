include(ArgHandle)

option(XCMAKE_CUDA_FLUSH_DENORMALS "Flush CUDA denormal values to zero" On)

# Set up an NVIDIA CUDA target.
function(configure_for_nvidia TARGET)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
    find_package(CUDA 8.0 REQUIRED)

    # Forbid CUDA 9, because it causes all kinda of nasty breakage.
    if ("${CUDA_VERSION_MAJOR}" GREATER 8)
        message(FATAL_ERROR "CUDA 9 harms performance and is therefore not supported. Please use CUDA 8")
    endif()

    message_colour(STATUS BoldGreen "${TARGET}: Using NVIDIA CUDA ${CUDA_VERSION_STRING} from ${CUDA_TOOLKIT_ROOT_DIR}")

    get_target_property(SOURCE_FILES ${TARGET} SOURCES)

    # This disables cmake's built-in CUDA support, which only does NVCC. This stops
    # cmake doing automatic things that derail our attempts to do this properly...
    set_source_files_properties(${SOURCE_FILES} PROPERTIES LANGUAGE CXX)

    # Compiler flags for cuda compilation on clang.
    target_compile_options(${TARGET} PRIVATE
        -x cuda
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${TARGET_CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Get PTXAS to be less unhelpful, provided we have a version of cmake supporting the
    # "Please don't fucking deduplicate my fucking compiler flags" option, which for some
    # reason is what they implemented instead of just *NOT DEDUPLICATING COMPILER OPTIONS?!?!*.
    if (NOT ${CMAKE_VERSION} VERSION_LESS "3.12.0")
        target_compile_options(${TARGET} PRIVATE
            "SHELL:-Xcuda-ptxas --warn-on-spills"

            # Assertions imply local memory usage, so don't enable this warning when assertions are turned on.
            $<IF:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,,SHELL:-Xcuda-ptxas --warn-on-local-memory-usage>
        )
    endif()

    # Add the cuda runtime library.
    target_include_directories(${TARGET} SYSTEM PUBLIC ${CUDA_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PUBLIC ${CUDA_LIBRARIES})
endfunction()

# Set up an AMD CUDA target.
function(configure_for_amd TARGET)
    find_package(AmdCuda REQUIRED)
    message_colour(STATUS BoldRed "${TARGET}: Using AMD CUDA from ${AMDCUDA_TOOLKIT_ROOT_DIR}")

    get_target_property(SOURCE_FILES ${TARGET} SOURCES)

    # This disables cmake's built-in CUDA support, which only does NVCC. This stops
    # cmake doing automatic things that derail our attempts to do this properly...
    set_source_files_properties(${SOURCE_FILES} PROPERTIES LANGUAGE CXX)

    # Compiler flags for cuda compilation on clang.
    target_compile_options(${TARGET} PRIVATE
        -x cuda
        --cuda-path=${AMDCUDA_TOOLKIT_ROOT_DIR}

        # The GPU targets selected...
        --cuda-gpu-arch=$<JOIN:${TARGET_AMD_GPUS}, --cuda-gpu-arch=>
    )

    # Add the cuda runtime library.
    target_link_libraries(${TARGET} PUBLIC AmdCuda::amdcuda)
endfunction()

function(add_cuda_to_target TARGET)
    if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
        configure_for_amd(${TARGET} ${SRC_LIST})
    elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
        configure_for_nvidia(${TARGET} ${SRC_LIST})
    elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "")
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS!")
    else ()
        message(FATAL_ERROR "Unknown GPU type: ${XCMAKE_GPU_TYPE}")
    endif ()

    # We're using Clang. It has fewer restrictions than NVCC.
    target_compile_options(${TARGET} PRIVATE -Wno-cuda-compat)
endfunction()

# Add an executable that uses CUDA.
function(add_cuda_executable TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST WIN32)
    remove_argument(FLAG SRC_LIST MACOSX_BUNDLE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    add_executable(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()

# Add a library that uses CUDA.
function(add_cuda_library TARGET)
    set(SRC_LIST ${ARGN})
    remove_argument(FLAG SRC_LIST STATIC)
    remove_argument(FLAG SRC_LIST SHARED)
    remove_argument(FLAG SRC_LIST MODULE)
    remove_argument(FLAG SRC_LIST EXCLUDE_FROM_ALL)

    add_library(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()
