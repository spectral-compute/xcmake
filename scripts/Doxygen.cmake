IncludeGuard(Doxygen)

# Generate Doxygen documentation, attached to a new target with the given name.
# The generated target will create documentation covering the provided HEADER_TARGETS, previously created with
# `add_headers()`.
function(add_doxygen TARGET)
    find_package(Doxygen)
    if (NOT DOXYGEN_FOUND)
        message_colour(STATUS BoldYellow "`make docs` will not be available because Doxygen is not installed.")
        return()
    endif()

    # Oh, the argparse boilerplate
    set(flags)
    set(oneValueArgs INSTALL_DESTINATION DOXYFILE LAYOUT_FILE)
    set(multiValueArgs HEADER_TARGETS)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    default_value(d_DOXYFILE "${CMAKE_CURRENT_LIST_DIR}/Doxyfile.in")
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

    # Make references to the STL link to cppreference.com.
    set(STL_TAG_FILE ${CMAKE_CURRENT_BINARY_DIR}/cppreference.tag.xml)
    if (NOT EXISTS ${STL_TAG_FILE})
        message_colour(STATUS BoldYellow "Downloading cppreference tagfile (for Doxygen). Use `-DENABLE_DOCS=OFF` to skip.")
        file(DOWNLOAD
            http://upload.cppreference.com/mwiki/images/f/f8/cppreference-doxygen-web.tag.xml ${CMAKE_CURRENT_BINARY_DIR}/cppreference.tag.xml
        )
    endif()
    set(TAGFILES "${STL_TAG_FILE}=http://en.cppreference.com/w/")
    set(DOXYGEN_LAYOUT_FILE ${d_LAYOUT_FILE})

    # Generate the final Doxyfile, injecting the variables we calculated above (notably including the list of inputs...)
    configure_file(${d_DOXYFILE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)

    # A stamp file is used to track the dependency, since Doxygen emits zillions of files.
    set(STAMP_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.stamp)

    # Command to actually run doxygen, depending on every header file and the doxyfile template.
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND doxygen
        COMMAND cmake -E touch ${STAMP_FILE}
        COMMENT "Doxygenation of ${TARGET}..."
        DEPENDS ${d_DOXYFILE}
        DEPENDS ${HEADERS_USED}
        DEPENDS ${DOXYGEN_LAYOUT_FILE}
        DEPENDS ${STL_TAG_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM
    )

    add_custom_target(${TARGET}
        DEPENDS ${STAMP_FILE}
    )

    # Make the new thing get built by `make docs`
    add_dependencies(docs ${TARGET})

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doxygen/ DESTINATION ${d_INSTALL_DESTINATION})
endfunction(add_doxygen)
