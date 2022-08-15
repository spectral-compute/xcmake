include_guard(GLOBAL)

define_xcmake_target_property(
    STD_FILESYSTEM FLAG
    BRIEF_DOCS "Target uses std::filesystem."
    DEFAULT OFF
)

# The windows STL has std::filesystem baked into it, at least as of VS2019. Supporting old versions of VS is enough of
# a nightmare that I'm not keen on trying to do it.
if (NOT WIN32)
    set_target_properties(STD_FILESYSTEM_EFFECTS
        PROPERTIES INTERFACE_LINK_LIBRARIES $<IF:$<BOOL:$<TARGET_PROPERTY:LIBCXX>>,,stdc++fs>
    )
endif()
