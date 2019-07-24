# This property allows XCMAKE to support the specific building of shared libraries when BUILD_SHARED_LIBS is off
# For example, a plugin which depends on static libraries built by the project

include_guard(GLOBAL)

define_xcmake_target_property(
        FPIC FLAG
        BRIEF_DOCS "Enable position independent code even for static libraries"
        DEFAULT ON
)
target_compile_options(FPIC_EFFECTS INTERFACE -fPIC)
