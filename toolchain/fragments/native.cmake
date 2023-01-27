set(CMAKE_CROSSCOMPILING 0)

set(DUMP_MACHINE_EXTRA_ARGS)

# Support MacOS non-native architecture build.
if (NOT "${XCMAKE_ARCH}" STREQUAL "native")
    if (NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "")
        message(FATAL_ERROR "Non-native architecture not supported for native OS except on Mac OS (OS is ${CMAKE_SYSTEM_NAME}).")
    endif()

    if ("${XCMAKE_ARCH}" STREQUAL "aarch64")
        set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE INTERNAL "")
    elseif("${XCMAKE_ARCH}" STREQUAL "x86_64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE INTERNAL "")
    else()
        message(FATAL_ERROR "Unknown architecture for Mac OS: ${XCMAKE_ARCH}.")
    endif()

    set(CMAKE_SYSTEM_PROCESSOR "${XCMAKE_ARCH}" CACHE INTERNAL "")
    set(DUMP_MACHINE_EXTRA_ARGS ${DUMP_MACHINE_EXTRA_ARGS} -arch ${CMAKE_OSX_ARCHITECTURES})
endif()

# Figure out the conventional target triple.
execute_process(COMMAND clang -dumpmachine ${DUMP_MACHINE_EXTRA_ARGS}
                OUTPUT_VARIABLE XCMAKE_CONVENTIONAL_TRIPLE OUTPUT_STRIP_TRAILING_WHITESPACE)
set(XCMAKE_CONVENTIONAL_TRIPLE ${XCMAKE_CONVENTIONAL_TRIPLE})
string(REPLACE "-" ";" XCMAKE_CONVENTIONAL_TRIPLE_PARTS ${XCMAKE_CONVENTIONAL_TRIPLE})
list(GET XCMAKE_CONVENTIONAL_TRIPLE_PARTS 0 XCMAKE_CONVENTIONAL_TRIPLE_ARCH)

# More xcmake stuff.
set(XCMAKE_GENERIC_TRIBBLE "native-${XCMAKE_ARCH}-generic")
include("${CMAKE_CURRENT_LIST_DIR}/microarch.cmake")
