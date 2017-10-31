# Create a header target with the specified target name.
function(add_headers TARGET)
    set(flags)
    set(oneValueArgs HEADER_PATH INSTALL_DESTINATION)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # TODO: Partial preprocessing and all that jazz...
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${h_HEADER_PATH}/ DESTINATION ./include/${h_INSTALL_DESTINATION})
endfunction()
