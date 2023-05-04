include_guard(GLOBAL)

# Breaks clion's language service...
set(DEF_SCALE ON)
if (NOT DEFINED ENV{CLION_IDE})
    set(DEF_SCALE OFF)
endif()

# We want non-CUDA C++ code that's part of a CUDA project to use enhanced address spaces, but we don't want to
# require that any resulting library can only be used by stuff compiled with our compiler. That's why this isn't
# part of the CUDA interface target.
define_xcmake_target_property(
    SCALE FLAG
    BRIEF_DOCS "Enable SCALE language extensions"
    DEFAULT ${DEF_SCALE}
)

target_optional_compile_options(SCALE_EFFECTS INTERFACE -fscale-addrspaces)
