# Globally-available utility functions, included everywhere.
macro(default_ifempty NAME VALUE)
    if (NOT ${NAME})
        set(${NAME} ${VALUE})
    endif()
endmacro()

macro(default_value NAME)
    if (NOT DEFINED ${NAME})
        set(${NAME} ${ARGN})
    endif()
endmacro()

# Directory for temporary scripts.
set(XCMAKE_TMP_SCRIPT_DIR "${CMAKE_BINARY_DIR}/tmp/cmake")
file(MAKE_DIRECTORY "${XCMAKE_TMP_SCRIPT_DIR}")

# Execute a string as a cmake script within the current context. Even more insane.
macro(exec SCRIPT)
    string(RANDOM SNAME)
    set(SCRIPT_PATH "${XCMAKE_TMP_SCRIPT_DIR}/${SNAME}.cmake")

    file(WRITE ${SCRIPT_PATH} "macro(do_the_thing)\n${SCRIPT}\nendmacro()")

    # Including a file makes cmake consider it a buildsystem dependency. So we mustn't delete it, or the cmake build
    # system is always considered dirty, and cmake is always rerun.
    include(${SCRIPT_PATH})

    do_the_thing()
endmacro()

# Invoke a function, macro, or command by name.
# This is, clearly, completely insane. All args given are forwarded to the target routine.
macro(dynamic_call FN_NAME)
    if (NOT COMMAND ${FN_NAME})
        message(FATAL_ERROR "No such function: ${FN_NAME}")
    endif()

    exec("${FN_NAME}(${ARGN})")
endmacro()

# Convert a directory path like `a/b/c` to the right number of `../` to undo it, like `../../../`
function (path_to_slashes PATH OUTVAR)
    string(REGEX REPLACE "[^/]+(/|$)" "../" DOTSLASHES "${PATH}")
    string(REGEX REPLACE "^/" "" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "/[^/]+" "/../" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "/\\./" "/" DOTSLASHES "${DOTSLASHES}")
    string(REGEX REPLACE "//" "/" DOTSLASHES "${DOTSLASHES}")
    set(${OUTVAR} ${DOTSLASHES} PARENT_SCOPE)
endfunction()
