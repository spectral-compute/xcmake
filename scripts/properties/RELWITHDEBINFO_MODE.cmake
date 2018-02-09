if ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    set(DEFAULT_RELDEB "ON")
else()
    set(DEFAULT_RELDEB "OFF")
endif()

define_xcmake_target_property(
    RELEASEWITHDEBUG_MODE FLAG
    BRIEF_DOCS "Apply release-with-debug-mode flags"
    DEFAULT ${DEFAULT_RELDEB}
)
target_compile_options(RELEASEWITHDEBUG_MODE_EFFECTS INTERFACE
    -gcolumn-info
    -fdebug-macro
    -fno-limit-debug-info
)
