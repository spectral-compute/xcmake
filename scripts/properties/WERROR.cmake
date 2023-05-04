include_guard(GLOBAL)

define_xcmake_target_property(
    WERROR FLAG
    BRIEF_DOCS "Warnings are errors"
    DEFAULT OFF
)
target_compile_options(WERROR_EFFECTS INTERFACE
    $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/WX>                      # MSVC
    $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-Werror>      # Clang
)
