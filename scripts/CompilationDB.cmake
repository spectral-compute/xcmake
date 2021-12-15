# Stuff to automatically un-break the clangd compilation database.
function (repair_cmake_compdb)
    file(READ ${CMAKE_BINARY_DIR}/compile_commands.json WTF)
    message("${WTF}")

    # Do the thing that makes clangd have nonterrible support for headers.
    execute_process(
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE COMP_DB
    )
endfunction()

# If exporting a language server file, it must be symlinked into the root of the srcdir. Ensure this has
# been done.
if (CMAKE_EXPORT_COMPILE_COMMANDS)
    set(F "${CMAKE_SOURCE_DIR}/compile_commands.json")
    set(CDB_FILE "${CMAKE_BINARY_DIR}/compile_commands.json")
    get_filename_component(EXPECTED "${CDB_FILE}" REALPATH)

    if (IS_SYMLINK "${F}")
        # Does it link to the wrong thing?
        file(READ_SYMLINK "${F}" SYMLINK_DST)

        # Resolve all absolute paths.
        get_filename_component(ACTUAL "${SYMLINK_DST}" REALPATH)
        if (NOT "${EXPECTED}" STREQUAL "${ACTUAL}")
            fatal_error("${CMAKE_SOURCE_DIR}/compile_commands.json should be a symlink to ${EXPECTED}, but it currently links to ${ACTUAL}. IDE support will not function correctly. If you're not trying to use IDE support, you might want to remove `CMAKE_EXPORT_COMPILE_COMMANDS`")
        endif()
    elseif (NOT EXISTS "${F}")
        # If it doesn't exist at all, just create it.
        file(CREATE_LINK "${EXPECTED}" "${F}" SYMBOLIC)
    endif()

    find_program(COMPDB_EXE compdb)
    add_custom_target(repair_compilation_db ALL
                "${COMPDB_EXE}" -p "${CMAKE_BINARY_DIR}" list > "${CDB_FILE}.tmp"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${CDB_FILE}.tmp" "${CDB_FILE}"
    )
    add_dependencies(ide repair_compilation_db)
endif()
