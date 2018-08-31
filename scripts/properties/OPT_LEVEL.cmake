if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set(DEFAULT_OPT "debug")
else()
    set(DEFAULT_OPT "unsafe")
endif ()

define_xcmake_target_property(
    OPT_LEVEL
    BRIEF_DOCS "Optimisation level to use"
    FULL_DOCS "Valid values are: none, debug, size, safe, and unsafe. Does more than just setting -Ofoo!"
    DEFAULT ${DEFAULT_OPT}
)
add_library(none_OPT_LEVEL_EFFECTS INTERFACE)
add_library(debug_OPT_LEVEL_EFFECTS INTERFACE)
add_library(safe_OPT_LEVEL_EFFECTS INTERFACE)
add_library(size_OPT_LEVEL_EFFECTS INTERFACE)
add_library(unsafe_OPT_LEVEL_EFFECTS INTERFACE)

target_compile_options(none_OPT_LEVEL_EFFECTS INTERFACE
    -O0
)

target_compile_options(size_OPT_LEVEL_EFFECTS INTERFACE
    -Oz
    # Can probably do more here if you care enough to bother.
)

target_compile_options(debug_OPT_LEVEL_EFFECTS INTERFACE
    -Og
)

target_compile_options(safe_OPT_LEVEL_EFFECTS INTERFACE
    -O3
)
target_compile_options(unsafe_OPT_LEVEL_EFFECTS INTERFACE
    -Ofast

    # Flush denormals in CUDA code, if this is a CUDA-using target.
    $<IF:$<BOOL:$<TARGET_PROPERTY:SP_CUDA>>,,-fcuda-flush-denormals-to-zero>
)
