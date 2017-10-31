# Write this function's arguments to stdout.
function(StdOut)
    # message() would also write to stdout, but it'd prepend ` -- `.
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${ARGN}")
endfunction()

# Reset the variables set with setTcValue and friends.
macro(resetTcValues)
    foreach (_var IN LISTS _XCMAKE_TOOLCHAIN_VARS)
        set(${_var} "${_XCMAKE_TOOLCHAIN_VAR_ORIGINAL_${_var}}" CACHE INTERNAL "")
    endforeach()
    unset(_XCMAKE_TOOLCHAIN_VARS)
endmacro()

# Set a toolchain exported variable.
macro(setTcValue VAR)
    if (NOT DEFINED _XCMAKE_TOOLCHAIN_VAR_ORIGINAL_${VAR})
        set(_XCMAKE_TOOLCHAIN_VAR_ORIGINAL_${VAR} "${VAR}" CACHE INTERNAL "")
    endif()

    set(_XCMAKE_TOOLCHAIN_VARS ${_XCMAKE_TOOLCHAIN_VARS} "${${VAR}}" CACHE INTERNAL "")
    set(${VAR} ${ARGN} CACHE INTERNAL "")
endmacro()

# Set a toolchain exported variable if it hasn't already been set.
macro(defaultTcValue VAR)
    if (NOT DEFINED ${VAR})
        setTcValue(${VAR} ${ARGN})
    endif()
endmacro()
