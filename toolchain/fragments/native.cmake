execute_process(COMMAND clang -dumpmachine OUTPUT_VARIABLE XCMAKE_CONVENTIONAL_TRIPLE OUTPUT_STRIP_TRAILING_WHITESPACE)
setTcValue(XCMAKE_CONVENTIONAL_TRIPLE ${XCMAKE_CONVENTIONAL_TRIPLE})

setTcValue(XCMAKE_GENERIC_TRIBBLE "native")

# Sadly, ARM/AArch64 and x86/x86_64 differ here.
string(REGEX MATCH "^(aarch64|arm).*" _use_mcpu "${XCMAKE_CONVENTIONAL_TRIPLE}")
if (_use_mcpu)
    setTcValue(XCMAKE_COMPILER_FLAGS "-mcpu=native")
else()
    setTcValue(XCMAKE_COMPILER_FLAGS "-march=native -mtune=native")
endif()