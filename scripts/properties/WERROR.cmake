include_guard(GLOBAL)


if (XCMAKE_WERORR)
    set(DEFAULT_WERROR "ON")
else()
    set(DEFAULT_WERROR "OFF")
endif()

define_xcmake_target_property(
    WERROR FLAG
    BRIEF_DOCS "Warnings are errors"
    DEFAULT ${DEFAULT_WERROR}
)
target_compile_options(WERROR_EFFECTS INTERFACE
    $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/WX>                      # MSVC
    $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-Werror>      # Clang
)
