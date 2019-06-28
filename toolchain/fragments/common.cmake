# This fragment runs last, and is responsible for global defaults and flushing standard values to the CMake cache.

# Prepend to the language flags.
listJoin(C_FLAGS XCMAKE_COMPILER_FLAGS " ")
listJoin(CXX_FLAGS XCMAKE_COMPILER_FLAGS " ")
set(CMAKE_C_FLAGS "${C_FLAGS}" CACHE INTERNAL "")
set(CMAKE_CXX_FLAGS "${CXX_FLAGS}" CACHE INTERNAL "")
