include_guard(GLOBAL)

define_xcmake_target_property(
    VECTORISER_REMARKS FLAG
    BRIEF_DOCS "Compile with vectoriser remarks"
    FULL_DOCS "This will print, for all loops, if it was vectorised, how, and why not."
)
target_compile_options(VECTORISER_REMARKS_EFFECTS INTERFACE
    -Rpass=loop-vectorize
    -Rpass-missed=loop-vectorize
    -Rpass-analysis=loop-vectorize
)
