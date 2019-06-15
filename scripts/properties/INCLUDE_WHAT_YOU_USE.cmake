include_guard(GLOBAL)

define_xcmake_global_property(
    INCLUDE_WHAT_YOU_USE FLAG
    BRIEF_DOCS "Run the include-what-you-use tool during the build"
    DEFAULT OFF
)

# We define our own version of this for two reasons:
# - CUDA support
# - Convenience (just a flag, and relying on users to put iwyu in PATH)
function(INCLUDE_WHAT_YOU_USE_EFFECTS TARGET)
    set_target_properties(
        ${TARGET}
        PROPERTIES
            CXX_INCLUDE_WHAT_YOU_USE ${XCMAKE_TOOLS_DIR}/iwyu/iwyu.sh
            C_INCLUDE_WHAT_YOU_USE ${XCMAKE_TOOLS_DIR}/iwyu/iwyu.sh
    )
endfunction()
