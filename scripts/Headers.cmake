# Create a header target with the specified target name.
#
# TARGET The name of the target to create.
# HEADER_PATH Where to find the headers to process.
# BUILD_DESTINATION Where to put the headers in the build tree. This is useful to merge multiple header directories
#                   together such that they can reference each other with relative paths.
# INSTALL_DESTINATION A subdirectory within include to install to.
# FORMAT The argument to give to clang-format's -style. If not given, clang-format will not run.
# FILTER_INCLUDE If given, only the exact entries in this list are added.
# FILTER_EXCLUDE No exact entry in this list is added.
# FILTER_INCLUDE_REGEX If given, then no header will be included that does not match at least one of the given regular
#                      expressions.
# FILTER_EXCLUDE_REGEX No header will be included that matches at least one of the given regular expressions.
# HEADER_EXT File extensions to consider when finding headers. Default is .h, .hpp, .cuh
#
# The following options run pcpp. Note that this has a few quirks, such as stripping #pragma once.
# DEFINE_MACRO Define a macro to be expanded during partial preprocessing.
# UNDEFINE_MACRO Undefine a macro to declare that it is to be treated as never to be defined during partial expanded.
# NEVERDEFINE_MACRO Never define the given macro, even if it's defined in the input.
# COMPRESS Compress the header. This is useful because otherwise, pcpp leaves newlines where stuff removed from
#          evaluated #ifs was.
function(add_headers TARGET)
    set(flags COMPRESS)
    set(oneValueArgs HEADER_PATH BUILD_DESTINATION INSTALL_DESTINATION FORMAT ENTRY)
    set(multiValueArgs FILTER_INCLUDE FILTER_EXCLUDE FILTER_INCLUDE_REGEX FILTER_EXCLUDE_REGEX
                       DEFINE_MACRO UNDEFINE_MACRO NEVERDEFINE_MACRO HEADER_EXT INCLUDE_PATH)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Make the target object for building unconditionally.
    add_custom_target(${TARGET}_ALL ALL)

    # We're going to construct a shadow header directory in the object directory, and install that. This lets us
    # apply transformations to the headers as part of the build process (such as expanding some preprocessor macros).
    set(SRC_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}")

    if ("${h_BUILD_DESTINATION}" STREQUAL "")
        set(DST_INCLUDE_DIR "${CMAKE_BINARY_DIR}/include/${TARGET}")
    else()
        set(DST_INCLUDE_DIR "${h_BUILD_DESTINATION}")
    endif()

    file(MAKE_DIRECTORY "${DST_INCLUDE_DIR}")

    # Default value for this argument.
    if ("${h_HEADER_EXT}" STREQUAL "")
        set(h_HEADER_EXT .h .hpp .cuh)
    endif()
    set(SEARCH_GLOB "")
    foreach(_ext IN LISTS h_HEADER_EXT)
        list(APPEND SEARCH_GLOB "${SRC_INCLUDE_DIR}/*${_ext}")
    endforeach ()
    file(GLOB_RECURSE SRC_HEADER_FILES RELATIVE "${SRC_INCLUDE_DIR}" CONFIGURE_DEPENDS ${SEARCH_GLOB})

    # Find PCPP if we're going to use it.
    if (h_DEFINE_MACRO OR h_UNDEFINE_MACRO OR h_NEVERDEFINE_MACRO OR h_COMPRESS)
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
        set(HEADER_PROCESS_DEPENDENCIES)
        set(FULL_HDR_PATH "${FULL_SRC_HDR_PATH}")
        if (PCPP_DIR)
            add_custom_target(${FILE_TGT}_PCPP)
            list(APPEND HEADER_PROCESS_DEPENDENCIES ${FILE_TGT}_PCPP)

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
            foreach (MACRO IN LISTS h_NEVERDEFINE_MACRO)
                list(APPEND PCPP_ARGS -N "${MACRO}")
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
                        -U__XCMAKE_PREPROCESS_FINAL_UNDEF__ # This is the last preprocessing step.
                        "${PCPP_ARGS}" -o "${FULL_HDR_PATH}" "${FULL_SRC_HDR_PATH}"
                COMMAND ${XCMAKE_TOOLS_DIR}/deduplicate_newlines.sh "${FULL_HDR_PATH}"
                DEPENDS "${FULL_SRC_HDR_PATH}" ${XCMAKE_TOOLS_DIR}/deduplicate_newlines.sh
            )
            add_custom_target(${FILE_TGT}_PCPP_OUT DEPENDS "${FULL_HDR_PATH}")
            add_dependencies(${FILE_TGT}_PCPP ${FILE_TGT}_PCPP_OUT)
        endif()

        if (NOT WIN32)
            add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
                COMMAND ${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh "${FULL_HDR_PATH}" ${XCMAKE_SANITISE_TRADEMARKS}
                DEPENDS ${HEADER_PROCESS_DEPENDENCIES}
            )
        endif()

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}" APPEND
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FULL_HDR_PATH}" "${OUTPUT_HDR_PATH}"
            DEPENDS ${HEADER_PROCESS_DEPENDENCIES}
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

# An option to turn off release header building.
option(XCMAKE_RELEASE_HEADER_LIBRARIES "Don't inline/process headers with add_release_header_library" On)

# Like add_headers, but (unless XCMAKE_INLINE_HEADER_LIBRARIES is off) inlines everything starting from a single
# entry-point header.
#
# The idea is to produce the closest thing to a "compiled" release build of a header library as possible given the need
# to still be C++.
#
# Preprocessing happens twice. The first time, macros aren't passed through if they can be fully evaluated. The second
# time, __XCMAKE_PREPROCESS_FINAL_UNDEF__ is explicitly undefined. To define macros that are exported by the header,
# wrap them in #ifndef __XCMAKE_PREPROCESS_FINAL_UNDEF__. This is done with explicit undefinition so that the header
# works when not pre-processed.
#
# Macros starting with `__` are not touched.
#
# If XCMAKE_INLINE_HEADER_LIBRARIES is off, then this just calls add_header_library. The idea is that including the
# entry point works the same regardless of whether this flag is on or off.
#
# The inlined version is more limited: it assumes all headers in HEADER_PATH are dependencies, even whether or not
# they're transitively used by ENTRY. It also assumes that no other headers are (though they may unresolved includes at
# this point).
#
# The following extra arguments exist:
#   ENTRY The entry point to start inlining from, relative to HEADER_PATH. If this is the not set, then the headers are
#         installed when XCMAKE_INLINE_HEADER_LIBRARIES is off (as normal), otherwise, targets are created but without
#         any generated ouptut.
#   INCLUDE_PATH Extra directories to give to PCPP to find headers. This is useful for common headers that contain
#                macros to expand things, but that are then undefined later so they don't end up in the final output.
#
# The following options exist matching those of add_headers: HEADER_PATH, INSTALL_DESTINATION, DEFINE_MACRO,
# UNDEFINE_MACRO, HEADER_EXT. Additionally, when XCMAKE_INLINE_HEADER_LIBRARIES is on, the arguments are just
# forwarded so all its arguments are available.
function(add_release_header_library TARGET)
    # Call add_headers.
    if (NOT XCMAKE_RELEASE_HEADER_LIBRARIES)
        add_headers(${TARGET} "${ARGN}")
        return()
    endif()

    # Parse the arguments.
    set(flags)
    set(oneValueArgs ENTRY HEADER_PATH BUILD_DESTINATION INSTALL_DESTINATION FORMAT)
    set(multiValueArgs DEFINE_MACRO UNDEFINE_MACRO NEVERDEFINE_MACRO HEADER_EXT INCLUDE_PATH)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Default value for this argument.
    if ("${h_HEADER_EXT}" STREQUAL "")
        set(h_HEADER_EXT .h .hpp .cuh)
    endif()

    set(SRC_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}")
    if ("${h_BUILD_DESTINATION}" STREQUAL "")
        set(DST_INCLUDE_DIR "${CMAKE_BINARY_DIR}/generated/headers/${TARGET}")
    else()
        set(DST_INCLUDE_DIR "${h_BUILD_DESTINATION}")
    endif()

    # Find PCPP.
    find_program(PCPP pcpp REQUIRED DOC "Python C PreProcessor program.")

    # Find the headers to use as dependencies.
    set(SEARCH_GLOB "")
    foreach(_ext IN LISTS h_HEADER_EXT)
        list(APPEND SEARCH_GLOB "${SRC_INCLUDE_DIR}/*${_ext}")
    endforeach ()
    file(GLOB_RECURSE SRC_HEADER_FILES CONFIGURE_DEPENDS ${SEARCH_GLOB})

    # Handle the empty entry point case. Do an abbreviated version of the stuff below.
    if ("${h_ENTRY}" STREQUAL "")
        add_custom_target(${TARGET}_ALL ALL)
        set_target_properties(${TARGET}_ALL PROPERTIES ORIGINAL_SOURCES "${SRC_HEADER_FILES}")
        add_library(${TARGET} INTERFACE)
        add_dependencies(${TARGET} ${TARGET}_ALL)
        return()
    endif()

    # Get the entry point paths.
    set(SRC_HDR_PATH "${SRC_INCLUDE_DIR}/${h_ENTRY}")
    set(DST_HDR_PATH "${DST_INCLUDE_DIR}/${h_ENTRY}")

    # Make a build include path.
    get_filename_component(DST_HDR_PATH_DIR "${DST_HDR_PATH}" DIRECTORY)
    file(MAKE_DIRECTORY "${DST_HDR_PATH_DIR}")

    # Figure out pcpp flags from the arguments.
    set(PCPP_ARGS)
    foreach (D IN LISTS h_INCLUDE_PATH)
        list(APPEND PCPP_ARGS -I "${D}")
    endforeach()
    foreach (MACRO IN LISTS h_DEFINE_MACRO)
        list(APPEND PCPP_ARGS -D "${MACRO}")
    endforeach()
    foreach (MACRO IN LISTS h_UNDEFINE_MACRO)
        list(APPEND PCPP_ARGS -U "${MACRO}")
    endforeach()
    foreach (MACRO IN LISTS h_NEVERDEFINE_MACRO)
        list(APPEND PCPP_ARGS -N "${MACRO}")
    endforeach()

    # Run pcpp.
    add_custom_command(
        OUTPUT "${DST_HDR_PATH}"
        COMMENT "Partially pre-processing and inlining ${h_ENTRY}"
        COMMAND "${PCPP}"
                --passthru-unfound-includes # No error for non-existent includes.
                --passthru-unknown-exprs # No error for uses of unknown macros.
                --passthru-magic-macros # Don't modify macros starting with double underscore.
                --line-directive # Disable insertion of line directives (yes, this flag does that).
                "${PCPP_ARGS}" -o "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-pcpp-1.h" "${SRC_HDR_PATH}"
        COMMAND "${PCPP}"
                --passthru-defines # Don't strip macros the header still defines.
                --passthru-unfound-includes
                --passthru-unknown-exprs
                --passthru-magic-macros
                --line-directive
                --compress # Remove blank lines, and so on.
                -U__XCMAKE_PREPROCESS_FINAL_UNDEF__ # This is the last preprocessing step.
                "${PCPP_ARGS}" -o "${DST_HDR_PATH}" "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-pcpp-1.h"
        DEPENDS "${SRC_HEADER_FILES}"
    )

    # Format the header.
    if (NOT "${h_FORMAT}" STREQUAL "")
        find_program(CLANG_FORMAT "clang-format" REQUIRED DOC "Clang source formatter.")
        string(REGEX REPLACE "[ \t\r\n]+" " " FORMAT "${h_FORMAT}") # Allow nicer formatted strings.
        add_custom_command(
            OUTPUT "${DST_HDR_PATH}" APPEND
            COMMAND "${CLANG_FORMAT}" -i "${DST_HDR_PATH}" --sort-includes=0 "-style=${FORMAT}"
        )

    endif()

    # Run the trademark sanitizer.
    if (NOT WIN32)
        add_custom_command(
            OUTPUT "${DST_HDR_PATH}" APPEND
            COMMAND "${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh" "${FULL_HDR_PATH}" "${XCMAKE_SANITISE_TRADEMARKS}"
            DEPENDS "${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh" "${SRC_HEADER_FILES}"
        )
    endif()

    # Create a target for the above. Name it with _ALL for compatibility with users of the ORIGINAL_SOURCES property.
    add_custom_target(${TARGET}_ALL ALL DEPENDS "${DST_HDR_PATH}")

    # Record the original sources.
    set_target_properties(${TARGET}_ALL PROPERTIES ORIGINAL_SOURCES "${SRC_HEADER_FILES}")

    # Set up the interface library. This is the target that was requested.
    add_library(${TARGET} INTERFACE)
    target_include_directories(${TARGET} INTERFACE "$<BUILD_INTERFACE:${DST_INCLUDE_DIR}>"
                                                   "$<INSTALL_INTERFACE:include/${h_INSTALL_DESTINATION}>")
    add_dependencies(${TARGET} ${TARGET}_ALL)
    install(TARGETS ${TARGET} EXPORT "${PROJECT_NAME}")

    # Transplant the entire output header directory into the right part of the install tree.
    install(DIRECTORY "${DST_INCLUDE_DIR}/" DESTINATION ./include/${h_INSTALL_DESTINATION})
endfunction()
