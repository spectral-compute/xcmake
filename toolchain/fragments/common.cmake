# This fragment runs last, and is responsible for global defaults and flushing standard values to the CMake cache.

# Use Clang by default.
defaultTcValue(CMAKE_C_COMPILER "clang")
defaultTcValue(CMAKE_CXX_COMPILER "clang++")

# Prepend to the language flags.
listJoin(C_FLAGS XCMAKE_COMPILER_FLAGS " ")
listJoin(CXX_FLAGS XCMAKE_COMPILER_FLAGS " ")
set(CMAKE_C_FLAGS "${C_FLAGS}" CACHE INTERNAL "")
set(CMAKE_CXX_FLAGS "${CXX_FLAGS}" CACHE INTERNAL "")
