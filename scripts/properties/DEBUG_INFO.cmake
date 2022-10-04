include_guard(GLOBAL)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" OR "${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    set(DEFAULT_DEB "ON")
else()
    set(DEFAULT_DEB "OFF")
endif()

define_xcmake_target_property(
    DEBUG_INFO FLAG
    BRIEF_DOCS "Add debug information to the binary"
    DEFAULT ${DEFAULT_DEB}
)
target_compile_options(DEBUG_INFO_EFFECTS INTERFACE
    -g
)
target_optional_compile_options(DEBUG_INFO_EFFECTS INTERFACE
    -gcolumn-info
    -fdebug-macro
    -fno-limit-debug-info
)
