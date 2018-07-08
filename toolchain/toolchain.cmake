################################################ XCMake Toolchain File #################################################
# Include some things we use.
include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)

# Toolchain options.
option(XCMAKE_SHOW_TRIBBLE "Show the values of the variables set by the toolchain file" Off)
set(XCMAKE_TRIBBLE native CACHE STRING "The XCMake target tribble to use")

# Dissect the target tribble.
if ("${XCMAKE_TRIBBLE}" STREQUAL "native")
    set(XCMAKE_OS "native")
    set(XCMAKE_ARCH "native")
    set(XCMAKE_MICROARCH "native")
else()
    # Make sure we got a valid tribble.
    string(REGEX MATCH "^[^-]+-[^-]+-[^-]+$" _tribble_match "${XCMAKE_TRIBBLE}")
    if (NOT _tribble_match)
        message(FATAL_ERROR "Invalid target tribble: ${XCMAKE_TRIBBLE}")
    endif()

    # Extract the components of the tribble by turning it into a list.
    string(REPLACE "-" ";" TRIBBLE_PARTS ${XCMAKE_TRIBBLE})

    list(GET TRIBBLE_PARTS 0 XCMAKE_OS)
    list(GET TRIBBLE_PARTS 1 XCMAKE_ARCH)
    list(GET TRIBBLE_PARTS 2 XCMAKE_MICROARCH)
endif()

# Include the fragments.
if ("${XCMAKE_OS}" STREQUAL "native" AND "${XCMAKE_ARCH}" STREQUAL "native")
    # Include the native toolchain fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/native.cmake)
else()
    # Include the microarchitecture fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/arch/${XCMAKE_ARCH}/${XCMAKE_MICROARCH}.cmake)

    # Include the general architecture fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/arch/${XCMAKE_ARCH}/common.cmake)

    # Include the common architecture fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/arch/common.cmake)

    # Include the OS fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/os/${XCMAKE_OS}.cmake)

    # Include the OS common fragment.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/os/common.cmake)

    # Include the cross compilation common cmake file.
    include(${CMAKE_CURRENT_LIST_DIR}/fragments/cross.cmake)
endif()

# Include the common cmake file.
include(${CMAKE_CURRENT_LIST_DIR}/fragments/common.cmake)

set(TARGET_AMD_GPUS "")
set(TARGET_CUDA_COMPUTE_CAPABILITIES "")

# Desugar the GPU information into something sensible...
foreach (_TGT IN LISTS XCMAKE_GPUS)
    # Very scientifically detect NVIDIA targets as being ones that start with sm_
    string(SUBSTRING "${_TGT}" 0 3 PREFIX)
    if ("${PREFIX}" STREQUAL "sm_")
        string(SUBSTRING "${_TGT}" 3 -1 CC)
        list(APPEND TARGET_CUDA_COMPUTE_CAPABILITIES ${CC})
        set(TARGET_GPU_TYPE "NVIDIA")
    else()
        list(APPEND TARGET_AMD_GPUS ${_TGT})
        set(TARGET_GPU_TYPE "AMD")
    endif()
endforeach()

# Make sure we don't have a mixture of GPU targets...
list(LENGTH TARGET_AMD_GPUS AMD_GPU_LENGTH)
list(LENGTH TARGET_CUDA_COMPUTE_CAPABILITIES NVIDIA_GPU_LENGTH)
if (${AMD_GPU_LENGTH} GREATER 0 AND ${NVIDIA_GPU_LENGTH} GREATER 0)
    message(FATAL_ERROR "You specified a mixture of AMD and NVIDIA GPU targets: ${XCMAKE_GPUS}")
endif()

defaultTcValue(XCMAKE_INTEGRATED_GPU "OFF")

# Set the global macro definition for integrated GPU targets.
if (XCMAKE_INTEGRATED_GPU)
    add_definitions(-DINTEGRATED_GPU)
endif()

# Handle the XCMAKE_SHOW_TRIBBLE case.
if (XCMAKE_SHOW_TRIBBLE OR DEFINED CMAKE_SCRIPT_MODE_FILE)
    foreach (_var IN ITEMS CMAKE_C_COMPILER
                           CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN
                           CMAKE_C_COMPILER_TARGET
                           CMAKE_C_FLAGS
                           CMAKE_CROSSCOMPILING
                           CMAKE_CXX_COMPILER
                           CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN
                           CMAKE_CXX_COMPILER_TARGET
                           CMAKE_CXX_FLAGS
                           CMAKE_EXE_LINKER_FLAGS
                           CMAKE_FIND_ROOT_PATH
                           CMAKE_FIND_ROOT_PATH_MODE_INCLUDE
                           CMAKE_FIND_ROOT_PATH_MODE_LIBRARY
                           CMAKE_FIND_ROOT_PATH_MODE_PACKAGE
                           CMAKE_FIND_ROOT_PATH_MODE_PROGRAM
                           CMAKE_MODULE_LINKER_FLAGS
                           CMAKE_SHARED_LINKER_FLAGS
                           CMAKE_SYSTEM_NAME

                           XCMAKE_ARCH
                           XCMAKE_CLANG_LINKER_FLAGS
                           XCMAKE_COMPILER_FLAGS
                           XCMAKE_CONVENTIONAL_TRIPLE
                           XCMAKE_CTNG_SAMPLE
                           XCMAKE_GENERIC_TRIBBLE
                           XCMAKE_MICROARCH
                           XCMAKE_OS
                           XCMAKE_TOOLCHAIN_DIR
                           XCMAKE_TRIBBLE)
        Stdout("${_var}=${${_var}}")
    endforeach()
endif()
