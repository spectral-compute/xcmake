include_guard(GLOBAL)

define_xcmake_target_property(
    LLVM_MODULES FLAG
    BRIEF_DOCS "Enable LLVM module support. This allows a target to be built *using* modules."
    DEFAULT OFF
)
target_compile_options(LLVM_MODULES_EFFECTS INTERFACE
    -fmodules

    # Load the module map for clang builtins
    -fbuiltin-module-map
)
