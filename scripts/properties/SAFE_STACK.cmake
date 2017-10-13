define_xcmake_target_property(
    SAFE_STACK FLAG
    BRIEF_DOCS "Compile with SafeStack"
)
target_compile_options(SAFE_STACK_EFFECTS INTERFACE
    -fsanitize=safe-stack
)
