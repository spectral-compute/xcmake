# This property allows XCMAKE to support the specific building of shared libraries when BUILD_SHARED_LIBS is off
# For example, a plugin which depends on static libraries built by the project

include_guard(GLOBAL)

set(FPIC_DEFAULT ON)
if(MSVC)
    set(FPIC_DEFAULT OFF)
endif()

define_xcmake_target_property(
        FPIC FLAG
        BRIEF_DOCS "Enable position independent code even for static libraries"
        DEFAULT ${FPIC_DEFAULT}
)
target_compile_options(FPIC_EFFECTS INTERFACE -fPIC)
