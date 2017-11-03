include(ArgHandle)

# The nop source file - a handy cmake workaround for cases where cmake insists you must have
# a source file, but I don't want to have one.
file(WRITE "${CMAKE_BINARY_DIR}/generated/nop.cpp" "// I like trains\n")
set(NOP_SOURCE_FILE "${CMAKE_BINARY_DIR}/generated/nop.cpp")

# Configure a library or executable target for CUDA, given the list of source files.
function(configure_for_cuda TARGET)
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
    target_include_directories(${TARGET} PRIVATE ${CUDA_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PRIVATE ${CUDA_LIBRARIES})
endfunction()

# Set up an AMD CUDA target. This runs hipify-clang over the source files, and compiles them with
# the AMD compiler.
function(configure_for_amd TARGET)
    # We're not going to get far without hipify!
    find_program(HIPIFY_EXECUTABLE hipify-clang)
    if (NOT HIPIFY_EXECUTABLE)
        message(FATAL_ERROR "Unable to find hipify-clang. Did you install it?")
    endif ()
    message_colour(STATUS Yellow "Using hipify: ${HIPIFY_EXECUTABLE}")

    # We need the CUDA includes for hipification...
    find_package(CUDA 8.0 REQUIRED)

    # And we need HIP for the eventual compilation...
    find_package(HIP REQUIRED)

    set(OUT_DIR "${CMAKE_BINARY_DIR}/generated/hip/${TARGET}")
    file(MAKE_DIRECTORY "${OUT_DIR}")
    set(STAMP_FILE "${OUT_DIR}/${TARGET}.stamp")

    # This is pretty infuriating.
    # `hipify-clang` needs most of the flags that we would pass to clang if we were to compile this
    # as CUDA. But not all of them. Hurrah!
    set(INCLUDE_DIRS "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
    set(SYS_INCLUDE_DIRS "$<TARGET_PROPERTY:${TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>")
    set(DEFS "$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>")
    set(OPS "")
    set(CUDA_FLAGS
        "$<$<BOOL:${INCLUDE_DIRS}>:-I$<JOIN:${INCLUDE_DIRS}, -I>>"
        "$<$<BOOL:${SYS_INCLUDE_DIRS}>:-isystem $<JOIN:${SYS_INCLUDE_DIRS}, -isystem >>"
        "$<$<BOOL:${DEFS}>:-D$<JOIN:${DEFS}, -D>>"
        -isystem ${CUDA_INCLUDE_DIRS}
        $<TARGET_PROPERTY:${TARGET},COMPILE_OPTIONS>
        -x cuda
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}

        # https://github.com/ROCm-Developer-Tools/HIP/issues/204
        -Wno-pragma-once-outside-header
    )

    # Make a rule to process each source file with hipify.
    foreach (_SRC IN LISTS ARGN)
        # Fix it if the user was silly and used absolute source paths..
        string(REPLACE ${CMAKE_CURRENT_SOURCE_DIR} "" ${_SRC} _SRC)
        set(OUT_FILE ${OUT_DIR}/${_SRC})

        get_filename_component(FULL_OUT_DIR ${OUT_FILE} DIRECTORY)
        file(MAKE_DIRECTORY ${FULL_OUT_DIR})

        add_custom_command(
            OUTPUT "${OUT_FILE}"
            DEPENDS "${_SRC}"
            COMMENT "Hipifying ${_SRC}..."
            COMMAND ${HIPIFY_EXECUTABLE} -o ${OUT_FILE} ${_SRC} -- ${CUDA_FLAGS}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            VERBATIM
        )
        target_sources(${TARGET} PRIVATE ${OUT_FILE})
    endforeach()
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

        # We don't want to actually compile _any_ of the input source files - they must go
        # through hipify first. We use the nop source file to silence a cmake warning.
        add_executable(${TARGET} ${ARGN} ${NOP_SOURCE_FILE})
        configure_for_amd(${TARGET} ${SRC_LIST})
    elseif("${TARGET_GPU_TYPE}" STREQUAL "NVIDIA")
        add_executable(${TARGET} ${ARGN})
        configure_for_cuda(${TARGET} ${SRC_LIST})
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
        list(REMOVE_ITEM ARGN ${SRC_LIST})
        add_library(${TARGET} ${ARGN} ${NOP_SOURCE_FILE})
        configure_for_amd(${TARGET} ${SRC_LIST})
    elseif ("${TARGET_GPU_TYPE}" STREQUAL "NVIDIA")
        add_library(${TARGET} ${ARGN})
        configure_for_cuda(${TARGET} ${SRC_LIST})
    elseif ("${TARGET_GPU_TYPE}" STREQUAL "")
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS!")
    else ()
        message(FATAL_ERROR "Unknown GPU type: ${TARGET_GPU_TYPE}")
    endif ()
endfunction()
