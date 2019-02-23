# Fancy mechanism for generating reference manuals from markdown in repos.

function (add_manual LIB_NAME)
    # Ensure pandoc is installed
    find_program(PANDOC_BINARY pandoc)
    if (NOT PANDOC_BINARY)
        message_colour(STATUS BoldYellow "Compilation of ${LIB_NAME} manual will be skipped because `pandoc` is not installed.")
        return()
    endif ()

    string(TOLOWER ${LIB_NAME} LOWER_LIB_NAME)
    set(TARGET ${LOWER_LIB_NAME}_manual)
    add_custom_target(${TARGET})

    set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/docs/${LOWER_LIB_NAME}")

    set(flags)
    set(oneValueArgs INSTALL_DESTINATION MANUAL_SRC PAGE_TITLE)
    set(multiValueArgs)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Set up pandoc-ification of the *.md files in the given directory.
    file(GLOB_RECURSE SOURCE_MARKDOWN "${d_MANUAL_SRC}/*.md")

    macro (make_src_target SRCFILE OUT_EXT)
        # Generate a unique target name for each file.
        string(LENGTH "${d_MANUAL_SRC}" SRCDIR_LEN)
        string(SUBSTRING "${SRCFILE}" ${SRCDIR_LEN} -1 REL_SRC)
        string(MAKE_C_IDENTIFIER "${REL_SRC}" SRC_TGT)
        set(SRC_TGT "${TARGET}${SRC_TGT}")

        # Make the working directory where we're going to generate the html.
        get_filename_component(IMM_DIR "${REL_SRC}" DIRECTORY)
        get_filename_component(BASENAME_WE "${REL_SRC}" NAME_WE)
        set(IMM_OUT_DIR "${OUT_DIR}/${IMM_DIR}")
        if ("${BASENAME_WE}" STREQUAL "README")
            set(BASENAME_WE index)
        endif()
        set(OUT_FILE "${IMM_OUT_DIR}/${BASENAME_WE}${OUT_EXT}")
        file(MAKE_DIRECTORY "${IMM_OUT_DIR}")

        add_custom_target(${SRC_TGT}
            DEPENDS "${OUT_FILE}"
        )
        add_dependencies(${TARGET} ${SRC_TGT})
    endmacro()

    # Create a doxygen-processing target for each file, so we can munch them all in parallel.
    foreach (MARKDOWN_FILE ${SOURCE_MARKDOWN})
        make_src_target(${MARKDOWN_FILE} ".html")

        # TODO: `--toc` (and other options) could be exposed per-file as a source file property :D
        add_custom_command(
            OUTPUT ${OUT_FILE}
            COMMAND pandoc
                      --fail-if-warnings
                      --from markdown
                      --to html
#                      --toc
                      --css style.css
                      --standalone ${MARKDOWN_FILE} > ${OUT_FILE}
            COMMENT "Pandoc-compiling ${MARKDOWN_FILE}..."
            DEPENDS "${MARKDOWN_FILE}"
            WORKING_DIRECTORY "${d_MANUAL_SRC}"
            VERBATIM
        )
    endforeach()

    # Compile any dot-graphs found.
    file(GLOB_RECURSE SOURCE_DOTS "${d_MANUAL_SRC}/*.dot")
    find_program(DOT_EXE dot)
    foreach (DOT_FILE ${SOURCE_DOTS})
        message(${DOT_EXE})
        if (DOT_EXE)
        else()
            message_colour(STATUS BoldYellow "Skipping compilation of dot-graphs in manual because `dot` is not installed.")
            break()
        endif()

        make_src_target(${DOT_FILE} ".svg")

        add_custom_command(
            OUTPUT ${OUT_FILE}
            COMMAND dot -Tsvg ${DOT_FILE} > ${OUT_FILE}
            COMMENT "dot-compiling ${DOT_FILE}..."
            DEPENDS "${DOT_FILE}"
            WORKING_DIRECTORY "${d_MANUAL_SRC}"
            VERBATIM
        )
    endforeach()

    # All files that aren't being processed get installed directly.
    install(
        DIRECTORY ${d_MANUAL_SRC}/
        DESTINATION ${d_INSTALL_DESTINATION}
        PATTERN *.md EXCLUDE
        PATTERN *.dot EXCLUDE
    )

    # Install all processed files.
    install(
        DIRECTORY ${OUT_DIR}/
        DESTINATION ${d_INSTALL_DESTINATION}
    )

    # Install the stylesheet
    install(
        FILES ${XCMAKE_TOOLS_DIR}/pandoc/style.css
        DESTINATION ${d_INSTALL_DESTINATION}
    )

    # Hook up to the global `docs` target.
    add_dependencies(docs ${TARGET})
endfunction()
