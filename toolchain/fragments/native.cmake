set(CMAKE_CROSSCOMPILING 0)

execute_process(COMMAND clang -dumpmachine OUTPUT_VARIABLE XCMAKE_CONVENTIONAL_TRIPLE OUTPUT_STRIP_TRAILING_WHITESPACE)
set(XCMAKE_CONVENTIONAL_TRIPLE ${XCMAKE_CONVENTIONAL_TRIPLE})
string(REPLACE "-" ";" XCMAKE_CONVENTIONAL_TRIPLE_PARTS ${XCMAKE_CONVENTIONAL_TRIPLE})
list(GET XCMAKE_CONVENTIONAL_TRIPLE_PARTS 0 XCMAKE_CONVENTIONAL_TRIPLE_ARCH)

set(XCMAKE_GENERIC_TRIBBLE "native-native-generic")

# x86_64 is actually called x86-64.
if ("${XCMAKE_CONVENTIONAL_TRIPLE_ARCH}" STREQUAL "x86_64")
    set(XCMAKE_CONVENTIONAL_TRIPLE_ARCH_CC "x86-64")
else()
    set(XCMAKE_CONVENTIONAL_TRIPLE_ARCH_CC "${XCMAKE_CONVENTIONAL_TRIPLE_ARCH}")
endif()

# See if we have a microarch fragment. If so, we should use that (e.g: for -mavx2). Otherwise, assume the microarch is a
# specific CPU.
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/arch/${XCMAKE_CONVENTIONAL_TRIPLE_ARCH}/${XCMAKE_MICROARCH}.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/arch/${XCMAKE_CONVENTIONAL_TRIPLE_ARCH}/${XCMAKE_MICROARCH}.cmake")
else()
    # Sadly, ARM/AArch64 and x86/x86_64 differ here.
    string(REGEX MATCH "^(aarch64|arm).*" _use_mcpu "${XCMAKE_CONVENTIONAL_TRIPLE}")
    if (_use_mcpu)
        list(APPEND XCMAKE_COMPILER_FLAGS -mcpu=${XCMAKE_MICROARCH})
    else()
        if ("${XCMAKE_MICROARCH}" STREQUAL "generic")
            list(APPEND XCMAKE_COMPILER_FLAGS -march=${XCMAKE_CONVENTIONAL_TRIPLE_ARCH_CC} -mtune=${XCMAKE_MICROARCH})
        else()
            list(APPEND XCMAKE_COMPILER_FLAGS -march=${XCMAKE_MICROARCH} -mtune=${XCMAKE_MICROARCH})
        endif()
    endif()
endif()

# If we're using clang-cl, we need to swap -mtune= for /tune:.
if (WIN32)
    string(REPLACE "-mtune=" "/tune:" XCMAKE_COMPILER_FLAGS "${XCMAKE_COMPILER_FLAGS}")
endif()
