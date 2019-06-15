include_guard(GLOBAL)

define_xcmake_target_property(
    BUILD_TYPE_AS_MACRO FLAG
    BRIEF_DOCS "Expose the CMAKE_BUILD_TYPE to the C preprocessor"
    DEFAULT ON
)
string(TOUPPER ${CMAKE_BUILD_TYPE} UPPER_BUILD_TYPE)
target_compile_definitions(BUILD_TYPE_AS_MACRO_EFFECTS INTERFACE
    -D${UPPER_BUILD_TYPE}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
)
