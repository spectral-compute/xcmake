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

function (add_pandoc_markdown TARGET BASEDIR MARKDOWN_FILE INSTALL_DESTINATION)
    if (NOT TARGET ${TARGET}_PREREQS)
        add_custom_target(${TARGET}_PREREQS)
    endif()

    make_src_target("${TARGET}" "${BASEDIR}" "${MARKDOWN_FILE}" ".html")

    # Build an appropriate sequence of "../" to get us to the top of the documentation tree we're in.
    path_to_slashes("${IMM_DIR}" DOTSLASHES)

    # And again to get us to the root of the install tree.
    path_to_slashes("${COMPONENT_INSTALL_ROOT}${INSTALL_DESTINATION}" DEST_DOTSLASHES)

    set(INTERMEDIATE_FILE "${OUT_FILE}.tmp")

    # This uses Python.
    find_package (Python3 REQUIRED COMPONENTS Interpreter)

    add_custom_command(OUTPUT "${OUT_FILE}"
        COMMAND "${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh" "${MARKDOWN_FILE}" ${XCMAKE_SANITISE_TRADEMARKS}

        # Preprocess the markdown.
        COMMAND "${Python3_EXECUTABLE}" "${XCMAKE_TOOLS_DIR}/pandoc/preprocessor.py"
                -i "${MARKDOWN_FILE}" -o "${INTERMEDIATE_FILE}.1" -t "${COMPONENT_INSTALL_ROOT}${INSTALL_DESTINATION}"
                ${ARGN}

        # Fix URLs prior to conversion to HTML
        COMMAND "${XCMAKE_TOOLS_DIR}/pandoc/url-rewriter.sh"
                "${INTERMEDIATE_FILE}.1"
                "${INTERMEDIATE_FILE}.2"
                "${COMPONENT_INSTALL_ROOT}${INSTALL_DESTINATION}"
                ${DOTSLASHES}${DEST_DOTSLASHES}
                "${${PROJECT_NAME}_DOC_REPLACEMENTS}"

        # Find code files that are dependencies of this markdown file
        # and save them to a dependency file used in DEPFILE directive
        COMMAND "${Python3_EXECUTABLE}" "${XCMAKE_TOOLS_DIR}/pandoc/code-snippet-dependencies.py"
                -d "${OUT_FILE}" -i "${INTERMEDIATE_FILE}.2" -o "${OUT_FILE}.d"

        # Convert the markdown to HTML.
        COMMAND "${XCMAKE_TOOLS_DIR}/pandoc/pandoc.sh" "${INTERMEDIATE_FILE}.2" "${OUT_FILE}" "${DOTSLASHES}style.css"

        # Tidy up the temporary file.
        COMMAND ${CMAKE_COMMAND} -E remove -f "${INTERMEDIATE_FILE}.1" "${INTERMEDIATE_FILE}.2"
        COMMENT "Pandoc-compiling ${MARKDOWN_FILE}..."
        DEPENDS
            "${TARGET}_PREREQS"
            "${MARKDOWN_FILE}"
            "${XCMAKE_TOOLS_DIR}/pandoc/pandoc.sh"
            "${XCMAKE_TOOLS_DIR}/pandoc/preprocessor.py"
            "${XCMAKE_TOOLS_DIR}/pandoc/url-rewriter.sh"
            "${XCMAKE_TOOLS_DIR}/pandoc/code-snippet-dependencies.py"
            "${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh"
        DEPFILE "${OUT_FILE}.d"
        WORKING_DIRECTORY "${d_MANUAL_SRC}"
    )
endfunction()

function (add_dot_graph TARGET BASEDIR DOT_FILE)
    make_src_target("${TARGET}" "${BASEDIR}" "${DOT_FILE}" ".svg")
    add_custom_command(OUTPUT ${OUT_FILE}
        COMMAND dot -Tsvg "${DOT_FILE}" > "${OUT_FILE}"
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
    add_custom_target(${TARGET}_PREREQS)

    set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/docs/${LOWER_LIB_NAME}")

    set(flags)
    set(oneValueArgs INSTALL_DESTINATION MANUAL_SRC PAGE_TITLE)
    set(multiValueArgs PREPROCESSOR_FLAG_NAMES DOXYGEN FILTER_EXCLUDE_REGEX)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_${LIB_NAME}_d_MANUAL_SRC ${d_MANUAL_SRC} CACHE INTERNAL "")
    set(INSTALL_EXCLUDE)

    # Set up pandoc-ification of the *.md files in the given directory.
    file(GLOB_RECURSE SOURCE_MARKDOWN RELATIVE "${d_MANUAL_SRC}" "${d_MANUAL_SRC}/*.md")
    foreach (REGEX ${d_FILTER_EXCLUDE_REGEX})
        list(FILTER SOURCE_MARKDOWN EXCLUDE REGEX "${REGEX}")
        list(APPEND INSTALL_EXCLUDE REGEX "${REGEX}" EXCLUDE)
    endforeach()

    # Figure out the preprocessor arguments.
    set(PREPROCESSOR_ARGS)
    foreach (FLAG ${d_PREPROCESSOR_FLAG_NAMES})
        set(PREPROCESSOR_ARGS "${PREPROCESSOR_ARGS}" -f "${FLAG}")
    endforeach()

    foreach (DT ${d_DOXYGEN})
        get_target_property(DEPENDEE_TAGFILE ${DT} DOXYGEN_TAGFILE)
        get_target_property(DEPENDEE_INSTALL_DESTINATION ${DT} DOXYGEN_INSTALL_DESTINATION)
        get_target_property(DEPENDEE_URL ${DT} DOXYGEN_URL)

        if (NOT "${DEPENDEE_INSTALL_DESTINATION}" STREQUAL "DEPENDEE_INSTALL_DESTINATION-NOTFOUND")
            set(PREPROCESSOR_ARGS "${PREPROCESSOR_ARGS}"
                -d "${DEPENDEE_TAGFILE}" "${DEPENDEE_INSTALL_DESTINATION}/html")
        elseif (NOT "${DEPENDEE_URL}" STREQUAL "${DEPENDEE_URL}-NOTFOUND")
            set(PREPROCESSOR_ARGS "${PREPROCESSOR_ARGS}" -D "${DEPENDEE_TAGFILE}" "${DEPENDEE_URL}")
        else()
            message(FATAL_ERROR "Dependency documentation ${DT} of ${TARGET} has no generated or published location!")
        endif()

        add_dependencies(${TARGET}_PREREQS ${DT})
    endforeach()

    # Create a pandoc-processing target for each file, so we can munch them all in parallel.
    foreach (MARKDOWN_FILE ${SOURCE_MARKDOWN})
        add_pandoc_markdown("${TARGET}" "${d_MANUAL_SRC}" "${d_MANUAL_SRC}/${MARKDOWN_FILE}" "${d_INSTALL_DESTINATION}"
                            ${PREPROCESSOR_ARGS})
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
        ${INSTALL_EXCLUDE}
    )

    # Install all processed files.
    install(
        DIRECTORY ${OUT_DIR}/
        DESTINATION ${d_INSTALL_DESTINATION}
        PATTERN "*.html.d" EXCLUDE
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
#        once at configure time with the argument "LIST", and once with "WRITE" and the directory where the script
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
    set(INTERMEDIATE_BASE_DIR "${XCMAKE_GENERATED_DIR}/${TARGET}")
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
        COMMAND "${Python3_EXECUTABLE}" "./${SCRIPT_FILE}" "WRITE" "${INTERMEDIATE_DIR}"
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
