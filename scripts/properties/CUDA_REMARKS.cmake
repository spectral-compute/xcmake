include_guard(GLOBAL)

define_xcmake_target_property(
    CUDA_REMARKS FLAG
    BRIEF_DOCS "Print extra information about optimisation failures in CUDA device code."
    DEFAULT OFF
)
target_compile_options(CUDA_REMARKS_EFFECTS INTERFACE
    -fcuda-remarks -Wno-unused-command-line-argument
)
