include_guard(GLOBAL)

define_xcmake_target_property(
    LIBCXX FLAG
    BRIEF_DOCS "Use libc++."
    FULL_DOCS "Use libc++ (the LLVM implementation of the C++ standard library)."
)

target_compile_options(LIBCXX_EFFECTS INTERFACE -fexceptions -stdlib=libc++)
target_link_options(LIBCXX_EFFECTS INTERFACE -fexceptions -stdlib=libc++)
