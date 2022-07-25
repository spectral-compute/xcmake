include_guard(GLOBAL)

define_xcmake_target_property(
    STATIC_STDCXXLIB FLAG
    BRIEF_DOCS "Statically link the C++ standard library."
    DEFAULT OFF
)

# With MSVC-like, there's always a need to set a standard library flag, and that's handled in Targets.cmake.
if (NOT MSVC)
    target_link_options(STATIC_STDCXXLIB_EFFECTS INTERFACE
                        "$<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:-static-libstdc++>")
endif()
