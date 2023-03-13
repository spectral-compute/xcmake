include_guard(GLOBAL)

define_xcmake_global_property(
    CLANG_TIDY FLAG
    BRIEF_DOCS "Enable clang-tidy. Is not applied to device code since that does not work yet..."
    DEFAULT OFF
)

add_custom_target(xcmake_clang_tidy DEPENDS "${XCMAKE_TOOLS_DIR}/clang-tidy/clang-tidy.sh"
                                            "${XCMAKE_TOOLS_DIR}/clang-tidy/defaults.yaml"
                                            "${XCMAKE_TOOLS_DIR}/clang-tidy/vfs.yaml")

function(CLANG_TIDY_EFFECTS TARGET)
    set_target_properties(${TARGET} PROPERTIES CXX_CLANG_TIDY "${XCMAKE_TOOLS_DIR}/clang-tidy/clang-tidy.sh")
    add_dependencies("${TARGET}" xcmake_clang_tidy)
endfunction()
