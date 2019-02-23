include(IncludeGuard)

IncludeGuard(Doxygen)

# Download cppreference.com tags file. This is to make references to the STL link to cppreference.com.
include(ExternalData)
set(ExternalData_URL_TEMPLATES
        "https://upload.cppreference.com/mwiki/images/f/f8/cppreference-doxygen-web.tag.xml")
ExternalData_Expand_Arguments(cppreference_data STL_TAG_FILE
        "DATA{${CMAKE_CURRENT_LIST_DIR}/../cppreference-doxygen-web.tag.xml}")
ExternalData_Add_Target(cppreference_data)

# Generate Doxygen documentation, attached to a new target with the given name.
# The generated target will create documentation covering the provided HEADER_TARGETS, previously created with
# `add_headers()`.
function(add_doxygen LIB_NAME)
    find_package(Doxygen)
    if (NOT DOXYGEN_FOUND)
        message_colour(STATUS BoldYellow "`make docs` will not be available because Doxygen is not installed.")
        return()
    endif()

    string(TOLOWER ${LIB_NAME} LOWER_LIB_NAME)

    # Name of the custom target to use
    set(TARGET ${LOWER_LIB_NAME}_doxygen)

    # Oh, the argparse boilerplate
    set(flags)
    set(oneValueArgs INSTALL_DESTINATION DOXYFILE LAYOUT_FILE)
    set(multiValueArgs HEADER_TARGETS DEPENDS)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    default_value(d_INSTALL_DESTINATION "docs/${TARGET}")

    # Extract the list of input paths from the list of given header targets, and build a list of all the header files
    # Doxygen is about to process, so we can add them as dependencies.
    set(DOXYGEN_INPUTS "")
    set(HEADERS_USED "")
    foreach (T ${d_HEADER_TARGETS})
        get_target_property(NEW_PATHS ${T} INCLUDE_DIRECTORIES)
        foreach (NEW_PATH ${NEW_PATHS})
            list(APPEND DOXYGEN_INPUTS "${NEW_PATH}")
            file(GLOB_RECURSE NEW_HEADERS "${NEW_PATH}/*.h" "${NEW_PATH}/*.hpp" "${NEW_PATH}/*.cuh")
            list(APPEND HEADERS_USED ${NEW_HEADERS})
        endforeach()
    endforeach ()

    # A stamp file is used to track the dependency, since Doxygen emits zillions of files.
    set(STAMP_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.stamp)

    add_custom_target(${TARGET}
        DEPENDS ${STAMP_FILE}
    )

    # The cppreference tagfile.
    set(TAGFILES "${STL_TAG_FILE}=http://en.cppreference.com/w/")

    # The tagfile we're going to generate.
    set(OUT_TAGFILE ${CMAKE_BINARY_DIR}/docs/tagfiles/${LIB_NAME}.tag)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/docs/tagfiles)

    # Collect up the tagfiles for the other doxygen targets we depend on.
    foreach (DT ${d_DEPENDS})
        add_dependencies(${TARGET} ${DT}_doxygen)
        set(TAGFILES "${TAGFILES} ${CMAKE_BINARY_DIR}/docs/tagfiles/${DT}.tag=../../../${DT}/reference/html")
    endforeach()

    set(DOXYGEN_LAYOUT_FILE "${XCMAKE_TOOLS_DIR}/doxygen/DoxygenLayout.xml")
    set(DOXYFILE "${XCMAKE_TOOLS_DIR}/doxygen/Doxyfile.in")

    # Generate the final Doxyfile, injecting the variables we calculated above (notably including the list of inputs...)
    configure_file(${DOXYFILE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)

    # Command to actually run doxygen, depending on every header file and the doxyfile template.
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND doxygen
        COMMAND cmake -E touch ${STAMP_FILE}
        COMMENT "Doxygenation of ${TARGET}..."
        DEPENDS ${DOXYFILE}
        DEPENDS ${CMAKE_CURRENT_LIST_DIR}/Doxyfile.suffix
        DEPENDS ${HEADERS_USED}
        DEPENDS ${DOXYGEN_LAYOUT_FILE}
        DEPENDS ${STL_TAG_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM
    )

    add_dependencies(${TARGET} cppreference_data ${DEPENDENT_DOXYTARGETS})

    # Make the new thing get built by `make docs`
    add_dependencies(docs ${TARGET})

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doxygen/ DESTINATION ${d_INSTALL_DESTINATION})
endfunction(add_doxygen)
