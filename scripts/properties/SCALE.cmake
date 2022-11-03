include_guard(GLOBAL)

define_xcmake_target_property(
    SCALE FLAG
    BRIEF_DOCS "Enable SCALE language extensions"
    DEFAULT OFF
)

target_optional_compile_options(SCALE_EFFECTS INTERFACE -fscale-addrspaces)
