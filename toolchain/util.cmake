# Write this function's arguments to stdout.
function(stdout)
    # message() would also write to stdout, but it'd prepend ` -- `.
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${ARGN}")
endfunction()

# Set a toolchain exported variable if it hasn't already been set.
macro(default_tc_value VAR)
    if (NOT DEFINED ${VAR})
        set(${VAR} ${ARGN})
    endif()
endmacro()

# Stringify a list, putting ${SEPARATOR} between the elements.
macro(list_join OUT LIST SEPARATOR)
    string(REPLACE ";" "${SEPARATOR}" ${OUT} "${${LIST}}")
endmacro()

macro(default_cache_value NAME VALUE)
    get_property(TYP CACHE ${NAME} PROPERTY TYPE)
    if (TYP)
    else ()
        set(${NAME} ${VALUE} CACHE INTERNAL "")
    endif()
endmacro()
