include_guard(GLOBAL)

define_xcmake_target_property(
    STD_FILESYSTEM FLAG
    BRIEF_DOCS "Target uses std::filesystem."
    DEFAULT OFF
)

# TODO: Once we add libc++ support, this wants to be a generator expression that turns it into a no-op when using libc++.
set_target_properties(STD_FILESYSTEM_EFFECTS
    PROPERTIES INTERFACE_LINK_LIBRARIES stdc++fs
)
