if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" OR "${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    set(DEFAULT_DEB "ON")
else()
    set(DEFAULT_DEB "OFF")
endif()

define_xcmake_target_property(
    DEBUG_MODE FLAG
    BRIEF_DOCS "Apply debug-mode flags"
    DEFAULT ${DEFAULT_DEB}
)
target_compile_options(DEBUG_MODE_EFFECTS INTERFACE
    -gcolumn-info
    -fdebug-macro
    -fno-limit-debug-info
)
