# Write this function's arguments to stdout.
function(StdOut)
    # message() would also write to stdout, but it'd prepend ` -- `.
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${ARGN}")
endfunction()

# Set a toolchain exported variable if it hasn't already been set.
macro(defaultTcValue VAR)
    if (NOT DEFINED ${VAR})
        set(${VAR} ${ARGN})
    endif()
endmacro()
