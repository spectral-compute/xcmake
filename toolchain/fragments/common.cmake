# This fragment runs last, and is responsible for global defaults and flushing standard values to the CMake cache.

# Prepend to the language flags.
list_join(C_FLAGS XCMAKE_COMPILER_FLAGS " ")
list_join(CXX_FLAGS XCMAKE_COMPILER_FLAGS " ")
default_cache_value(CMAKE_C_FLAGS "${C_FLAGS}")
default_cache_value(CMAKE_CXX_FLAGS "${CXX_FLAGS}")
