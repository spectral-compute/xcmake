# Create a header target with the specified target name.
function(add_headers TARGET)
    set(flags)
    set(oneValueArgs HEADER_PATH INSTALL_DESTINATION)
    set(multiValueArgs)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Make the target object.
    add_custom_target(${TARGET})
    set_target_properties(${TARGET} PROPERTIES
        INCLUDE_DIRECTORIES ${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}/
    )

    # TODO: Partial preprocessing and all that jazz...
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}/ DESTINATION ./include/${h_INSTALL_DESTINATION}
            FILES_MATCHING REGEX "\\.(cuh)|h(pp)?$")
endfunction()
