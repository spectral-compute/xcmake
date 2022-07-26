include_guard(GLOBAL)

define_xcmake_target_property(
    SOURCE_COVERAGE FLAG
    BRIEF_DOCS "Enable Clang's source-level overage report generation."
    DEFAULT OFF
)
target_compile_options(SOURCE_COVERAGE_EFFECTS INTERFACE
    --coverage
)
target_link_options(SOURCE_COVERAGE_EFFECTS INTERFACE --coverage)
target_link_libraries(SOURCE_COVERAGE_EFFECTS INTERFACE RAW gcov)

# Actually invoking `gcovr` is nontrivial, so let's make that convenient for people.
function (enable_coverage)
    set(flags)
    set(oneValueArgs)
    set(multiValueArgs EXCLUDE_FILE_PATTERNS EXCLUDE_LINE_PATTERNS)
    cmake_parse_arguments("a" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Adapt the exclude patterns to deal with gcov being insane (and requiring them to be either absolute paths, or paths
    # relative to the objdir root.
    set(A "")
    foreach (_P ${a_EXCLUDE_FILE_PATTERNS})
        set(A "${A};-e;${CMAKE_SOURCE_DIR}/${_P}")
    endforeach()

    # To keep things even more exciting, the line patterns argument can only be included once, so you need to compose it
    # as a regex.
    set(LINE_PATTERNS "")
    foreach (_P ${a_EXCLUDE_LINE_PATTERNS})
        if ("${LINE_PATTERNS}" STREQUAL "")
            set(LINE_PATTERNS ${_P})
        else()
            set(LINE_PATTERNS "${LINE_PATTERNS}|${_P}")
        endif()
    endforeach()
    if ("${LINE_PATTERNS}" STREQUAL "")
    else()
        set(A "${A};--exclude-lines-by-pattern;.*(${LINE_PATTERNS}).*")
    endif()

    find_program(GCOVR_EXE gcovr)

    add_custom_target(coverage
        COMMAND ${GCOVR_EXE} --html-details -o coverage/index.html -s --gcov-executable "llvm-cov gcov" --exclude-unreachable-branches --exclude-throw-branches ${A} -r "${CMAKE_SOURCE_DIR}" .

        # No, there seems to be no option to stop it making these :D
        COMMAND rm -f ${CMAKE_SOURCE_DIR}/*.gcov

        COMMENT "Generating coverage report..."
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
    )
endfunction()
