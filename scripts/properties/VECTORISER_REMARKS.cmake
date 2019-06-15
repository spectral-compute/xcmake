include_guard(GLOBAL)

define_xcmake_target_property(
    VECTORISER_REMARKS FLAG
    BRIEF_DOCS "Compile with vectoriser remarks"
    FULL_DOCS "Print detailled information about loop vectorisation."
)
target_compile_options(VECTORISER_REMARKS_EFFECTS INTERFACE
    -Rpass=loop-vectorize
    -Rpass-missed=loop-vectorize
    -Rpass-analysis=loop-vectorize
)
