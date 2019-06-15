include_guard(GLOBAL)

define_xcmake_target_property(
    SAFE_STACK FLAG
    BRIEF_DOCS "Compile with LLVM's SafeStack"
)
target_compile_options(SAFE_STACK_EFFECTS INTERFACE
    -fsanitize=safe-stack
)
