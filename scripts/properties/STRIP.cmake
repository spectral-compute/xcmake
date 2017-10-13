if ("${CMAKE_BUILD_TYPE}" STREQUAL Release)
    set(DEFAULT_STRIP "ON")
else()
    set(DEFAULT_STRIP "OFF")
endif()

define_xcmake_target_property(
    STRIP FLAG
    BRIEF_DOCS "Strip symbols - default-on in release builds"
    DEFAULT ${DEFAULT_STRIP}
)
set_target_properties(STRIP_EFFECTS
    PROPERTIES INTERFACE_LINK_LIBRARIES -Wl,--strip-all
)
