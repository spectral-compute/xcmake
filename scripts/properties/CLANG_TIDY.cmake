include_guard(GLOBAL)

define_xcmake_global_property(
    CLANG_TIDY FLAG
    BRIEF_DOCS "Enable clang-tidy. Is not applied to device code since that does not work yet..."
    DEFAULT OFF
)

add_custom_target(xcmake_clang_tidy DEPENDS "${XCMAKE_TOOLS_DIR}/clang-tidy/clang-tidy.sh"
                                            "${XCMAKE_TOOLS_DIR}/clang-tidy/defaults.yaml"
                                            "${XCMAKE_TOOLS_DIR}/clang-tidy/vfs.yaml")

function(find_clang_tidy)
    if (${CMAKE_C_COMPILER_ID} STREQUAL Clang)
        get_filename_component(DIR "${CMAKE_C_COMPILER}" DIRECTORY)
        list(APPEND HINTS "${DIR}")
    endif()
    if (${CMAKE_CXX_COMPILER_ID} STREQUAL Clang)
        get_filename_component(DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
        list(APPEND HINTS "${DIR}")
    endif()

    # The `HINTS` variable should not be quoted. The below is robust to paths
    # with spaces, and the variable being empty.
    find_program(CLANG_TIDY_BIN clang-tidy HINTS ${HINTS} REQUIRED)
endfunction()

function(CLANG_TIDY_EFFECTS TARGET)
    if (NOT DEFINED CLANG_TIDY_BIN)
        find_clang_tidy()
    endif()
    set_target_properties("${TARGET}" PROPERTIES CXX_CLANG_TIDY "${XCMAKE_TOOLS_DIR}/clang-tidy/clang-tidy.sh;${CLANG_TIDY_BIN};${CMAKE_SOURCE_DIR}")
    add_dependencies("${TARGET}" xcmake_clang_tidy)
endfunction()
