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
    string(REGEX MATCH "^[^-]+-[^-]+-[^-]+(-[^-]+)?$" _tribble_match "${XCMAKE_TRIBBLE}")
    if (NOT _tribble_match)
        message(FATAL_ERROR "Invalid target tribble: ${XCMAKE_TRIBBLE}")
    endif()

    # Extract the components of the tribble by turning it into a list.
    string(REPLACE "-" ";" TRIBBLE_PARTS ${XCMAKE_TRIBBLE})

    list(GET TRIBBLE_PARTS 0 XCMAKE_OS)
    list(GET TRIBBLE_PARTS 1 XCMAKE_ARCH)
    list(GET TRIBBLE_PARTS 2 XCMAKE_MICROARCH)

    list(LENGTH TRIBBLE_PARTS TRIBBLE_NUM_PARTS)
    if (${TRIBBLE_NUM_PARTS} EQUAL 4)
        # GPU type was specified in the tribble.
        list(GET TRIBBLE_PARTS 3 XCMAKE_GPU_TYPE)

        # If the GPU type was given in the target tribble, validate it.
        if (NOT ${XCMAKE_GPU_TYPE} STREQUAL "amd" AND NOT ${XCMAKE_GPU_TYPE} STREQUAL "nvidia")
            message(FATAL_ERROR "Invalid GPU type: ${XCMAKE_GPU_TYPE}")
        endif ()
    endif()
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
        set(XCMAKE_GPU_TYPE "nvidia")
    else()
        list(APPEND TARGET_AMD_GPUS ${_TGT})
        set(XCMAKE_GPU_TYPE "amd")
    endif()
endforeach()

set(XCMAKE_INTEGRATED_GPU OFF CACHE BOOL "Does the GPU share the same memory as the host?")
set(XCMAKE_GPUS "${XCMAKE_GPUS}" CACHE STRING "GPUs to build for")

default_tc_value(XCMAKE_GPU_TYPE "OFF")  # No GPU

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
default_tc_value(XCMAKE_NVIDIA_GPU 0)
default_tc_value(XCMAKE_AMD_GPU 0)

# Set the global macro definition for integrated GPU targets.
if (XCMAKE_INTEGRATED_GPU)
    add_definitions(-DINTEGRATED_GPU)
endif()

# Provide default values for a bunch of cmake builtins that don't have it. This mostly exists to silence warnings
default_tc_value(CMAKE_STATIC_LIBRARY_PREFIX "")
default_tc_value(CMAKE_STATIC_LIBRARY_SUFFIX "")
default_tc_value(CMAKE_SHARED_LIBRARY_PREFIX "")
default_tc_value(CMAKE_SHARED_LIBRARY_SUFFIX "")
default_tc_value(CMAKE_IMPORT_LIBRARY_PREFIX "")
default_tc_value(CMAKE_IMPORT_LIBRARY_SUFFIX "")

default_tc_value(CMAKE_FIND_ROOT_PATH "")

default_tc_value(CMAKE_INSTALL_BINDIR "bin")
default_tc_value(CMAKE_INSTALL_SBINDIR "sbin")
default_tc_value(CMAKE_INSTALL_LIBDIR "lib")
default_tc_value(CMAKE_INSTALL_INCLUDEDIR "include")
default_tc_value(CMAKE_INSTALL_SYSCONFDIR "etc")
default_tc_value(CMAKE_INSTALL_SHARESTATEDIR "com")
default_tc_value(CMAKE_INSTALL_LOCALSTATEDIR "var")

# This being defualt-off creates a lot of problems, and saves at best a tiny amount of binary size.
default_tc_value(CMAKE_POSITION_INDEPENDENT_CODE "ON")

# Provide a variable to denote if the platform we're on uses IMPLIBS for its shared libraries
# Please flesh this out with more possibilities as they're needed
default_tc_value(XCMAKE_IMPLIB_PLATFORM FALSE)
if(WIN32)
    set(XCMAKE_IMPLIB_PLATFORM TRUE)
endif()

# Set `OUTVAR` to the first program in `NAMES` that can be found, or crash. If `OUTVAR` is already set to something
# (because the user or a toolchain fragment explicitly set that program to something), then do nothing.
macro (find_default_program OUTVAR)
    if (NOT ${OUTVAR})
        find_program(${OUTVAR} NAMES ${ARGN})
        set(${OUTVAR} ${${OUTVAR}} CACHE INTERNAL "") # Cache it.

        if (NOT ${OUTVAR})
            message(FATAL_ERROR "Failed to find default ${OUTVAR} using these names: ${NAMES}.")
        endif()
    endif()
endmacro()

# Find the default compilers/linkers/etc.
if(WIN32)
    find_default_program(CMAKE_LINKER "lld-link.exe")
    find_default_program(CMAKE_C_COMPILER "clang-cl.exe")
    find_default_program(CMAKE_CXX_COMPILER "clang-cl.exe")
else()
    find_default_program(CMAKE_LINKER ld.lld ld.gold ld.bfd ld)
    find_default_program(CMAKE_C_COMPILER clang)
    find_default_program(CMAKE_CXX_COMPILER clang++)

    # Make sure that CMAKE_LINKER actually sets the linker. Can hook this up to XCMAKE_CLANG_LINKER_FLAGS if we ever care...
    # -fuse-ld is an unknown argument to lld-link
    default_cache_value(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=\"${CMAKE_LINKER}\"")
    default_cache_value(CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=\"${CMAKE_LINKER}\"")
    default_cache_value(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=\"${CMAKE_LINKER}\"")
endif()

# Handle the XCMAKE_SHOW_TRIBBLE case.
if(XCMAKE_SHOW_TRIBBLE OR DEFINED CMAKE_SCRIPT_MODE_FILE)
    foreach (_var IN ITEMS
            CMAKE_C_COMPILER
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
            XCMAKE_GPU_TYPE
            XCMAKE_AMD_GPU
            XCMAKE_NVIDIA_GPU
            XCMAKE_CLANG_LINKER_FLAGS
            XCMAKE_COMPILER_FLAGS
            XCMAKE_CONVENTIONAL_TRIPLE
            XCMAKE_CTNG_SAMPLE
            XCMAKE_GENERIC_TRIBBLE
            XCMAKE_MICROARCH
            XCMAKE_OS
            XCMAKE_TOOLCHAIN_DIR
            XCMAKE_TRIBBLE
        )
        stdout("${_var}=${${_var}}")
    endforeach()
endif()
