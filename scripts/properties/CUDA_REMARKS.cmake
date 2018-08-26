define_xcmake_target_property(
    CUDA_REMARKS FLAG
    BRIEF_DOCS "Enable compiler remarks related to CUDA."
    DEFAULT OFF
)
target_compile_options(CUDA_REMARKS_EFFECTS INTERFACE
    -cuda-remarks
)
