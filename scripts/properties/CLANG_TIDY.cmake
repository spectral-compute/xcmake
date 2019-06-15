include_guard(GLOBAL)

define_xcmake_global_property(
    CLANG_TIDY FLAG
    BRIEF_DOCS "Enable clang-tidy. Is not applied to device code since that does not work yet..."
    DEFAULT OFF
)

function(CLANG_TIDY_EFFECTS TARGET)
    set_target_properties(
        ${TARGET}
        PROPERTIES CXX_CLANG_TIDY ${XCMAKE_TOOLS_DIR}/clang-tidy.sh
    )
endfunction()
