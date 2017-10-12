# We're cross compiling!
setTcValue(CMAKE_CROSSCOMPILING TRUE)

# Calculate the generic tribble.
defaultTcValue(XCMAKE_GENERIC_TRIBBLE "${XCMAKE_OS}-${XCMAKE_ARCH}-generic")

# Calculate the crosstool-NG template and the conventional target tuple.
defaultTcValue(XCMAKE_TRIPLE_VENDOR unknown)
defaultTcValue(XCMAKE_CTNG_VENDOR ${XCMAKE_TRIPLE_VENDOR})
if (XCMAKE_TRIPLE_ABI)
    setTcValue(XCMAKE_CTNG_SAMPLE "${XCMAKE_ARCH}-${XCMAKE_CTNG_VENDOR}-${XCMAKE_TRIPLE_OS}-${XCMAKE_TRIPLE_ABI}")
    setTcValue(XCMAKE_CONVENTIONAL_TRIPLE
               "${XCMAKE_ARCH}-${XCMAKE_TRIPLE_VENDOR}-${XCMAKE_TRIPLE_OS}-${XCMAKE_TRIPLE_ABI}")
else()
    setTcValue(XCMAKE_CTNG_SAMPLE "${XCMAKE_ARCH}-${XCMAKE_CTNG_VENDOR}-${XCMAKE_TRIPLE_OS}")
    setTcValue(XCMAKE_CONVENTIONAL_TRIPLE "${XCMAKE_ARCH}-${XCMAKE_TRIPLE_VENDOR}-${XCMAKE_TRIPLE_OS}")
endif()

# Set up Clang's target.
defaultTcValue(CMAKE_C_COMPILER_TARGET "${XCMAKE_CONVENTIONAL_TRIPLE}")
defaultTcValue(CMAKE_CXX_COMPILER_TARGET "${XCMAKE_CONVENTIONAL_TRIPLE}")

# Get the toolchain location.
if (NOT DEFINED XCMAKE_TOOLCHAIN_DIR)
    # TODO: A more elaborate "autodetect".
    setTcValue(XCMAKE_TOOLCHAIN_DIR "/usr/${XCMAKE_TRIBBLE}")
endif()

# Get find_package() and friends to look in the right place.
setTcValue(CMAKE_FIND_ROOT_PATH "${XCMAKE_TOOLCHAIN_DIR}" "${CMAKE_FIND_ROOT_PATH}")
setTcValue(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE only)
setTcValue(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY only)
setTcValue(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE only)
setTcValue(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM never)

# Set up Clang's toolchain location.
defaultTcValue(CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN "${XCMAKE_TOOLCHAIN_DIR}/toolchain")
defaultTcValue(CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN "${XCMAKE_TOOLCHAIN_DIR}/toolchain")

# Set the sysroot location.
defaultTcValue(CMAKE_SYSROOT "${XCMAKE_TOOLCHAIN_DIR}/toolchain/${XCMAKE_CONVENTIONAL_TRIPLE}/sysroot")

# Set the linker to use.
setTcValue(XCMAKE_CLANG_LINKER_FLAGS "-fuse-ld=${XCMAKE_TOOLCHAIN_DIR}/toolchain/bin/${XCMAKE_CONVENTIONAL_TRIPLE}-ld")
setTcValue(CMAKE_EXE_LINKER_FLAGS "${XCMAKE_CLANG_LINKER_FLAGS}")
setTcValue(CMAKE_MODULE_LINKER_FLAGS "${XCMAKE_CLANG_LINKER_FLAGS}")
setTcValue(CMAKE_SHARED_LINKER_FLAGS "${XCMAKE_CLANG_LINKER_FLAGS}")