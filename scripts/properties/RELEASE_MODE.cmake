if ("${CMAKE_BUILD_TYPE}" STREQUAL "Release" OR "${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    set(DEFAULT_OPT "ON")
else()
    set(DEFAULT_OPT "OFF")
endif()

define_xcmake_target_property(
    RELEASE_MODE FLAG
    BRIEF_DOCS "Apply optimised-output flags"
    DEFAULT ${DEFAULT_OPT}
)
# TODO: CUDA + LTO is a puzzling one...
target_compile_options(RELEASE_MODE_EFFECTS INTERFACE
    -Ofast
#    -flto
#    -fwhole-program-vtables
)
#target_link_libraries(RELEASE_MODE_EFFECTS INTERFACE
#    -flto
#)
