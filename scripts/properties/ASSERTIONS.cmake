include_guard(GLOBAL)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set(DEFAULT_ASS "ON")
else()
    set(DEFAULT_ASS "OFF")
endif()

define_xcmake_target_property(
    ASSERTIONS FLAG
    BRIEF_DOCS "Enable assertions"
    DEFAULT ${DEFAULT_ASS}
)
target_compile_definitions(ASSERTIONS_EFFECTS INTERFACE
    -DENABLE_ASSERTIONS

    # Enable assertions baked into the gnu STL.
    -D_GLIBCXX_ASSERTIONS

    # Enable libc++ assertions, too.
    -D_LIBCPP_ENABLE_ASSERTIONS
)
target_optional_compile_options(ASSERTIONS_EFFECTS INTERFACE
    # Don't warn about optimiser failures (assertions cause lots of them).
    -Wno-pass-failed
)
