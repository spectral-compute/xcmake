# Create a header target with the specified target name.
#
# TARGET The name of the target to create.
# HEADER_PATH Where to find the headers to process.
# INSTALL_DESTINATION A subdirectory within include to install to.
# FILTER_INCLUDE If given, only the exact entries in this list are added.
# FILTER_EXCLUDE No exact entry in this list is added.
# FILTER_INCLUDE_REGEX If given, then no header will be included that does not match at least one of the given regular
#                      expressions.
# FILTER_EXCLUDE_REGEX No header will be included that matches at least one of the given regular expressions.
#
# The following options run pcpp. Note that this has a few quirks, such as stripping #pragma once.
# DEFINE_MACRO Define a macro to be expanded during partial preprocessing.
# UNDEFINE_MACRO Undefine a macro to declare that it is to be treated as never to be defined during partial expanded.
# COMPRESS Compress the header. This is useful because otherwise, pcpp leaves newlines where stuff removed from
#          evaluated #ifs was.
function(add_headers TARGET)
    set(flags COMPRESS)
    set(oneValueArgs HEADER_PATH INSTALL_DESTINATION)
    set(multiValueArgs FILTER_INCLUDE FILTER_EXCLUDE FILTER_INCLUDE_REGEX FILTER_EXCLUDE_REGEX
                       DEFINE_MACRO UNDEFINE_MACRO)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Make the target object for building unconditionally.
    add_custom_target(${TARGET}_ALL ALL)

    # We're going to construct a shadow header directory in the object directory, and install that. This lets us
    # apply transformations to the headers as part of the build process (such as expanding some preprocessor macros).
    set(SRC_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}")
    set(DST_INCLUDE_DIR "${CMAKE_BINARY_DIR}/include/${TARGET}")

    file(MAKE_DIRECTORY "${DST_INCLUDE_DIR}")

    file(GLOB_RECURSE SRC_HEADER_FILES RELATIVE "${SRC_INCLUDE_DIR}"
        "${SRC_INCLUDE_DIR}/*.hpp"
        "${SRC_INCLUDE_DIR}/*.cuh"
        "${SRC_INCLUDE_DIR}/*.h"
    )

    # Find PCPP if we're going to use it.
    if (h_DEFINE_MACRO OR h_UNDEFINE_MACRO OR h_COMPRESS)
        set(PCPP_DIR "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}/pcpp")
        find_program(PCPP pcpp REQUIRED DOC "Python C PreProcessor program.")
    else()
        set(PCPP_DIR)
    endif()

    # Create a target to process each header file (this is only moderately insane).
    set(ORIGINAL_SOURCES "")
    foreach (SRC_HDR_FILE ${SRC_HEADER_FILES})
        # Check that we didn't filter this header away.
        if (h_FILTER_INCLUDE)
            list(FIND h_FILTER_INCLUDE ${SRC_HDR_FILE} IDX)
            if ("${IDX}" EQUAL "-1")
                continue()
            endif()
        endif()

        if (h_FILTER_EXCLUDE)
            list(FIND h_FILTER_EXCLUDE ${SRC_HDR_FILE} IDX)
            if (NOT "${IDX}" EQUAL "-1")
                continue()
            endif()
        endif()

        if (h_FILTER_INCLUDE_REGEX)
            set(FOUND 0)
            foreach (REGEX IN LISTS h_FILTER_INCLUDE_REGEX)
                if ("${SRC_HDR_FILE}" MATCHES "^${REGEX}$")
                    set(FOUND 1)
                endif()
            endforeach()
            if (NOT FOUND)
                continue()
            endif()
        endif()

        if (h_FILTER_EXCLUDE_REGEX)
            set(FOUND 0)
            foreach (REGEX IN LISTS h_FILTER_EXCLUDE_REGEX)
                if ("${SRC_HDR_FILE}" MATCHES "^${REGEX}$")
                    set(FOUND 1)
                endif()
            endforeach()
            if (FOUND)
                continue()
            endif()
        endif()

        # A unique name for the target.
        string(MAKE_C_IDENTIFIER "${TARGET}_${SRC_HDR_FILE}" FILE_TGT)

        set(FULL_SRC_HDR_PATH "${SRC_INCLUDE_DIR}/${SRC_HDR_FILE}")
        set(OUTPUT_HDR_PATH "${DST_INCLUDE_DIR}/${SRC_HDR_FILE}")

        list(APPEND ORIGINAL_SOURCES "${FULL_SRC_HDR_PATH}")

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}"
            COMMENT "Preparing ${SRC_HDR_FILE} for deployment..."
            DEPENDS "${FULL_SRC_HDR_PATH}"
        )

        # Partially pre-process.
        add_custom_target(${FILE_TGT}_PCPP)
        set(FULL_HDR_PATH "${FULL_SRC_HDR_PATH}")
        if (PCPP_DIR)
            set(FULL_HDR_PATH "${PCPP_DIR}/${SRC_HDR_FILE}")
            get_filename_component(FULL_HDR_PATH_DIR "${FULL_HDR_PATH}" DIRECTORY)
            file(MAKE_DIRECTORY "${FULL_HDR_PATH_DIR}")

            # Figure out pcpp flags from the arguments.
            set(PCPP_ARGS)

            if (h_COMPRESS)
                list(APPEND PCPP_ARGS --compress)
            endif()

            foreach (MACRO IN LISTS h_DEFINE_MACRO)
                list(APPEND PCPP_ARGS -D "${MACRO}")
            endforeach()
            foreach (MACRO IN LISTS h_UNDEFINE_MACRO)
                list(APPEND PCPP_ARGS -U "${MACRO}")
            endforeach()

            # Run pcpp.
            add_custom_command(
                OUTPUT "${FULL_HDR_PATH}"
                COMMENT "Partially pre-processing ${SRC_HDR_FILE}"
                COMMAND "${PCPP}"
                        --passthru-defines # Don't strip macros the header defines.
                        --passthru-unfound-includes # No error for non-existent includes.
                        --passthru-unknown-exprs # No error for uses of unknown macros.
                        --passthru-comments # Don't strip comments.
                        --passthru-magic-macros # Don't modify macros starting with double underscore.
                        --passthru-includes ".*" # Don't try to inline inclusions.
                        --disable-auto-pragma-once # Don't mangle #pragma once.
                        --line-directive # Disable insertion of line directives (yes, this flag does that).
                        "${PCPP_ARGS}" -o "${FULL_HDR_PATH}" "${FULL_SRC_HDR_PATH}"
                COMMAND ${XCMAKE_TOOLS_DIR}/deduplicate_newlines.sh "${FULL_HDR_PATH}"
                DEPENDS "${FULL_SRC_HDR_PATH}" ${XCMAKE_TOOLS_DIR}/deduplicate_newlines.sh
            )
            message(${FULL_HDR_PATH})
            add_custom_target(${FILE_TGT}_PCPP_OUT DEPENDS "${FULL_HDR_PATH}")
            add_dependencies(${FILE_TGT}_PCPP ${FILE_TGT}_PCPP_OUT)
        endif()

        if (NOT WIN32)
            add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
                COMMAND ${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh "${FULL_HDR_PATH}" ${XCMAKE_SANITISE_TRADEMARKS}
                DEPENDS ${FILE_TGT}_PCPP
            )
        endif()

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FULL_HDR_PATH}" "${OUTPUT_HDR_PATH}"
            DEPENDS ${FILE_TGT}_PCPP
        )
        add_custom_target(${FILE_TGT}
            DEPENDS "${OUTPUT_HDR_PATH}"
        )
        add_dependencies(${TARGET}_ALL ${FILE_TGT})
    endforeach()

    # Record the original sources.
    set_target_properties(${TARGET}_ALL PROPERTIES ORIGINAL_SOURCES "${ORIGINAL_SOURCES}")

    # Set up the interface library. This is the target that was requested.
    add_library(${TARGET} INTERFACE)
    target_include_directories(${TARGET} INTERFACE
        $<BUILD_INTERFACE:${DST_INCLUDE_DIR}>
        $<INSTALL_INTERFACE:include/${h_INSTALL_DESTINATION}>
    )
    add_dependencies(${TARGET} ${TARGET}_ALL)
    install(TARGETS ${TARGET} EXPORT ${PROJECT_NAME})

    # Transplant the entire output header directory into the right part of the install tree.
    install(DIRECTORY ${DST_INCLUDE_DIR}/ DESTINATION ./include/${h_INSTALL_DESTINATION})
endfunction()
