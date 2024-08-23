# If PATH is a symlink, follow it (and any symlinks it points to), recursively, until it
# stops being a symlink. Returns the resulting absolute path.
function (resolve_symlink OUTVAR LINKNAME)
    while (IS_SYMLINK "${LINKNAME}")
        # READ_SYMLINK gives you the raw symlink value (eg. `../blah`), so if the symlink
        # stored a relative path you have to fix it up to get something meaningful.
        file(READ_SYMLINK "${LINKNAME}" TMP)
        if (NOT IS_ABSOLUTE "${TMP}")
            get_filename_component(LINK_DIR "${LINKNAME}" DIRECTORY)
            set(LINKNAME "${LINK_DIR}/${TMP}")
        else()
            set(LINKNAME "${TMP}")
        endif()
    endwhile()

    set(${OUTVAR} "${LINKNAME}" PARENT_SCOPE)
endfunction()

# Convert a directory path like `a/b/c` to the right number of `../` to undo it, like `../../../`
function (path_to_slashes PATH OUTVAR)
    string(REGEX REPLACE "[^/]+(/|$)" "../" DOTSLASHES "${PATH}")
    string(REGEX REPLACE "^/" "" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "/[^/]+" "/../" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "/\\./" "/" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "//" "/" DOTSLASHES "${DOTSLASHES}")
    set(${OUTVAR} ${DOTSLASHES} PARENT_SCOPE)
endfunction()

# Given a path a file we want to make, ensure the corresponding directory exists.
function (ensure_directory FILEPATH)
    get_filename_component(DIR "${FILEPATH}" DIRECTORY)
    file(MAKE_DIRECTORY "${DIR}")
endfunction()
