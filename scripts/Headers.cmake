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
function(add_headers TARGET)
    set(flags)
    set(oneValueArgs HEADER_PATH INSTALL_DESTINATION)
    set(multiValueArgs FILTER_INCLUDE FILTER_EXCLUDE FILTER_INCLUDE_REGEX FILTER_EXCLUDE_REGEX)
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

        set(FULL_HDR_PATH "${SRC_INCLUDE_DIR}/${SRC_HDR_FILE}")
        set(OUTPUT_HDR_PATH "${DST_INCLUDE_DIR}/${SRC_HDR_FILE}")

        list(APPEND ORIGINAL_SOURCES "${FULL_HDR_PATH}")

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}"
            COMMENT "Preparing ${SRC_HDR_FILE} for deployment..."
            DEPENDS "${FULL_HDR_PATH}"
        )

        if (NOT WIN32)
            add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
                COMMAND ${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh "${FULL_HDR_PATH}" ${XCMAKE_SANITISE_TRADEMARKS}
            )
        endif()

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FULL_HDR_PATH}" "${OUTPUT_HDR_PATH}"
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
