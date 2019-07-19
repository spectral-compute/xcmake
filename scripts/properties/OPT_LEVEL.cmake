include_guard(GLOBAL)

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
    VALID_VALUES none debug size safe unsafe
)

# This one has to be funtion-style so we can run a generator expression on TARGET.
function(OPT_LEVEL_EFFECTS TARGET)
    add_library(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE)

    target_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
        -O0
    )
    target_optional_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE
        -Oz
        # Can probably do more here if you care enough to bother.
    )

    target_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        -Og
    )
    target_optional_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE
        -O3
    )
    target_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
        -Ofast
        # There are also CUDA translation unit specific flags, predicated on the
        # OPT_LEVEL target property, defined in CUDA.cmake
    )

    # Filter on Windows until Clang issue #270 is properly resolved
    if(NOT WIN32)
        target_optional_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
            # An experimental but years-old optimisation.
            -fstrict-vtable-pointers
        )
    endif()

    # I realise this is ridiculous.
    target_link_libraries(
        ${TARGET} PRIVATE
        $<$<BOOL:$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>>:${TARGET}_$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>_OPT_LEVEL_EFFECTS>
    )
endfunction()
