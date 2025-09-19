include_guard(GLOBAL)

define_xcmake_target_property(
    WERROR FLAG
    BRIEF_DOCS "Warnings are errors"
    DEFAULT ON
)
target_compile_options(WERROR_EFFECTS INTERFACE
    # It's silly that we need to list them all 3 times, but that ends up being less awful than doing
    # complex genexp logic :D
    $<$<COMPILE_LANG_AND_ID:C,NVIDIA>:-Werror all-warnings>
    $<$<COMPILE_LANG_AND_ID:CXX,NVIDIA>:-Werror all-warnings>
    $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-Werror all-warnings>

    $<$<COMPILE_LANG_AND_ID:C,MSVC>:/WX>     # MSVC
    $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/WX>   # MSVC

    $<$<COMPILE_LANG_AND_ID:C,Clang,AppleClang,GNU>:-Werror>       # Everything else
    $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang,GNU>:-Werror>     # Everything else
    $<$<COMPILE_LANG_AND_ID:CUDA,Clang,AppleClang,GNU>:-Werror>    # Everything else
)
