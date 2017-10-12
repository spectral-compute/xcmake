# Write this function's arguments to stdout.
function(StdOut)
    # message() would also write to stdout, but it'd prepend ` -- `.
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${ARGN}")
endfunction()

# Reset the variables set with setTcValue and friends.
macro(resetTcValues)
    foreach (_var IN LISTS _XCMAKE_TOOLCHAIN_VARS)
        unset(${_var} CACHE)
    endforeach()
    unset(_XCMAKE_TOOLCHAIN_VARS)
endmacro()

# Set a toolchain exported variable.
macro(setTcValue VAR)
    set(_XCMAKE_TOOLCHAIN_VARS ${_XCMAKE_TOOLCHAIN_VARS} ${VAR} CACHE INTERNAL "")
    set(${VAR} ${ARGN} CACHE INTERNAL "")
endmacro()

# Set a toolchain exported variable if it hasn't already been set.
macro(defaultTcValue VAR)
    if (NOT DEFINED ${VAR})
        setTcValue(${VAR} ${ARGN})
    endif()
endmacro()
