include_guard(GLOBAL)

define_xcmake_global_property(
    CLANG_TIDY FLAG
    DEFAULT OFF
)

function(CLANG_TIDY_EFFECTS TARGET)
    set_target_properties(
        ${TARGET}
        PROPERTIES CXX_CLANG_TIDY ${XCMAKE_TOOLS_DIR}/clang-tidy.sh
    )
endfunction()
