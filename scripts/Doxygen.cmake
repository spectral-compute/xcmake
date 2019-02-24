include(IncludeGuard)

IncludeGuard(Doxygen)

function(add_cppreference_tagfile TARGET)
    if (TARGET cppreference_data)
        return()
    endif ()

    add_subdirectory("${XCMAKE_TOOLS_DIR}/doxygen/externaltags/cppreference" "${CMAKE_BINARY_DIR}/tagfiles/cppreference")
    add_dependencies(${TARGET} cppreference_data)
endfunction()

function(add_nvcuda_tagfile TARGET)
    if (TARGET nvcuda_doxygen)
        return()
    endif ()

    add_subdirectory("${XCMAKE_TOOLS_DIR}/doxygen/externaltags/nvcuda" "${CMAKE_BINARY_DIR}/tagfiles/nvcuda")
    add_dependencies(${TARGET} libnvcuda_tag_file)
endfunction()


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
    set(flags NOINSTALL)
    set(oneValueArgs INSTALL_DESTINATION DOXYFILE LAYOUT_FILE DOXYFILE_SUFFIX)
    set(multiValueArgs HEADER_TARGETS DEPENDS INPUT_HEADERS)
    cmake_parse_arguments("d" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    default_value(d_INSTALL_DESTINATION "docs/${TARGET}")
    default_value(d_DOXYFILE_SUFFIX "Doxyfile.suffix")

    # Extract the list of input paths from the list of given header targets, and build a list of all the header files
    # Doxygen is about to process, so we can add them as dependencies.
    set(DOXYGEN_INPUTS "")
    set(DOXYGEN_INPUT_DIRS "")
    set(HEADERS_USED "")
    foreach (T ${d_HEADER_TARGETS})
        get_target_property(NEW_PATHS ${T} INCLUDE_DIRECTORIES)
        foreach (NEW_PATH ${NEW_PATHS})
            set(DOXYGEN_INPUTS "${DOXYGEN_INPUTS} ${NEW_PATH}")
            set(DOXYGEN_INPUT_DIRS "${DOXYGEN_INPUT_DIRS} ${NEW_PATH}")

            file(GLOB_RECURSE NEW_HEADERS "${NEW_PATH}/*.h" "${NEW_PATH}/*.hpp" "${NEW_PATH}/*.cuh")
            list(APPEND HEADERS_USED ${NEW_HEADERS})
        endforeach()
    endforeach ()

    # Add things that were specified as single-file inputs
    foreach (NEW_HEADER ${d_INPUT_HEADERS})
        get_filename_component(NEW_DIR ${NEW_HEADER} DIRECTORY)
        set(DOXYGEN_INPUTS "${DOXYGEN_INPUTS} ${NEW_HEADER}")
        set(DOXYGEN_INPUT_DIRS "${DOXYGEN_INPUT_DIRS} ${NEW_DIR}")
        list(APPEND HEADERS_USED ${NEW_HEADER})
    endforeach()

    # Add the things we always include.
    set(DOXYGEN_INPUTS "${DOXYGEN_INPUTS} ${XCMAKE_TOOLS_DIR}/doxygen/include")
    set(DOXYGEN_INPUT_DIRS "${DOXYGEN_INPUT_DIRS} ${XCMAKE_TOOLS_DIR}/doxygen/include")

    # A stamp file is used to track the dependency, since Doxygen emits zillions of files.
    set(STAMP_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.stamp)

    add_custom_target(${TARGET}
        DEPENDS ${STAMP_FILE}
    )

    # The cppreference tagfile.
    set(TAGFILES "${STL_TAG_FILE}=http://en.cppreference.com/w/")

    add_cppreference_tagfile(${TARGET})

    # If we're doxygenating a CUDA target, make sure the NVCUDA crossreference target is registered.
    get_target_property(IS_CUDA ${LIB_NAME} CUDA)
    if (IS_CUDA)
        add_nvcuda_tagfile(${TARGET})
        set(TAGFILES "${TAGFILES} ${CMAKE_BINARY_DIR}/docs/tagfiles/libnvcuda.tag=https://docs.nvidia.com/cuda/cuda-runtime-api/")
    endif ()

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
        OUTPUT ${STAMP_FILE} ${OUT_TAGFILE}
        COMMAND doxygen
        COMMAND cmake -E touch ${STAMP_FILE}
        COMMENT "Doxygenation of ${TARGET}..."
        DEPENDS ${DOXYFILE}
        DEPENDS ${d_DOXYFILE_SUFFIX}
        DEPENDS ${HEADERS_USED}
        DEPENDS ${DOXYGEN_LAYOUT_FILE}
#        DEPENDS ${STL_TAG_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM
    )

    add_dependencies(${TARGET} cppreference_data ${DEPENDENT_DOXYTARGETS})

    # Make the new thing get built by `make docs`
    add_dependencies(docs ${TARGET})

    if (NOT "${d_NOINSTALL}")
        install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doxygen/ DESTINATION ${d_INSTALL_DESTINATION})
    endif()
endfunction(add_doxygen)
