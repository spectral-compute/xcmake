include_guard(GLOBAL)

define_xcmake_target_property(
    SCALE FLAG
    BRIEF_DOCS "Enable SCALE language extensions"
    DEFAULT ON
)

target_optional_compile_options(SCALE_EFFECTS INTERFACE -fscale-addrspaces)
