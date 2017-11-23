# Use Clang by default.
defaultTcValue(CMAKE_C_COMPILER "clang")
defaultTcValue(CMAKE_CXX_COMPILER "clang++")

# Prepend to the language flags.
set(CMAKE_C_FLAGS "${XCMAKE_COMPILER_FLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${XCMAKE_COMPILER_FLAGS} ${CMAKE_CXX_FLAGS}")
