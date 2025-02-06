include_guard(GLOBAL)

define_xcmake_target_property(
    WERROR FLAG
    BRIEF_DOCS "Warnings are errors"
    DEFAULT ON
)
target_compile_options(WERROR_EFFECTS INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/WX>                     # MSVC
    $<$<CXX_COMPILER_ID:Clang,AppleClang,GNU>:-Werror> # Clang/GCC
    $<$<COMPILE_LANGUAGE:CUDA>:-Werror all-warnings>   # NVCC
)
