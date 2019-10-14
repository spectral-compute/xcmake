# Create a header target with the specified target name.
function(add_headers TARGET)
    set(flags)
    set(oneValueArgs HEADER_PATH INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Make the target object.
    add_custom_target(${TARGET} ALL)
    set_target_properties(${TARGET} PROPERTIES
        INCLUDE_DIRECTORIES ${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}/
    )

    # We're going to construct a shadow header directory in the object directory, and install that. This lets us
    # apply transformations to the headers as part of the build process (such as expanding some preprocessor macros).
    set(SRC_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}")
    set(DST_INCLUDE_DIR "${CMAKE_BINARY_DIR}/include/${TARGET}/")

    file(MAKE_DIRECTORY "${DST_INCLUDE_DIR}")

    file(GLOB_RECURSE SRC_HEADER_FILES RELATIVE "${SRC_INCLUDE_DIR}"
        "${SRC_INCLUDE_DIR}/*.hpp"
        "${SRC_INCLUDE_DIR}/*.cuh"
        "${SRC_INCLUDE_DIR}/*.h"
    )

    # Create a target to process each header file (this is only moderately insane).
    foreach (SRC_HDR_FILE ${SRC_HEADER_FILES})
        # A unique name for the target.
        string(MAKE_C_IDENTIFIER "${TARGET}_${SRC_HDR_FILE}" FILE_TGT)

        set(FULL_HDR_PATH "${SRC_INCLUDE_DIR}/${SRC_HDR_FILE}")
        set(OUTPUT_HDR_PATH "${DST_INCLUDE_DIR}/${SRC_HDR_FILE}")

        add_custom_command(OUTPUT "${OUTPUT_HDR_PATH}"
            COMMAND ${XCMAKE_TOOLS_DIR}/tm-sanitiser.sh "${FULL_HDR_PATH}" ${XCMAKE_SANITISE_TRADEMARKS}

            # TODO: Insert partial preprocessing here...
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FULL_HDR_PATH}" "${OUTPUT_HDR_PATH}"
            COMMENT "Preparing ${SRC_HDR_FILE} for deployment..."
            DEPENDS "${FULL_HDR_PATH}"
        )
        add_custom_target(${FILE_TGT}
            DEPENDS "${OUTPUT_HDR_PATH}"
        )
        add_dependencies(${TARGET} ${FILE_TGT})
    endforeach()

    # Transplant the entire output header directory into the right part of the install tree.
    install(DIRECTORY ${DST_INCLUDE_DIR}/ DESTINATION ./include/${h_INSTALL_DESTINATION})
endfunction()
