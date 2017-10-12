################################################ XCMake Toolchain File #################################################
# Include some things we use.
include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)

# The toolchain file gets called more than once. We only want to keep the things that applied the last time we ran.
resetTcValues()

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

    # Extract the components of the tribble.
    string(REGEX REPLACE "^([^-]+)-[^-]+-[^-]+$" "\\1" XCMAKE_OS "${XCMAKE_TRIBBLE}")
    string(REGEX REPLACE "^[^-]+-([^-]+)-[^-]+$" "\\1" XCMAKE_ARCH "${XCMAKE_TRIBBLE}")
    string(REGEX REPLACE "^[^-]+-[^-]+-([^-]+)$" "\\1" XCMAKE_MICROARCH "${XCMAKE_TRIBBLE}")
endif()

# Include the fragments.
if ("${XCMAKE_TRIBBLE}" STREQUAL "native")
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

# Handle the XCMAKE_SHOW_TRIBBLE case.
if (XCMAKE_SHOW_TRIBBLE)
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