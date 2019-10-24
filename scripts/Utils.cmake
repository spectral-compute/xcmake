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

# Invoke a function, macro, or command by name.
# This is, clearly, completely insane. All args given are forwarded to the target routine.
macro(dynamic_call FN_NAME)
    if (NOT COMMAND ${FN_NAME})
        message(FATAL_ERROR "No such function: ${FN_NAME}")
    endif()

    string(RANDOM SNAME)
    set(SCRIPT_PATH "${XCMAKE_TMP_SCRIPT_DIR}/${SNAME}.cmake")

    file(WRITE ${SCRIPT_PATH} "${FN_NAME}(${ARGN})")
    include(${SCRIPT_PATH})
    # Including a file makes cmake consider it a buildsystem dependency. So we mustn't delete it, or the cmake build
    # system is always considered dirty, and cmake is always rerun.
endmacro()
