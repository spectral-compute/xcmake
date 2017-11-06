# Globally-available utility functions, included everywhere.
macro(default_value NAME VALUE)
    if (NOT DEFINED ${NAME})
        set(${NAME} ${VALUE})
    endif()
endmacro()

# Use *sparingly*
macro(default_cache_value NAME VALUE)
    if (NOT DEFINED ${NAME})
        set(${NAME} ${VALUE} CACHE INTERNAL "")
    endif()
endmacro()

# Invoke a function, macro, or command by name.
# This is, clearly, completely insane. All args given are forwarded to the target routine.
macro(dynamic_call FN_NAME)
    if (NOT COMMAND ${FN_NAME})
        message(FATAL_ERROR "No such function: ${FN_NAME}")
    endif()

    string(RANDOM SNAME)
    set(SCRIPT_PATH "${CMAKE_BINARY_DIR}/${SNAME}.cmake")

    file(WRITE ${SCRIPT_PATH} "${FN_NAME}(${ARGN})")
    include(${SCRIPT_PATH})
    file(REMOVE ${SCRIPT_PATH})
endmacro()
