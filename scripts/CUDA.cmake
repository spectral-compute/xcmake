set(XCMAKE_INTEGRATED_GPU OFF CACHE BOOL "Does the GPU share the same memory as the host?")

option(XCMAKE_CUDA_SYMBOL_HASHING "Hash CUDA symbol names. This slightly reduces launch latency and makes certain NVIDIA development tools not crash if you have very long kernel names, but can be annoying if you want to look at profiler output" ON)

# Set the global macro definition for integrated GPU targets.
if (XCMAKE_INTEGRATED_GPU)
    add_definitions(-DINTEGRATED_GPU)
endif()


macro(initialise_cuda_variables)
    if (NOT XCMAKE_GPUS)
        message(BOLD_YELLOW "Warning: Attempting to auto-detect GPU. Specify GPU targets explicitly with `-DXCMAKE_GPUS`")

        # Try, ridiculously, to figure out what GPU the user has installed.
        set(AUTODETECT_BINDIR "${CMAKE_BINARY_DIR}/gpu_autodetect")
        file(MAKE_DIRECTORY "${AUTODETECT_BINDIR}")
        try_compile(COMPILE_SUCCESS
            "${AUTODETECT_BINDIR}"                            # Bindir
            "${XCMAKE_TOOLS_DIR}/gpu_autodetect"              # Srcdir
            gpu_autodetect
            OUTPUT_VARIABLE BUILD_OUTPUT
        )
        execute_process(
            COMMAND "${AUTODETECT_BINDIR}/gpu_autodetect"
            WORKING_DIRECTORY "${AUTODETECT_BINDIR}"
            RESULT_VARIABLE RUN_SUCCESS
            OUTPUT_VARIABLE RUN_OUTPUT
        )

        if (NOT COMPILE_SUCCESS)
            message(BOLD_RED "Error compiling GPU autodetection program. Is CUDA installed?")
            fatal_error("${BUILD_OUTPUT}")
        endif()

        if (NOT RUN_SUCCESS STREQUAL "0")
            message(BOLD_RED "Error running GPU autodetection program. Is CUDA installed?")
            fatal_error("${RUN_OUTPUT}")
        endif()

        # Parse out the number of GPUs.
        string(SUBSTRING "${RUN_OUTPUT}" 0 1 NUM_GPUS)
        string(SUBSTRING "${RUN_OUTPUT}" 1 -1 GPU_ARCH)

        if (${NUM_GPUS} STREQUAL 0)
            fatal_error("There is no GPU in this computer, and you did not specify any GPU targets with -DXCMAKE_GPUS. Either specify a target GPU architecture explicitly, or disable CUDA for your project.")
        endif()

        set(XCMAKE_GPUS "${GPU_ARCH}")
        message(BOLD_YELLOW "Warning: Autodetected ${NUM_GPUS} GPUs. Targeting the 0th...")
        message(BOLD_YELLOW "Warning: Autodetected GPU architecture: ${XCMAKE_GPUS}")
    endif()

    set(TARGET_AMD_GPUS "")
    set(TARGET_CUDA_COMPUTE_CAPABILITIES "")

    # Desugar the GPU information into something sensible...
    foreach (_TGT IN LISTS XCMAKE_GPUS)
        # Very scientifically detect NVIDIA targets as being ones that start with sm_
        string(SUBSTRING "${_TGT}" 0 3 PREFIX)
        if ("${PREFIX}" STREQUAL "sm_")
            string(SUBSTRING "${_TGT}" 3 -1 CC)
            list(APPEND TARGET_CUDA_COMPUTE_CAPABILITIES ${CC})
            set(XCMAKE_GPU_TYPE "nvidia")
        else()
            list(APPEND TARGET_AMD_GPUS ${_TGT})
            set(XCMAKE_GPU_TYPE "amd")
        endif()
    endforeach()

    default_value(XCMAKE_GPU_TYPE "OFF")  # No GPU

    set(XCMAKE_GPUS "${XCMAKE_GPUS}" CACHE STRING "GPUs to build for")
    set(XCMAKE_GPU_TYPE "${XCMAKE_GPU_TYPE}" CACHE STRING "The target GPU vendor")
    set(TARGET_CUDA_COMPUTE_CAPABILITIES "${TARGET_CUDA_COMPUTE_CAPABILITIES}" CACHE STRING "Target NVIDIA GPU architectures")
    set(TARGET_AMD_GPUS "${TARGET_AMD_GPUS}" CACHE STRING "Targert AMD GPU architectures")

    # Make sure we don't have a mixture of GPU targets...
    list(LENGTH TARGET_AMD_GPUS AMD_GPU_LENGTH)
    list(LENGTH TARGET_CUDA_COMPUTE_CAPABILITIES NVIDIA_GPU_LENGTH)
    if (${AMD_GPU_LENGTH} GREATER 0 AND ${NVIDIA_GPU_LENGTH} GREATER 0)
        message(FATAL_ERROR "You specified a mixture of AMD and NVIDIA GPU targets: ${XCMAKE_GPUS}")
    endif()

    # GPU type flags for the benefit of the preprocessor :D

    if (XCMAKE_GPU_TYPE STREQUAL "amd")
        set(XCMAKE_AMD_GPU 1)
    elseif(XCMAKE_GPU_TYPE STREQUAL "nvidia")
        set(XCMAKE_NVIDIA_GPU 1)
    endif()

    default_value(XCMAKE_NVIDIA_GPU 0)
    default_value(XCMAKE_AMD_GPU 0)

    set(XCMAKE_NVIDIA_GPU "${XCMAKE_NVIDIA_GPU}" CACHE BOOL "Building for NVIDIA GPUs?")
    set(XCMAKE_AMD_GPU "${XCMAKE_AMD_GPU}" CACHE BOOL "Building for AMD GPUs?")
endmacro()

macro(lazy_init_cuda)
    if (NOT TARGET XCMAKE_INITIALISED_CUDA)
        if (NOT XCMAKE_GPU_TYPE)
            initialise_cuda_variables()
        endif()
        populate_cuda_property()

        add_custom_target(XCMAKE_INITIALISED_CUDA)
    endif()
endmacro()

function(add_cuda_to_target TARGET)
    lazy_init_cuda()

    if (XCMAKE_GPU_TYPE)
        if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
        elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
        else ()
            message(FATAL_ERROR "Unknown GPU type: ${XCMAKE_GPU_TYPE}")
        endif ()

        set_target_properties(${TARGET} PROPERTIES CUDA ON)
    else()
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS, so CUDA targets are not supported.")
    endif()
endfunction()

# Add an executable that uses CUDA.
function(add_cuda_executable TARGET)
    lazy_init_cuda()
    add_executable(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()

# Add a library that uses CUDA.
function(add_cuda_library TARGET)
    lazy_init_cuda()
    add_library(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()
