include_guard(GLOBAL)

define_xcmake_target_property(
    SOURCE_COVERAGE FLAG
    BRIEF_DOCS "Enable Clang's source-level overage report generation."
    DEFAULT OFF
)
target_compile_options(SOURCE_COVERAGE_EFFECTS INTERFACE
    -fprofile-instr-generate -fcoverage-mapping
)
