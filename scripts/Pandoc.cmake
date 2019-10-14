# Fancy mechanism for generating reference manuals from markdown in repos.

macro (make_src_target TARGET BASEDIR SRCFILE OUT_EXT)
    # Generate a unique target name for each file.
    string(LENGTH "${BASEDIR}" SRCDIR_LEN)
    string(SUBSTRING "${SRCFILE}" ${SRCDIR_LEN} -1 REL_SRC)

    string(MAKE_C_IDENTIFIER "${REL_SRC}" SRC_TGT)
    set(SRC_TGT "${TARGET}${SRC_TGT}")

    # Make the working directory where we're going to generate the output.
    get_filename_component(IMM_DIR "${REL_SRC}" DIRECTORY)
    get_filename_component(BASENAME_WE "${REL_SRC}" NAME_WE)
    set(IMM_OUT_DIR "${OUT_DIR}/${IMM_DIR}")
    if ("${BASENAME_WE}" STREQUAL "README")
        set(BASENAME_WE index)
    endif()
    set(OUT_FILE "${IMM_OUT_DIR}/${BASENAME_WE}${OUT_EXT}")
    file(MAKE_DIRECTORY "${IMM_OUT_DIR}")

    add_custom_target(${SRC_TGT} DEPENDS "${OUT_FILE}")
    add_dependencies(${TARGET} ${SRC_TGT})
endmacro()

function (add_pandoc_markdown TARGET BASEDIR DOT_FILE)
    make_src_target("${TARGET}" "${BASEDIR}" "${MARKDOWN_FILE}" ".html")

    # Build an appropriate sequence of "../" to refer to the stylesheet.
    string(REGEX REPLACE "/[a-zA-Z0-9_-]+" "../" DOTSLASHES "${IMM_DIR}")
    string(REGEX REPLACE "^/" "" DOTSLASHES "${DOTSLASHES}")

    # TODO: `--toc` (and other options) could be exposed per-file as a source file property :D
    add_custom_command(OUTPUT ${OUT_FILE}
        COMMAND ${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh ${MARKDOWN_FILE} ${XCMAKE_SANITISE_TRADEMARKS}
        COMMAND pandoc
            --fail-if-warnings
            --from markdown
            --to html
#           --toc
            --css ${DOTSLASHES}style.css
            --standalone ${MARKDOWN_FILE} > ${OUT_FILE}
        COMMENT "Pandoc-compiling ${MARKDOWN_FILE}..."
        DEPENDS "${MARKDOWN_FILE}"
        WORKING_DIRECTORY "${d_MANUAL_SRC}"
    )
endfunction()

function (add_dot_graph TARGET BASEDIR DOT_FILE)
    make_src_target("${TARGET}" "${BASEDIR}" "${DOT_FILE}" ".svg")
    add_custom_command(OUTPUT ${OUT_FILE}
        COMMAND dot -Tsvg ${DOT_FILE} > ${OUT_FILE}
        COMMENT "dot-compiling ${DOT_FILE}..."
        DEPENDS "${DOT_FILE}"
        WORKING_DIRECTORY "${d_MANUAL_SRC}"
    )
endfunction()

# Add a manual.
function (add_manual LIB_NAME)
    # Abort if docs are disabled
    ensure_docs_enabled()

    # Ensure pandoc is installed
    find_program(PANDOC_BINARY pandoc)
    if (NOT PANDOC_BINARY)
        message(BOLD_YELLOW "Compilation of ${LIB_NAME} manual will be skipped because `pandoc` is not installed.")
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

    set(_${LIB_NAME}_d_MANUAL_SRC ${d_MANUAL_SRC} CACHE INTERNAL "")

    # Set up pandoc-ification of the *.md files in the given directory.
    file(GLOB_RECURSE SOURCE_MARKDOWN "${d_MANUAL_SRC}/*.md")

    # Create a doxygen-processing target for each file, so we can munch them all in parallel.
    foreach (MARKDOWN_FILE ${SOURCE_MARKDOWN})
        add_pandoc_markdown("${TARGET}" "${d_MANUAL_SRC}" "${MARKDOWN_FILE}")
    endforeach()

    # Compile any dot-graphs found.
    find_program(DOT_EXE dot)
    if (DOT_EXE)
        file(GLOB_RECURSE SOURCE_DOTS "${d_MANUAL_SRC}/*.dot")
        foreach (DOT_FILE ${SOURCE_DOTS})
            add_dot_graph("${TARGET}" "${d_MANUAL_SRC}" "${DOT_FILE}")
        endforeach()
    else()
        message(BOLD_YELLOW "Skipping compilation of dot-graphs in manual because `dot` is not installed.")
    endif()

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

# Add a script to generate part of a manual.
#
# Markdown and dot files can be generated. They are then preprocessed as they would be if they were checked in directly.
#
# LIB_NAME The same as the LIB_NAME given to add_manual().
# SCRIPT A path to the script call relative to the MANUAL_SRC directory given to add_manual(). It will be called twice:
#        once at congigure time with the argument "LIST", and once with "WRITE" and the directory where the script
#        should write its output at build time. When called with "LIST", the script should list all the files it
#        produces as a semicolon separated list with no newline at the end. This script will be run from the directory
#        that contains it.
# DEPENDENCIES A list of dependencies for the given script. This is relative to the MANUAL_SRC directory given to
#              add_manual().
function (add_manual_generator LIB_NAME)
    # Abort if library has docs disabled
    ensure_docs_enabled()

    find_package(Python3 COMPONENTS Interpreter)
    if (NOT Python3_FOUND)
        message("Can't find Python 3 interpreter. Either install it, or disable building documentation with `-DENABLE_DOCS=OFF`" FATAL_ERROR)
    endif()

    set(flags)
    set(oneValueArgs SCRIPT)
    set(multiValueArgs DEPENDENCIES)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(d_MANUAL_SRC ${_${LIB_NAME}_d_MANUAL_SRC})

    string(TOLOWER ${LIB_NAME} LOWER_LIB_NAME)
    set(TARGET ${LOWER_LIB_NAME}_manual)

    # Abort if library has docs disabled
    ensure_docs_enabled()

    if (NOT TARGET ${TARGET})
        message(YELLOW "Can't add manual generator to nonexistant manual: " ${TARGET})
        return ()
    endif ()

    set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/docs/${LOWER_LIB_NAME}")

    # Create a directory for the script to write its output to.
    get_filename_component(SCRIPT_DIR "${d_SCRIPT}" DIRECTORY)
    get_filename_component(SCRIPT_FILE "${d_SCRIPT}" NAME)
    set(INTERMEDIATE_BASE_DIR "${CMAKE_BINARY_DIR}/generated/${TARGET}")
    set(INTERMEDIATE_DIR "${INTERMEDIATE_BASE_DIR}/${SCRIPT_DIR}")
    file(MAKE_DIRECTORY "${INTERMEDIATE_DIR}")

    # Get a list of files the generator generates.
    execute_process(COMMAND "${Python3_EXECUTABLE}" "./${SCRIPT_FILE}" "LIST"
                    WORKING_DIRECTORY "${d_MANUAL_SRC}/${SCRIPT_DIR}"
                    OUTPUT_VARIABLE GENERATED_FILES)

    set(GENERATED_PATHS "")
    # Make any missing output directories
    foreach (outFile IN LISTS GENERATED_FILES)
        set(GENERATED_PATH "${INTERMEDIATE_DIR}/${outFile}")
        list(APPEND GENERATED_PATHS "${GENERATED_PATH}")
        get_filename_component(GENERATED_DIR "${outFile}" DIRECTORY)
        file(MAKE_DIRECTORY "${INTERMEDIATE_DIR}/${GENERATED_DIR}")
    endforeach()

    # Create a target for runnig the generator script.
    set(DEPENDENCIES "")
    foreach (dep IN LISTS d_DEPENDENCIES)
        set(DEPENDENCIES "${DEPENDENCIES}" "${d_MANUAL_SRC}/${dep}")
    endforeach()

    add_custom_command(OUTPUT ${GENERATED_PATHS}
        COMMAND "./${SCRIPT_FILE}" "WRITE" "${INTERMEDIATE_DIR}"
        WORKING_DIRECTORY "${d_MANUAL_SRC}/${SCRIPT_DIR}"
        COMMENT "Running documentation generation script ${d_SCRIPT}"
        DEPENDS "${d_MANUAL_SRC}/${d_SCRIPT}" "${DEPENDENCIES}"
        WORKING_DIRECTORY "${d_MANUAL_SRC}/${SCRIPT_DIR}"
    )

    # Add all the generated files to the manual.
    foreach (outFile IN LISTS GENERATED_FILES)
        set(GENERATED_PATH "${INTERMEDIATE_DIR}/${outFile}")
        get_filename_component(ext "${outFile}" EXT)
        if (ext STREQUAL ".dot")
            add_dot_graph("${TARGET}" "${INTERMEDIATE_BASE_DIR}" "${GENERATED_PATH}")
        elseif (ext STREQUAL ".md")
            add_pandoc_markdown("${TARGET}" "${INTERMEDIATE_BASE_DIR}" "${GENERATED_PATH}")
        else()
            message(BOLD_RED "Generated manual file of type ${ext} is not supported")
        endif()
    endforeach()
endfunction()
